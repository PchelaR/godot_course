class_name TowerMenu
extends Node2D

signal upgrade_pressed
signal sell_pressed

var tower: Tower = null

@onready var upgrade_button: Button = $Upgrade
@onready var upgrade_price: Label = $Upgrade/Price
@onready var sell_price: Label = $Sell/Price


func _ready() -> void:
	close()


func open(selected: Tower, money: int) -> void:
	tower = selected
	position = tower.global_position
	visible = true
	tower.show_range(true)
	refresh(money)


func refresh(money: int) -> void:
	if not visible or not is_instance_valid(tower):
		return
	upgrade_button.visible = tower.can_upgrade()
	upgrade_button.disabled = tower.data.upgrade_cost > money
	upgrade_button.modulate.a = 0.5 if upgrade_button.disabled else 1.0
	upgrade_price.text = str(tower.data.upgrade_cost)
	sell_price.text = "+%d" % tower.sell_price()


func close() -> void:
	if is_instance_valid(tower):
		tower.show_range(false)
	visible = false


func _on_upgrade_pressed() -> void:
	upgrade_pressed.emit()


func _on_sell_pressed() -> void:
	sell_pressed.emit()
