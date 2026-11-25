extends Sprite2D

var turn_speed: float = 2.0


func _ready() -> void:
	position = get_viewport_rect().size / 2


func _process(delta: float) -> void:
	rotation += turn_speed * delta
