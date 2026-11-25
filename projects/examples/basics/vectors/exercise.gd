extends Sprite2D

var speed: float = 240.0
var stop_distance: float = 100.0


func _ready() -> void:
	position = Vector2(60, 60)


func _process(delta: float) -> void:
	var center: Vector2 = get_viewport_rect().size / 2
	if position.distance_to(center) <= stop_distance:
		return
	position += position.direction_to(center) * speed * delta
