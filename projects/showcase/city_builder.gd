class_name CityBuilder
extends RefCounted

const FIELD: Color = Palette.PAPER
const ROAD: Color = Palette.WINDOW
const PAVEMENT: Color = Palette.PAPER
const BUILDING: Color = Palette.MUTED
const LINE: Color = Palette.INK
const STOP: Color = Palette.ACCENT
const PARK: Color = Palette.PAPER
const TREE: Color = Palette.MUTED
const WATER: Color = Palette.WINDOW
const FLOOR: Color = Palette.WINDOW
const FURNITURE: Color = Palette.MUTED
const DOOR: Color = Palette.ACCENT
const WALL: float = 8.0
const DOORWAY: float = 32.0
const DASH: float = 28.0
const ALLEY: float = 36.0
const BRIDGES: Array[Vector4i] = [Vector4i(3, 0, 3, 1), Vector4i(1, 4, 2, 4), Vector4i(5, 4, 6, 4)]

var roads: RoadMap
var ground: Node2D
var world: Node2D
var lights: TrafficLights
var random: RandomNumberGenerator
var parking: Array[Transform2D] = []
var garage: Rect2 = Rect2()
var overhead: Node2D
var covers: Array[Rect2] = []
var roof_layer: Node2D
var roofs: Array[Polygon2D] = []
var rooms: Array[Rect2] = []
var current_lot: Rect2 = Rect2()


func _init(
	map: RoadMap, ground_node: Node2D, world_node: Node2D, lights_node: TrafficLights, generator: RandomNumberGenerator
) -> void:
	roads = map
	ground = ground_node
	world = world_node
	lights = lights_node
	random = generator


func build() -> void:
	rect(Rect2(Vector2.ZERO, roads.size), FIELD, ground)
	build_roads()
	for index: int in RoadMap.BLOCKS.size():
		build_block(index)
	build_outskirts()
	build_border()
	if overhead != null:
		build_overhead()


func build_roads() -> void:
	for node: Vector2i in roads.nodes():
		var center: Vector2 = roads.node_position(node)
		var box: Vector2 = Vector2(RoadMap.COLUMN_ROADS[node.x], RoadMap.ROW_ROADS[node.y])
		rect(Rect2(center - box / 2.0, box), ROAD, ground)
		for direction: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			if not roads.has_road(node, node + direction):
				continue
			var next: Vector2 = roads.node_position(node + direction)
			var width: float = roads.road_width(node, direction)
			var along: Vector2 = Vector2(direction)
			var length: float = center.distance_to(next)
			strip((center + next) / 2.0, along, length, width, ROAD, ground)
			var start: float = roads.half_box(node, direction) + 34.0
			var stop: float = length - roads.half_box(node + direction, direction) - 34.0
			if width > 200.0:
				for side: float in [-5.0, 5.0]:
					var middle: Vector2 = center + along * (start + stop) / 2.0 + roads.right_of(direction) * side
					strip(middle, along, stop - start, 2.0, LINE, ground)
			else:
				var distance: float = start + DASH / 2.0
				while distance < stop - DASH / 2.0:
					strip(center + along * distance, along, DASH, 2.0, LINE, ground)
					distance += DASH * 2.0
		if roads.signalized(node):
			for direction: Vector2i in RoadMap.DIRECTIONS:
				if roads.has_road(node, node + direction):
					build_arm(node, direction)


func build_arm(node: Vector2i, direction: Vector2i) -> void:
	var along: Vector2 = Vector2(direction)
	var across: Vector2 = roads.right_of(direction)
	var width: float = roads.road_width(node, direction)
	var center: Vector2 = roads.node_position(node)
	var box: float = roads.half_box(node, direction)
	for stripe: int in int(width / 16.0):
		var middle: Vector2 = center + along * (box + 16.0) + across * (-width / 2.0 + 8.0 + stripe * 16.0)
		strip(middle, along, 22.0, 4.0, LINE, ground)
	var bar_center: Vector2 = center + along * (box + 34.0) - across * width / 4.0
	lights.add_bar(strip(bar_center, along, 6.0, width / 2.0 - 8.0, STOP, null), 0 if direction.x != 0 else 1)


func build_block(index: int) -> void:
	var area: Rect2 = roads.block_rect(index)
	rect(area, PAVEMENT, ground)
	var lot: Rect2 = area.grow(-RoadMap.SIDEWALK)
	match roads.block_kind(index):
		"P":
			rect(lot, PARK, ground)
			var center: Vector2 = lot.get_center()
			strip(center, Vector2.RIGHT, lot.size.x, 22.0, ROAD, ground)
			strip(center, Vector2.DOWN, lot.size.y, 22.0, ROAD, ground)
			for count: int in 12:
				var spot: Vector2 = random_point(lot.grow(-30.0))
				if absf(spot.x - center.x) > 40.0 and absf(spot.y - center.y) > 40.0:
					tree(spot)
		"S":
			rect(lot, ROAD, ground)
			var center: Vector2 = lot.get_center()
			var fountain: StaticBody2D = StaticBody2D.new()
			fountain.position = center
			var shape: CollisionShape2D = CollisionShape2D.new()
			var circle_shape: CircleShape2D = CircleShape2D.new()
			circle_shape.radius = 62.0
			shape.shape = circle_shape
			fountain.add_child(shape)
			fountain.add_child(polygon(circle(66.0, 24), BUILDING))
			fountain.add_child(polygon(circle(56.0, 24), WATER))
			world.add_child(fountain)
			var corners: Array[Vector2] = [lot.position, lot.end, Vector2(lot.end.x, lot.position.y)]
			corners.append(Vector2(lot.position.x, lot.end.y))
			for corner: Vector2 in corners:
				tree(corner + (center - corner).normalized() * 60.0)
		"L":
			rect(lot, ROAD, ground)
			if index == RoadMap.GARAGE_BLOCK:
				garage = Rect2(lot.get_center() - Vector2(70.0, 40.0), Vector2(140.0, 80.0))
				for side: Vector2 in [Vector2.UP, Vector2.DOWN]:
					strip(garage.get_center() + side * 40.0, Vector2.RIGHT, 140.0, 4.0, STOP, ground)
				for side: Vector2 in [Vector2.LEFT, Vector2.RIGHT]:
					strip(garage.get_center() + side * 70.0, Vector2.DOWN, 80.0, 4.0, STOP, ground)
			var slots: int = int(lot.size.x / 56.0)
			for slot: int in slots:
				var x: float = lot.position.x + 28.0 + slot * 56.0
				for row: int in 2:
					var y: float = lot.position.y + 40.0 if row == 0 else lot.end.y - 40.0
					strip(Vector2(x - 28.0, y), Vector2.DOWN, 52.0, 2.0, LINE, ground)
					parking.append(Transform2D(PI / 2.0 if row == 0 else -PI / 2.0, Vector2(x, y)))
		_:
			current_lot = lot
			fill_buildings(lot)


func fill_buildings(lot: Rect2) -> void:
	var horizontal: bool = lot.size.x >= lot.size.y
	var depth: float = lot.size.y if horizontal else lot.size.x
	if depth < 220.0:
		chop(lot, horizontal)
		return
	var gap: float = ALLEY if random.randf() < 0.4 else 0.0
	var first: float = (depth - gap) * random.randf_range(0.4, 0.6)
	if horizontal:
		chop(Rect2(lot.position, Vector2(lot.size.x, first)), true)
		chop(Rect2(lot.position.x, lot.position.y + first + gap, lot.size.x, depth - first - gap), true)
	else:
		chop(Rect2(lot.position, Vector2(first, lot.size.y)), false)
		chop(Rect2(lot.position.x + first + gap, lot.position.y, depth - first - gap, lot.size.y), false)


func chop(strip_area: Rect2, horizontal: bool) -> void:
	var start: float = strip_area.position.x if horizontal else strip_area.position.y
	var finish: float = strip_area.end.x if horizontal else strip_area.end.y
	var cursor: float = start
	while cursor < finish - 1.0:
		var length: float = random.randf_range(90.0, 220.0)
		if finish - (cursor + length) < 90.0:
			length = finish - cursor
		var part: Rect2 = Rect2(cursor, strip_area.position.y, length, strip_area.size.y)
		if not horizontal:
			part = Rect2(strip_area.position.x, cursor, strip_area.size.x, length)
		building(part)
		cursor += length
		if random.randf() < 0.12 and finish - cursor > 200.0:
			cursor += ALLEY


func building(area: Rect2) -> void:
	var big: bool = area.size.x >= 110.0 and area.size.y >= 100.0
	if big and roof_layer != null and random.randf() < 0.35:
		interior(area)
		return
	var body: StaticBody2D = solid(area, BUILDING)
	body.get_child(1).scale = (area.size - Vector2(3.0, 3.0)) / area.size


func build_overhead() -> void:
	var rail_y: float = roads.line_y[2] + RoadMap.ROW_ROADS[2] / 2.0 + RoadMap.CELL_HEIGHTS[2] * 0.5
	var rail_x: float = roads.line_x[4] + RoadMap.COLUMN_ROADS[4] / 2.0 + RoadMap.CELL_WIDTHS[4] * 0.5
	railway(Vector2(roads.size.x / 2.0, rail_y), Vector2.RIGHT, roads.size.x)
	railway(Vector2(rail_x, roads.size.y / 2.0), Vector2.DOWN, roads.size.y)
	for bridge: Vector4i in BRIDGES:
		var a: Vector2 = roads.node_position(Vector2i(bridge.x, bridge.y))
		var b: Vector2 = roads.node_position(Vector2i(bridge.z, bridge.w))
		var along: Vector2 = (b - a).normalized()
		var across: Vector2 = along.orthogonal()
		var width: float = roads.road_width(Vector2i(bridge.x, bridge.y), Vector2i(along)) + RoadMap.SIDEWALK * 2.0
		var middle: Vector2 = (a + b) / 2.0
		strip(middle, across, width, 34.0, PAVEMENT, overhead)
		for side: float in [-17.0, 17.0]:
			strip(middle + along * side, across, width, 3.0, LINE, overhead)
		var half: Vector2 = (across * width + along * 34.0).abs() / 2.0
		covers.append(Rect2(middle - half, half * 2.0))


func railway(middle: Vector2, along: Vector2, length: float) -> void:
	var across: Vector2 = along.orthogonal()
	strip(middle, along, length, 48.0, BUILDING, overhead)
	for side: float in [-14.0, 14.0]:
		strip(middle + across * side, along, length, 3.0, LINE, overhead)
	var distance: float = -length / 2.0
	while distance < length / 2.0:
		strip(middle + along * distance, across, 40.0, 4.0, LINE, overhead)
		distance += 26.0
	var half: Vector2 = (along * length + across * 48.0).abs() / 2.0
	covers.append(Rect2(middle - half, half * 2.0))


func interior(area: Rect2) -> void:
	var sides: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var walls: Array[Rect2] = [
		Rect2(area.position, Vector2(area.size.x, WALL)),
		Rect2(area.position.x, area.end.y - WALL, area.size.x, WALL),
		Rect2(area.position, Vector2(WALL, area.size.y)),
		Rect2(area.end.x - WALL, area.position.y, WALL, area.size.y),
	]
	var touching: Array[bool] = [
		is_equal_approx(area.position.y, current_lot.position.y),
		is_equal_approx(area.end.y, current_lot.end.y),
		is_equal_approx(area.position.x, current_lot.position.x),
		is_equal_approx(area.end.x, current_lot.end.x),
	]
	var door: int = maxi(touching.find(true), 0)
	rect(area, FLOOR, ground)
	for index: int in 4:
		var wall: Rect2 = walls[index]
		if index != door:
			solid(wall, BUILDING)
		elif index < 2:
			var piece: float = (wall.size.x - DOORWAY) / 2.0
			solid(Rect2(wall.position, Vector2(piece, WALL)), BUILDING)
			solid(Rect2(wall.end.x - piece, wall.position.y, piece, WALL), BUILDING)
		else:
			var piece: float = (wall.size.y - DOORWAY) / 2.0
			solid(Rect2(wall.position, Vector2(WALL, piece)), BUILDING)
			solid(Rect2(wall.position.x, wall.end.y - piece, WALL, piece), BUILDING)
	var doorstop: StaticBody2D = solid(walls[door], BUILDING)
	doorstop.collision_layer = 16
	doorstop.get_child(1).visible = false
	var outside: Vector2 = sides[door]
	var mark: Vector2 = walls[door].get_center() + outside * (WALL / 2.0 + 3.0)
	strip(mark, outside.orthogonal(), DOORWAY + 6.0, 5.0, DOOR, ground)
	furnish(area.grow(-WALL - 8.0), outside)
	rect(area, BUILDING, roof_layer)
	roofs.append(roof_layer.get_child(-1) as Polygon2D)
	rooms.append(area)


func furnish(room: Rect2, outside: Vector2) -> void:
	var center: Vector2 = room.get_center()
	solid(Rect2(center - Vector2(22.0, 14.0), Vector2(44.0, 28.0)), FURNITURE)
	for offset: Vector2 in [Vector2(-32.0, 0.0), Vector2(32.0, 0.0), Vector2(0.0, -24.0), Vector2(0.0, 24.0)]:
		rect(Rect2(center + offset - Vector2(6.0, 6.0), Vector2(12.0, 12.0)), FURNITURE, ground)
	var corners: Array[Vector2] = [room.position, Vector2(room.end.x, room.position.y), room.end]
	corners.append(Vector2(room.position.x, room.end.y))
	for corner: Vector2 in corners:
		if (corner - center).normalized().dot(outside) < 0.0:
			var plant: Polygon2D = polygon(circle(8.0, 12), FURNITURE)
			plant.position = corner + (center - corner).normalized() * 10.0
			ground.add_child(plant)
	var across: Vector2 = outside.orthogonal().abs()
	var back: Vector2 = center - outside * ((room.size * outside.abs()).length() / 2.0 - 10.0)
	var sofa: Vector2 = across * minf((room.size * across).length() * 0.5, 70.0) + outside.abs() * 18.0
	solid(Rect2(back - sofa / 2.0, sofa), FURNITURE)


func build_outskirts() -> void:
	var city: Rect2 = roads.city_rect().grow(60.0)
	var planted: int = 0
	while planted < 80:
		var spot: Vector2 = random_point(Rect2(Vector2(40.0, 40.0), roads.size - Vector2(80.0, 80.0)))
		if not city.has_point(spot):
			tree(spot)
			planted += 1


func build_border() -> void:
	var size: Vector2 = roads.size
	solid(Rect2(-64.0, -64.0, size.x + 128.0, 64.0), BUILDING)
	solid(Rect2(-64.0, size.y, size.x + 128.0, 64.0), BUILDING)
	solid(Rect2(-64.0, 0.0, 64.0, size.y), BUILDING)
	solid(Rect2(size.x, 0.0, 64.0, size.y), BUILDING)


func tree(spot: Vector2) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = spot
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle_shape: CircleShape2D = CircleShape2D.new()
	circle_shape.radius = 16.0
	shape.shape = circle_shape
	body.add_child(shape)
	body.add_child(polygon(circle(18.0, 12), TREE))
	world.add_child(body)


func circle(radius: float, steps: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for step: int in steps:
		points.append(Vector2.from_angle(step * TAU / steps) * radius)
	return points


func polygon(points: PackedVector2Array, color: Color) -> Polygon2D:
	var shape: Polygon2D = Polygon2D.new()
	shape.color = color
	shape.polygon = points
	return shape


func rect(area: Rect2, color: Color, parent: Node) -> void:
	var corners: Array[Vector2] = [area.position, Vector2(area.end.x, area.position.y), area.end]
	corners.append(Vector2(area.position.x, area.end.y))
	parent.add_child(polygon(PackedVector2Array(corners), color))


func strip(middle: Vector2, along: Vector2, length: float, width: float, color: Color, parent: Node) -> Polygon2D:
	var a: Vector2 = along * length / 2.0
	var b: Vector2 = Vector2(-along.y, along.x) * width / 2.0
	var corners: Array[Vector2] = [middle - a - b, middle + a - b, middle + a + b, middle - a + b]
	var shape: Polygon2D = polygon(PackedVector2Array(corners), color)
	if parent != null:
		parent.add_child(shape)
	return shape


func solid(area: Rect2, color: Color) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = area.get_center()
	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = area.size
	shape.shape = box
	body.add_child(shape)
	rect(Rect2(-area.size / 2.0, area.size), color, body)
	world.add_child(body)
	return body


func random_point(area: Rect2) -> Vector2:
	return area.position + Vector2(random.randf(), random.randf()) * area.size
