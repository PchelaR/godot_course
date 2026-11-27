extends Node2D

const NEIGHBORS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

@export var roads: TileMapLayer
@export var hall_cell: Vector2i = Vector2i.ZERO


func _ready() -> void:
	refresh()


func refresh() -> void:
	var reached: Dictionary[Vector2i, bool] = connected_roads()
	for building: Node2D in get_children():
		var cell: Vector2i = roads.local_to_map(building.position)
		building.modulate.a = 1.0 if touches(cell, reached) else 0.35


func connected_roads() -> Dictionary[Vector2i, bool]:
	var reached: Dictionary[Vector2i, bool] = {}
	var queue: Array[Vector2i] = []
	for offset: Vector2i in NEIGHBORS:
		visit(hall_cell + offset, reached, queue)
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for offset: Vector2i in NEIGHBORS:
			visit(cell + offset, reached, queue)
	return reached


func visit(cell: Vector2i, reached: Dictionary[Vector2i, bool], queue: Array[Vector2i]) -> void:
	if reached.has(cell) or roads.get_cell_source_id(cell) == -1:
		return
	reached[cell] = true
	queue.append(cell)


func touches(cell: Vector2i, reached: Dictionary[Vector2i, bool]) -> bool:
	for offset: Vector2i in NEIGHBORS:
		if reached.has(cell + offset):
			return true
	return false
