class_name GameState
extends Node

const PATH: String = "user://progress.cfg"
const SECTION: String = "stars"

var stars: Dictionary[int, int] = {}


func _ready() -> void:
	load_progress()


func stars_of(number: int) -> int:
	return stars.get(number, 0)


func record(number: int, earned: int) -> void:
	stars[number] = maxi(stars_of(number), earned)
	save_progress()


func save_progress() -> void:
	var config: ConfigFile = ConfigFile.new()
	for number: int in stars:
		config.set_value(SECTION, str(number), stars[number])
	config.save(PATH)


func load_progress() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(PATH) != OK:
		return
	for key: String in config.get_section_keys(SECTION):
		stars[key.to_int()] = config.get_value(SECTION, key, 0)
