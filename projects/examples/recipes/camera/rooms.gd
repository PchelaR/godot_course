extends Camera2D

@export var target: Node2D
@export var room_size: Vector2 = Vector2(1152, 648)
@export var move_time: float = 0.45

var room: Vector2i
var tween: Tween


func _ready() -> void:
	room = room_of(target.global_position)
	global_position = center_of(room)


func _process(_delta: float) -> void:
	var current: Vector2i = room_of(target.global_position)
	if current == room:
		return
	room = current
	if tween != null:
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", center_of(room), move_time)


func room_of(point: Vector2) -> Vector2i:
	return Vector2i((point / room_size).floor())


func center_of(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * room_size
