extends Node2D

signal stepped(cell: Vector2i)

@export var map: TileMapLayer
@export var step_time: float = 0.12
@export var bump_distance: float = 8.0

var cell: Vector2i
var busy: bool = false


func _ready() -> void:
	cell = map.local_to_map(position)
	position = map.map_to_local(cell)


func _physics_process(_delta: float) -> void:
	if busy:
		return
	var step: Vector2i = read_input()
	if step == Vector2i.ZERO:
		return
	if is_free(cell + step):
		move_to(cell + step)
	else:
		bump(step)


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


func move_to(target: Vector2i) -> void:
	busy = true
	cell = target
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", map.map_to_local(cell), step_time)
	await tween.finished
	busy = false
	stepped.emit(cell)


func bump(step: Vector2i) -> void:
	busy = true
	var home: Vector2 = map.map_to_local(cell)
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", home + Vector2(step) * bump_distance, step_time / 3)
	tween.tween_property(self, "position", home, step_time / 3)
	await tween.finished
	busy = false


func is_free(target: Vector2i) -> bool:
	var data: TileData = map.get_cell_tile_data(target)
	return data != null and not data.get_custom_data("wall")
