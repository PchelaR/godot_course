class_name Player
extends CharacterBody2D

signal fired(origin: Vector2, direction: Vector2)
signal hurt(health: float)

@export var speed: float = 200.0
@export var acceleration: float = 1800.0
@export var fire_interval: float = 0.14
@export var spread: float = 0.04
@export var down_duration: float = 1.0
@export var auto_aim_range: float = 300.0
@export var max_health: float = 100.0

var aim: Vector2 = Vector2.RIGHT
var cooldown: float = 0.0
var mouse_idle: float = 10.0
var down_time: float = 0.0
var health: float = 100.0

@onready var look: Node2D = $Look
@onready var muzzle: Marker2D = $Look/Muzzle
@onready var flash: Polygon2D = $Look/Flash
@onready var reach: Area2D = $Reach


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_idle = 0.0


func _physics_process(delta: float) -> void:
	cooldown -= delta
	mouse_idle += delta
	flash.visible = cooldown > fire_interval - 0.05
	if down_time > 0.0:
		down_time -= delta
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		if down_time <= 0.0:
			modulate.a = 1.0
		return
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = velocity.move_toward(direction * speed, acceleration * delta)
	move_and_slide()
	aim = aim_direction(direction)
	look.rotation = aim.angle()
	if Input.is_action_pressed("shoot") and cooldown <= 0.0:
		cooldown = fire_interval
		fired.emit(muzzle.global_position, aim.rotated(randf_range(-spread, spread)))


func aim_direction(direction: Vector2) -> Vector2:
	if mouse_idle < 2.0:
		return (get_global_mouse_position() - global_position).normalized()
	var best: Node2D = null
	for node: Node in get_tree().get_nodes_in_group("people"):
		var person: Citizen = node as Citizen
		if person == null or person.is_dead():
			continue
		var distance: float = global_position.distance_to(person.global_position)
		if distance < auto_aim_range and (best == null or distance < global_position.distance_to(best.global_position)):
			best = person
	if best != null:
		return (best.global_position - global_position).normalized()
	return direction.normalized() if direction != Vector2.ZERO else aim


func nearest_vehicle() -> Vehicle:
	var best: Vehicle = null
	for body: Node2D in reach.get_overlapping_bodies():
		var car: Vehicle = body as Vehicle
		if car == null or car.wrecked:
			continue
		if best == null or position.distance_to(car.position) < position.distance_to(best.position):
			best = car
	return best


func set_active(active: bool) -> void:
	visible = active
	velocity = Vector2.ZERO
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	collision_layer = 2 if active else 0


func hit_by_car(car: Vehicle) -> void:
	if down_time > 0.0 or car.speed() < 160.0:
		return
	down_time = down_duration
	velocity = car.linear_velocity * 0.6
	modulate.a = 0.5
	take_damage(clampf((car.speed() - 120.0) * 0.2, 5.0, 60.0))


func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	hurt.emit(health)


func reset() -> void:
	health = max_health
	down_time = 0.0
	modulate.a = 1.0
	hurt.emit(health)
