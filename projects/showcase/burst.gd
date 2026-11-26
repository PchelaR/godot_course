extends Node2D

@export var radius: float = 90.0
@export var small: bool = false

@onready var particles: CPUParticles2D = $Particles
@onready var flash: Polygon2D = $Flash


func _ready() -> void:
	if small:
		radius = 10.0
		particles.amount = 6
		particles.lifetime = 0.25
		particles.initial_velocity_min = 40.0
		particles.initial_velocity_max = 120.0
		particles.scale_amount_min = 2.0
		particles.scale_amount_max = 3.0
	particles.emitting = true
	var points: PackedVector2Array = PackedVector2Array()
	for step: int in 16:
		points.append(Vector2.from_angle(step * TAU / 16.0) * radius)
	flash.polygon = points
	var tween: Tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.12 if small else 0.35)
	tween.parallel().tween_property(flash, "scale", Vector2(1.4, 1.4), 0.12 if small else 0.35)
	get_tree().create_timer(particles.lifetime + 0.3).timeout.connect(queue_free)
