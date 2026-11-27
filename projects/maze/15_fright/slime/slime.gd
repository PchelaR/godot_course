class_name Slime
extends Walker

enum Mode { HOUSE, LEAVE, SCATTER, CHASE, FRIGHTENED }

const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]
const FRIGHT_SPEED: float = 0.6

@export var hero: Hero
@export var character: Character
@export var partner: Slime

var mode: Mode = Mode.HOUSE
var wave_mode: Mode = Mode.SCATTER
var turn_back: bool = false

@onready var body: AnimatedSprite2D = $Body
@onready var eyes: Sprite2D = $Eyes
@onready var scared: Node2D = $Scared
@onready var scared_body: AnimatedSprite2D = $Scared/Body
@onready var scared_face: AnimatedSprite2D = $Scared/Face


func _ready() -> void:
	super()
	body.sprite_frames = character.frames
	body.play(&"move")


func _physics_process(delta: float) -> void:
	var factor: float = FRIGHT_SPEED if mode == Mode.FRIGHTENED else 1.0
	advance(speed * factor * delta)
	look()


func switch_mode(next: Mode) -> void:
	wave_mode = next
	if mode != Mode.SCATTER and mode != Mode.CHASE:
		return
	if mode == next:
		return
	mode = next
	turn_back = true


func release() -> void:
	if mode == Mode.HOUSE:
		mode = Mode.LEAVE


func frighten() -> void:
	if mode != Mode.SCATTER and mode != Mode.CHASE and mode != Mode.FRIGHTENED:
		return
	mode = Mode.FRIGHTENED
	turn_back = true
	show_scared(true)


func flash() -> void:
	if mode == Mode.FRIGHTENED:
		play_scared(&"flash")


func calm() -> void:
	if mode == Mode.FRIGHTENED:
		mode = wave_mode
		show_scared(false)


func show_scared(value: bool) -> void:
	body.visible = not value
	eyes.visible = not value
	scared.visible = value
	if value:
		play_scared(&"scared")


func play_scared(animation: StringName) -> void:
	scared_body.play(animation)
	scared_face.play(animation)


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
	var options: Array[Vector2i] = []
	for option: Vector2i in DIRECTIONS:
		if option != -direction and not blocked(cell + option):
			options.append(option)
	if options.is_empty():
		direction = -direction
		return
	if mode == Mode.FRIGHTENED:
		direction = options.pick_random()
		return
	var best: Vector2i = options[0]
	for option: Vector2i in options:
		if (cell + option).distance_squared_to(target()) < (cell + best).distance_squared_to(target()):
			best = option
	direction = best


func target() -> Vector2i:
	var goal: Vector2i = cell
	match mode:
		Mode.HOUSE, Mode.FRIGHTENED:
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
