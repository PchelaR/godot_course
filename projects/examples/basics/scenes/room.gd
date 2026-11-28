extends Control

@export var title: String = "Комната"
@export_file("*.tscn") var next_room: String = ""

@onready var label: Label = $Box/Label


func _ready() -> void:
	label.text = "%s\nПереходов: %d" % [title, Session.moves]


func _on_door_pressed() -> void:
	Session.moves += 1
	get_tree().change_scene_to_file(next_room)
