extends Node2D

const STEPS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
const REACH: Color = Color(0.7843, 0.651, 0.8627, 0.4)

@export var map: TileMapLayer
@export var unit: Node2D
@export var moves: int = 4
@export var step_time: float = 0.12

var unit_cell: Vector2i
var came_from: Dictionary[Vector2i, Vector2i] = {}
var walking: bool = false


func _ready() -> void:
	unit_cell = map.local_to_map(unit.position)
	unit.position = map.map_to_local(unit_cell)
	find_reachable()


func _unhandled_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if walking or click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var cell: Vector2i = map.local_to_map(map.get_local_mouse_position())
	if cell != unit_cell and came_from.has(cell):
		walk(path_to(cell))


func is_free(cell: Vector2i) -> bool:
	var data: TileData = map.get_cell_tile_data(cell)
	return data != null and not data.get_custom_data("wall")


func find_reachable() -> void:
	came_from = {unit_cell: unit_cell}
	var frontier: Array[Vector2i] = [unit_cell]
	for _round: int in range(moves):
		var next: Array[Vector2i] = []
		for cell: Vector2i in frontier:
			for step: Vector2i in STEPS:
				var neighbor: Vector2i = cell + step
				if is_free(neighbor) and not came_from.has(neighbor):
					came_from[neighbor] = cell
					next.append(neighbor)
		frontier = next
	queue_redraw()


func path_to(cell: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	while cell != unit_cell:
		path.push_front(cell)
		cell = came_from[cell]
	return path


func walk(path: Array[Vector2i]) -> void:
	walking = true
	came_from = {}
	queue_redraw()
	var tween: Tween = create_tween()
	for cell: Vector2i in path:
		tween.tween_property(unit, "position", map.map_to_local(cell), step_time)
	await tween.finished
	unit_cell = path.back()
	walking = false
	find_reachable()


func _draw() -> void:
	var size: Vector2 = Vector2(map.tile_set.tile_size)
	for cell: Vector2i in came_from:
		if cell != unit_cell:
			var corner: Vector2 = map.position + map.map_to_local(cell) - size / 2
			draw_rect(Rect2(corner, size).grow(-3.0), REACH)
