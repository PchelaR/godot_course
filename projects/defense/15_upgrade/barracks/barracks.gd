extends Tower

const SPOTS: Array[Vector2] = [Vector2(0, -16), Vector2(-16, 14), Vector2(16, 14)]

@export var soldier_scene: PackedScene
@export var upgraded_health: int = 18
@export var upgraded_damage: int = 2

var rally: Vector2 = Vector2.ZERO
var soldiers: Array[Soldier] = []


func _ready() -> void:
	var road: Path2D = get_tree().get_first_node_in_group("road")
	var closest: Vector2 = road.curve.get_closest_point(road.to_local(global_position))
	rally = road.to_global(closest)
	for spot: Vector2 in SPOTS:
		var soldier: Soldier = soldier_scene.instantiate()
		soldier.barracks = self
		soldier.home = rally + spot
		soldier.position = global_position
		add_child(soldier)
		soldiers.append(soldier)


func apply_upgrade() -> void:
	for soldier: Soldier in soldiers:
		soldier.strengthen(upgraded_health, upgraded_damage)
