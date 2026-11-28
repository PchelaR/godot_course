extends Polygon2D

@export var jump_height: float = 120.0
@export var duration: float = 0.5

var ground: float = 0.0
var tween: Tween = null


func _ready() -> void:
	ground = position.y


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		jump()


func jump() -> void:
	if tween != null:
		tween.kill()
	position.y = ground
	scale = Vector2.ONE
	var half: float = duration / 2.0
	tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "position:y", ground - jump_height, half).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", ground, half).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(1.3, 0.7), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC)
