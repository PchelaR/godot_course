extends Sprite2D

var ticks: int = 0


func _ready() -> void:
	position = get_viewport_rect().size / 2
	var timer: Timer = $Timer
	timer.timeout.connect(_on_timer_timeout)


func _on_timer_timeout() -> void:
	rotation += PI / 6
	ticks += 1
	if ticks == 12:
		var timer: Timer = $Timer
		timer.stop()
