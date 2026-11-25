extends Node

@export var hero: Hero


func _ready() -> void:
	hero.health_changed.connect(_on_hero_health_changed)
	hero.died.connect(_on_hero_died)


func _on_hero_health_changed(health: int) -> void:
	print("Здоровье: ", health)


func _on_hero_died() -> void:
	print("Герой погиб")
