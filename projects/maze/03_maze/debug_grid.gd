extends Node2D

const LINE: Color = Color(0.9373, 0.8863, 0.8, 0.25)
const WALL: Color = Color(0.9333, 0.4157, 0.2588, 0.45)

var enabled: bool = false

@onready var maze: Maze = get_parent()


func _ready() -> void:
	if OS.has_feature("web"):
		var timer := Timer.new()
		timer.wait_time = 0.3
		timer.autostart = true
		timer.timeout.connect(_on_timer_timeout)
		add_child(timer)


func _on_timer_timeout() -> void:
	var wanted: bool = JavaScriptBridge.eval("window.godotDebug === true ? 1 : 0") == 1
	if wanted != enabled:
		enabled = wanted
		queue_redraw()


func _draw() -> void:
	if not enabled:
		return
	var size: Vector2 = Vector2(maze.tile_set.tile_size)
	for cell: Vector2i in maze.get_used_cells():
		var corner: Vector2 = maze.map_to_local(cell) - size / 2
		if maze.is_wall(cell):
			draw_rect(Rect2(corner, size), WALL)
		draw_rect(Rect2(corner, size), LINE, false, 1.0)
