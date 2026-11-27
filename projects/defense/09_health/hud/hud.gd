class_name Hud
extends Control

@onready var lives_label: Label = $Bar/Lives
@onready var money_label: Label = $Bar/Money
@onready var wave_label: Label = $Bar/Wave
@onready var message: Label = $Message


func show_lives(lives: int) -> void:
	lives_label.text = "ЖИЗНИ %d" % lives


func show_money(money: int) -> void:
	money_label.text = "ЗОЛОТО %d" % money


func show_wave(number: int, total: int) -> void:
	wave_label.text = "ВОЛНА %d/%d" % [number, total]


func show_message(text: String) -> void:
	message.text = text
	message.visible = true
