extends Node


func _ready() -> void:
	greet()
	print(add(2, 3))
	print(is_alive(0))


func greet() -> void:
	print("Привет!")


func add(a: int, b: int) -> int:
	return a + b


func is_alive(health: int) -> bool:
	return health > 0
