extends Line2D

@export var road: Path2D


func _ready() -> void:
	points = road.curve.get_baked_points()
