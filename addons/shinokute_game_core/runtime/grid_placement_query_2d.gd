class_name ShinokuteGridPlacementQuery2D
extends RefCounted

const DEFAULT_DIRECTION_PRIORITY = [
	Vector2i.DOWN,
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.UP
]

func sorted_candidates(origin: Vector2i, config: Dictionary = {}) -> Array:
	var radius := maxi(0, int(config.get("radius", 0)))
	var occupancy = config.get("occupancy", null)
	var blocked = config.get("blocked", [])
	var direction_priority := Array(config.get("direction_priority", DEFAULT_DIRECTION_PRIORITY))
	var result: Array = []
	var seen := {}
	for distance in range(1, radius + 1):
		for offset in _shell_offsets(distance, direction_priority):
			var offset_vec := Vector2i(offset)
			var cell := origin + offset_vec
			if seen.has(cell):
				continue
			seen[cell] = true
			if not _in_bounds(cell, config):
				continue
			if _is_blocked(cell, blocked):
				continue
			if occupancy != null and occupancy.has_method("is_occupied") and bool(occupancy.is_occupied(cell, {"blocking_only": true})):
				continue
			result.append(cell)
	return result

func first_available(origin: Vector2i, config: Dictionary = {}) -> Dictionary:
	var candidates := sorted_candidates(origin, config)
	if candidates.is_empty():
		return {"status": "missing"}
	return {"status": "found", "cell": candidates[0]}

func _shell_offsets(distance: int, direction_priority: Array) -> Array:
	var result: Array = []
	for direction in direction_priority:
		var offset := Vector2i(direction) * distance
		if offset != Vector2i.ZERO and not result.has(offset):
			result.append(offset)
	for y in range(-distance, distance + 1):
		for x in range(-distance, distance + 1):
			var offset := Vector2i(x, y)
			if offset == Vector2i.ZERO:
				continue
			if max(abs(offset.x), abs(offset.y)) != distance:
				continue
			if not result.has(offset):
				result.append(offset)
	return result

func _in_bounds(cell: Vector2i, config: Dictionary) -> bool:
	var width := int(config.get("width", 0))
	var height := int(config.get("height", 0))
	if width <= 0 or height <= 0:
		return true
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height

func _is_blocked(cell: Vector2i, blocked) -> bool:
	if blocked is Dictionary:
		return bool(Dictionary(blocked).get(cell, false))
	return Array(blocked).has(cell)
