class_name Level
extends Node2D

const WAVES: Array[float] = [7.0, 20.0, 7.0, 20.0, 5.0, 20.0, 5.0]

var score: int = 0
var wave: int = 0
var coins_eaten: int = 0

@onready var hud: Hud = $Hud
@onready var slimes: Node2D = $Maze/Slimes
@onready var waves: Timer = $Waves
@onready var idle: Timer = $Idle


func _ready() -> void:
	hud.show_score(score)
	start_wave()
	release_slimes()


func start_wave() -> void:
	var mode: Slime.Mode = Slime.Mode.SCATTER if wave % 2 == 0 else Slime.Mode.CHASE
	for slime: Slime in slimes.get_children():
		slime.switch_mode(mode)
	if wave < WAVES.size():
		waves.start(WAVES[wave])


func release_slimes() -> void:
	for slime: Slime in slimes.get_children():
		if coins_eaten >= slime.character.release_coins:
			slime.release()


func _on_coins_eaten(points: int) -> void:
	score += points
	coins_eaten += 1
	hud.show_score(score)
	release_slimes()
	idle.start()


func _on_waves_timeout() -> void:
	wave += 1
	start_wave()


func _on_idle_timeout() -> void:
	for slime: Slime in slimes.get_children():
		if slime.mode == Slime.Mode.HOUSE:
			slime.release()
			return
