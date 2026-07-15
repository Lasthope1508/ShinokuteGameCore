class_name ShinokuteTurnEnergyScheduler
extends RefCounted

var _entries: Dictionary = {}
var _order: Dictionary = {}
var _ready_threshold := 100.0
var _turn_index := 0
var _id_key := "id"
var _speed_key := "speed"
var _energy_key := "energy"
var _priority_key := "priority"

func configure(entries: Array, config: Dictionary = {}) -> void:
	_entries = {}
	_order = {}
	_ready_threshold = float(max(0.0001, float(config.get("ready_threshold", 100.0))))
	_turn_index = int(max(0, int(config.get("turn_index", 0))))
	_id_key = String(config.get("id_key", "id"))
	_speed_key = String(config.get("speed_key", "speed"))
	_energy_key = String(config.get("energy_key", "energy"))
	_priority_key = String(config.get("priority_key", "priority"))
	var index := 0
	for item in entries:
		if not (item is Dictionary):
			continue
		var raw := Dictionary(item)
		var actor_id := String(raw.get(_id_key, "")).strip_edges()
		if actor_id.is_empty() or _entries.has(actor_id):
			continue
		_entries[actor_id] = {
			"id": actor_id,
			"speed": float(max(0.0, float(raw.get(_speed_key, _ready_threshold)))),
			"energy": float(raw.get(_energy_key, 0.0)),
			"priority": int(raw.get(_priority_key, 0)),
			"data": raw.duplicate(true)
		}
		_order[actor_id] = index
		index += 1

func actor_ids() -> Array:
	return _entries.keys()

func advance(delta_turns: float = 1.0) -> Array:
	var delta := max(0.0, delta_turns)
	for actor_id in _entries.keys():
		var entry := Dictionary(_entries[actor_id])
		entry["energy"] = float(entry.get("energy", 0.0)) + float(entry.get("speed", 0.0)) * delta
		_entries[actor_id] = entry
	_turn_index += 1
	return ready_actors()

func ready_actors() -> Array:
	var ready: Array = []
	for actor_id in _entries.keys():
		var entry := Dictionary(_entries[actor_id])
		if float(entry.get("energy", 0.0)) >= _ready_threshold:
			ready.append(_public_entry(entry))
	ready.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _ready_sort_before(a, b)
	)
	return ready

func spend(actor_id: String, amount: float = -1.0) -> bool:
	var key := actor_id.strip_edges()
	if not _entries.has(key):
		return false
	var cost := _ready_threshold if amount < 0.0 else max(0.0, amount)
	var entry := Dictionary(_entries[key])
	entry["energy"] = max(0.0, float(entry.get("energy", 0.0)) - cost)
	_entries[key] = entry
	return true

func energy_for(actor_id: String) -> float:
	var key := actor_id.strip_edges()
	if not _entries.has(key):
		return 0.0
	return float(Dictionary(_entries[key]).get("energy", 0.0))

func speed_for(actor_id: String) -> float:
	var key := actor_id.strip_edges()
	if not _entries.has(key):
		return 0.0
	return float(Dictionary(_entries[key]).get("speed", 0.0))

func priority_for(actor_id: String) -> int:
	var key := actor_id.strip_edges()
	if not _entries.has(key):
		return 0
	return int(Dictionary(_entries[key]).get("priority", 0))

func snapshot() -> Dictionary:
	return {
		"entries": _entries.duplicate(true),
		"order": _order.duplicate(true),
		"ready_threshold": _ready_threshold,
		"turn_index": _turn_index
	}

func restore(snapshot_data: Dictionary) -> void:
	_entries = Dictionary(snapshot_data.get("entries", {})).duplicate(true)
	_order = Dictionary(snapshot_data.get("order", {})).duplicate(true)
	_ready_threshold = float(max(0.0001, float(snapshot_data.get("ready_threshold", 100.0))))
	_turn_index = int(max(0, int(snapshot_data.get("turn_index", 0))))

func turn_index() -> int:
	return _turn_index

func ready_threshold() -> float:
	return _ready_threshold

func _public_entry(entry: Dictionary) -> Dictionary:
	return {
		"id": String(entry.get("id", "")),
		"speed": float(entry.get("speed", 0.0)),
		"energy": float(entry.get("energy", 0.0)),
		"priority": int(entry.get("priority", 0)),
		"turn_index": _turn_index,
		"data": Dictionary(entry.get("data", {})).duplicate(true)
	}

func _ready_sort_before(a: Dictionary, b: Dictionary) -> bool:
	var a_energy := float(a.get("energy", 0.0))
	var b_energy := float(b.get("energy", 0.0))
	if not is_equal_approx(a_energy, b_energy):
		return a_energy > b_energy
	var a_priority := int(a.get("priority", 0))
	var b_priority := int(b.get("priority", 0))
	if a_priority != b_priority:
		return a_priority > b_priority
	return int(_order.get(String(a.get("id", "")), 0)) < int(_order.get(String(b.get("id", "")), 0))
