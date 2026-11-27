extends Node

@onready var camera: ShakeCamera = $ShakeCamera


func _ready() -> void:
	print(camera.offset)
	camera.shake(3, 0.5)
	camera._process(0.1)
	report()
	camera._process(0.3)
	report()
	camera._process(0.2)
	print(camera.offset)


func report() -> void:
	var limit: float = ceilf(3.0 * camera.time_left / 0.5)
	var inside: bool = absf(camera.offset.x) <= limit and absf(camera.offset.y) <= limit
	print(limit, " ", inside, " ", camera.offset == camera.offset.round())
