class_name ShyCharacter
extends Character

@export var courage: int = 8


func chase_target(slime: Slime) -> Vector2i:
	if slime.cell.distance_squared_to(slime.hero.cell) > courage * courage:
		return slime.hero.cell
	return corner
