class_name Bullet
extends Node2D

signal hit(bullet: Bullet, collider: Object, point: Vector2)

@export var speed: float = 1400.0
@export var lifetime: float = 0.7

var direction: Vector2 = Vector2.RIGHT
var damage: float = 10.0
var by_player: bool = false
var exclude: Array[RID] = []


func launch(from: Vector2, toward: Vector2, ignore: Array[RID]) -> void:
	global_position = from
	direction = toward.normalized()
	rotation = direction.angle()
	exclude = ignore


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	var from: Vector2 = global_position
	var to: Vector2 = from + direction * speed * delta
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to, 15, exclude)
	var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		hit.emit(self, result["collider"], result["position"])
		queue_free()
		return
	global_position = to
