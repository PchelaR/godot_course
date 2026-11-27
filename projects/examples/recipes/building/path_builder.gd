extends Node2D

const FREE: Color = Color(0.9098, 0.3333, 0.1843, 0.5)
const BLOCKED: Color = Color(0.1686, 0.1294, 0.1098, 0.5)
const NEIGHBORS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const NOWHERE: Vector2i = Vector2i(-1000, -1000)

@export var ground: TileMapLayer
@export var building_scene: PackedScene
@export var start: Vector2i = Vector2i(0, 6)
@export var goal: Vector2i = Vector2i(23, 6)

var buildings: Dictionary[Vector2i, Node2D] = {}

@onready var ghost: Polygon2D = $Ghost
@onready var route: Line2D = $Route


func _ready() -> void:
	show_route()


func _process(_delta: float) -> void:
	var cell: Vector2i = hovered_cell()
	ghost.position = ground.map_to_local(cell)
	ghost.color = FREE if can_build(cell) else BLOCKED


func _unhandled_input(event: InputEvent) -> void:
	var cell: Vector2i = hovered_cell()
	if event.is_action_pressed("build") and can_build(cell):
		var building: Node2D = building_scene.instantiate()
		building.position = ground.map_to_local(cell)
		add_child(building)
		buildings[cell] = building
		show_route()
	elif event.is_action_pressed("demolish") and buildings.has(cell):
		buildings[cell].queue_free()
		buildings.erase(cell)
		show_route()


func hovered_cell() -> Vector2i:
	return ground.local_to_map(ground.get_local_mouse_position())


func can_build(cell: Vector2i) -> bool:
	if cell == start or cell == goal or not passable(cell, NOWHERE):
		return false
	return not find_path(cell).is_empty()


func passable(cell: Vector2i, extra_wall: Vector2i) -> bool:
	if cell == extra_wall or buildings.has(cell):
		return false
	var data: TileData = ground.get_cell_tile_data(cell)
	return data != null and data.get_custom_data("buildable")


func find_path(extra_wall: Vector2i) -> Array[Vector2i]:
	var came_from: Dictionary[Vector2i, Vector2i] = {start: start}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if cell == goal:
			break
		for offset: Vector2i in NEIGHBORS:
			var next: Vector2i = cell + offset
			if not came_from.has(next) and passable(next, extra_wall):
				came_from[next] = cell
				queue.append(next)
	var path: Array[Vector2i] = []
	if not came_from.has(goal):
		return path
	var step: Vector2i = goal
	while step != start:
		path.push_front(step)
		step = came_from[step]
	path.push_front(start)
	return path


func show_route() -> void:
	var points: PackedVector2Array = []
	for cell: Vector2i in find_path(NOWHERE):
		points.append(ground.map_to_local(cell))
	route.points = points
