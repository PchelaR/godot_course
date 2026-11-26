extends CharacterBody2D

@export var speed: float = 400.0
@export var marker: Node2D

var target: Vector2


func _ready() -> void:
	target = global_position


func _unhandled_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		target = get_global_mouse_position()
		marker.global_position = target


func _physics_process(delta: float) -> void:
	var offset: Vector2 = target - global_position
	if offset.length() < 1.0:
		velocity = Vector2.ZERO
		return
	look_at(target)
	velocity = offset.limit_length(speed * delta) / delta
	move_and_slide()
