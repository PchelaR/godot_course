class_name Tower
extends Node2D

const SELL_SHARE: float = 0.6

@export var range_color: Color = Color(0.1686, 0.1294, 0.1098, 0.6)

var data: TowerData = null
var level: int = 1
var showing_range: bool = false

@onready var range_area: Area2D = $Range
@onready var radius: float = ($Range/Shape.shape as CircleShape2D).radius
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


func show_range(shown: bool) -> void:
	showing_range = shown
	queue_redraw()


func _draw() -> void:
	if showing_range:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, range_color, 3.0)
