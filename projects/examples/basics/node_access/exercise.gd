extends Node2D

var interval: float = 0.25
var elapsed: float = 0.0
var current: int = 0

@onready var lamps: Node2D = $Lamps


func _ready() -> void:
	switch_lamp(current, true)


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < interval:
		return
	elapsed -= interval
	switch_lamp(current, false)
	var count: int = lamps.get_child_count()
	current = (current - 1 + count) % count
	switch_lamp(current, true)


func switch_lamp(index: int, enabled: bool) -> void:
	var light: Polygon2D = lamps.get_child(index).get_node("Light")
	light.visible = enabled
