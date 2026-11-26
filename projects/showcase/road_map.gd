class_name RoadMap
extends RefCounted

const OUTSKIRTS: float = 480.0
const SIDEWALK: float = 28.0
const STOP_GAP: float = 64.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
const BLOCKS: Array[Rect2i] = [
	Rect2i(0, 0, 3, 1),
	Rect2i(3, 0, 1, 2),
	Rect2i(4, 0, 2, 1),
	Rect2i(0, 1, 1, 2),
	Rect2i(1, 1, 2, 1),
	Rect2i(4, 1, 1, 1),
	Rect2i(5, 1, 1, 3),
	Rect2i(1, 2, 1, 1),
	Rect2i(2, 2, 2, 1),
	Rect2i(4, 2, 1, 2),
	Rect2i(0, 3, 2, 1),
	Rect2i(2, 3, 1, 2),
	Rect2i(3, 3, 1, 1),
	Rect2i(0, 4, 2, 1),
	Rect2i(3, 4, 3, 1),
]
const KINDS: String = "BBPBBSBLBBBPLBB"
const GARAGE_BLOCK: int = 12
const START_BLOCK: int = 7
const CELL_WIDTHS: Array[float] = [420.0, 360.0, 520.0, 300.0, 440.0, 380.0]
const CELL_HEIGHTS: Array[float] = [360.0, 300.0, 420.0, 320.0, 380.0]
const COLUMN_ROADS: Array[float] = [160.0, 140.0, 140.0, 240.0, 140.0, 160.0, 160.0]
const ROW_ROADS: Array[float] = [160.0, 140.0, 240.0, 140.0, 140.0, 160.0]

var line_x: Array[float] = []
var line_y: Array[float] = []
var removed: Dictionary[Vector4i, bool] = {}
var size: Vector2 = Vector2.ZERO


func _init() -> void:
	var x: float = OUTSKIRTS
	for index: int in COLUMN_ROADS.size():
		line_x.append(x + COLUMN_ROADS[index] / 2.0)
		x += COLUMN_ROADS[index] + (CELL_WIDTHS[index] if index < CELL_WIDTHS.size() else 0.0)
	var y: float = OUTSKIRTS
	for index: int in ROW_ROADS.size():
		line_y.append(y + ROW_ROADS[index] / 2.0)
		y += ROW_ROADS[index] + (CELL_HEIGHTS[index] if index < CELL_HEIGHTS.size() else 0.0)
	size = Vector2(x + OUTSKIRTS, y + OUTSKIRTS)
	for block: Rect2i in BLOCKS:
		for column: int in range(block.position.x + 1, block.end.x):
			for row: int in range(block.position.y, block.end.y):
				removed[_key(Vector2i(column, row), Vector2i(column, row + 1))] = true
		for row: int in range(block.position.y + 1, block.end.y):
			for column: int in range(block.position.x, block.end.x):
				removed[_key(Vector2i(column, row), Vector2i(column + 1, row))] = true


func _key(a: Vector2i, b: Vector2i) -> Vector4i:
	if b.x < a.x or b.y < a.y:
		return Vector4i(b.x, b.y, a.x, a.y)
	return Vector4i(a.x, a.y, b.x, b.y)


func _in_grid(node: Vector2i) -> bool:
	return node.x >= 0 and node.y >= 0 and node.x < line_x.size() and node.y < line_y.size()


func has_road(a: Vector2i, b: Vector2i) -> bool:
	return _in_grid(a) and _in_grid(b) and not removed.has(_key(a, b))


func _degree(node: Vector2i) -> int:
	var count: int = 0
	for direction: Vector2i in DIRECTIONS:
		if has_road(node, node + direction):
			count += 1
	return count


func signalized(node: Vector2i) -> bool:
	return _degree(node) >= 3


func nodes() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for column: int in line_x.size():
		for row: int in line_y.size():
			if _degree(Vector2i(column, row)) > 0:
				result.append(Vector2i(column, row))
	return result


func node_position(node: Vector2i) -> Vector2:
	return Vector2(line_x[node.x], line_y[node.y])


func road_width(node: Vector2i, direction: Vector2i) -> float:
	return ROW_ROADS[node.y] if direction.x != 0 else COLUMN_ROADS[node.x]


func half_box(node: Vector2i, direction: Vector2i) -> float:
	return COLUMN_ROADS[node.x] / 2.0 if direction.x != 0 else ROW_ROADS[node.y] / 2.0


func right_of(direction: Vector2i) -> Vector2:
	return Vector2(-direction.y, direction.x)


func lane_start(node: Vector2i, direction: Vector2i) -> Vector2:
	var along: Vector2 = Vector2(direction) * half_box(node, direction)
	return node_position(node) + along + right_of(direction) * road_width(node, direction) / 4.0


func lane_end(node: Vector2i, direction: Vector2i) -> Vector2:
	var along: Vector2 = Vector2(direction) * (half_box(node, direction) + STOP_GAP)
	return node_position(node) - along + right_of(direction) * road_width(node, direction) / 4.0


func exits(node: Vector2i, arriving: Vector2i) -> Array[Vector2i]:
	var left: Vector2i = Vector2i(arriving.y, -arriving.x)
	var options: Array[Vector2i] = []
	for direction: Vector2i in DIRECTIONS:
		if direction != -arriving and direction != left and has_road(node, node + direction):
			options.append(direction)
	if options.is_empty() and has_road(node, node + left):
		options.append(left)
	if options.is_empty():
		options.append(-arriving)
	return options


func snap(point: Vector2, facing: Vector2) -> Vector4i:
	var best: Vector4i = Vector4i.ZERO
	var best_distance: float = INF
	for node: Vector2i in nodes():
		for direction: Vector2i in DIRECTIONS:
			if not has_road(node, node + direction):
				continue
			var start: Vector2 = lane_start(node, direction)
			var finish: Vector2 = lane_end(node + direction, direction)
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(point, start, finish)
			var distance: float = point.distance_to(closest) + (1.0 - facing.dot(Vector2(direction))) * 40.0
			if distance < best_distance:
				best_distance = distance
				best = Vector4i(node.x, node.y, direction.x, direction.y)
	return best


func block_rect(index: int) -> Rect2:
	var cells: Rect2i = BLOCKS[index]
	var left: float = line_x[cells.position.x] + COLUMN_ROADS[cells.position.x] / 2.0
	var top: float = line_y[cells.position.y] + ROW_ROADS[cells.position.y] / 2.0
	var right: float = line_x[cells.end.x] - COLUMN_ROADS[cells.end.x] / 2.0
	var bottom: float = line_y[cells.end.y] - ROW_ROADS[cells.end.y] / 2.0
	return Rect2(left, top, right - left, bottom - top)


func block_kind(index: int) -> String:
	return KINDS[index]


func _block_at(point: Vector2) -> int:
	for index: int in BLOCKS.size():
		if block_rect(index).has_point(point):
			return index
	return -1


func city_rect() -> Rect2:
	var left: float = line_x[0] - COLUMN_ROADS[0] / 2.0
	var top: float = line_y[0] - ROW_ROADS[0] / 2.0
	var right: float = line_x[-1] + COLUMN_ROADS[-1] / 2.0
	var bottom: float = line_y[-1] + ROW_ROADS[-1] / 2.0
	return Rect2(left, top, right - left, bottom - top)


func _ring(index: int) -> Rect2:
	return block_rect(index).grow(-SIDEWALK / 2.0)


func corner_position(index: int, corner: int) -> Vector2:
	var rect: Rect2 = _ring(index)
	match corner:
		0:
			return rect.position
		1:
			return Vector2(rect.end.x, rect.position.y)
		2:
			return rect.end
	return Vector2(rect.position.x, rect.end.y)


func corner_node(index: int, corner: int) -> Vector2i:
	var cells: Rect2i = BLOCKS[index]
	match corner:
		0:
			return cells.position
		1:
			return Vector2i(cells.end.x, cells.position.y)
		2:
			return cells.end
	return Vector2i(cells.position.x, cells.end.y)


func side_corners(index: int, point: Vector2) -> Array[int]:
	var rect: Rect2 = _ring(index)
	var distances: Array[float] = [
		absf(point.y - rect.position.y),
		absf(point.x - rect.end.x),
		absf(point.y - rect.end.y),
		absf(point.x - rect.position.x),
	]
	var side: int = distances.find(distances.min())
	return [side, (side + 1) % 4]


func crossing(index: int, corner: int, vertical: bool) -> Vector3:
	var start: Vector2 = corner_position(index, corner)
	var node: Vector2i = corner_node(index, corner)
	var step: Vector2 = Vector2.ZERO
	var distance: float = SIDEWALK
	if vertical:
		step = Vector2(0.0, -1.0 if corner < 2 else 1.0)
		distance += ROW_ROADS[node.y]
	else:
		step = Vector2(-1.0 if corner == 0 or corner == 3 else 1.0, 0.0)
		distance += COLUMN_ROADS[node.x]
	var target: Vector2 = start + step * distance
	return Vector3(target.x, target.y, _block_at(target))


func nearest_corner(point: Vector2) -> Vector2i:
	var best: Vector2i = Vector2i.ZERO
	var best_distance: float = INF
	for index: int in BLOCKS.size():
		for corner: int in 4:
			var distance: float = point.distance_squared_to(corner_position(index, corner))
			if distance < best_distance:
				best_distance = distance
				best = Vector2i(index, corner)
	return best
