class_name Shell
extends Node2D

const BLAST_TIME: float = 0.3

@export var flight_time: float = 1.0
@export var height: float = 120.0
@export var damage: int = 4
@export var blast_radius: float = 60.0

var from: Vector2 = Vector2.ZERO
var to: Vector2 = Vector2.ZERO
var time: float = 0.0

@onready var look: Node2D = $Look
@onready var blast: Node2D = $Blast
@onready var debris: CPUParticles2D = $Debris


func _physics_process(delta: float) -> void:
	time += delta
	var t: float = minf(time / flight_time, 1.0)
	global_position = from.lerp(to, t) + Vector2(0.0, -height * 4.0 * t * (1.0 - t))
	if t >= 1.0:
		explode()


func explode() -> void:
	set_physics_process(false)
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node as Enemy
		if enemy.flying:
			continue
		if enemy.global_position.distance_to(to) <= blast_radius:
			enemy.take_damage(damage)
	look.visible = false
	blast.visible = true
	debris.emitting = true
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(blast, "scale", Vector2.ONE, BLAST_TIME).from(Vector2(0.2, 0.2))
	tween.tween_property(blast, "modulate:a", 0.0, BLAST_TIME)
	await debris.finished
	queue_free()
