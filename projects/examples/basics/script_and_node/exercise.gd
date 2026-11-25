extends Sprite2D

var turn_speed: float = -1.0


func _ready() -> void:
	position = Vector2(200, 150)


func _process(delta: float) -> void:
	rotation += turn_speed * delta
