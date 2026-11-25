extends Node

const DEFAULT_SCENE: String = "res://basics/script_and_node/spinner.tscn"
const CAMERA_SCRIPT: String = "res://tools/demo_camera.gd"
const THEME_QUERY: String = (
	"(() => { try { return window.parent.document.documentElement.dataset.theme || 'dark'; }"
	+ " catch (error) { return 'dark'; } })()"
)

var light_background: Color = Color("#fdf4e3")
var dark_colors: Dictionary[String, Color] = {
	"fdf4e3": Color("#27211b"),
	"f4e4c9": Color("#1c1814"),
	"2b211c": Color("#a08f7c"),
	"7d6a5a": Color("#a08f7c"),
	"e8552f": Color("#ee6a42"),
	"c8a6dc": Color("#b39bd1"),
}
var painted: Array[Dictionary] = []
var dark: bool = false
var applied: bool = false
var debug_view: bool = false


func _ready() -> void:
	var path: String = DEFAULT_SCENE
	if OS.has_feature("web"):
		var requested: String = str(
			JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('scene') || ''")
		)
		if requested != "":
			path = "res://%s.tscn" % requested
	if not ResourceLoader.exists(path):
		push_error("Scene not found: %s" % path)
		return
	var scene: PackedScene = load(path)
	var demo: Node = scene.instantiate()
	add_child(demo)
	if not (demo is Camera2D) and demo.find_children("*", "Camera2D").is_empty():
		add_camera()
	if OS.has_feature("web"):
		collect_colors(demo)
		sync_theme()
		var timer := Timer.new()
		timer.wait_time = 0.3
		timer.autostart = true
		timer.timeout.connect(sync_theme)
		timer.timeout.connect(sync_debug)
		add_child(timer)


func add_camera() -> void:
	var camera := Camera2D.new()
	camera.set_script(load(CAMERA_SCRIPT))
	camera.position = get_viewport().get_visible_rect().size / 2
	add_child(camera)
	camera.make_current()


func collect_colors(node: Node) -> void:
	for property: String in ["color", "default_color"]:
		var value: Variant = node.get(property)
		if value is Color:
			painted.append({"node": node, "property": property, "light": value})
	for child: Node in node.get_children():
		collect_colors(child)


func sync_theme() -> void:
	var wanted: bool = str(JavaScriptBridge.eval(THEME_QUERY)) != "light"
	if applied and wanted == dark:
		return
	dark = wanted
	applied = true
	RenderingServer.set_default_clear_color(themed(light_background))
	for entry: Dictionary in painted:
		var node: Node = entry["node"]
		if is_instance_valid(node):
			node.set(entry["property"], themed(entry["light"]))


func themed(color: Color) -> Color:
	if not dark:
		return color
	var mapped: Color = dark_colors.get(color.to_html(false), color)
	return mapped


func sync_debug() -> void:
	var wanted: bool = JavaScriptBridge.eval("window.godotDebug === true ? 1 : 0") == 1
	if wanted == debug_view:
		return
	debug_view = wanted
	Engine.set_meta("debug_view", debug_view)
	get_tree().call_group("debug_view", "set_debug_view", debug_view)
