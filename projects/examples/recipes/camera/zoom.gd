extends Camera2D

@export var zoom_step: float = 1.15
@export var min_zoom: float = 0.4
@export var max_zoom: float = 2.5
@export var smoothing: float = 10.0

var wanted: float = 1.0


func _unhandled_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or not button.pressed:
		return
	if button.button_index == MOUSE_BUTTON_WHEEL_UP:
		wanted *= zoom_step
	elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		wanted /= zoom_step
	wanted = clampf(wanted, min_zoom, max_zoom)


func _process(delta: float) -> void:
	var value: float = lerpf(zoom.x, wanted, 1.0 - exp(-smoothing * delta))
	zoom = Vector2(value, value)
