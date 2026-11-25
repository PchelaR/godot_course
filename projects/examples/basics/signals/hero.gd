class_name Hero
extends Node

signal health_changed(health: int)
signal died

var health: int = 100


func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	health_changed.emit(health)
	if health == 0:
		died.emit()
