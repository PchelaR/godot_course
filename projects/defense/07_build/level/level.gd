extends Node2D

const RESTART_DELAY: float = 3.0

@export var lives: int = 20
@export var money: int = 200

var selected: Plot = null

@onready var waves: Waves = $Waves
@onready var plots: Node2D = $Map/Plots
@onready var towers: Node2D = $Towers
@onready var hud: Hud = $Interface/Hud
@onready var build_menu: BuildMenu = $Interface/BuildMenu


func _ready() -> void:
	hud.show_lives(lives)
	hud.show_money(money)
	hud.show_wave(0, waves.waves.size())
	for plot: Plot in plots.get_children():
		plot.clicked.connect(_on_plot_clicked)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("select"):
		build_menu.close()


func _on_plot_clicked(plot: Plot) -> void:
	if plot.tower != null:
		return
	selected = plot
	build_menu.open(plot.global_position, money)


func _on_build_menu_picked(data: TowerData) -> void:
	build_menu.close()
	if data.cost > money:
		return
	money -= data.cost
	hud.show_money(money)
	var tower: Node2D = data.scene.instantiate()
	tower.position = selected.global_position
	towers.add_child(tower)
	selected.tower = tower


func _on_waves_wave_started(number: int) -> void:
	hud.show_wave(number, waves.waves.size())


func _on_waves_enemy_spawned(enemy: Enemy) -> void:
	enemy.escaped.connect(_on_enemy_escaped)


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
