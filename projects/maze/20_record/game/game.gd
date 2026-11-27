class_name GameState
extends Node

const SAVE_PATH: String = "user://record.cfg"

var last_score: int = 0
var high_score: int = 0
var new_record: bool = false
var save_path: String = SAVE_PATH


func _ready() -> void:
	load_record()


func submit(score: int) -> void:
	last_score = score
	new_record = score > high_score
	if new_record:
		high_score = score
		save_record()


func load_record() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(save_path) == OK:
		high_score = config.get_value("record", "high_score", 0)


func save_record() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("record", "high_score", high_score)
	config.save(save_path)
