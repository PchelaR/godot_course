class_name GameState
extends Node

var stars: Dictionary[int, int] = {}


func stars_of(number: int) -> int:
	return stars.get(number, 0)


func record(number: int, earned: int) -> void:
	stars[number] = maxi(stars_of(number), earned)
