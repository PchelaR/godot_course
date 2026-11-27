extends Node2D

@export var roads: TileMapLayer
@export var citizen_scene: PackedScene
@export var doors: Array[Vector2i] = []

var grid: AStarGrid2D = AStarGrid2D.new()


func _ready() -> void:
	grid.region = roads.get_used_rect()
	grid.cell_size = Vector2(roads.tile_set.tile_size)
	grid.offset = grid.cell_size / 2.0
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for y: int in range(grid.region.position.y, grid.region.end.y):
		for x: int in range(grid.region.position.x, grid.region.end.x):
			var cell: Vector2i = Vector2i(x, y)
			grid.set_point_solid(cell, roads.get_cell_source_id(cell) == -1)


func _on_timer_timeout() -> void:
	var from: Vector2i = doors.pick_random()
	var to: Vector2i = doors.pick_random()
	if from == to:
		return
	var citizen: Citizen = citizen_scene.instantiate()
	citizen.position = grid.get_point_position(from)
	citizen.path = grid.get_point_path(from, to)
	add_child(citizen)
