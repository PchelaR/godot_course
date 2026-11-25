extends Node


func _ready() -> void:
	var coin: Node = $Coin
	coin.queue_free()
	print(coin.is_queued_for_deletion())
	print(get_child_count())
	print("_ready завершён")
