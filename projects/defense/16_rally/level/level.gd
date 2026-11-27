extends Node2D

const RESTART_DELAY: float = 3.0

@export var lives: int = 20
@export var money: int = 200

var selected: Plot = null
var rallying: Barracks = null

@onready var waves: Waves = $Waves
@onready var plots: Node2D = $Map/Plots
@onready var towers: Node2D = $Towers
@onready var hud: Hud = $Interface/Hud
@onready var build_menu: BuildMenu = $Interface/BuildMenu
@onready var tower_menu: TowerMenu = $Interface/TowerMenu


func _ready() -> void:
	hud.show_lives(lives)
	hud.show_money(money)
	hud.show_wave(0, waves.waves.size())
	for plot: Plot in plots.get_children():
		plot.clicked.connect(_on_plot_clicked)


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


func _on_tower_menu_upgrade_pressed() -> void:
	tower_menu.close()
	var tower: Tower = selected.tower
	if not tower.can_upgrade() or tower.data.upgrade_cost > money:
		return
	money -= tower.data.upgrade_cost
	hud.show_money(money)
	tower.upgrade()


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


func _on_waves_enemy_spawned(enemy: Enemy) -> void:
	enemy.escaped.connect(_on_enemy_escaped)
	enemy.died.connect(_on_enemy_died)


func _on_enemy_died(reward: int) -> void:
	money += reward
	hud.show_money(money)


func _on_enemy_escaped() -> void:
	if lives == 0:
		return
	lives -= 1
	hud.show_lives(lives)
	if lives == 0:
		lose()


func lose() -> void:
	hud.show_message("ПОРАЖЕНИЕ")
	get_tree().paused = true
	await get_tree().create_timer(RESTART_DELAY).timeout
	get_tree().paused = false
	get_tree().reload_current_scene()
