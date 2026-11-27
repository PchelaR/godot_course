class_name Coins
extends TileMapLayer

signal eaten(points: int)
signal powered
signal cleared


func eat(cell: Vector2i) -> void:
	var data: TileData = get_cell_tile_data(cell)
	if data == null:
		return
	erase_cell(cell)
	eaten.emit(data.get_custom_data("points"))
	if data.get_custom_data("power"):
		powered.emit()
	if get_used_cells().is_empty():
		cleared.emit()
