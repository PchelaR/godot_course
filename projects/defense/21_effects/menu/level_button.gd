class_name LevelButton
extends Button

@export var number: int = 1
@export var level_scene: PackedScene
@export var earned_color: Color = Color(0.9098, 0.3333, 0.1843, 1)
@export var missing_color: Color = Color(0.4902, 0.4157, 0.3529, 1)

@onready var stars: Array[ColorRect] = [$Stars/Star1, $Stars/Star2, $Stars/Star3]


func _ready() -> void:
	text = str(number)
	disabled = number > 1 and Game.stars_of(number - 1) == 0
	modulate.a = 0.5 if disabled else 1.0
	var earned: int = Game.stars_of(number)
	for index: int in stars.size():
		stars[index].color = earned_color if index < earned else missing_color


func _pressed() -> void:
	get_tree().change_scene_to_packed(level_scene)
