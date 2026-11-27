class_name Coins
extends TileMapLayer

signal eaten(points: int)
signal powered
signal cleared

var start_tiles: PackedByteArray

@onready var coin_sound: AudioStreamPlayer = $CoinSound
@onready var crystal_sound: AudioStreamPlayer = $CrystalSound


func _ready() -> void:
	start_tiles = tile_map_data


func refill() -> void:
	tile_map_data = start_tiles


func eat(cell: Vector2i) -> void:
	var data: TileData = get_cell_tile_data(cell)
	if data == null:
		return
	erase_cell(cell)
	eaten.emit(data.get_custom_data("points"))
	if data.get_custom_data("power"):
		crystal_sound.play()
		powered.emit()
	else:
		coin_sound.play()
	if get_used_cells().is_empty():
		cleared.emit()
