class_name ShinokuteGridPathQuery2D
extends RefCounted

const ORTHOGONAL_DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const DIAGONAL_DIRECTIONS := [
	Vector2i(-1, -1),
	Vector2i(1, -1),
	Vector2i(1, 1),
	Vector2i(-1, 1)
]

func neighbors(cell: Vector2i, config: Dictionary = {}) -> Array:
	var result: Array = []
	var directions := ORTHOGONAL_DIRECTIONS.duplicate()
	if bool(config.get("allow_diagonal", false)):
		directions.append_array(DIAGONAL_DIRECTIONS)
	for direction in directions:
		var next: Vector2i = cell + direction
		if is_passable(next, config):
			result.append(next)
	return result

func shortest_path(start: Vector2i, target: Vector2i, config: Dictionary = {}) -> Array:
	if not is_in_bounds(start, config) or not is_in_bounds(target, config):
		return []
	if not is_passable(start, config) or not is_passable(target, config):
		return []
	var queue: Array = [start]
	var visited := {start: true}
	var previous := {}
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == target:
			return _reconstruct_path(start, target, previous)
		for next in neighbors(current, config):
			if visited.has(next):
				continue
			visited[next] = true
			previous[next] = current
			queue.append(next)
	return []

func distance_field(start: Vector2i, config: Dictionary = {}, max_distance: int = -1) -> Dictionary:
	if not is_passable(start, config):
		return {}
	var distances := {start: 0}
	var queue: Array = [start]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var current_distance := int(distances[current])
		if max_distance >= 0 and current_distance >= max_distance:
			continue
		for next in neighbors(current, config):
			if distances.has(next):
				continue
			distances[next] = current_distance + 1
			queue.append(next)
	return distances

func ray_cells(start: Vector2i, target: Vector2i, _config: Dictionary = {}) -> Array:
	var result: Array = []
	var x0 := start.x
	var y0 := start.y
	var x1 := target.x
	var y1 := target.y
	var dx: int = abs(x1 - x0)
	var sx := 1 if x0 < x1 else -1
	var dy: int = -abs(y1 - y0)
	var sy := 1 if y0 < y1 else -1
	var err: int = dx + dy
	while true:
		result.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy
	return result

func line_hits_blocked(start: Vector2i, target: Vector2i, config: Dictionary = {}) -> Dictionary:
	for cell in ray_cells(start, target, config):
		if is_blocked(cell, config):
			return {"blocked": true, "cell": cell}
	return {"blocked": false, "cell": target}

func is_in_bounds(cell: Vector2i, config: Dictionary = {}) -> bool:
	var width := int(config.get("width", 0))
	var height := int(config.get("height", 0))
	if width <= 0 or height <= 0:
		return true
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height

func is_blocked(cell: Vector2i, config: Dictionary = {}) -> bool:
	var blocked = config.get("blocked", [])
	if blocked is Dictionary:
		return Dictionary(blocked).has(cell) or bool(Dictionary(blocked).get(cell, false))
	return Array(blocked).has(cell)

func is_passable(cell: Vector2i, config: Dictionary = {}) -> bool:
	if not is_in_bounds(cell, config):
		return false
	return not is_blocked(cell, config)

func _reconstruct_path(start: Vector2i, target: Vector2i, previous: Dictionary) -> Array:
	var path: Array = [target]
	var cursor := target
	while cursor != start:
		if not previous.has(cursor):
			return []
		cursor = previous[cursor]
		path.push_front(cursor)
	return path
