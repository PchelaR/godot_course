extends Node


func _ready() -> void:
	print(get_child_count())
	var child := Node.new()
	add_child(child)
	print(get_child_count())
	print(child.get_parent() == self)
