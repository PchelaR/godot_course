class_name Hud
extends Control

signal call_pressed

@onready var lives_label: Label = $Bar/Lives
@onready var money_label: Label = $Bar/Money
@onready var wave_label: Label = $Bar/Wave
@onready var call_button: Button = $CallWave


func show_lives(lives: int) -> void:
	lives_label.text = "ЖИЗНИ %d" % lives


func show_money(money: int) -> void:
	money_label.text = "ЗОЛОТО %d" % money


func show_wave(number: int, total: int) -> void:
	wave_label.text = "ВОЛНА %d/%d" % [number, total]


func show_call_button(label: String) -> void:
	call_button.text = label
	call_button.visible = true


func hide_call_button() -> void:
	call_button.visible = false


func _on_call_wave_pressed() -> void:
	call_pressed.emit()
