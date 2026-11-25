extends Camera2D

const ZOOM_STEP: float = 1.1
const MIN_ZOOM: float = 0.25
const MAX_ZOOM: float = 4.0

var dragging: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_WHEEL_UP and button.pressed:
			set_zoom_level(zoom.x * ZOOM_STEP)
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN and button.pressed:
			set_zoom_level(zoom.x / ZOOM_STEP)
		elif button.button_index == MOUSE_BUTTON_LEFT:
			dragging = button.pressed
	elif event is InputEventMouseMotion and dragging:
		var motion := event as InputEventMouseMotion
		position -= motion.relative / zoom


func set_zoom_level(level: float) -> void:
	var value: float = clampf(level, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2(value, value)
