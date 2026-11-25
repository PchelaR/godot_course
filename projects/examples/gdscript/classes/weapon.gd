class_name Weapon
extends RefCounted

var title: String
var damage: int


func _init(weapon_title: String, weapon_damage: int) -> void:
	title = weapon_title
	damage = weapon_damage


func describe() -> String:
	return "%s, урон %d" % [title, damage]
