class_name Slime
extends Walker

enum Mode { HOUSE, LEAVE, SCATTER, CHASE }

const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]

@export var hero: Hero
@export var character: Character
@export var partner: Slime

var mode: Mode = Mode.HOUSE
var wave_mode: Mode = Mode.SCATTER
var turn_back: bool = false

@onready var body: AnimatedSprite2D = $Body
@onready var eyes: Sprite2D = $Eyes


func _ready() -> void:
	super()
	body.sprite_frames = character.frames
	body.play(&"move")


func _physics_process(delta: float) -> void:
	advance(speed * delta)
	look()


func switch_mode(next: Mode) -> void:
	wave_mode = next
	if mode == next or mode == Mode.HOUSE or mode == Mode.LEAVE:
		return
	mode = next
	turn_back = true


func release() -> void:
	if mode == Mode.HOUSE:
		mode = Mode.LEAVE


func blocked(target_cell: Vector2i) -> bool:
	if mode == Mode.LEAVE and target_cell == maze.door:
		return false
	return maze.is_wall(target_cell)


func choose_direction() -> void:
	if mode == Mode.LEAVE and cell == maze.house_exit():
		mode = wave_mode
	if turn_back:
		turn_back = false
		if direction != Vector2i.ZERO and not blocked(cell - direction):
			direction = -direction
			return
	var best: Vector2i = -direction
	var best_distance: int = -1
	for option: Vector2i in DIRECTIONS:
		if option == -direction or blocked(cell + option):
			continue
		var distance: int = (cell + option).distance_squared_to(target())
		if best_distance < 0 or distance < best_distance:
			best_distance = distance
			best = option
	direction = best


func target() -> Vector2i:
	var goal: Vector2i = cell
	match mode:
		Mode.HOUSE:
			goal = cell
		Mode.LEAVE:
			goal = maze.house_exit()
		Mode.SCATTER:
			goal = character.corner
		Mode.CHASE:
			goal = character.chase_target(self)
	return goal


func look() -> void:
	if direction.x != 0:
		eyes.frame = 0 if direction.x > 0 else 1
