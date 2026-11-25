extends Sprite2D

var speed: float = 300.0


func _ready() -> void:
	position = get_viewport_rect().size / 2


func _process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	position += direction * speed * delta
	if Input.is_action_just_pressed("ui_accept"):
		rotation += PI / 2


func _unhandled_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		position = get_global_mouse_position()
