class_name ShinokuteSpatialHash2D
extends RefCounted

var _cell_size := 64.0
var _entries: Dictionary = {}
var _cells: Dictionary = {}

func configure(cell_size: float = 64.0) -> void:
	_cell_size = max(1.0, cell_size)
	clear()

func clear() -> void:
	_entries.clear()
	_cells.clear()

func upsert(id: String, position: Vector2, radius: float = 0.0, payload: Dictionary = {}) -> void:
	if id.is_empty():
		return
	remove(id)
	var entry := {
		"id": id,
		"position": position,
		"radius": max(0.0, radius),
		"payload": payload.duplicate(true)
	}
	_entries[id] = entry
	for cell in _cells_for(position, radius):
		var key := _cell_key(cell)
		if not _cells.has(key):
			_cells[key] = []
		Array(_cells[key]).append(id)

func remove(id: String) -> void:
	if not _entries.has(id):
		return
	var entry := Dictionary(_entries[id])
	for cell in _cells_for(Vector2(entry.get("position", Vector2.ZERO)), float(entry.get("radius", 0.0))):
		var key := _cell_key(cell)
		if not _cells.has(key):
			continue
		var ids := Array(_cells[key])
		ids.erase(id)
		if ids.is_empty():
			_cells.erase(key)
		else:
			_cells[key] = ids
	_entries.erase(id)

func query_radius(center: Vector2, radius: float) -> Array:
	var result: Array = []
	var seen := {}
	for cell in _cells_for(center, radius):
		var key := _cell_key(cell)
		for id in Array(_cells.get(key, [])):
			var entry_id := String(id)
			if seen.has(entry_id) or not _entries.has(entry_id):
				continue
			seen[entry_id] = true
			var entry := Dictionary(_entries[entry_id])
			var entry_position: Vector2 = entry.get("position", Vector2.ZERO)
			var entry_radius := float(entry.get("radius", 0.0))
			if entry_position.distance_to(center) <= radius + entry_radius:
				result.append(entry.duplicate(true))
	return result

func entry_count() -> int:
	return _entries.size()

func _cells_for(position: Vector2, radius: float) -> Array:
	var safe_radius := max(0.0, radius)
	var min_cell := _cell_for(position - Vector2.ONE * safe_radius)
	var max_cell := _cell_for(position + Vector2.ONE * safe_radius)
	var cells: Array = []
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			cells.append(Vector2i(x, y))
	return cells

func _cell_for(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / _cell_size), floori(position.y / _cell_size))

func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
