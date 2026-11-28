extends Node

@onready var map: TileMapLayer = $Map


func _ready() -> void:
	print("Стен на карте: ", count_walls())


func count_walls() -> int:
	var total: int = 0
	for cell: Vector2i in map.get_used_cells():
		var data: TileData = map.get_cell_tile_data(cell)
		if data.get_custom_data("wall"):
			total += 1
	return total
