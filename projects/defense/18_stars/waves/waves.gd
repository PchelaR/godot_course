class_name Waves
extends Node

signal wave_started(number: int)
signal break_started
signal enemy_spawned(enemy: Enemy)
signal finished

@export var waves: Array[Wave] = []
@export var road: Path2D
@export var bonus_per_second: int = 2

var number: int = 0
var left: int = 0

@onready var spawn_timer: Timer = $SpawnTimer
@onready var break_timer: Timer = $BreakTimer


func start() -> void:
	break_started.emit()


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
		break_started.emit()
	else:
		finished.emit()


func call_early() -> int:
	if number > 0 and break_timer.is_stopped():
		return 0
	var bonus: int = ceili(break_timer.time_left) * bonus_per_second
	break_timer.stop()
	start_wave()
	return bonus


func _on_spawn_timer_timeout() -> void:
	spawn()


func _on_break_timer_timeout() -> void:
	start_wave()
