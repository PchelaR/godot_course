extends Node


func _ready() -> void:
	var command: String = "attack"
	match command:
		"move":
			print("Движение")
		"attack", "shoot":
			print("Атака")
		_:
			print("Неизвестная команда")
