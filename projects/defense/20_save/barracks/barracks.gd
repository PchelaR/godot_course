class_name Barracks
extends Tower

const SPOTS: Array[Vector2] = [Vector2(0, -16), Vector2(-16, 14), Vector2(16, 14)]

@export var soldier_scene: PackedScene
@export var upgraded_health: int = 18
@export var upgraded_damage: int = 2

var road: Path2D = null
var rally: Vector2 = Vector2.ZERO
var soldiers: Array[Soldier] = []

@onready var radius: float = ($Range/Shape.shape as CircleShape2D).radius
@onready var ring: Line2D = $Ring


func _ready() -> void:
	road = get_tree().get_first_node_in_group("road")
	rally = closest_on_road(global_position)
	for spot: Vector2 in SPOTS:
		var soldier: Soldier = soldier_scene.instantiate()
		soldier.barracks = self
		soldier.home = rally + spot
		soldier.position = global_position
		add_child(soldier)
		soldiers.append(soldier)


func closest_on_road(point: Vector2) -> Vector2:
	return road.to_global(road.curve.get_closest_point(road.to_local(point)))


func move_rally(point: Vector2) -> void:
	var target: Vector2 = closest_on_road(point)
	if target.distance_to(global_position) > radius:
		return
	rally = target
	for index: int in soldiers.size():
		soldiers[index].home = rally + SPOTS[index]


func show_range(shown: bool) -> void:
	ring.visible = shown


func apply_upgrade() -> void:
	for soldier: Soldier in soldiers:
		soldier.strengthen(upgraded_health, upgraded_damage)
