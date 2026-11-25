class_name MagicStaff
extends Weapon

var mana_cost: int


func _init(weapon_title: String, weapon_damage: int, cost: int) -> void:
	super(weapon_title, weapon_damage)
	mana_cost = cost


func describe() -> String:
	return super.describe() + ", мана %d" % mana_cost
