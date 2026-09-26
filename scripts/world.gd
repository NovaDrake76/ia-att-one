class_name World
extends Node2D

const ROWS := 3
const COLS := 3
const SCENARIO_DIR := "res://scenarios"
const AREA_DIR := "user://areas"
const ENEMY_SIZE := 24.0
const ITEM_SIZE := 18.0
const ACTIVE_COLOR := Color(0.15, 0.23, 0.15)
const INACTIVE_COLOR := Color(0.06, 0.06, 0.07)

var scenarios: Array[Dictionary] = []
var scenario_index := -1
var config: Dictionary = {}
var grid: Array = []
var active_areas: Array[Area] = []
var playing := false
var time_left := 0.0
var blast_time := 0.0

@onready var player: Player = $Player
@onready var hud: Hud = $HUD


func _ready() -> void:
	var files := DirAccess.get_files_at(SCENARIO_DIR)
	files.sort()
	for file in files:
		if file.get_extension() == "json":
			scenarios.append(JSON.parse_string(FileAccess.get_file_as_string(SCENARIO_DIR.path_join(file))))
	hud.create_menu(scenarios)
	hud.show_menu("Survive until the timer runs out!")


func start(index: int) -> void:
	scenario_index = index
	config = scenarios[index]
	player.position = world_rect().get_center()
	player.setup(config.player_speed, config.player_health)
	player.show()
	time_left = config.survival_time
	blast_time = 0.0
	create_grid()
	update_active_areas()
	playing = true
	hud.hide_menu()


func finish(message: String) -> void:
	playing = false
	hud.show_menu(message)


func world_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(COLS, ROWS) * float(config.area_size))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and scenario_index >= 0:
		start(scenario_index)
	elif playing and event.is_action_pressed("menu"):
		finish("Run stopped.")
	elif playing and event.is_action_pressed("use_medkit"):
		player.use_medkit(config.medkit_heal)
	elif playing and event.is_action_pressed("use_ammo"):
		if player.use_ammo():
			blast()


func _process(delta: float) -> void:
	queue_redraw()
	if not playing:
		return
	time_left -= delta
	blast_time -= delta
	player.move(delta, world_rect())
	update_active_areas()
	collect_items()
	update_enemies(delta)
	reassign_enemies()
	if player.health <= 0:
		finish("You died!")
	elif time_left <= 0:
		finish("You survived!")


func create_grid() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(config.seed)
	DirAccess.make_dir_recursive_absolute(AREA_DIR)
	grid.clear()
	active_areas.clear()
	for row in ROWS:
		grid.append([])
		for col in COLS:
			save_area(generate_area(Vector2i(col, row), rng))
			grid[row].append(null)


func generate_area(cell: Vector2i, rng: RandomNumberGenerator) -> Area:
	var area := Area.new(cell, config.area_size)
	var spawn_rect := area.rect.grow(-ENEMY_SIZE)
	for i in int(config.enemies_per_area):
		var point := random_point(spawn_rect, rng)
		if point.distance_to(player.position) > config.safe_radius:
			area.enemies.append(Enemy.new(point, config.enemy_health))
	for i in int(config.health_kits_per_area):
		area.items.append(Item.new(random_point(spawn_rect, rng), Item.HEALTH))
	for i in int(config.ammo_boxes_per_area):
		area.items.append(Item.new(random_point(spawn_rect, rng), Item.AMMO))
	return area


func random_point(rect: Rect2, rng: RandomNumberGenerator) -> Vector2:
	return Vector2(rng.randf_range(rect.position.x, rect.end.x), rng.randf_range(rect.position.y, rect.end.y))


func cell_of(point: Vector2) -> Vector2i:
	return Vector2i(point / config.area_size).clamp(Vector2i.ZERO, Vector2i(COLS - 1, ROWS - 1))


func area_at(cell: Vector2i) -> Area:
	return grid[cell.y][cell.x]


func cells_near_player() -> Array[Vector2i]:
	var size: float = config.area_size
	var activation_distance: float = config.activation_distance
	var cell := cell_of(player.position)
	var local_position := player.position - Vector2(cell) * size
	var side := Vector2i.ZERO
	if local_position.x < activation_distance:
		side.x = -1
	elif local_position.x > size - activation_distance:
		side.x = 1
	if local_position.y < activation_distance:
		side.y = -1
	elif local_position.y > size - activation_distance:
		side.y = 1
	var cells: Array[Vector2i] = [cell]
	for neighbor in [cell + Vector2i(side.x, 0), cell + Vector2i(0, side.y), cell + side]:
		if neighbor not in cells and Rect2i(0, 0, COLS, ROWS).has_point(neighbor):
			cells.append(neighbor)
	return cells


func update_active_areas() -> void:
	var wanted := cells_near_player()
	active_areas.clear()
	for row in ROWS:
		for col in COLS:
			var cell := Vector2i(col, row)
			if cell in wanted:
				if grid[row][col] == null:
					grid[row][col] = load_area(cell)
				active_areas.append(grid[row][col])
			elif grid[row][col] != null:
				save_area(grid[row][col])
				grid[row][col] = null


func area_path(cell: Vector2i) -> String:
	return AREA_DIR.path_join("area_%d_%d.json" % [cell.y, cell.x])


func save_area(area: Area) -> void:
	var file := FileAccess.open(area_path(area.cell), FileAccess.WRITE)
	file.store_string(JSON.stringify(area.to_dict(), "\t"))


func load_area(cell: Vector2i) -> Area:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(area_path(cell)))
	return Area.from_dict(cell, config.area_size, data)


func collect_items() -> void:
	var pickup_distance := Player.RADIUS + ITEM_SIZE / 2
	for area in active_areas:
		for i in range(area.items.size() - 1, -1, -1):
			if area.items[i].position.distance_to(player.position) < pickup_distance:
				player.pick_up(area.items[i])
				area.items.remove_at(i)


func update_enemies(delta: float) -> void:
	var step: float = config.enemy_speed * delta
	var touch_distance := Player.RADIUS + ENEMY_SIZE / 2
	var touching := 0
	for area in active_areas:
		for enemy in area.enemies:
			enemy.chase(player.position, step)
			if enemy.position.distance_to(player.position) < touch_distance:
				touching += 1
	player.health -= touching * config.enemy_damage * delta
	player.modulate = Color(1, 0.35, 0.35) if touching > 0 else Color.WHITE


func reassign_enemies() -> void:
	for area in active_areas:
		for i in range(area.enemies.size() - 1, -1, -1):
			var target := area_at(cell_of(area.enemies[i].position))
			if target != area and target in active_areas:
				target.enemies.append(area.enemies[i])
				area.enemies.remove_at(i)


func blast() -> void:
	blast_time = 0.25
	for area in active_areas:
		for enemy in area.enemies:
			if enemy.position.distance_to(player.position) < config.ammo_radius:
				enemy.health -= config.ammo_damage
		area.enemies = area.enemies.filter(func(e: Enemy) -> bool: return e.health > 0)


func _draw() -> void:
	if grid.is_empty():
		return
	var size: float = config.area_size
	for row in ROWS:
		for col in COLS:
			var rect := Rect2(Vector2(col, row) * size, Vector2(size, size))
			draw_rect(rect, ACTIVE_COLOR if grid[row][col] != null else INACTIVE_COLOR)
			draw_rect(rect, Color(0.45, 0.45, 0.45), false, 4.0)
	var current := Rect2(Vector2(cell_of(player.position)) * size, Vector2(size, size))
	draw_rect(current.grow(-config.activation_distance), Color(1, 1, 1, 0.25), false, 2.0)
	for area in active_areas:
		draw_area(area)
	if blast_time > 0:
		draw_arc(player.position, config.ammo_radius, 0, TAU, 64, Color(1, 0.6, 0.1), 6.0)


func draw_area(area: Area) -> void:
	for item in area.items:
		if item.kind == Item.HEALTH:
			draw_circle(item.position, ITEM_SIZE / 2, Color(0.2, 0.85, 0.3))
		else:
			draw_rect(Rect2(item.position - Vector2.ONE * ITEM_SIZE / 2, Vector2.ONE * ITEM_SIZE), Color(1, 0.8, 0.1))
	for enemy in area.enemies:
		draw_rect(Rect2(enemy.position - Vector2.ONE * ENEMY_SIZE / 2, Vector2.ONE * ENEMY_SIZE), Color(0.95, 0.2, 0.2))
