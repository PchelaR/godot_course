extends TileMapLayer

@export var ground: TileMapLayer
@export var house_scene: PackedScene

var houses: Dictionary[Vector2i, Node2D] = {}


func _process(_delta: float) -> void:
	var cell: Vector2i = local_to_map(get_local_mouse_position())
	if Input.is_action_pressed("build") and can_zone(cell):
		set_cell(cell, 0, Vector2i.ZERO)
	elif Input.is_action_pressed("demolish") and get_cell_source_id(cell) != -1:
		erase_cell(cell)
		if houses.has(cell):
			houses[cell].queue_free()
			houses.erase(cell)


func can_zone(cell: Vector2i) -> bool:
	if get_cell_source_id(cell) != -1:
		return false
	var data: TileData = ground.get_cell_tile_data(cell)
	return data != null and data.get_custom_data("buildable")


func _on_growth_timeout() -> void:
	var empty: Array[Vector2i] = []
	for cell: Vector2i in get_used_cells():
		if not houses.has(cell):
			empty.append(cell)
	if empty.is_empty():
		return
	var cell: Vector2i = empty.pick_random()
	var house: Node2D = house_scene.instantiate()
	house.position = map_to_local(cell)
	add_child(house)
	houses[cell] = house
