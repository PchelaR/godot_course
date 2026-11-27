class_name TowerMenu
extends Node2D

signal upgrade_pressed
signal sell_pressed

@onready var upgrade_button: Button = $Upgrade
@onready var upgrade_price: Label = $Upgrade/Price
@onready var sell_price: Label = $Sell/Price


func _ready() -> void:
	close()


func open(tower: Tower, money: int) -> void:
	position = tower.global_position
	visible = true
	upgrade_button.visible = tower.can_upgrade()
	upgrade_button.disabled = tower.data.upgrade_cost > money
	upgrade_button.modulate.a = 0.5 if upgrade_button.disabled else 1.0
	upgrade_price.text = str(tower.data.upgrade_cost)
	sell_price.text = "+%d" % tower.sell_price()


func close() -> void:
	visible = false


func _on_upgrade_pressed() -> void:
	upgrade_pressed.emit()


func _on_sell_pressed() -> void:
	sell_pressed.emit()
