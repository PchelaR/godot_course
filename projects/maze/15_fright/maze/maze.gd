class_name Maze
extends TileMapLayer

@export var door: Vector2i = Vector2i(12, 6)


func is_wall(cell: Vector2i) -> bool:
	var data: TileData = get_cell_tile_data(cell)
	return data == null or data.get_custom_data("wall")


func through_tunnel(cell: Vector2i) -> Vector2i:
	var area: Rect2i = get_used_rect()
	if cell.x == area.position.x:
		return Vector2i(area.end.x - 1, cell.y)
	if cell.x == area.end.x - 1:
		return Vector2i(area.position.x, cell.y)
	return cell


func house_exit() -> Vector2i:
	return door + Vector2i.UP
