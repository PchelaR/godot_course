extends Node2D

const HEAT_STARS: Array[float] = [40.0, 140.0, 300.0, 520.0, 800.0]
const RESPRAY_PRICE: int = 250
const DISTRICTS: Array[String] = [
	"Квартал Узлов",
	"Сигнальная слобода",
	"Парк Экземпляров",
	"Векторный квартал",
	"Дерево Сцены",
	"Площадь Сигналов",
	"Тайловые дворы",
	"Стоянка Ресурсов",
	"Квартал Групп",
	"Колбэк-сити",
	"Глобальные координаты",
	"Парк Областей",
	"Покрасочная",
	"Локальные координаты",
	"Физтела",
]
const OUTSKIRTS_NAME: String = "Загород"
const THEME_QUERY: String = (
	"(() => { try { return window.parent.document.documentElement.dataset.theme || 'dark'; }"
	+ " catch (error) { return 'dark'; } })()"
)
const TROPHY_EVENT: String = (
	"try { window.parent.dispatchEvent(new CustomEvent('godot-trophy', { detail: '%s' })); }" + " catch (error) {}"
)

@export var vehicle_scene: PackedScene
@export var citizen_scene: PackedScene
@export var bullet_scene: PackedScene
@export var burst_scene: PackedScene
@export var traffic_target: int = 22
@export var citizen_target: int = 55
@export var provoke_chance: float = 0.08
@export var city_seed: int = 11

var roads: RoadMap = RoadMap.new()
var random: RandomNumberGenerator = RandomNumberGenerator.new()
var driving: Vehicle = null
var money: int = 0
var heat: float = 0.0
var crime_timer: float = 0.0
var manage_timer: float = 0.0
var frozen: float = 0.0
var theme_timer: float = 0.0
var garage: Rect2 = Rect2()
var covers: Array[Rect2] = []
var car_map: RID
var roofs: Array[Polygon2D] = []
var rooms: Array[Rect2] = []
var unlocked: Dictionary[String, bool] = {}
var district: int = -2

@onready var ground: Node2D = $Ground
@onready var skid_marks: Node2D = $SkidMarks
@onready var lights: TrafficLights = $Lights
@onready var world: Node2D = $World
@onready var overhead: Node2D = $Overhead
@onready var roof_layer: Node2D = $Roofs
@onready var player: Player = $World/Player
@onready var camera: CityCamera = $Camera
@onready var hud: Hud = $Hud


func _ready() -> void:
	random.seed = city_seed
	var builder: CityBuilder = CityBuilder.new(roads, ground, world, lights, random)
	builder.overhead = overhead
	builder.roof_layer = roof_layer
	builder.build()
	garage = builder.garage
	covers = builder.covers
	roofs = builder.roofs
	rooms = builder.rooms
	_bake_navigation()
	for spot: Transform2D in builder.parking:
		if random.randf() < 0.6:
			_spawn_vehicle(spot.origin, spot.get_rotation(), false)
	for index: int in traffic_target:
		_spawn_traffic(false)
	for index: int in citizen_target:
		_spawn_citizen(false)
	lights.refresh()
	player.fired.connect(_on_player_fired)
	player.hurt.connect(_on_player_hurt)
	camera.limit_right = int(roads.size.x)
	camera.limit_bottom = int(roads.size.y)
	respawn()
	hud.show_money(money)
	sync_theme(true)


func _process(delta: float) -> void:
	var under: bool = false
	for cover: Rect2 in covers:
		if cover.has_point(controlled().global_position):
			under = true
	overhead.modulate.a = lerpf(overhead.modulate.a, 0.35 if under else 1.0, 1.0 - exp(-8.0 * delta))
	for index: int in roofs.size():
		var inside: bool = driving == null and rooms[index].has_point(player.global_position)
		roofs[index].modulate.a = lerpf(roofs[index].modulate.a, 0.0 if inside else 1.0, 1.0 - exp(-10.0 * delta))
	theme_timer -= delta
	if theme_timer <= 0.0:
		theme_timer = 0.5
		sync_theme(false)
	_update_district()


func _update_district() -> void:
	var spot: Vector2 = controlled().global_position
	var found: int = -1 if roads.city_rect().has_point(spot) else DISTRICTS.size()
	for index: int in RoadMap.BLOCKS.size():
		if roads.block_rect(index).grow(36.0).has_point(spot):
			found = index
			break
	if found < 0 or found == district:
		return
	district = found
	hud.show_district(DISTRICTS[found] if found < DISTRICTS.size() else OUTSKIRTS_NAME)


func _physics_process(delta: float) -> void:
	if frozen > 0.0:
		frozen -= delta
		if frozen <= 0.0:
			respawn()
		return
	var nearby: Vehicle = player.nearest_vehicle() if driving == null else null
	if Input.is_action_just_pressed("interact"):
		if driving != null:
			_leave_vehicle()
		elif nearby != null:
			_enter_vehicle(nearby)
	if driving != null:
		driving.throttle = Input.get_axis("move_down", "move_up")
		driving.steer = Input.get_axis("move_left", "move_right")
		driving.handbrake = Input.is_action_pressed("handbrake")
		hud.show_hint("WASD — РУЛЬ · ПРОБЕЛ — РУЧНИК · E — ВЫЙТИ")
		if garage.has_point(driving.global_position) and heat > 0.0:
			_respray()
	elif nearby != null:
		hud.show_hint("E — УГНАТЬ МАШИНУ" if nearby.has_driver else "E — СЕСТЬ В МАШИНУ")
	else:
		hud.show_hint("WASD — ИДТИ · МЫШЬ — ПРИЦЕЛ · ЛКМ — ОГОНЬ")
	_update_wanted(delta)
	manage_timer -= delta
	if manage_timer <= 0.0:
		manage_timer = 1.0
		_manage_population()


func controlled() -> Node2D:
	return driving if driving != null else player


func stars() -> int:
	var count: int = 0
	for threshold: float in HEAT_STARS:
		if heat >= threshold:
			count += 1
	return count


func crime(amount: float) -> void:
	heat = minf(heat + amount, 1000.0)
	crime_timer = 6.0


func award(amount: int, at: Vector2) -> void:
	money += amount
	hud.show_money(money)
	_popup("+$%d" % amount, at)


func game_over(text: String, color: Color) -> void:
	if frozen > 0.0:
		return
	frozen = 2.5
	hud.announce(text, color)
	money = int(money * 0.9)
	hud.show_money(money)
	heat = 0.0
	hud.show_stars(0, false)
	player.process_mode = Node.PROCESS_MODE_DISABLED
	if driving != null:
		driving.throttle = 0.0
		driving.handbrake = true
	for group: String in ["police", "cops"]:
		for node: Node in get_tree().get_nodes_in_group(group):
			if node != driving:
				node.queue_free()


func respawn() -> void:
	if driving != null:
		driving.player_driven = false
		driving.repaint()
		driving = null
	player.set_active(true)
	player.reset()
	player.global_position = roads.corner_position(RoadMap.START_BLOCK, 0)
	camera.target = player
	camera.snap()
	hud.announce("НУЛЕВОЙ КВАРТАЛ", Palette.tint(Palette.ACCENT))
	district = -2


func sync_theme(force: bool) -> void:
	var dark: bool = true
	if OS.has_feature("web"):
		dark = str(JavaScriptBridge.eval(THEME_QUERY)) != "light"
	if dark == Palette.dark and not force:
		return
	Palette.dark = dark
	RenderingServer.set_default_clear_color(Palette.tint(Palette.PAPER))
	Palette.paint(self)


func trophy(id: String) -> void:
	if unlocked.has(id):
		return
	unlocked[id] = true
	if OS.has_feature("web"):
		JavaScriptBridge.eval(TROPHY_EVENT % id)


func _spawn_vehicle(at: Vector2, angle: float, police: bool) -> Vehicle:
	var car: Vehicle = vehicle_scene.instantiate()
	car.position = at
	car.rotation = angle
	car.police = police
	world.add_child(car)
	Palette.paint(car)
	car.exploded.connect(_on_vehicle_exploded)
	car.skidded.connect(skid_marks._on_vehicle_skidded)
	return car


func _spawn_traffic(offscreen: bool) -> Vehicle:
	var lane: Vector4i = _free_lane(900.0 if offscreen else 0.0)
	if lane.z == 0 and lane.w == 0:
		return null
	var from: Vector2i = Vector2i(lane.x, lane.y)
	var direction: Vector2i = Vector2i(lane.z, lane.w)
	var start: Vector2 = roads.lane_start(from, direction)
	var finish: Vector2 = roads.lane_end(from + direction, direction)
	var spot: Vector2 = start.lerp(finish, random.randf_range(0.1, 0.6))
	var car: Vehicle = _spawn_vehicle(spot, Vector2(direction).angle(), false)
	car.has_driver = true
	car.add_to_group("traffic")
	car.autopilot.setup(roads, lights, from, direction)
	return car


func _spawn_person(at: Vector2, police: bool) -> Citizen:
	var person: Citizen = citizen_scene.instantiate()
	person.police = police
	person.position = at
	world.add_child(person)
	Palette.paint(person)
	person.roads = roads
	person.lights = lights
	person.add_to_group("cops" if police else "citizens")
	person.died.connect(_on_person_died)
	person.fired.connect(_on_person_fired)
	if police:
		person.caught.connect(_on_cop_caught)
	return person


func _spawn_citizen(offscreen: bool) -> void:
	for attempt: int in 20:
		var block: int = random.randi() % RoadMap.BLOCKS.size()
		var corner: int = random.randi() % 4
		var spot: Vector2 = roads.corner_position(block, corner)
		if offscreen and spot.distance_to(controlled().global_position) < 700.0:
			continue
		_spawn_person(spot, false).setup(roads, lights, block, corner)
		return


func _free_lane(min_distance: float) -> Vector4i:
	var all: Array[Vector2i] = roads.nodes()
	var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query.collision_mask = 4
	for attempt: int in 40:
		var node: Vector2i = all[random.randi() % all.size()]
		var direction: Vector2i = RoadMap.DIRECTIONS[random.randi() % 4]
		if not roads.has_road(node, node + direction):
			continue
		query.position = roads.lane_start(node, direction).lerp(roads.lane_end(node + direction, direction), 0.35)
		if query.position.distance_to(controlled().global_position) < min_distance:
			continue
		if get_world_2d().direct_space_state.intersect_point(query).is_empty():
			return Vector4i(node.x, node.y, direction.x, direction.y)
	return Vector4i.ZERO


func _enter_vehicle(car: Vehicle) -> void:
	if car.has_driver:
		var nearest: Vector2i = roads.nearest_corner(car.global_position)
		var driver: Citizen = _spawn_person(car.global_position, false)
		driver.setup(roads, lights, nearest.x, nearest.y)
		driver.global_position = car.global_position - car.global_transform.y * 30.0
		if random.randf() < provoke_chance:
			driver.provoke(car)
		else:
			driver.panic(car.global_position)
		crime(50.0)
		car.has_driver = false
		car.autopilot.target = null
		trophy("hijack")
	if car.police:
		crime(120.0)
	for group: String in ["traffic", "police", "abandoned"]:
		car.remove_from_group(group)
	driving = car
	car.player_driven = true
	car.handbrake = false
	car.repaint()
	player.set_active(false)
	camera.target = car
	trophy("driver")


func _leave_vehicle() -> void:
	var car: Vehicle = driving
	driving = null
	car.player_driven = false
	car.throttle = 0.0
	car.steer = 0.0
	car.handbrake = true
	car.repaint()
	player.global_position = _exit_point(car)
	player.set_active(true)
	camera.target = player


func _exit_point(car: Vehicle) -> Vector2:
	var side: Vector2 = car.global_transform.y
	var back: Vector2 = car.global_transform.x
	var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query.collision_mask = 5
	for offset: Vector2 in [-side * 34.0, side * 34.0, -back * 46.0, back * 46.0]:
		query.position = car.global_position + offset
		if get_world_2d().direct_space_state.intersect_point(query).is_empty():
			return query.position
	return car.global_position - side * 34.0


func _respray() -> void:
	heat = 0.0
	crime_timer = 0.0
	money = maxi(money - RESPRAY_PRICE, 0)
	hud.show_money(money)
	driving.health = driving.max_health
	driving.fuse = 0.0
	_popup("ПОКРАСКА −$%d" % RESPRAY_PRICE, driving.global_position)
	for group: String in ["police", "cops"]:
		for node: Node in get_tree().get_nodes_in_group(group):
			var hunter: Node2D = node as Node2D
			if hunter.global_position.distance_to(driving.global_position) > 300.0:
				hunter.queue_free()


func _update_wanted(delta: float) -> void:
	crime_timer -= delta
	var seen: bool = false
	var target: Node2D = controlled()
	for group: String in ["police", "cops"]:
		for node: Node in get_tree().get_nodes_in_group(group):
			if (node as Node2D).global_position.distance_to(target.global_position) < 500.0:
				seen = true
	if crime_timer <= 0.0 and not seen:
		heat = maxf(heat - 10.0 * delta, 0.0)
	var level: int = stars()
	hud.show_stars(level, crime_timer > 0.0 or seen)
	if level >= 5:
		trophy("stars")
	var speed: float = driving.speed() if driving != null else player.velocity.length()
	for node: Node in get_tree().get_nodes_in_group("police"):
		var car: Vehicle = node as Vehicle
		car.autopilot.target = target if level > 0 and car.has_driver else null
		var distance: float = car.global_position.distance_to(target.global_position)
		var stop: bool = (level >= 2 and distance < 320.0) or (level == 1 and distance < 220.0 and speed < 60.0)
		if stop and car.has_driver and not car.has_meta("cops_out"):
			car.set_meta("cops_out", true)
			for _index: int in 2 if level >= 2 else 1:
				_spawn_person(_exit_point(car), true)
			car.has_driver = false
			car.autopilot.target = null
			car.throttle = 0.0
			car.steer = 0.0
			car.handbrake = true
			car.remove_from_group("police")
			car.add_to_group("abandoned")
	for node: Node in get_tree().get_nodes_in_group("cops"):
		var cop: Citizen = node as Citizen
		if level > 0:
			cop.pursue(target, level >= 2)
		elif cop.quarry != null:
			cop.calm()


func _manage_population() -> void:
	var traffic: int = get_tree().get_nodes_in_group("traffic").size()
	for index: int in mini(traffic_target - traffic, 2):
		_spawn_traffic(true)
	var people: int = get_tree().get_nodes_in_group("citizens").size()
	for index: int in mini(citizen_target - people, 3):
		_spawn_citizen(true)
	var wanted: int = mini(stars(), 4)
	if get_tree().get_nodes_in_group("police").size() < wanted:
		var lane: Vector4i = _free_lane(900.0)
		if lane.z != 0 or lane.w != 0:
			var from: Vector2i = Vector2i(lane.x, lane.y)
			var direction: Vector2i = Vector2i(lane.z, lane.w)
			var car: Vehicle = _spawn_vehicle(roads.lane_start(from, direction), Vector2(direction).angle(), true)
			car.has_driver = true
			car.add_to_group("police")
			car.autopilot.agent.set_navigation_map(car_map)
			car.autopilot.setup(roads, lights, from, direction)
	var here: Vector2 = controlled().global_position
	for group: String in ["police", "cops", "wrecks", "abandoned"]:
		for node: Node in get_tree().get_nodes_in_group(group):
			var thing: Node2D = node as Node2D
			var gone: bool = group in ["wrecks", "abandoned"] or wanted == 0
			if gone and thing.global_position.distance_to(here) > 1400.0 and thing != driving:
				thing.queue_free()


func _bake_navigation() -> void:
	var source: NavigationMeshSourceGeometryData2D = NavigationMeshSourceGeometryData2D.new()
	var probe: NavigationPolygon = NavigationPolygon.new()
	probe.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	probe.parsed_collision_mask = 1
	NavigationServer2D.parse_source_geometry_data(probe, source, world)
	var size: Vector2 = roads.size
	source.add_traversable_outline(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0.0), size, Vector2(0.0, size.y)]))
	car_map = NavigationServer2D.map_create()
	NavigationServer2D.map_set_active(car_map, true)
	for radius: float in [8.0, 34.0]:
		var polygon: NavigationPolygon = NavigationPolygon.new()
		polygon.agent_radius = radius
		NavigationServer2D.bake_from_source_geometry_data(polygon, source)
		var region: NavigationRegion2D = NavigationRegion2D.new()
		region.navigation_polygon = polygon
		add_child(region)
		if radius > 20.0:
			region.set_navigation_map(car_map)


func _shoot(origin: Vector2, direction: Vector2, ignore: Array[RID], damage: float, by_player: bool) -> void:
	var bullet: Bullet = bullet_scene.instantiate()
	world.add_child(bullet)
	Palette.paint(bullet)
	bullet.damage = damage
	bullet.by_player = by_player
	bullet.launch(origin, direction, ignore)
	bullet.hit.connect(_on_bullet_hit)


func _burst(at: Vector2, small: bool) -> void:
	var effect: Node2D = burst_scene.instantiate()
	effect.set("small", small)
	effect.position = at
	world.add_child(effect)
	Palette.paint(effect)


func _popup(text: String, at: Vector2) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Palette.tint(Palette.ACCENT))
	label.add_theme_color_override("font_outline_color", Palette.tint(Palette.PAPER))
	label.add_theme_constant_override("outline_size", 6)
	label.position = at + Vector2(-30.0, -40.0)
	world.add_child(label)
	var tween: Tween = label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 40.0, 0.9)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.9)
	tween.tween_callback(label.queue_free)


func _provoke_near(point: Vector2, radius: float) -> void:
	for node: Node in get_tree().get_nodes_in_group("citizens"):
		var person: Citizen = node as Citizen
		if person.global_position.distance_to(point) < radius:
			if random.randf() < provoke_chance:
				person.provoke(controlled())
			else:
				person.panic(point)


func _explode(car: Vehicle) -> void:
	_burst(car.global_position, false)
	var distance: float = car.global_position.distance_to(controlled().global_position)
	camera.shake(0.7 if distance < 400.0 else 0.25)
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 150.0
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, car.global_position)
	query.collision_mask = 14
	for hit: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 48):
		var body: Node2D = hit["collider"] as Node2D
		var away: Vector2 = body.global_position - car.global_position
		var power: float = clampf(1.0 - away.length() / 150.0, 0.0, 1.0)
		if body is Vehicle and body != car:
			var other: Vehicle = body
			other.apply_central_impulse(away.normalized() * 700.0 * power * other.mass)
			other.damage.call_deferred(50.0 * power)
		elif body is Citizen:
			(body as Citizen).die(away, distance < 600.0)
		elif body == player:
			player.take_damage(90.0 * power)
	if car == driving:
		game_over("WASTED", Palette.tint(Palette.ACCENT))


func _on_player_fired(origin: Vector2, direction: Vector2) -> void:
	var ignore: Array[RID] = [player.get_rid()]
	_shoot(origin, direction, ignore, 0.0, true)
	camera.shake(0.08)
	crime(3.0)
	_provoke_near(origin, 300.0)


func _on_person_fired(origin: Vector2, direction: Vector2, shooter: Citizen) -> void:
	var ignore: Array[RID] = [shooter.get_rid()]
	_shoot(origin, direction, ignore, 6.0 if shooter.police else 5.0, false)


func _on_bullet_hit(bullet: Bullet, collider: Object, point: Vector2) -> void:
	_burst(point, true)
	if collider is Citizen:
		(collider as Citizen).shot(bullet.direction, bullet.by_player)
	elif collider == player:
		player.take_damage(bullet.damage)
		camera.shake(0.15)
	elif collider is Vehicle:
		var car: Vehicle = collider
		car.damage(9.0)
		car.apply_impulse(bullet.direction * 30.0 * car.mass, point - car.global_position)
		if car.police and bullet.by_player:
			crime(25.0)


func _on_player_hurt(health: float) -> void:
	hud.show_health(health)
	if health <= 0.0:
		game_over("WASTED", Palette.tint(Palette.ACCENT))


func _on_person_died(person: Citizen, by_player: bool) -> void:
	if not by_player:
		return
	if person.police:
		crime(80.0)
		award(50, person.global_position)
	else:
		crime(25.0)
		award(10, person.global_position)
	_provoke_near(person.global_position, 200.0)


func _on_vehicle_exploded(car: Vehicle) -> void:
	for group: String in ["traffic", "police", "abandoned"]:
		car.remove_from_group(group)
	car.add_to_group("wrecks")
	if car.global_position.distance_to(controlled().global_position) < 600.0:
		award(250 if car.police else 100, car.global_position)
		crime(150.0 if car.police else 60.0)
	trophy("boom")
	_explode.call_deferred(car)


func _on_cop_caught() -> void:
	game_over("BUSTED", Palette.tint(Palette.LILAC))
