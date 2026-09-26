class_name Hud
extends CanvasLayer

@onready var world: World = get_parent()
@onready var info: Label = $Info
@onready var menu: Control = $Menu
@onready var title: Label = %Title
@onready var buttons: VBoxContainer = %Buttons


func create_menu(scenarios: Array[Dictionary]) -> void:
	for i in scenarios.size():
		var button := Button.new()
		button.text = scenarios[i].name
		button.pressed.connect(world.start.bind(i))
		buttons.add_child(button)


func show_menu(message: String) -> void:
	title.text = message
	menu.show()


func hide_menu() -> void:
	menu.hide()


func _process(_delta: float) -> void:
	if world.grid.is_empty():
		return
	var player := world.player
	info.text = "\n".join([
		world.config.name,
		"Time left: %.1f s" % maxf(world.time_left, 0.0),
		"Health: %d / %d" % [ceili(maxf(player.health, 0.0)), player.max_health],
		"Medkits: %d" % player.medkits,
		"Ammo: %d" % player.ammo,
	])
