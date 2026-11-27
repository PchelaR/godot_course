class_name TowerButton
extends Button

signal picked(data: TowerData)

@export var data: TowerData

@onready var price: Label = $Price


func _ready() -> void:
	price.text = str(data.cost)


func update(money: int) -> void:
	disabled = data.cost > money
	modulate.a = 0.5 if disabled else 1.0


func _pressed() -> void:
	picked.emit(data)
