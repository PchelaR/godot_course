extends Tower

const SPOTS: Array[Vector2] = [Vector2(0, -16), Vector2(-16, 14), Vector2(16, 14)]

@export var soldier_scene: PackedScene

var rally: Vector2 = Vector2.ZERO


func _ready() -> void:
	var road: Path2D = get_tree().get_first_node_in_group("road")
	var closest: Vector2 = road.curve.get_closest_point(road.to_local(global_position))
	rally = road.to_global(closest)
	for spot: Vector2 in SPOTS:
		var soldier: Soldier = soldier_scene.instantiate()
		soldier.home = rally + spot
		soldier.position = global_position
		add_child(soldier)
