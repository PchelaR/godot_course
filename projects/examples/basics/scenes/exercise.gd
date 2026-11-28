extends Node

var moves: int = 0
var visits: Dictionary[String, int] = {}


func visit(room: String) -> int:
	visits[room] = visits.get(room, 0) + 1
	return visits[room]
