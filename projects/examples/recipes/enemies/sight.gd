extends CharacterBody2D

const CALM: Color = Color(0.7843, 0.651, 0.8627, 0.25)
const ALERT: Color = Color(0.9098, 0.3333, 0.1843, 0.35)

@export var player: Node2D
@export var view_distance: float = 360.0
@export var view_angle: float = 70.0
@export var sweep: float = 1.0
@export var sweep_speed: float = 0.8

var base_rotation: float
var time: float = 0.0
var sees: bool = false

@onready var eye: RayCast2D = $Eye


func _ready() -> void:
	base_rotation = rotation


func _physics_process(delta: float) -> void:
	sees = can_see(player)
	if sees:
		look_at(player.global_position)
	else:
		time += delta
		rotation = base_rotation + sin(time * sweep_speed) * sweep
	queue_redraw()


func can_see(target: Node2D) -> bool:
	var offset: Vector2 = target.global_position - global_position
	if offset.length() > view_distance:
		return false
	var facing: Vector2 = Vector2.RIGHT.rotated(global_rotation)
	if absf(rad_to_deg(facing.angle_to(offset))) > view_angle / 2:
		return false
	eye.target_position = eye.to_local(target.global_position)
	eye.force_raycast_update()
	return eye.get_collider() == target


func _draw() -> void:
	var half: float = deg_to_rad(view_angle / 2)
	var points: PackedVector2Array = [Vector2.ZERO]
	for i: int in range(17):
		var angle: float = lerpf(-half, half, i / 16.0)
		points.append(Vector2.RIGHT.rotated(angle) * view_distance)
	draw_colored_polygon(points, ALERT if sees else CALM)
