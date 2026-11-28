class_name BuildMenu
extends Node2D

signal picked(data: TowerData)


func _ready() -> void:
	close()
	for button: TowerButton in get_children():
		button.picked.connect(_on_button_picked)


func open(at: Vector2, money: int) -> void:
	position = at
	visible = true
	refresh(money)


func refresh(money: int) -> void:
	for button: TowerButton in get_children():
		button.update(money)


func close() -> void:
	visible = false


func _on_button_picked(data: TowerData) -> void:
	picked.emit(data)
