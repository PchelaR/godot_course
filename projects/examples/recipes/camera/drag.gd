extends Camera2D

@export var world_size: Vector2 = Vector2(3456, 1944)

var dragging: bool = false


func _unhandled_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
		dragging = button.pressed
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and dragging:
		position -= motion.relative / zoom
		keep_inside()


func keep_inside() -> void:
	var half: Vector2 = get_viewport_rect().size / zoom / 2.0
	position = position.clamp(half, world_size - half)
