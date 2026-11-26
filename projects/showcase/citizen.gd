class_name Citizen
extends CharacterBody2D

signal died(citizen: Citizen, by_player: bool)
signal caught
signal fired(origin: Vector2, direction: Vector2, shooter: Citizen)

enum State { WALK, WAIT, FLEE, DEAD, CHASE, FIGHT }

@export var walk_speed: float = 45.0
@export var run_speed: float = 170.0
@export var scary_speed: float = 150.0
@export var flee_duration: float = 1.4
@export var catch_distance: float = 24.0
@export var fade_time: float = 15.0
@export var fight_range: float = 340.0
@export var keep_near: float = 170.0
@export var keep_far: float = 260.0
@export var police: bool = false

var roads: RoadMap
var lights: TrafficLights
var state: State = State.WALK
var block: int = 0
var corner: int = 0
var next_block: int = 0
var next_corner: int = 0
var crossing_axis: int = -1
var target: Vector2 = Vector2.ZERO
var timer: float = 0.0
var speed: float = 45.0
var threats: Array[Vehicle] = []
var quarry: Node2D = null
var armed: bool = false
var hostile_time: float = 0.0
var cooldown: float = 0.0
var fire_interval: float = 0.9
var spread: float = 0.12
var strafe: float = 1.0
var repath: float = 0.0
var stepping: bool = false

@onready var shape: CollisionShape2D = $Shape
@onready var look: Node2D = $Look
@onready var body_look: Polygon2D = $Look/Body
@onready var fear: Area2D = $Fear
@onready var agent: NavigationAgent2D = $Agent


func _ready() -> void:
	add_to_group("people")
	Palette.set_light(body_look, "color", Palette.LILAC if police else Palette.MUTED)
	strafe = 1.0 if randf() < 0.5 else -1.0
	fear.body_entered.connect(_on_fear_body_entered)
	fear.body_exited.connect(_on_fear_body_exited)
	agent.velocity_computed.connect(_on_agent_velocity_computed)


func setup(map: RoadMap, lights_node: TrafficLights, at_block: int, at_corner: int) -> void:
	roads = map
	lights = lights_node
	block = at_block
	corner = at_corner
	position = roads.corner_position(block, corner)
	speed = walk_speed * randf_range(0.8, 1.3)
	_choose_next()


func _physics_process(delta: float) -> void:
	if state == State.DEAD or NavigationServer2D.map_get_iteration_id(agent.get_navigation_map()) == 0:
		return
	cooldown -= delta
	repath -= delta
	stepping = false
	agent.velocity = Vector2.ZERO
	if state == State.FIGHT:
		_fight(delta)
		return
	if state == State.CHASE:
		_hunt()
		return
	var threat: Vehicle = _scariest()
	if threat != null:
		panic(threat.global_position)
	if state == State.FLEE:
		timer -= delta
		if timer > 0.0:
			_walk(run_speed)
			return
		rejoin()
	if state == State.WAIT:
		timer -= delta
		if timer > 0.0 or (crossing_axis >= 0 and not lights.walk_allowed(crossing_axis)):
			return
		state = State.WALK
	if _walk(speed):
		_arrive()


func _go(point: Vector2) -> void:
	target = point
	agent.target_position = point


func _walk(pace: float) -> bool:
	if agent.is_navigation_finished():
		return true
	agent.velocity = (agent.get_next_path_position() - global_position).normalized() * pace
	stepping = true
	return false


func _follow(point: Vector2) -> void:
	if repath <= 0.0:
		repath = 0.3
		agent.target_position = point


func _hunt() -> void:
	if quarry == null or not is_instance_valid(quarry):
		calm()
		return
	if global_position.distance_to(quarry.global_position) < catch_distance:
		caught.emit()
	_follow(quarry.global_position)
	_walk(run_speed * 0.85)


func _fight(delta: float) -> void:
	if quarry == null or not is_instance_valid(quarry):
		calm()
		return
	if not police:
		hostile_time -= delta
		if hostile_time <= 0.0:
			calm()
			return
	var offset: Vector2 = quarry.global_position - global_position
	var distance: float = offset.length()
	var seen: bool = distance < fight_range and _clear_shot(quarry.global_position)
	if not seen or distance > keep_far:
		_follow(quarry.global_position)
		_walk(run_speed * 0.8)
	else:
		var move: Vector2 = offset.normalized().orthogonal() * strafe * 0.6
		if distance < keep_near:
			move = -offset.normalized()
		velocity = move * run_speed * 0.8
		move_and_slide()
		if get_slide_collision_count() > 0:
			strafe = -strafe
	_face(offset)
	if seen and cooldown <= 0.0:
		cooldown = fire_interval * randf_range(0.8, 1.3)
		var aim: Vector2 = offset.normalized()
		fired.emit(global_position + aim * 12.0, aim.rotated(randf_range(-spread, spread)), self)


func provoke(enemy: Node2D) -> void:
	if state == State.DEAD or police:
		return
	quarry = enemy
	armed = true
	hostile_time = 10.0
	state = State.FIGHT


func pursue(enemy: Node2D, shooting: bool) -> void:
	if state == State.DEAD:
		return
	quarry = enemy
	armed = shooting
	fire_interval = 0.9
	spread = 0.14
	state = State.FIGHT if shooting else State.CHASE


func calm() -> void:
	armed = false
	quarry = null
	rejoin()


func _clear_shot(point: Vector2) -> bool:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, point, 1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _arrive() -> void:
	block = next_block
	if next_corner < 0:
		var corners: Array[int] = roads.side_corners(block, position)
		next_corner = corners[randi() % 2]
		_go(roads.corner_position(block, next_corner))
		return
	corner = next_corner
	_choose_next()


func _choose_next() -> void:
	crossing_axis = -1
	next_block = block
	var roll: float = randf()
	if roll < 0.35:
		var vertical: bool = randf() < 0.5
		var landing: Vector3 = roads.crossing(block, corner, vertical)
		if landing.z >= 0.0:
			next_block = int(landing.z)
			next_corner = -1
			_go(Vector2(landing.x, landing.y))
			if roads.signalized(roads.corner_node(block, corner)):
				crossing_axis = 0 if vertical else 1
			wait(0.3)
			return
	if roll < 0.5 and roads.block_kind(block) in ["P", "S"]:
		var lot: Rect2 = roads.block_rect(block).grow(-RoadMap.SIDEWALK * 2.0)
		next_corner = -1
		_go(lot.position + Vector2(randf(), randf()) * lot.size)
		return
	next_corner = (corner + (1 if randf() < 0.5 else 3)) % 4
	_go(roads.corner_position(block, next_corner))
	if randf() < 0.15:
		wait(randf_range(1.0, 3.0))


func wait(duration: float) -> void:
	state = State.WAIT
	timer = duration


func is_waiting() -> bool:
	return state == State.WAIT


func is_dead() -> bool:
	return state == State.DEAD


func _face(direction: Vector2) -> void:
	if direction.length() > 8.0:
		look.rotation = lerp_angle(look.rotation, direction.angle(), 0.2)


func panic(from: Vector2) -> void:
	if state in [State.DEAD, State.CHASE, State.FIGHT]:
		return
	state = State.FLEE
	timer = flee_duration
	_go(global_position + (global_position - from).normalized() * 220.0)


func rejoin() -> void:
	var nearest: Vector2i = roads.nearest_corner(global_position)
	next_block = nearest.x
	next_corner = nearest.y
	crossing_axis = -1
	_go(roads.corner_position(next_block, next_corner))
	state = State.WALK


func _scariest() -> Vehicle:
	for car: Vehicle in threats:
		if is_instance_valid(car) and car.speed() > scary_speed:
			return car
	return null


func die(push: Vector2, by_player: bool) -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	agent.avoidance_enabled = false
	shape.set_deferred("disabled", true)
	modulate.a = 0.35
	for group: String in ["people", "citizens", "cops"]:
		remove_from_group(group)
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", position + push.normalized() * 30.0, 0.2)
	get_tree().create_timer(fade_time).timeout.connect(queue_free)
	died.emit(self, by_player)


func hit_by_car(car: Vehicle) -> void:
	if state == State.DEAD:
		return
	if car.speed() > car.knock_speed:
		die(car.linear_velocity, car.player_driven)
	else:
		position += (global_position - car.global_position).normalized() * 8.0
		panic(car.global_position)


func shot(direction: Vector2, by_player: bool) -> void:
	die(direction, by_player)


func _on_agent_velocity_computed(safe: Vector2) -> void:
	if not stepping or state == State.DEAD:
		return
	stepping = false
	velocity = velocity.lerp(safe, 0.3)
	_face(velocity)
	move_and_slide()


func _on_fear_body_entered(body: Node2D) -> void:
	var car: Vehicle = body as Vehicle
	if car != null:
		threats.append(car)


func _on_fear_body_exited(body: Node2D) -> void:
	var car: Vehicle = body as Vehicle
	if car != null:
		threats.erase(car)
