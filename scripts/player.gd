class_name Player
extends Node2D

const RADIUS := 16.0

var speed := 0.0
var max_health := 0.0
var health := 0.0
var medkits := 0
var ammo := 0

@onready var camera: Camera2D = $Camera2D


func setup(start_speed: float, start_health: float) -> void:
	speed = start_speed
	max_health = start_health
	health = start_health
	medkits = 0
	ammo = 0
	camera.reset_smoothing()


func move(delta: float, bounds: Rect2) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	position = (position + direction * speed * delta).clamp(bounds.position, bounds.end)


func pick_up(item: Item) -> void:
	if item.kind == Item.HEALTH:
		medkits += 1
	else:
		ammo += 1


func use_medkit(heal: float) -> void:
	if medkits > 0 and health < max_health:
		medkits -= 1
		health = minf(health + heal, max_health)


func use_ammo() -> bool:
	if ammo == 0:
		return false
	ammo -= 1
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		camera.zoom = (camera.zoom * 1.25).clampf(0.05, 4.0)
	elif event.is_action_pressed("zoom_out"):
		camera.zoom = (camera.zoom / 1.25).clampf(0.05, 4.0)


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(0.3, 0.6, 1.0))
