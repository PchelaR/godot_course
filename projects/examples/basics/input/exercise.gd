extends Sprite2D

var speed: float = 300.0


func _ready() -> void:
	position = get_viewport_rect().size / 2


func _process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var current_speed: float = speed
	if Input.is_action_pressed("ui_accept"):
		current_speed = speed * 2
	position += direction * current_speed * delta


func _unhandled_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed:
		return
	if click.button_index == MOUSE_BUTTON_LEFT:
		position = get_global_mouse_position()
	elif click.button_index == MOUSE_BUTTON_RIGHT:
		rotation += PI / 2
