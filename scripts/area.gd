class_name Area
extends RefCounted

var cell: Vector2i
var rect: Rect2
var enemies: Array[Enemy] = []
var items: Array[Item] = []


func _init(grid_cell: Vector2i, size: float) -> void:
	cell = grid_cell
	rect = Rect2(Vector2(grid_cell) * size, Vector2(size, size))


func to_dict() -> Dictionary:
	var enemy_list := []
	for enemy in enemies:
		enemy_list.append({"x": enemy.position.x, "y": enemy.position.y, "health": enemy.health})
	var item_list := []
	for item in items:
		item_list.append({"x": item.position.x, "y": item.position.y, "kind": item.kind})
	return {"enemies": enemy_list, "items": item_list}


static func from_dict(grid_cell: Vector2i, size: float, data: Dictionary) -> Area:
	var area := Area.new(grid_cell, size)
	for enemy in data.enemies:
		area.enemies.append(Enemy.new(Vector2(enemy.x, enemy.y), enemy.health))
	for item in data.items:
		area.items.append(Item.new(Vector2(item.x, item.y), item.kind))
	return area
