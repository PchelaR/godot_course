extends Node

@onready var pause: Control = $Level/Pause


func _ready() -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = "pause"
	event.pressed = true
	report()
	pause._unhandled_input(event)
	report()
	pause._unhandled_input(event)
	report()


func report() -> void:
	print(get_tree().paused, " ", pause.visible, " ", pause.can_process())
