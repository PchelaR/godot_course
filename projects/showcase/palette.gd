class_name Palette
extends RefCounted

const WINDOW: Color = Color("#fdf4e3")
const PAPER: Color = Color("#f4e4c9")
const INK: Color = Color("#2b211c")
const MUTED: Color = Color("#7d6a5a")
const ACCENT: Color = Color("#e8552f")
const LILAC: Color = Color("#c8a6dc")
const DARK: Dictionary[String, Color] = {
	"fdf4e3": Color("#27211b"),
	"f4e4c9": Color("#1c1814"),
	"2b211c": Color("#efe2cc"),
	"7d6a5a": Color("#a08f7c"),
	"e8552f": Color("#ee6a42"),
	"c8a6dc": Color("#b39bd1"),
}
const PROPERTIES: Array[String] = ["color", "default_color"]

static var dark: bool = true


static func tint(light: Color) -> Color:
	if not dark:
		return light
	var mapped: Color = DARK.get(light.to_html(false), light)
	mapped.a = light.a
	return mapped


static func paint(node: Node) -> void:
	for property: String in PROPERTIES:
		var value: Variant = node.get(property)
		if value is Color:
			if not node.has_meta(property):
				node.set_meta(property, value)
			node.set(property, tint(node.get_meta(property)))
	for child: Node in node.get_children():
		paint(child)


static func set_light(node: Node, property: String, light: Color) -> void:
	node.set_meta(property, light)
	node.set(property, tint(light))
