class_name Waves
extends Node

signal wave_started(number: int)
signal enemy_spawned(enemy: Enemy)
signal finished

@export var waves: Array[Wave] = []
@export var road: Path2D
@export var first_pause: float = 5.0

var number: int = 0
var left: int = 0

@onready var spawn_timer: Timer = $SpawnTimer
@onready var break_timer: Timer = $BreakTimer


func _ready() -> void:
	break_timer.start(first_pause)


func current() -> Wave:
	return waves[number - 1]


func start_wave() -> void:
	number += 1
	left = current().count
	wave_started.emit(number)
	spawn_timer.start(current().interval)
	spawn()


func spawn() -> void:
	var enemy: Enemy = current().enemy_scene.instantiate()
	road.add_child(enemy)
	enemy_spawned.emit(enemy)
	left -= 1
	if left > 0:
		return
	spawn_timer.stop()
	if number < waves.size():
		break_timer.start(current().pause_after)
	else:
		finished.emit()


func _on_spawn_timer_timeout() -> void:
	spawn()


func _on_break_timer_timeout() -> void:
	start_wave()
