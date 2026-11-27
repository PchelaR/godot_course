extends Node2D

const FREE: Color = Color(1, 1, 1, 0.5)
const BLOCKED: Color = Color(0.2, 0.2, 0.2, 0.5)

@export var ground: TileMapLayer
@export var building_scene: PackedScene
@export var size: Vector2i = Vector2i(3, 1)

var turns: int = 0
var occupied: Dictionary[Vector2i, Node2D] = {}

@onready var ghost: Node2D = $Ghost


func _process(_delta: float) -> void:
	var origin: Vector2i = hovered_origin()
	ghost.position = center(origin)
	ghost.rotation = turns * PI / 2.0
	ghost.modulate = FREE if can_build(origin) else BLOCKED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("rotate"):
		turns = (turns + 1) % 4
	elif event.is_action_pressed("build") and can_build(hovered_origin()):
		place(hovered_origin())
	elif event.is_action_pressed("demolish"):
		var cell: Vector2i = ground.local_to_map(ground.get_local_mouse_position())
		if occupied.has(cell):
			remove(occupied[cell])


func current_size() -> Vector2i:
	return Vector2i(size.y, size.x) if turns % 2 == 1 else size


func hovered_origin() -> Vector2i:
	var cell: Vector2i = ground.local_to_map(ground.get_local_mouse_position())
	return cell - (current_size() - Vector2i.ONE) / 2


func center(origin: Vector2i) -> Vector2:
	var tile: Vector2 = Vector2(ground.tile_set.tile_size)
	return ground.map_to_local(origin) - tile / 2.0 + Vector2(current_size()) * tile / 2.0


func cells_of(origin: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in current_size().y:
		for x: int in current_size().x:
			cells.append(origin + Vector2i(x, y))
	return cells


func can_build(origin: Vector2i) -> bool:
	for cell: Vector2i in cells_of(origin):
		if occupied.has(cell):
			return false
		var data: TileData = ground.get_cell_tile_data(cell)
		if data == null or not data.get_custom_data("buildable"):
			return false
	return true


func place(origin: Vector2i) -> void:
	var building: Node2D = building_scene.instantiate()
	building.position = center(origin)
	building.rotation = turns * PI / 2.0
	add_child(building)
	for cell: Vector2i in cells_of(origin):
		occupied[cell] = building


func remove(building: Node2D) -> void:
	for cell: Vector2i in occupied.keys():
		if occupied[cell] == building:
			occupied.erase(cell)
	building.queue_free()
