extends Node2D

@export var map: TileMapLayer
@export var step_time: float = 0.12

var cell: Vector2i
var grid: AStarGrid2D = AStarGrid2D.new()


func _ready() -> void:
	cell = map.local_to_map(position)
	position = map.map_to_local(cell)
	grid.region = map.get_used_rect()
	grid.cell_size = Vector2(map.tile_set.tile_size)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for tile: Vector2i in map.get_used_cells():
		if map.get_cell_tile_data(tile).get_custom_data("wall"):
			grid.set_point_solid(tile)


func _on_player_stepped(player_cell: Vector2i) -> void:
	var path: Array[Vector2i] = grid.get_id_path(cell, player_cell)
	if path.size() < 3:
		return
	cell = path[1]
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", map.map_to_local(cell), step_time)
