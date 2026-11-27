class_name Tower
extends Node2D

const SELL_SHARE: float = 0.6

var data: TowerData = null
var level: int = 1

@onready var range_area: Area2D = $Range
@onready var mark: Node2D = $Mark


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


func can_upgrade() -> bool:
	return level == 1


func upgrade() -> void:
	level = 2
	mark.visible = true
	apply_upgrade()


func apply_upgrade() -> void:
	pass


func sell_price() -> int:
	var spent: int = data.cost
	if level == 2:
		spent += data.upgrade_cost
	return int(spent * SELL_SHARE)
