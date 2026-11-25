extends Node

enum State { IDLE, RUN, JUMP }

var state: State = State.IDLE


func _ready() -> void:
	print(state)
	state = State.JUMP
	print(state)
	print(State.keys()[state])
	match state:
		State.IDLE:
			print("Стоит")
		State.RUN:
			print("Бежит")
		State.JUMP:
			print("Прыгает")
