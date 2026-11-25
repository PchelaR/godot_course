extends Node2D

@export var coin_scene: PackedScene


func _ready() -> void:
	var timer: Timer = $Timer
	timer.timeout.connect(_on_timer_timeout)


func _on_timer_timeout() -> void:
	var coin: Node2D = coin_scene.instantiate()
	coin.position = Vector2(randf_range(40.0, 1112.0), -40.0)
	add_child(coin)
