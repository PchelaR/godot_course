extends Node2D

const FREE: Color = Color(0.9098, 0.3333, 0.1843, 0.5)
const BLOCKED: Color = Color(0.1686, 0.1294, 0.1098, 0.5)
const MARGIN: float = 4.0

@export var ground: TileMapLayer
@export var color: Color = Color(0.9098, 0.3333, 0.1843, 1)
@export var sizes: Array[Vector2i] = [Vector2i(1, 1), Vector2i(2, 2), Vector2i(3, 2)]

var size_index: int = 0
var occupied: Dictionary[Vector2i, Node2D] = {}

@onready var ghost: Polygon2D = $Ghost


func _process(_delta: float) -> void:
	var origin: Vector2i = hovered_origin()
	ghost.polygon = footprint(current_size())
	ghost.position = corner(origin)
	ghost.color = FREE if can_build(origin) else BLOCKED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("next_building"):
		size_index = (size_index + 1) % sizes.size()
	elif event.is_action_pressed("build") and can_build(hovered_origin()):
		place(hovered_origin())
	elif event.is_action_pressed("demolish"):
		var cell: Vector2i = ground.local_to_map(ground.get_local_mouse_position())
		if occupied.has(cell):
			remove(occupied[cell])


func current_size() -> Vector2i:
	return sizes[size_index]


func hovered_origin() -> Vector2i:
	var cell: Vector2i = ground.local_to_map(ground.get_local_mouse_position())
	return cell - (current_size() - Vector2i.ONE) / 2


func corner(origin: Vector2i) -> Vector2:
	return ground.map_to_local(origin) - Vector2(ground.tile_set.tile_size) / 2.0


func footprint(size: Vector2i) -> PackedVector2Array:
	var full: Vector2 = Vector2(size * ground.tile_set.tile_size)
	var low: Vector2 = Vector2.ONE * MARGIN
	var high: Vector2 = full - Vector2.ONE * MARGIN
	return PackedVector2Array([low, Vector2(high.x, low.y), high, Vector2(low.x, high.y)])


func cells_of(origin: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in size.y:
		for x: int in size.x:
			cells.append(origin + Vector2i(x, y))
	return cells


func can_build(origin: Vector2i) -> bool:
	for cell: Vector2i in cells_of(origin, current_size()):
		if occupied.has(cell):
			return false
		var data: TileData = ground.get_cell_tile_data(cell)
		if data == null or not data.get_custom_data("buildable"):
			return false
	return true


func place(origin: Vector2i) -> void:
	var building: Polygon2D = Polygon2D.new()
	building.polygon = footprint(current_size())
	building.color = color
	building.position = corner(origin)
	add_child(building)
	for cell: Vector2i in cells_of(origin, current_size()):
		occupied[cell] = building


func remove(building: Node2D) -> void:
	for cell: Vector2i in occupied.keys():
		if occupied[cell] == building:
			occupied.erase(cell)
	building.queue_free()
