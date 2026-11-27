class_name FloatText
extends Label

const OFFSET: Vector2 = Vector2(-40, -48)
const RISE: float = 40.0
const TIME: float = 0.8


func _ready() -> void:
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - RISE, TIME)
	tween.tween_property(self, "modulate:a", 0.0, TIME)
	tween.chain().tween_callback(queue_free)
