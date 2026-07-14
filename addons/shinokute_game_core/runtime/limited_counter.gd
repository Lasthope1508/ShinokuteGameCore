class_name ShinokuteLimitedCounter
extends RefCounted

var _limits: Dictionary = {}
var _counts: Dictionary = {}
var _id_key := "id"
var _limit_key := "max_quantity"

func configure(limit_entries: Array, counts: Dictionary = {}, id_key: String = "id", limit_key: String = "max_quantity") -> void:
	_limits = {}
	_counts = {}
	_id_key = id_key
	_limit_key = limit_key
	for item in limit_entries:
		if not (item is Dictionary):
			continue
		var entry := Dictionary(item)
		var id := String(entry.get(_id_key, "")).strip_edges()
		if id.is_empty():
			continue
		_limits[id] = int(max(0, int(entry.get(_limit_key, 0))))
	for id in counts.keys():
		var key := String(id).strip_edges()
		if key.is_empty():
			continue
		_counts[key] = int(max(0, int(counts[id])))

func can_consume(id: String, amount: int = 1) -> bool:
	var key := id.strip_edges()
	var next_count := count_for_id(key) + int(max(1, amount))
	var limit := limit_for_id(key)
	return limit <= 0 or next_count <= limit

func consume(id: String, amount: int = 1) -> bool:
	var key := id.strip_edges()
	if key.is_empty() or not can_consume(key, amount):
		return false
	_counts[key] = count_for_id(key) + int(max(1, amount))
	return true

func count_for_id(id: String) -> int:
	return int(_counts.get(id.strip_edges(), 0))

func limit_for_id(id: String) -> int:
	return int(_limits.get(id.strip_edges(), 0))

func counts() -> Dictionary:
	return _counts.duplicate(true)

func limits() -> Dictionary:
	return _limits.duplicate(true)

func filter_entries(entries: Array, id_key: String = "") -> Array:
	var key := id_key if not id_key.is_empty() else _id_key
	var filtered: Array = []
	for item in entries:
		if not (item is Dictionary):
			continue
		var entry := Dictionary(item).duplicate(true)
		if can_consume(String(entry.get(key, ""))):
			filtered.append(entry)
	return filtered
