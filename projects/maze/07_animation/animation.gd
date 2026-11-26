extends Node2D

@onready var hero: Hero = $Maze/Hero


func _ready() -> void:
	report()
	hero.steer(Vector2i.RIGHT)
	hero.advance(8.0)
	hero.animate()
	report()
	hero.steer(Vector2i.LEFT)
	hero.animate()
	report()
	hero.advance(200.0)
	hero.animate()
	report()


func report() -> void:
	print(hero.sprite.animation, " ", hero.sprite.is_playing(), " ", hero.cell)
