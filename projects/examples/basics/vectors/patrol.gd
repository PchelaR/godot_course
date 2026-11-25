extends Sprite2D

var speed: float = 240.0
var points: Array[Vector2] = [
	Vector2(376, 204),
	Vector2(776, 204),
	Vector2(776, 444),
	Vector2(376, 444),
]
var target: int = 1


func _ready() -> void:
	position = points[0]


func _process(delta: float) -> void:
	var goal: Vector2 = points[target]
	var step: float = speed * delta
	if position.distance_to(goal) <= step:
		position = goal
		target = (target + 1) % points.size()
		return
	position += position.direction_to(goal) * step
