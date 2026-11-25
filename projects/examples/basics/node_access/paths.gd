extends Node2D


func _ready() -> void:
	var lamps: Node = get_node("Lamps")
	print(lamps.name)
	var first: Node = get_node("Lamps/Lamp1")
	print(first.name)
	print(first.get_node("..").name)
	print(first.get_node("../Lamp3").name)
	print(first.get_node("../../Wire").name)
	print($Lamps/Lamp2.name)
	print(has_node("Lamps/Lamp6"))
