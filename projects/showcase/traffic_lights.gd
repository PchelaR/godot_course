class_name TrafficLights
extends Node2D

@export var green_time: float = 7.0
@export var clear_time: float = 2.5

var phase: int = 0
var timer: float = 0.0
var horizontal_bars: Array[Node2D] = []
var vertical_bars: Array[Node2D] = []


func _physics_process(delta: float) -> void:
	timer += delta
	if timer >= (green_time if phase % 2 == 0 else clear_time):
		timer = 0.0
		phase = (phase + 1) % 4
		refresh()


func is_green(axis: int) -> bool:
	return phase == axis * 2


func walk_allowed(axis: int) -> bool:
	return not is_green(axis)


func add_bar(bar: Node2D, axis: int) -> void:
	if axis == 0:
		horizontal_bars.append(bar)
	else:
		vertical_bars.append(bar)
	add_child(bar)


func refresh() -> void:
	for bar: Node2D in horizontal_bars:
		bar.visible = not is_green(0)
	for bar: Node2D in vertical_bars:
		bar.visible = not is_green(1)
