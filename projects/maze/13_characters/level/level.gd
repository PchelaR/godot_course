class_name Level
extends Node2D

const WAVES: Array[float] = [7.0, 20.0, 7.0, 20.0, 5.0, 20.0, 5.0]

var score: int = 0
var wave: int = 0

@onready var hud: Hud = $Hud
@onready var slimes: Node2D = $Maze/Slimes
@onready var waves: Timer = $Waves


func _ready() -> void:
	hud.show_score(score)
	start_wave()


func start_wave() -> void:
	var mode: Slime.Mode = Slime.Mode.SCATTER if wave % 2 == 0 else Slime.Mode.CHASE
	for slime: Slime in slimes.get_children():
		slime.switch_mode(mode)
	if wave < WAVES.size():
		waves.start(WAVES[wave])


func _on_coins_eaten(points: int) -> void:
	score += points
	hud.show_score(score)


func _on_waves_timeout() -> void:
	wave += 1
	start_wave()
