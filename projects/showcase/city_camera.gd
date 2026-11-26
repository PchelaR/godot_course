class_name CityCamera
extends Camera2D

@export var target: Node2D
@export var smoothing: float = 6.0
@export var walk_zoom: float = 1.3
@export var drive_zoom: float = 1.0
@export var fast_zoom: float = 0.6
@export var fast_speed: float = 500.0
@export var zoom_smoothing: float = 2.0
@export var peek: float = 0.3
@export var peek_limit: float = 220.0
@export var shake_strength: float = 18.0

var trauma: float = 0.0


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var wanted_position: Vector2 = target.global_position
	var wanted_zoom: float = walk_zoom
	var car: Vehicle = target as Vehicle
	if car != null:
		wanted_position += car.linear_velocity * 0.35
		wanted_zoom = lerpf(drive_zoom, fast_zoom, minf(car.speed() / fast_speed, 1.0))
	else:
		wanted_position += ((get_global_mouse_position() - target.global_position) * peek).limit_length(peek_limit)
	global_position = global_position.lerp(wanted_position, 1.0 - exp(-smoothing * delta))
	zoom = zoom.lerp(Vector2.ONE * wanted_zoom, 1.0 - exp(-zoom_smoothing * delta))
	trauma = maxf(trauma - delta * 1.5, 0.0)
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * trauma * trauma * shake_strength


func shake(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)


func snap() -> void:
	if target != null:
		global_position = target.global_position
