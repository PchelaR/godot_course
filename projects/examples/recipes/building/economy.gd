extends Node2D

const FREE: Color = Color(0.9098, 0.3333, 0.1843, 0.5)
const BLOCKED: Color = Color(0.1686, 0.1294, 0.1098, 0.5)

@export var ground: TileMapLayer
@export var building_scene: PackedScene
@export var money_label: Label
@export var money: int = 120
@export var price: int = 50

var buildings: Dictionary[Vector2i, Node2D] = {}

@onready var ghost: Polygon2D = $Ghost


func _ready() -> void:
	show_money()


func _process(_delta: float) -> void:
	var cell: Vector2i = hovered_cell()
	ghost.position = ground.map_to_local(cell)
	ghost.color = FREE if can_build(cell) and money >= price else BLOCKED


func _unhandled_input(event: InputEvent) -> void:
	var cell: Vector2i = hovered_cell()
	if event.is_action_pressed("build") and can_build(cell) and money >= price:
		money -= price
		place(cell)
		show_money()


func hovered_cell() -> Vector2i:
	return ground.local_to_map(ground.get_local_mouse_position())


func can_build(cell: Vector2i) -> bool:
	if buildings.has(cell):
		return false
	var data: TileData = ground.get_cell_tile_data(cell)
	return data != null and data.get_custom_data("buildable")


func place(cell: Vector2i) -> void:
	var building: Node2D = building_scene.instantiate()
	building.position = ground.map_to_local(cell)
	add_child(building)
	buildings[cell] = building
	building.connect("produced", _on_building_produced)


func show_money() -> void:
	money_label.text = "Деньги: %d" % money


func _on_building_produced(amount: int) -> void:
	money += amount
	show_money()
