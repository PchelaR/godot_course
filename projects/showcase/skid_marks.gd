extends Node2D

@export var limit: int = 500
@export var fade_time: float = 8.0
@export var mark_color: Color = Color(0.1686, 0.1294, 0.1098, 0.25)


func add_mark(at: Vector2) -> void:
	var mark: Polygon2D = Polygon2D.new()
	Palette.set_light(mark, "color", mark_color)
	mark.polygon = PackedVector2Array([Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)])
	mark.position = at
	add_child(mark)
	var tween: Tween = mark.create_tween()
	tween.tween_property(mark, "modulate:a", 0.0, fade_time)
	tween.tween_callback(mark.queue_free)
	if get_child_count() > limit:
		get_child(0).queue_free()


func _on_vehicle_skidded(left: Vector2, right: Vector2) -> void:
	add_mark(left)
	add_mark(right)
