extends Node

const PATH: String = "user://example_progress.cfg"


func _ready() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("player", "name", "Герой")
	config.set_value("player", "level", 3)
	config.set_value("settings", "volume", 0.5)
	config.save(PATH)

	var loaded: ConfigFile = ConfigFile.new()
	var error: Error = loaded.load(PATH)
	print("Загрузилось: ", error == OK)
	print(loaded.get_value("player", "name"))
	print(loaded.get_value("player", "level"))
	print(loaded.get_value("settings", "volume"))
	print(loaded.get_value("player", "gold", 0))
