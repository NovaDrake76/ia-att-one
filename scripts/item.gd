class_name Item
extends RefCounted

const HEALTH := "health"
const AMMO := "ammo"

var position: Vector2
var kind: String


func _init(start_position: Vector2, item_kind: String) -> void:
	position = start_position
	kind = item_kind
