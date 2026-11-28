extends Node

@onready var map: TileMapLayer = $Map


func _ready() -> void:
	for cell: Vector2i in [Vector2i(0, 0), Vector2i(1, 1), Vector2i(3, 2), Vector2i(30, 5)]:
		print(cell, " стена: ", is_wall(cell))
	print("Клетка точки (100, 70): ", map.local_to_map(Vector2(100, 70)))
	print("Центр клетки (2, 1): ", map.map_to_local(Vector2i(2, 1)))


func is_wall(cell: Vector2i) -> bool:
	var data: TileData = map.get_cell_tile_data(cell)
	if data == null:
		return true
	return data.get_custom_data("wall")
