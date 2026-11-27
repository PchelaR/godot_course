class_name FlankCharacter
extends Character

@export var ahead: int = 2


func chase_target(slime: Slime) -> Vector2i:
	if slime.partner == null:
		return slime.hero.cell
	var pivot: Vector2i = slime.hero.cell + slime.hero.direction * ahead
	return pivot + (pivot - slime.partner.cell)
