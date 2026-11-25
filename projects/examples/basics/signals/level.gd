extends Node


func _ready() -> void:
	var hero: Hero = $Hero
	hero.take_damage(30)
	hero.take_damage(50)
	hero.take_damage(40)
