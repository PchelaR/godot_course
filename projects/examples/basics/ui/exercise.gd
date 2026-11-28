extends Control

@export var max_health: int = 100

var health: int = 70

@onready var bar: ProgressBar = $Margin/Box/Health/Bar
@onready var status: Label = $Margin/Box/Status


func _ready() -> void:
	bar.max_value = max_health
	show_health()


func show_health() -> void:
	bar.value = health
	status.text = "Герой погиб" if health == 0 else "Здоровье: %d из %d" % [health, max_health]


func _on_hit_pressed() -> void:
	health = maxi(health - 10, 0)
	show_health()


func _on_heal_pressed() -> void:
	health = mini(health + 10, max_health)
	show_health()


func _on_reset_pressed() -> void:
	health = max_health
	show_health()
