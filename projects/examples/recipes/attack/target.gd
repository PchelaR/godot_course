extends StaticBody2D

@export var health: int = 3
@export var respawn_time: float = 1.5

var left: int

@onready var look: Polygon2D = $Look
@onready var shape: CollisionShape2D = $Shape


func _ready() -> void:
	left = health


func take_hit(damage: int) -> void:
	left -= damage
	look.scale = Vector2.ONE * (0.5 + 0.5 * float(left) / health)
	if left <= 0:
		fall()


func fall() -> void:
	visible = false
	shape.set_deferred("disabled", true)
	await get_tree().create_timer(respawn_time).timeout
	left = health
	look.scale = Vector2.ONE
	visible = true
	shape.set_deferred("disabled", false)
