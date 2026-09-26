class_name Enemy
extends RefCounted

var position: Vector2
var health: float


func _init(start_position: Vector2, start_health: float) -> void:
	position = start_position
	health = start_health


func chase(target: Vector2, step: float) -> void:
	position = position.move_toward(target, step)
