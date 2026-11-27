class_name Tower
extends Node2D

@onready var range_area: Area2D = $Range


func enemies_in_range() -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	for area: Area2D in range_area.get_overlapping_areas():
		var enemy: Enemy = area.get_parent() as Enemy
		if enemy != null:
			enemies.append(enemy)
	return enemies


func first_enemy() -> Enemy:
	var best: Enemy = null
	for enemy: Enemy in enemies_in_range():
		if best == null or enemy.progress > best.progress:
			best = enemy
	return best
