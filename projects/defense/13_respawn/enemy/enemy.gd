class_name Enemy
extends PathFollow2D

signal escaped
signal died(reward: int)

@export var speed: float = 60.0
@export var health: int = 10
@export var reward: int = 10
@export var damage: int = 1
@export var hit_time: float = 1.0

var health_left: int = 0
var blocker: Soldier = null
var cooldown: float = 0.0

@onready var fill: Node2D = $HealthBar/Fill


func _ready() -> void:
	health_left = health


func _physics_process(delta: float) -> void:
	if is_instance_valid(blocker) and blocker.visible:
		fight(delta)
		return
	progress += speed * delta
	if progress_ratio >= 1.0:
		escaped.emit()
		queue_free()


func fight(delta: float) -> void:
	if global_position.distance_to(blocker.global_position) > Soldier.REACH:
		return
	cooldown -= delta
	if cooldown <= 0.0:
		cooldown = hit_time
		blocker.take_damage(damage)


func position_in(seconds: float) -> Vector2:
	var road: Path2D = get_parent()
	return road.to_global(road.curve.sample_baked(progress + speed * seconds))


func take_damage(amount: int) -> void:
	if health_left <= 0:
		return
	health_left -= amount
	fill.scale.x = maxf(float(health_left) / health, 0.0)
	if health_left <= 0:
		died.emit(reward)
		queue_free()
