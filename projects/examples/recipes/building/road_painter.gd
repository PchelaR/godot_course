extends TileMapLayer

signal roads_changed

const NEIGHBORS: Dictionary[Vector2i, int] = {
	Vector2i.UP: 1,
	Vector2i.RIGHT: 2,
	Vector2i.DOWN: 4,
	Vector2i.LEFT: 8,
}

@export var ground: TileMapLayer


func _process(_delta: float) -> void:
	var cell: Vector2i = local_to_map(get_local_mouse_position())
	if Input.is_action_pressed("build") and can_pave(cell) and not has_road(cell):
		set_road(cell, true)
	elif Input.is_action_pressed("demolish") and has_road(cell):
		set_road(cell, false)


func has_road(cell: Vector2i) -> bool:
	return get_cell_source_id(cell) != -1


func can_pave(cell: Vector2i) -> bool:
	var data: TileData = ground.get_cell_tile_data(cell)
	return data != null and data.get_custom_data("buildable")


func set_road(cell: Vector2i, value: bool) -> void:
	if value:
		set_cell(cell, 0, Vector2i.ZERO)
	else:
		erase_cell(cell)
	refresh(cell)
	for offset: Vector2i in NEIGHBORS:
		refresh(cell + offset)
	roads_changed.emit()


func refresh(cell: Vector2i) -> void:
	if not has_road(cell):
		return
	var mask: int = 0
	for offset: Vector2i in NEIGHBORS:
		if has_road(cell + offset):
			mask |= NEIGHBORS[offset]
	set_cell(cell, 0, Vector2i(mask & 3, mask >> 2))
