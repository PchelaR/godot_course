class_name Level
extends Node2D

const WAVES: Array[float] = [7.0, 20.0, 7.0, 20.0, 5.0, 20.0, 5.0]
const FRIGHT_TIME: float = 6.0
const FLASH_TIME: float = 2.0
const CATCH_POINTS: Array[int] = [200, 400, 800, 1600]
const CAUGHT_PAUSE: float = 0.5

var score: int = 0
var wave: int = 0
var coins_eaten: int = 0
var flashing: bool = false
var caught_in_row: int = 0
var lives: int = 3
var resetting: bool = false

@onready var hud: Hud = $Hud
@onready var hero: Hero = $Maze/Hero
@onready var slimes: Node2D = $Maze/Slimes
@onready var waves: Timer = $Waves
@onready var idle: Timer = $Idle
@onready var fright: Timer = $Fright


func _ready() -> void:
	hud.show_score(score)
	hud.show_lives(lives)
	start_round()


func start_round() -> void:
	hero.reset()
	for slime: Slime in slimes.get_children():
		slime.reset()
	wave = 0
	flashing = false
	waves.paused = false
	start_wave()
	release_slimes()
	idle.start()
	freeze(false)
	resetting = false


func freeze(value: bool) -> void:
	hero.set_physics_process(not value)
	for slime: Slime in slimes.get_children():
		slime.set_physics_process(not value)


func lose_life() -> void:
	resetting = true
	freeze(true)
	waves.stop()
	fright.stop()
	idle.stop()
	lives -= 1
	hud.show_lives(lives)
	hero.die()
	await hero.died
	await get_tree().create_timer(CAUGHT_PAUSE).timeout
	if lives == 0:
		get_tree().reload_current_scene()
		return
	start_round()


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


func _on_coins_powered() -> void:
	waves.paused = true
	flashing = false
	caught_in_row = 0
	for slime: Slime in slimes.get_children():
		slime.frighten()
	fright.start(FRIGHT_TIME - FLASH_TIME)


func _on_fright_timeout() -> void:
	if not flashing:
		flashing = true
		for slime: Slime in slimes.get_children():
			slime.flash()
		fright.start(FLASH_TIME)
		return
	for slime: Slime in slimes.get_children():
		slime.calm()
	waves.paused = false


func _on_waves_timeout() -> void:
	wave += 1
	start_wave()


func _on_idle_timeout() -> void:
	for slime: Slime in slimes.get_children():
		if slime.mode == Slime.Mode.HOUSE:
			slime.release()
			return


func _on_slime_touched(slime: Slime) -> void:
	if resetting:
		return
	match slime.mode:
		Slime.Mode.FRIGHTENED:
			slime.catch()
			score += CATCH_POINTS[mini(caught_in_row, CATCH_POINTS.size() - 1)]
			caught_in_row += 1
			hud.show_score(score)
		Slime.Mode.EYES, Slime.Mode.HOUSE:
			pass
		_:
			lose_life()
