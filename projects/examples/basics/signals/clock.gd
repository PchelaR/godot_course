extends Sprite2D


func _ready() -> void:
	position = get_viewport_rect().size / 2
	var timer: Timer = $Timer
	timer.timeout.connect(_on_timer_timeout)


func _on_timer_timeout() -> void:
	rotation += PI / 6
