class_name Hud
extends CanvasLayer

const STAR_ON: Color = Color("#2b211c")
const STAR_OFF: Color = Color(0.1686, 0.1294, 0.1098, 0.22)

var blink: float = 0.0
var level: int = 0
var hot: bool = false
var district_fade: Tween

@onready var money: Label = $Bar/Money
@onready var hint: Label = $Bar/Hint
@onready var stars: Control = $Bar/Stars
@onready var health_fill: ColorRect = $Bar/Health/Fill
@onready var message: Label = $Message
@onready var district: Label = $District


func _ready() -> void:
	message.visible = false
	district.modulate.a = 0.0
	for index: int in 5:
		var star: Polygon2D = Polygon2D.new()
		var points: PackedVector2Array = PackedVector2Array()
		for step: int in 10:
			var radius: float = 11.0 if step % 2 == 0 else 4.5
			points.append(Vector2.from_angle(-PI / 2.0 + step * PI / 5.0) * radius)
		star.polygon = points
		star.position = Vector2(14.0 + index * 26.0, 18.0)
		stars.add_child(star)
	show_stars(0, false)


func _process(delta: float) -> void:
	blink += delta
	var visible_now: bool = not hot or int(blink * 4.0) % 2 == 0
	for index: int in stars.get_child_count():
		var star: Polygon2D = stars.get_child(index)
		star.color = STAR_ON if index < level and visible_now else STAR_OFF


func show_money(amount: int) -> void:
	money.text = "$ %s" % str(amount).pad_zeros(6)


func show_health(health: float) -> void:
	health_fill.scale.x = clampf(health / 100.0, 0.0, 1.0)


func show_stars(count: int, flashing: bool) -> void:
	level = count
	hot = flashing


func show_hint(text: String) -> void:
	hint.text = text


func announce(text: String, color: Color) -> void:
	message.text = text
	message.add_theme_color_override("font_color", color)
	message.visible = true
	get_tree().create_timer(2.5).timeout.connect(func() -> void: message.visible = false)


func show_district(text: String) -> void:
	district.text = text
	if district_fade != null:
		district_fade.kill()
	district.modulate.a = 1.0
	district_fade = create_tween()
	district_fade.tween_interval(2.0)
	district_fade.tween_property(district, "modulate:a", 0.0, 0.8)
