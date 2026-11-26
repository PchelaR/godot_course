extends Node2D

@export var distance: float = 300.0
@export var speed: float = 120.0
@export var bob_height: float = 24.0
@export var bob_speed: float = 3.0

var start: Vector2
var time: float = 0.0


func _ready() -> void:
	start = position


func _process(delta: float) -> void:
	time += delta
	var x: float = pingpong(time * speed, distance)
	var y: float = sin(time * bob_speed) * bob_height
	position = start + Vector2(x, y)
