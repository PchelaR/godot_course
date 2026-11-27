class_name Character
extends Resource

@export var frames: SpriteFrames
@export var corner: Vector2i = Vector2i.ZERO
@export var color: Color = Color.WHITE
@export var release_coins: int = 0


func chase_target(slime: Slime) -> Vector2i:
	return slime.hero.cell
