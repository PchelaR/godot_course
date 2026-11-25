extends Node2D


func _ready() -> void:
	var lamps: Node = $Lamps
	print(lamps.get_child_count())
	print(lamps.get_child(0).name)
	print(lamps.get_child(2).name)
	for lamp in lamps.get_children():
		print(lamp.name)
