class_name ShinokuteRuntimeLedger
extends RefCounted

var _definitions: Dictionary = {}
var _values: Dictionary = {}
var _events: Array = []

func configure(definitions: Array, initial_values: Dictionary = {}) -> void:
	_definitions = {}
	_values = {}
	_events = []
	for item in definitions:
		if not (item is Dictionary):
			continue
		var entry := Dictionary(item).duplicate(true)
		var id := String(entry.get("id", ""))
		if id.is_empty():
			continue
		_definitions[id] = entry
		var default_value = entry.get("default", entry.get("min", 0))
		_values[id] = _clamped_value(id, initial_values.get(id, default_value)).get("value")

func value(id: String, fallback = 0):
	if _values.has(id):
		return _values[id]
	return fallback

func set_value(id: String, new_value, source: String = "") -> Dictionary:
	_ensure_definition(id)
	var previous = _values.get(id, 0)
	var clamped := _clamped_value(id, new_value)
	var current = clamped.get("value")
	_values[id] = current
	var report := {
		"id": id,
		"source": source,
		"previous": previous,
		"current": current,
		"delta": float(current) - float(previous),
		"changed": current != previous,
		"clamped": bool(clamped.get("clamped", false))
	}
	if bool(report.get("changed", false)):
		_events.append(report.duplicate(true))
	return report

func add(id: String, amount, source: String = "") -> Dictionary:
	return set_value(id, float(value(id, 0)) + float(amount), source)

func snapshot() -> Dictionary:
	return _values.duplicate(true)

func restore(values: Dictionary) -> void:
	_values = values.duplicate(true)

func events() -> Array:
	return _events.duplicate(true)

func clear_events() -> void:
	_events.clear()

func _ensure_definition(id: String) -> void:
	if not _definitions.has(id):
		_definitions[id] = {"id": id}
	if not _values.has(id):
		_values[id] = _clamped_value(id, _definitions[id].get("default", _definitions[id].get("min", 0))).get("value")

func _clamped_value(id: String, raw_value) -> Dictionary:
	var entry: Dictionary = Dictionary(_definitions.get(id, {}))
	var value = raw_value
	var clamped := false
	if entry.has("min") and float(value) < float(entry.get("min", 0)):
		value = entry.get("min")
		clamped = true
	if entry.has("max") and float(value) > float(entry.get("max", 0)):
		value = entry.get("max")
		clamped = true
	return {"value": value, "clamped": clamped}
