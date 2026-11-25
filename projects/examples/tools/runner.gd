extends SceneTree

var frames: int = 0
var physics_frames: int = 0


func _initialize() -> void:
	var path: String = OS.get_cmdline_user_args()[0]
	var node: Node
	if path.ends_with(".tscn"):
		var scene: PackedScene = load(path)
		node = scene.instantiate()
	else:
		var script: GDScript = load(path)
		node = script.new()
	root.add_child.call_deferred(node)


func _physics_process(_delta: float) -> bool:
	physics_frames += 1
	return false


func _process(_delta: float) -> bool:
	frames += 1
	return frames > 2 and physics_frames > 2
