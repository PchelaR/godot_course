extends Node2D

const RESTART_DELAY: float = 3.0

@export var lives: int = 20
@export var money: int = 200

@onready var waves: Waves = $Waves
@onready var hud: Hud = $Interface/Hud


func _ready() -> void:
	hud.show_lives(lives)
	hud.show_money(money)
	hud.show_wave(0, waves.waves.size())


func _on_waves_wave_started(number: int) -> void:
	hud.show_wave(number, waves.waves.size())


func _on_waves_enemy_spawned(enemy: Enemy) -> void:
	enemy.escaped.connect(_on_enemy_escaped)


func _on_enemy_escaped() -> void:
	if lives == 0:
		return
	lives -= 1
	hud.show_lives(lives)
	if lives == 0:
		lose()


func lose() -> void:
	hud.show_message("ПОРАЖЕНИЕ")
	get_tree().paused = true
	await get_tree().create_timer(RESTART_DELAY).timeout
	get_tree().paused = false
	get_tree().reload_current_scene()
