extends Node


func _ready() -> void:
	var prices: Dictionary[String, int] = {"меч": 50, "щит": 30}
	for item in prices:
		print(item, " — ", prices[item])
	print(prices.keys())
	print(prices.values())
