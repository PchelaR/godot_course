class_name Maze
extends TileMapLayer


func is_wall(cell: Vector2i) -> bool:
	var data: TileData = get_cell_tile_data(cell)
	return data == null or data.get_custom_data("wall")
