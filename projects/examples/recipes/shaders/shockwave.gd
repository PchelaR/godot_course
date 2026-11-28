extends ColorRect

@export var duration: float = 0.8
@export var max_radius: float = 1.2

@onready var shader: ShaderMaterial = material as ShaderMaterial


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("build"):
		return
	shader.set_shader_parameter("center", get_global_mouse_position() / size)
	shader.set_shader_parameter("aspect", size.x / size.y)
	var tween: Tween = create_tween()
	tween.tween_property(shader, "shader_parameter/radius", max_radius, duration).from(0.0)
