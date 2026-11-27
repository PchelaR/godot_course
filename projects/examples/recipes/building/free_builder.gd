extends Node2D

const FREE: Color = Color(0.9098, 0.3333, 0.1843, 0.5)
const BLOCKED: Color = Color(0.1686, 0.1294, 0.1098, 0.5)

@export var building_scene: PackedScene
@export var area: Rect2 = Rect2(24, 24, 1104, 600)
@export var footprint: Vector2 = Vector2(64, 48)

@onready var ghost: Node2D = $Ghost
@onready var look: Polygon2D = $Ghost/Look
@onready var probe: ShapeCast2D = $Ghost/Probe


func _process(_delta: float) -> void:
	ghost.global_position = get_global_mouse_position()
	look.color = FREE if can_build() else BLOCKED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build") and can_build():
		var building: Node2D = building_scene.instantiate()
		building.global_position = ghost.global_position
		get_parent().add_child(building)


func can_build() -> bool:
	var rect: Rect2 = Rect2(ghost.global_position - footprint / 2.0, footprint)
	if not area.encloses(rect):
		return false
	probe.force_shapecast_update()
	return not probe.is_colliding()
