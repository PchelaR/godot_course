extends Node2D

@onready var coin: AudioStreamPlayer = $Coin
@onready var chime: AudioStreamPlayer2D = $Chime


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		coin.play()
	elif event.is_action_pressed("build"):
		chime.position = get_global_mouse_position()
		chime.play()
