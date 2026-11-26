extends Camera2D

@export var targets: Array[Node2D] = []
@export var margin: float = 160.0
@export var min_zoom: float = 0.3
@export var max_zoom: float = 1.0
@export var smoothing: float = 4.0


func _process(delta: float) -> void:
	var area: Rect2 = Rect2(targets[0].global_position, Vector2.ZERO)
	for target: Node2D in targets:
		area = area.expand(target.global_position)
	area = area.grow(margin)
	var screen: Vector2 = get_viewport_rect().size
	var fit: float = minf(screen.x / area.size.x, screen.y / area.size.y)
	var wanted: float = clampf(fit, min_zoom, max_zoom)
	var weight: float = 1.0 - exp(-smoothing * delta)
	global_position = global_position.lerp(area.get_center(), weight)
	zoom = zoom.lerp(Vector2(wanted, wanted), weight)
