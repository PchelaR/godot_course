extends Node2D

@export var coin_scene: PackedScene


func _ready() -> void:
	print(get_child_count())
	for i in range(3):
		var coin: Node2D = coin_scene.instantiate()
		coin.position = Vector2(100 * i, 0)
		add_child(coin)
	print(get_child_count())
	for coin in get_children():
		print(coin.position)
