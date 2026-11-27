extends Node

@onready var coins: Coins = $Coins


func _ready() -> void:
	coins.eat(Vector2i(2, 1))
	report()
	coins.eat(Vector2i(1, 1))
	report()
	var randomizer: AudioStreamRandomizer = coins.coin_sound.stream
	print(snappedf(randomizer.random_pitch, 0.01))


func report() -> void:
	print(coins.coin_sound.playing, " ", coins.crystal_sound.playing)
