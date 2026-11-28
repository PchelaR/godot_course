extends Sprite2D

@export var max_tilt: float = 18.0
@export var idle_tilt: float = 4.0
@export var smoothing: float = 10.0
@export var lift: float = 30.0

var tilt: Vector2 = Vector2.ZERO
var time: float = 0.0
var selected: bool = false
var rest: Vector2 = Vector2.ZERO

@onready var shader: ShaderMaterial = material as ShaderMaterial


func _ready() -> void:
	rest = position
	time = randf() * TAU


func _process(delta: float) -> void:
	time += delta
	var local: Vector2 = to_local(get_global_mouse_position())
	var half: Vector2 = texture.get_size() / 2.0
	var wanted: Vector2 = Vector2(sin(time), cos(time * 0.8)) * idle_tilt
	if get_rect().has_point(local):
		wanted = local / half * max_tilt
	tilt = tilt.lerp(wanted, 1.0 - exp(-smoothing * delta))
	shader.set_shader_parameter("y_rot", tilt.x)
	shader.set_shader_parameter("x_rot", -tilt.y)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("build"):
		return
	if not get_rect().has_point(to_local(get_global_mouse_position())):
		return
	get_viewport().set_input_as_handled()
	selected = not selected
	var tween: Tween = create_tween().set_parallel()
	var target: Vector2 = rest + Vector2(0.0, -lift if selected else 0.0)
	tween.tween_property(self, "position", target, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.5).from(Vector2(1.15, 1.15)).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "rotation", 0.0, 0.5).from(0.15).set_trans(Tween.TRANS_ELASTIC)
