class_name ShinokuteGridOccupancy2D
extends RefCounted

var _entries: Dictionary = {}
var _cells: Dictionary = {}
var _blocked: Dictionary = {}
var _width := 0
var _height := 0

func configure(config: Dictionary = {}) -> void:
	_entries = {}
	_cells = {}
	_blocked = {}
	_width = int(config.get("width", 0))
	_height = int(config.get("height", 0))
	for cell in Array(config.get("blocked", [])):
		_blocked[Vector2i(cell)] = true

func place(entry: Dictionary) -> Dictionary:
	var normalized := _normalize_entry(entry)
	var id := String(normalized.get("id", ""))
	if id.is_empty():
		return {"status": "blocked", "reason": "missing_id"}
	var cell := Vector2i(normalized.get("cell", Vector2i.ZERO))
	if not _can_place_entry(normalized, id):
		return {"status": "blocked", "reason": "blocked_cell" if is_blocked(cell) else "occupied", "entry": normalized}
	if _entries.has(id):
		_unlink_entry(id)
	_entries[id] = normalized
	_link_entry(normalized)
	return {"status": "placed", "entry": normalized}

func move(id: String, cell: Vector2i) -> Dictionary:
	if not _entries.has(id):
		return {"status": "blocked", "reason": "missing_entry"}
	var current := Dictionary(_entries[id]).duplicate(true)
	var target := current.duplicate(true)
	target["cell"] = cell
	if not _can_place_entry(target, id):
		return {"status": "blocked", "reason": "blocked_cell" if is_blocked(cell) else "occupied", "entry": current}
	_unlink_entry(id)
	_entries[id] = target
	_link_entry(target)
	return {"status": "moved", "entry": target}

func remove(id: String) -> bool:
	if not _entries.has(id):
		return false
	_unlink_entry(id)
	_entries.erase(id)
	return true

func entry(id: String) -> Dictionary:
	if not _entries.has(id):
		return {}
	return Dictionary(_entries[id]).duplicate(true)

func entries_at(cell: Vector2i) -> Array:
	if not _cells.has(cell):
		return []
	return Array(_cells[cell]).duplicate(true)

func is_occupied(cell: Vector2i, config: Dictionary = {}) -> bool:
	if is_blocked(cell):
		return true
	var blocking_only := bool(config.get("blocking_only", false))
	if not _cells.has(cell):
		return false
	for entry in Array(_cells[cell]):
		var item := Dictionary(entry)
		if blocking_only and not bool(item.get("blocks", false)):
			continue
		return true
	return false

func is_blocked(cell: Vector2i) -> bool:
	if _blocked.has(cell):
		return true
	if _width > 0 and (cell.x < 0 or cell.x >= _width):
		return true
	if _height > 0 and (cell.y < 0 or cell.y >= _height):
		return true
	return false

func is_cell_available(cell: Vector2i, ignore_id: String = "") -> bool:
	if is_blocked(cell):
		return false
	if not _cells.has(cell):
		return true
	for entry in Array(_cells[cell]):
		var item := Dictionary(entry)
		if String(item.get("id", "")) == ignore_id:
			continue
		if bool(item.get("blocks", false)):
			return false
	return true

func _can_place_entry(entry: Dictionary, ignore_id: String = "") -> bool:
	var cell := Vector2i(entry.get("cell", Vector2i.ZERO))
	if is_blocked(cell):
		return false
	if not bool(entry.get("blocks", false)):
		return true
	return is_cell_available(cell, ignore_id)

func snapshot() -> Dictionary:
	return {
		"entries": _entries.duplicate(true),
		"blocked": _blocked.duplicate(true),
		"width": _width,
		"height": _height
	}

func restore(snapshot_data: Dictionary) -> void:
	_entries = Dictionary(snapshot_data.get("entries", {})).duplicate(true)
	_blocked = Dictionary(snapshot_data.get("blocked", {})).duplicate(true)
	_width = int(snapshot_data.get("width", 0))
	_height = int(snapshot_data.get("height", 0))
	_cells = {}
	for entry in _entries.values():
		_link_entry(Dictionary(entry))

func _normalize_entry(entry: Dictionary) -> Dictionary:
	var normalized := Dictionary(entry).duplicate(true)
	normalized["id"] = String(normalized.get("id", "")).strip_edges()
	normalized["cell"] = Vector2i(normalized.get("cell", Vector2i.ZERO))
	normalized["layer"] = String(normalized.get("layer", ""))
	normalized["blocks"] = bool(normalized.get("blocks", false))
	normalized["tags"] = Array(normalized.get("tags", [])).duplicate(true)
	return normalized

func _link_entry(entry: Dictionary) -> void:
	var cell := Vector2i(entry.get("cell", Vector2i.ZERO))
	if not _cells.has(cell):
		_cells[cell] = []
	_cells[cell].append(entry.duplicate(true))

func _unlink_entry(id: String) -> void:
	if not _entries.has(id):
		return
	var cell := Vector2i(Dictionary(_entries[id]).get("cell", Vector2i.ZERO))
	if _cells.has(cell):
		var filtered: Array = []
		for entry in Array(_cells[cell]):
			if String(Dictionary(entry).get("id", "")) == id:
				continue
			filtered.append(Dictionary(entry).duplicate(true))
		if filtered.is_empty():
			_cells.erase(cell)
		else:
			_cells[cell] = filtered
