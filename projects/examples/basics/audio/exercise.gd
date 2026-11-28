extends Node2D

@onready var coin: AudioStreamPlayer = $Coin
@onready var chime: AudioStreamPlayer2D = $Chime


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		coin.play()
	elif event.is_action_pressed("build"):
		var mouse: Vector2 = get_global_mouse_position()
		chime.position = mouse
		chime.pitch_scale = lerpf(1.5, 0.7, mouse.y / get_viewport_rect().size.y)
		chime.play()
