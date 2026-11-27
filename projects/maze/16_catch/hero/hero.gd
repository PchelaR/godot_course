class_name Hero
extends Walker

const ANIMATIONS: Dictionary[Vector2i, String] = {
	Vector2i.RIGHT: "right",
	Vector2i.LEFT: "left",
	Vector2i.UP: "up",
	Vector2i.DOWN: "down",
}

var wanted: Vector2i = Vector2i.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	steer(read_input())
	advance(speed * delta)
	animate()


func animate() -> void:
	if direction == Vector2i.ZERO:
		sprite.pause()
		return
	sprite.play(ANIMATIONS[direction])


func steer(input: Vector2i) -> void:
	if input == Vector2i.ZERO:
		return
	wanted = input
	if direction != Vector2i.ZERO and wanted == -direction and position != maze.map_to_local(cell):
		cell += direction
		direction = wanted


func choose_direction() -> void:
	if wanted != Vector2i.ZERO and not maze.is_wall(cell + wanted):
		direction = wanted
	elif maze.is_wall(cell + direction):
		direction = Vector2i.ZERO


func read_input() -> Vector2i:
	if Input.is_action_pressed("move_right"):
		return Vector2i.RIGHT
	if Input.is_action_pressed("move_left"):
		return Vector2i.LEFT
	if Input.is_action_pressed("move_down"):
		return Vector2i.DOWN
	if Input.is_action_pressed("move_up"):
		return Vector2i.UP
	return Vector2i.ZERO
