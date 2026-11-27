class_name Slime
extends Walker

const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]

@export var hero: Hero

@onready var eyes: Sprite2D = $Eyes


func _physics_process(delta: float) -> void:
	advance(speed * delta)
	look()


func choose_direction() -> void:
	var best: Vector2i = -direction
	var best_distance: int = -1
	for option: Vector2i in DIRECTIONS:
		if option == -direction or maze.is_wall(cell + option):
			continue
		var distance: int = (cell + option).distance_squared_to(target())
		if best_distance < 0 or distance < best_distance:
			best_distance = distance
			best = option
	direction = best


func target() -> Vector2i:
	return hero.cell


func look() -> void:
	if direction.x != 0:
		eyes.frame = 0 if direction.x > 0 else 1
