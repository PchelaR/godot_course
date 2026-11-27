extends Camera2D

@export var speed: float = 800.0
@export var edge: float = 24.0
@export var world_size: Vector2 = Vector2(3456, 1944)

var mouse_inside: bool = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_inside = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT:
		mouse_inside = false


func _process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if mouse_inside:
		direction += edge_direction()
	position += direction.limit_length(1.0) * speed * delta / zoom.x
	keep_inside()


func edge_direction() -> Vector2:
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var size: Vector2 = get_viewport_rect().size
	var direction: Vector2 = Vector2.ZERO
	if mouse.x < edge:
		direction.x = -1.0
	elif mouse.x > size.x - edge:
		direction.x = 1.0
	if mouse.y < edge:
		direction.y = -1.0
	elif mouse.y > size.y - edge:
		direction.y = 1.0
	return direction


func keep_inside() -> void:
	var half: Vector2 = get_viewport_rect().size / zoom / 2.0
	position = position.clamp(half, world_size - half)
