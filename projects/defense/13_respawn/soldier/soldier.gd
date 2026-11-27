class_name Soldier
extends Node2D

const REACH: float = 28.0

@export var speed: float = 90.0
@export var health: int = 12
@export var damage: int = 1
@export var hit_time: float = 1.0
@export var respawn_time: float = 8.0

var barracks: Tower = null
var home: Vector2 = Vector2.ZERO
var enemy: Enemy = null
var health_left: int = 0
var cooldown: float = 0.0
var dead_time: float = 0.0

@onready var fill: Node2D = $HealthBar/Fill


func _ready() -> void:
	health_left = health


func _physics_process(delta: float) -> void:
	if not visible:
		dead_time -= delta
		if dead_time <= 0.0:
			revive()
		return
	if not is_instance_valid(enemy):
		enemy = find_enemy()
	if enemy == null:
		global_position = global_position.move_toward(home, speed * delta)
		return
	var side: Vector2 = enemy.global_position.direction_to(global_position)
	var spot: Vector2 = enemy.global_position + side * (REACH - 4.0)
	global_position = global_position.move_toward(spot, speed * delta)
	if global_position.distance_to(enemy.global_position) > REACH:
		return
	cooldown -= delta
	if cooldown <= 0.0:
		cooldown = hit_time
		enemy.take_damage(damage)


func find_enemy() -> Enemy:
	for candidate: Enemy in barracks.enemies_in_range():
		if not is_instance_valid(candidate.blocker):
			candidate.blocker = self
			return candidate
	return null


func take_damage(amount: int) -> void:
	health_left -= amount
	fill.scale.x = maxf(float(health_left) / health, 0.0)
	if health_left <= 0:
		die()


func die() -> void:
	if is_instance_valid(enemy):
		enemy.blocker = null
	enemy = null
	visible = false
	dead_time = respawn_time


func revive() -> void:
	health_left = health
	fill.scale.x = 1.0
	global_position = barracks.global_position
	visible = true
