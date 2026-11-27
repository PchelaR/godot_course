class_name Slime
extends Walker

enum Mode { SCATTER, CHASE }

const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]

@export var hero: Hero
@export var corner: Vector2i = Vector2i(24, -1)

var mode: Mode = Mode.SCATTER
var turn_back: bool = false

@onready var eyes: Sprite2D = $Eyes


func _physics_process(delta: float) -> void:
	advance(speed * delta)
	look()


func switch_mode(next: Mode) -> void:
	if next == mode:
		return
	mode = next
	turn_back = true


func choose_direction() -> void:
	if turn_back:
		turn_back = false
		if direction != Vector2i.ZERO and not maze.is_wall(cell - direction):
			direction = -direction
			return
	var best: Vector2i = -direction
	var best_distance: int = -1
	for option: Vector2i in DIRECTIONS:
		if option == -direction or maze.is_wall(cell + option):
			continue
		var distance: int = (cell + option).distance_squared_to(target())
		if best_distance < 0 or distance < best_distance:
			best_distance = distance
			best = option
	direction = best


func target() -> Vector2i:
	var goal: Vector2i = hero.cell
	match mode:
		Mode.SCATTER:
			goal = corner
		Mode.CHASE:
			goal = hero.cell
	return goal


func look() -> void:
	if direction.x != 0:
		eyes.frame = 0 if direction.x > 0 else 1
