class_name Level
extends Node2D

@export var number: int = 1
@export var map_scene: PackedScene
@export var lives: int = 20
@export var money: int = 200
@export var three_star_lives: int = 18
@export var two_star_lives: int = 10
@export var float_text_scene: PackedScene

var selected: Plot = null
var rallying: Barracks = null
var alive: int = 0
var all_spawned: bool = false

@onready var waves: Waves = $Waves
@onready var towers: Node2D = $Towers
@onready var hud: Hud = $Interface/Hud
@onready var build_menu: BuildMenu = $Interface/BuildMenu
@onready var tower_menu: TowerMenu = $Interface/TowerMenu
@onready var result: Result = $Interface/Result


func _ready() -> void:
	var map: Map = map_scene.instantiate()
	add_child(map)
	move_child(map, 0)
	waves.road = map.road
	hud.show_lives(lives)
	hud.show_money(money)
	hud.show_wave(0, waves.waves.size())
	for plot: Plot in map.plots.get_children():
		plot.clicked.connect(_on_plot_clicked)
	waves.start()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("select"):
		return
	build_menu.close()
	tower_menu.close()
	if rallying != null:
		if is_instance_valid(rallying):
			rallying.move_rally(get_global_mouse_position())
			rallying.show_range(false)
		rallying = null
		get_viewport().set_input_as_handled()


func _on_plot_clicked(plot: Plot) -> void:
	selected = plot
	if plot.tower == null:
		build_menu.open(plot.global_position, money)
	else:
		tower_menu.open(plot.tower, money)


func _on_build_menu_picked(data: TowerData) -> void:
	build_menu.close()
	if data.cost > money:
		return
	money -= data.cost
	hud.show_money(money)
	var tower: Tower = data.scene.instantiate()
	tower.data = data
	tower.position = selected.global_position
	towers.add_child(tower)
	selected.tower = tower
	pop(tower)


func _on_tower_menu_upgrade_pressed() -> void:
	tower_menu.close()
	var tower: Tower = selected.tower
	if not tower.can_upgrade() or tower.data.upgrade_cost > money:
		return
	money -= tower.data.upgrade_cost
	hud.show_money(money)
	tower.upgrade()
	pop(tower)


func _on_tower_menu_rally_pressed() -> void:
	tower_menu.close()
	rallying = selected.tower as Barracks
	rallying.show_range(true)


func _on_tower_menu_sell_pressed() -> void:
	tower_menu.close()
	var tower: Tower = selected.tower
	money += tower.sell_price()
	hud.show_money(money)
	tower.queue_free()
	selected.tower = null


func _on_waves_wave_started(number: int) -> void:
	hud.show_wave(number, waves.waves.size())
	hud.hide_call_button()


func _on_waves_break_started() -> void:
	hud.show_call_button("НАЧАТЬ ВОЛНУ" if waves.number == 0 else "ВОЛНА РАНЬШЕ")


func _on_hud_call_pressed() -> void:
	money += waves.call_early()
	hud.show_money(money)


func _on_waves_enemy_spawned(enemy: Enemy) -> void:
	alive += 1
	enemy.escaped.connect(_on_enemy_escaped)
	enemy.died.connect(_on_enemy_died)


func _on_waves_finished() -> void:
	all_spawned = true
	check_victory()


func _on_enemy_died(reward: int, at: Vector2) -> void:
	alive -= 1
	money += reward
	hud.show_money(money)
	var text: FloatText = float_text_scene.instantiate()
	text.text = "+%d" % reward
	text.position = at + FloatText.OFFSET
	add_child(text)
	check_victory()


func pop(tower: Tower) -> void:
	tower.scale = Vector2(0.4, 0.4)
	var tween: Tween = create_tween()
	tween.tween_property(tower, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_enemy_escaped() -> void:
	alive -= 1
	if lives == 0:
		return
	lives -= 1
	hud.show_lives(lives)
	if lives == 0:
		get_tree().paused = true
		result.show_result(false, 0)
	else:
		check_victory()


func check_victory() -> void:
	if all_spawned and alive == 0 and lives > 0:
		get_tree().paused = true
		var earned: int = stars_for(lives)
		Game.record(number, earned)
		result.show_result(true, earned)


func stars_for(lives_left: int) -> int:
	if lives_left >= three_star_lives:
		return 3
	if lives_left >= two_star_lives:
		return 2
	return 1
