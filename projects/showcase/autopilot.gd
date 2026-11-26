class_name Autopilot
extends Node

@export var cruise_speed: float = 170.0
@export var chase_speed: float = 340.0
@export var patience: float = 2.5

var roads: RoadMap
var lights: TrafficLights
var node: Vector2i = Vector2i.ZERO
var heading: Vector2i = Vector2i.RIGHT
var path: Array[Vector2] = []
var signal_ahead: bool = false
var blocked: float = 0.0
var reversing: float = 0.0
var route_timer: float = 0.0
var target: Node2D = null
var lost: float = 0.0
var bypass: float = 0.0
var stuck: float = 0.0
var queued: bool = false

@onready var vehicle: Vehicle = get_parent()
@onready var ahead: RayCast2D = $"../Ahead"
@onready var agent: NavigationAgent2D = $"../Agent"


func setup(map: RoadMap, lights_node: TrafficLights, from: Vector2i, direction: Vector2i) -> void:
	roads = map
	lights = lights_node
	heading = direction
	node = from + direction
	path = [roads.lane_end(node, heading)]
	signal_ahead = roads.signalized(node)


func _physics_process(delta: float) -> void:
	if roads == null or not vehicle.has_driver or vehicle.player_driven or vehicle.wrecked:
		return
	if reversing > 0.0:
		reversing -= delta
		vehicle.handbrake = false
		vehicle.throttle = -1.0
		if reversing <= 0.0 and target == null:
			rejoin()
		return
	if target != null and is_instance_valid(target):
		chase(delta)
		return
	bypass -= delta
	queued = false
	if path.is_empty():
		if signal_ahead and not lights.is_green(axis()):
			queued = true
			drive(0.0)
			return
		plan_turn()
	while path.size() > 1 and vehicle.global_position.distance_to(path[0]) < 30.0:
		path.remove_at(0)
	if path.size() == 1 and vehicle.global_position.distance_to(path[0]) < 14.0:
		path.clear()
		drive(0.0)
		return
	var wanted: float = cruise_speed
	var remaining: float = remaining_distance()
	var error: float = steer_to(path[0])
	lost = lost + delta if absf(error) > 1.6 else 0.0
	if lost > 0.8:
		rejoin()
		return
	if signal_ahead and not lights.is_green(axis()) and remaining > 20.0:
		wanted = minf(wanted, sqrt(1000.0 * maxf(remaining - 12.0, 0.0)))
	if absf(error) > 0.6 or path.size() > 2:
		wanted = minf(wanted, 70.0)
	if obstacle():
		wanted = 0.0
		blocked += delta
		var other: Vehicle = ahead.get_collider() as Vehicle
		if other != null and other.autopilot.queued:
			queued = true
			blocked = 0.0
		elif blocked > 6.0 or (blocked > 1.2 and other != null and not other.has_driver):
			overtake()
	else:
		blocked = 0.0
	if blocked > patience * 3.0:
		reverse(0.8)
	stuck = stuck + delta if wanted > 40.0 and vehicle.speed() < 8.0 else 0.0
	if stuck > 1.2:
		stuck = 0.0
		reverse(1.0)
	drive(wanted)


func overtake() -> void:
	var blocker: Node2D = ahead.get_collider() as Node2D
	if blocker == null:
		return
	var forward: Vector2 = vehicle.global_transform.x
	var side: Vector2 = forward.orthogonal() * 46.0
	path.push_front(blocker.global_position + forward * 70.0 + side)
	path.push_front(blocker.global_position - forward * 20.0 + side)
	bypass = 2.5
	blocked = 0.0


func chase(delta: float) -> void:
	var goal: Vector2 = target.global_position
	var here: Vector2 = vehicle.global_position
	route_timer -= delta
	if route_timer <= 0.0:
		route_timer = 0.4
		agent.target_position = goal
	var next: Vector2 = agent.get_next_path_position()
	var error: float = steer_to(next)
	var wanted: float = chase_speed if here.distance_to(goal) > 90.0 else 60.0
	if absf(error) > 0.35:
		wanted = minf(wanted, 130.0)
	else:
		wanted = minf(wanted, corner_speed(here))
	if wall_ahead():
		wanted = minf(wanted, 70.0)
	if vehicle.speed() < 20.0 and vehicle.throttle > 0.5:
		blocked += delta
	else:
		blocked = 0.0
	if blocked > 1.0:
		reverse(0.8)
	drive(wanted)


func corner_speed(here: Vector2) -> float:
	var points: PackedVector2Array = agent.get_current_navigation_path()
	var index: int = agent.get_current_navigation_path_index()
	if index + 1 >= points.size():
		return chase_speed
	var corner: Vector2 = points[index]
	var before: Vector2 = (corner - here).normalized()
	var after: Vector2 = (points[index + 1] - corner).normalized()
	var sharpness: float = 1.0 - before.dot(after)
	var distance: float = here.distance_to(corner)
	if sharpness < 0.3 or distance > 220.0:
		return chase_speed
	return lerpf(120.0, chase_speed, clampf(distance / 220.0, 0.0, 1.0) * (1.0 - minf(sharpness, 1.0)))


func reverse(duration: float) -> void:
	blocked = 0.0
	reversing = duration
	vehicle.steer = -vehicle.steer


func axis() -> int:
	return 0 if heading.x != 0 else 1


func plan_turn() -> void:
	var options: Array[Vector2i] = roads.exits(node, heading)
	var exit: Vector2i = options[randi() % options.size()]
	path = turn_points(vehicle.global_position, heading, roads.lane_start(node, exit), exit)
	heading = exit
	node += exit
	path.append(roads.lane_end(node, heading))
	signal_ahead = roads.signalized(node)


func turn_points(from: Vector2, entry: Vector2i, to: Vector2, exit: Vector2i) -> Array[Vector2]:
	if entry == exit or entry == -exit:
		return [to]
	var corner: Vector2 = from + Vector2(entry) * (to - from).dot(Vector2(entry))
	var points: Array[Vector2] = []
	for step: int in range(1, 9):
		var t: float = step / 8.0
		points.append(from.lerp(corner, t).lerp(corner.lerp(to, t), t))
	return points


func rejoin() -> void:
	var lane: Vector4i = roads.snap(vehicle.global_position, vehicle.global_transform.x)
	if lane.z == 0 and lane.w == 0:
		return
	heading = Vector2i(lane.z, lane.w)
	node = Vector2i(lane.x, lane.y) + heading
	var finish: Vector2 = roads.lane_end(node, heading)
	var start: Vector2 = roads.lane_start(node - heading, heading)
	var along: Vector2 = Geometry2D.get_closest_point_to_segment(vehicle.global_position, start, finish)
	path = [along.move_toward(finish, 60.0), finish]
	signal_ahead = roads.signalized(node)
	lost = 0.0


func remaining_distance() -> float:
	var total: float = 0.0
	var from: Vector2 = vehicle.global_position
	for point: Vector2 in path:
		total += from.distance_to(point)
		from = point
	return total


func steer_to(point: Vector2) -> float:
	var desired: float = (point - vehicle.global_position).angle()
	var error: float = angle_difference(vehicle.global_rotation, desired)
	vehicle.steer = clampf(error * 2.5, -1.0, 1.0)
	return error


func drive(wanted: float) -> void:
	var speed: float = vehicle.linear_velocity.dot(vehicle.global_transform.x)
	if wanted < 1.0:
		vehicle.throttle = -1.0 if speed > 40.0 else 0.0
		vehicle.handbrake = speed <= 40.0
		return
	vehicle.handbrake = false
	vehicle.throttle = clampf((wanted - speed) / 60.0, -1.0, 1.0)


func obstacle() -> bool:
	if bypass > 0.0 or not ahead.is_colliding():
		return false
	var citizen: Citizen = ahead.get_collider() as Citizen
	return citizen == null or not citizen.is_waiting()


func wall_ahead() -> bool:
	var forward: Vector2 = vehicle.global_transform.x
	var reach: float = maxf(60.0, vehicle.speed() * 0.5)
	var from: Vector2 = vehicle.global_position
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, from + forward * reach, 1)
	return not vehicle.get_world_2d().direct_space_state.intersect_ray(query).is_empty()
