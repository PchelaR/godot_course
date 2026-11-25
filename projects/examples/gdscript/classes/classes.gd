extends Node


func _ready() -> void:
	var sword := Weapon.new("Меч", 10)
	var staff := MagicStaff.new("Посох", 6, 15)
	print(sword.describe())
	print(staff.describe())
	sword.damage += 5
	print(sword.damage)
	print(staff is Weapon)
	var spare: Weapon = null
	print(spare == null)
