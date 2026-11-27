extends Node2D

const LINE: Color = Color(0.9373, 0.8863, 0.8, 0.25)
const WALL: Color = Color(0.9333, 0.4157, 0.2588, 0.45)
const HERO: Color = Color(0.702, 0.6078, 0.8196, 1)
const WANTED: Color = Color(0.9333, 0.4157, 0.2588, 1)
const SLIME: Color = Color(0.898, 0.3216, 0.3216, 1)

@export var hero: Hero
@export var slime: Slime

var enabled: bool = false

@onready var maze: Maze = get_parent()


func _ready() -> void:
	if OS.has_feature("web"):
		var timer := Timer.new()
		timer.wait_time = 0.3
		timer.autostart = true
		timer.timeout.connect(_on_timer_timeout)
		add_child(timer)


func _process(_delta: float) -> void:
	if enabled:
		queue_redraw()


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
	if slime != null:
		draw_slime(size)
	if hero == null:
		return
	var current: Vector2 = maze.map_to_local(hero.cell) - size / 2
	draw_rect(Rect2(current, size), HERO, false, 2.0)
	if hero.direction != Vector2i.ZERO:
		var next: Vector2 = maze.map_to_local(hero.cell + hero.direction) - size / 2
		draw_rect(Rect2(next, size).grow(-3.0), HERO, false, 1.0)
	if hero.wanted != Vector2i.ZERO and hero.wanted != hero.direction:
		var mark: Vector2 = maze.map_to_local(hero.cell + hero.wanted)
		draw_rect(Rect2(mark - Vector2(3, 3), Vector2(6, 6)), WANTED)


func draw_slime(size: Vector2) -> void:
	var center: Vector2 = maze.map_to_local(slime.cell)
	var goal: Vector2 = maze.map_to_local(slime.target())
	draw_line(center, goal, Color(SLIME, 0.5), 1.0)
	draw_rect(Rect2(goal - Vector2(4, 4), Vector2(8, 8)), SLIME, false, 1.0)
	draw_rect(Rect2(center - size / 2, size), SLIME, false, 2.0)
	for option: Vector2i in Slime.DIRECTIONS:
		if option == -slime.direction or maze.is_wall(slime.cell + option):
			continue
		var mark: Vector2 = maze.map_to_local(slime.cell + option)
		draw_rect(Rect2(mark - Vector2(2, 2), Vector2(4, 4)), SLIME)
