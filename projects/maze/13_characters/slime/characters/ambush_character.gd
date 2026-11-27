class_name AmbushCharacter
extends Character

@export var ahead: int = 4


func chase_target(slime: Slime) -> Vector2i:
	return slime.hero.cell + slime.hero.direction * ahead
