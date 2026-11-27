extends Node

const CHECK_PATH: String = "user://check_record.cfg"


func _ready() -> void:
	var game: GameState = GameState.new()
	game.save_path = CHECK_PATH
	game.submit(120)
	report(game)
	game.submit(80)
	report(game)
	var restarted: GameState = GameState.new()
	restarted.save_path = CHECK_PATH
	restarted.load_record()
	report(restarted)
	game.free()
	restarted.free()


func report(game: GameState) -> void:
	print(game.last_score, " ", game.high_score, " ", game.new_record)
