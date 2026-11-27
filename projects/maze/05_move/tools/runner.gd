extends SceneTree

const MARKER: String = "@@@ "
const FAILED: String = "@@@FAIL"

var mode: String = ""
var paths: PackedStringArray = []
var index: int = -1
var current: Node = null
var frames: int = 0
var physics_frames: int = 0


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	mode = args[0]
	paths = args.slice(1)
	if mode == "run":
		start_next()


func mark(path: String) -> void:
	print(MARKER + path)
	printerr(MARKER + path)


func check_all() -> void:
	for path: String in paths:
		mark(path)
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			print(FAILED)


func start_next() -> void:
	index += 1
	frames = 0
	physics_frames = 0
	if index >= paths.size():
		quit()
		return
	var path: String = paths[index]
	mark(path)
	current = create(path)
	if current == null:
		print(FAILED)
		start_next()
		return
	root.add_child.call_deferred(current)


func create(path: String) -> Node:
	if path.ends_with(".tscn"):
		var scene: PackedScene = load(path)
		return scene.instantiate() if scene != null else null
	var script: GDScript = load(path)
	return script.new() if script != null else null


func _physics_process(_delta: float) -> bool:
	physics_frames += 1
	return false


func _process(_delta: float) -> bool:
	if mode == "check":
		check_all()
		return true
	if current == null:
		return false
	frames += 1
	if frames > 2 and physics_frames > 2:
		current.free()
		current = null
		start_next()
	return false
