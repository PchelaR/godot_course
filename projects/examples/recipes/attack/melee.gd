extends Node2D

@export var damage: int = 1
@export var active_time: float = 0.12
@export var cooldown_time: float = 0.35

var cooldown: float = 0.0
var hit: Array[Node2D] = []

@onready var hitbox: Area2D = $Hitbox
@onready var slash: Polygon2D = $Slash


func _ready() -> void:
	hitbox.monitoring = false
	slash.visible = false


func _process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and cooldown == 0.0:
		swing()


func swing() -> void:
	cooldown = cooldown_time
	look_at(get_global_mouse_position())
	hit.clear()
	hitbox.monitoring = true
	slash.visible = true
	await get_tree().create_timer(active_time).timeout
	hitbox.monitoring = false
	slash.visible = false


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body in hit or not body.has_method("take_hit"):
		return
	hit.append(body)
	body.call("take_hit", damage)
