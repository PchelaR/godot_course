extends Sprite2D

@export var duration: float = 0.3

@onready var shader: ShaderMaterial = material as ShaderMaterial


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var tween: Tween = create_tween()
		tween.tween_property(shader, "shader_parameter/amount", 0.0, duration).from(1.0)
