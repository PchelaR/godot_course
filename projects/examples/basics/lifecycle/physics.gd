extends Node

var checked: bool = false


func _ready() -> void:
	print(Engine.physics_ticks_per_second)


func _physics_process(delta: float) -> void:
	if checked:
		return
	checked = true
	print(is_equal_approx(delta, 1.0 / Engine.physics_ticks_per_second))
