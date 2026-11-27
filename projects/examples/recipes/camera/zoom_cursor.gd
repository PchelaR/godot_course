extends Camera2D

@export var zoom_step: float = 1.15
@export var min_zoom: float = 0.4
@export var max_zoom: float = 2.5
@export var world_size: Vector2 = Vector2(3456, 1944)


func _unhandled_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or not button.pressed:
		return
	var factor: float = 1.0
	if button.button_index == MOUSE_BUTTON_WHEEL_UP:
		factor = zoom_step
	elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		factor = 1.0 / zoom_step
	else:
		return
	var offset: Vector2 = get_viewport().get_mouse_position() - get_viewport_rect().size / 2.0
	var before: Vector2 = offset / zoom
	var value: float = clampf(zoom.x * factor, min_zoom, max_zoom)
	zoom = Vector2(value, value)
	position += before - offset / zoom
	keep_inside()


func keep_inside() -> void:
	var half: Vector2 = get_viewport_rect().size / zoom / 2.0
	position = position.clamp(half, world_size - half)
