class_name Bullet
extends Area2D

@export var speed: float = 900.0
@export var damage: int = 1
@export var lifetime: float = 1.5


func _physics_process(delta: float) -> void:
	position += transform.x * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		return
	if body.has_method("take_hit"):
		body.call("take_hit", damage)
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_hit"):
		area.call("take_hit", damage)
		queue_free()
