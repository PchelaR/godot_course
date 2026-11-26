extends Node2D

@export var map: TileMapLayer
@export var speed: float = 240.0

var cell: Vector2i
var direction: Vector2i = Vector2i.ZERO
var wanted: Vector2i = Vector2i.ZERO


func _ready() -> void:
	cell = map.local_to_map(position)
	position = map.map_to_local(cell)


func _physics_process(delta: float) -> void:
	steer(read_input())
	advance(speed * delta)


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


func steer(input: Vector2i) -> void:
	if input == Vector2i.ZERO:
		return
	wanted = input
	if direction != Vector2i.ZERO and wanted == -direction and position != map.map_to_local(cell):
		cell += direction
		direction = wanted


func advance(step: float) -> void:
	while step > 0.0:
		if position == map.map_to_local(cell):
			choose_direction()
			if direction == Vector2i.ZERO:
				return
		var target: Vector2 = map.map_to_local(cell + direction)
		var left: float = position.distance_to(target)
		if step < left:
			position = position.move_toward(target, step)
			return
		position = target
		cell += direction
		step -= left


func choose_direction() -> void:
	if wanted != Vector2i.ZERO and is_free(cell + wanted):
		direction = wanted
	elif not is_free(cell + direction):
		direction = Vector2i.ZERO


func is_free(target: Vector2i) -> bool:
	var data: TileData = map.get_cell_tile_data(target)
	return data != null and not data.get_custom_data("wall")
