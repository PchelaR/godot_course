class_name Hero
extends Walker

signal died

const ANIMATIONS: Dictionary[Vector2i, String] = {
	Vector2i.RIGHT: "right",
	Vector2i.LEFT: "left",
	Vector2i.UP: "up",
	Vector2i.DOWN: "down",
}
const BLINKS: int = 3
const BLINK_TIME: float = 0.15
const FALL_TIME: float = 0.5
const FALL_SPEED: float = 48.0

var wanted: Vector2i = Vector2i.ZERO
var dying: bool = false
var death_time: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	steer(read_input())
	advance(speed * delta)
	animate()


func _process(delta: float) -> void:
	if not dying:
		return
	death_time += delta
	var blinking: float = BLINKS * 2 * BLINK_TIME
	if death_time < blinking:
		sprite.visible = int(death_time / BLINK_TIME) % 2 == 1
		return
	sprite.visible = true
	sprite.flip_v = true
	sprite.position.y += FALL_SPEED * delta
	if death_time >= blinking + FALL_TIME:
		dying = false
		sprite.visible = false
		died.emit()


func reset() -> void:
	super()
	wanted = Vector2i.ZERO
	dying = false
	sprite.visible = true
	sprite.flip_v = false
	sprite.position = Vector2.ZERO


func die() -> void:
	dying = true
	death_time = 0.0
	sprite.pause()


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
