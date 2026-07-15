class_name ShinokuteVisibilityField2D
extends RefCounted

const ORTHOGONAL_DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const DIAGONAL_DIRECTIONS := [
	Vector2i(-1, -1),
	Vector2i(1, -1),
	Vector2i(1, 1),
	Vector2i(-1, 1)
]

func compute_visible(origin: Vector2i, config: Dictionary = {}) -> Dictionary:
	var visible := {}
	var width := int(config.get("width", 0))
	var height := int(config.get("height", 0))
	var radius := int(config.get("radius", -1))
	var include_diagonal := bool(config.get("allow_diagonal", true))
	for y in range(height if height > 0 else 1):
		for x in range(width if width > 0 else 1):
			var cell := Vector2i(x, y)
			if radius >= 0 and origin.distance_to(cell) > float(radius):
				continue
			if _line_reaches(origin, cell, config, include_diagonal):
				visible[cell] = true
	return visible

func update_seen(previous_seen, visible: Dictionary) -> Dictionary:
	var seen := {}
	if previous_seen is Dictionary:
		for key in Dictionary(previous_seen).keys():
			if bool(Dictionary(previous_seen).get(key, false)):
				seen[key] = true
	elif previous_seen is Array:
		for cell in Array(previous_seen):
			seen[cell] = true
	for cell in visible.keys():
		if bool(visible.get(cell, false)):
			seen[cell] = true
	return seen

func query_cell(cell: Vector2i, visible: Dictionary, seen) -> Dictionary:
	var was_seen := false
	if seen is Dictionary:
		was_seen = bool(Dictionary(seen).get(cell, false))
	elif seen is Array:
		was_seen = Array(seen).has(cell)
	var is_visible := bool(Dictionary(visible).get(cell, false))
	var state := "hidden"
	if is_visible:
		state = "visible"
	elif was_seen:
		state = "seen"
	return {
		"cell": cell,
		"visible": is_visible,
		"seen": was_seen,
		"state": state
	}

func ray_cells(start: Vector2i, target: Vector2i) -> Array:
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

func visible_ring(origin: Vector2i, radius: int, config: Dictionary = {}) -> Dictionary:
	var ring := {}
	var shape_radius := max(0, radius)
	for y in range(origin.y - shape_radius, origin.y + shape_radius + 1):
		for x in range(origin.x - shape_radius, origin.x + shape_radius + 1):
			var cell := Vector2i(x, y)
			if int(origin.distance_to(cell)) != shape_radius:
				continue
			if _line_reaches(origin, cell, config, bool(config.get("allow_diagonal", true))):
				ring[cell] = true
	return ring

func _line_reaches(origin: Vector2i, target: Vector2i, config: Dictionary, include_diagonal: bool) -> bool:
	var ray := ray_cells(origin, target)
	for index in range(ray.size()):
		var cell: Vector2i = ray[index]
		if index == 0:
			continue
		if cell == target:
			return true
		if is_opaque(cell, config):
			return false
		if not include_diagonal and _is_diagonal_step(ray[index - 1], cell):
			return false
	return true

func _is_diagonal_step(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	return abs(from_cell.x - to_cell.x) == 1 and abs(from_cell.y - to_cell.y) == 1

func is_opaque(cell: Vector2i, config: Dictionary = {}) -> bool:
	var opaque = config.get("opaque", [])
	if opaque is Dictionary:
		return bool(Dictionary(opaque).get(cell, false))
	return Array(opaque).has(cell)
