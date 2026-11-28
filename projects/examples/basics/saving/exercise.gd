extends Node

const PATH: String = "user://example_record.cfg"


func _ready() -> void:
	print(save_record(120))
	print(save_record(80))
	print(save_record(200))


func save_record(score: int) -> int:
	var config: ConfigFile = ConfigFile.new()
	config.load(PATH)
	var best: int = config.get_value("record", "best", 0)
	if score > best:
		best = score
		config.set_value("record", "best", best)
		config.save(PATH)
	return best
