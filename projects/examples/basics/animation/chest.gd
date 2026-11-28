extends Node2D

var opened: bool = false

@onready var animation: AnimationPlayer = $AnimationPlayer


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return
	opened = not opened
	if opened:
		animation.play("open")
	else:
		animation.play_backwards("open")


func _on_animation_player_animation_finished(animation_name: StringName) -> void:
	if animation_name == "open" and opened:
		animation.play("glow")
