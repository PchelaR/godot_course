extends ColorRect

@export var duration: float = 1.2
@export var pause: float = 1.0

var busy: bool = false

@onready var shader: ShaderMaterial = material as ShaderMaterial


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("build") and not busy:
		dissolve()


func dissolve() -> void:
	busy = true
	var tween: Tween = create_tween()
	tween.tween_property(shader, "shader_parameter/progress", 1.0, duration)
	tween.tween_interval(pause)
	tween.tween_property(shader, "shader_parameter/progress", 0.0, duration)
	await tween.finished
	busy = false
