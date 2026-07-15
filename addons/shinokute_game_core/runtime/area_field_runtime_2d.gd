class_name ShinokuteAreaFieldRuntime2D
extends RefCounted

var _fields: Dictionary = {}
var _cell_size := 1.0

func configure(config: Dictionary = {}) -> void:
	_fields = {}
	_cell_size = float(max(0.0001, float(config.get("cell_size", 1.0))))
	for item in Array(config.get("fields", [])):
		if item is Dictionary:
			add_field(Dictionary(item))

func add_field(field: Dictionary) -> void:
	var id := String(field.get("id", "")).strip_edges()
	if id.is_empty():
		return
	var normalized := field.duplicate(true)
	normalized["id"] = id
	normalized["field_type"] = String(normalized.get("field_type", normalized.get("type", "")))
	normalized["position"] = Vector2(normalized.get("position", Vector2.ZERO))
	normalized["radius"] = float(max(0.0, float(normalized.get("radius", 0.0))))
	normalized["intensity"] = float(max(0.0, float(normalized.get("intensity", 1.0))))
	normalized["duration"] = float(max(0.0, float(normalized.get("duration", 0.0))))
	normalized["tick_interval"] = float(max(0.0, float(normalized.get("tick_interval", 0.0))))
	normalized["elapsed"] = float(max(0.0, float(normalized.get("elapsed", 0.0))))
	normalized["tick_elapsed"] = float(max(0.0, float(normalized.get("tick_elapsed", 0.0))))
	normalized["tags"] = Array(normalized.get("tags", [])).duplicate(true)
	_fields[id] = normalized

func advance(delta: float) -> Array:
	var events: Array = []
	var step := max(0.0, delta)
	var expired: Array = []
	for id in _fields.keys():
		var field := Dictionary(_fields[id]).duplicate(true)
		field["elapsed"] = float(field.get("elapsed", 0.0)) + step
		var tick_interval := float(field.get("tick_interval", 0.0))
		if tick_interval > 0.0:
			field["tick_elapsed"] = float(field.get("tick_elapsed", 0.0)) + step
			while float(field.get("tick_elapsed", 0.0)) >= tick_interval:
				field["tick_elapsed"] = float(field.get("tick_elapsed", 0.0)) - tick_interval
				events.append(_event("tick", field))
		if float(field.get("duration", 0.0)) > 0.0 and float(field.get("elapsed", 0.0)) >= float(field.get("duration", 0.0)):
			events.append(_event("expired", field))
			expired.append(id)
		else:
			_fields[id] = field
	for id in expired:
		_fields.erase(id)
	return events

func query_point(point: Vector2) -> Array:
	var result: Array = []
	for field in _fields.values():
		var entry := Dictionary(field)
		if _contains_point(entry, point):
			result.append(_public_field(entry))
	return result

func query_radius(point: Vector2, radius: float) -> Array:
	var result: Array = []
	var query_radius_value := max(0.0, radius)
	for field in _fields.values():
		var entry := Dictionary(field)
		var distance := point.distance_to(Vector2(entry.get("position", Vector2.ZERO)))
		if distance <= query_radius_value + float(entry.get("radius", 0.0)):
			result.append(_public_field(entry))
	return result

func active_fields() -> Array:
	var result: Array = []
	for field in _fields.values():
		result.append(_public_field(Dictionary(field)))
	return result

func snapshot() -> Dictionary:
	return {
		"cell_size": _cell_size,
		"fields": _fields.duplicate(true)
	}

func restore(snapshot_data: Dictionary) -> void:
	_cell_size = float(max(0.0001, float(snapshot_data.get("cell_size", 1.0))))
	_fields = Dictionary(snapshot_data.get("fields", {})).duplicate(true)

func _contains_point(field: Dictionary, point: Vector2) -> bool:
	var shape := String(field.get("shape", "circle"))
	var position := Vector2(field.get("position", Vector2.ZERO))
	if shape == "rect":
		var size := Vector2(field.get("size", Vector2.ZERO))
		return Rect2(position - size * 0.5, size).has_point(point)
	return position.distance_to(point) <= float(field.get("radius", 0.0))

func _event(event_type: String, field: Dictionary) -> Dictionary:
	var packed := _public_field(field)
	packed["type"] = event_type
	return packed

func _public_field(field: Dictionary) -> Dictionary:
	return {
		"id": String(field.get("id", "")),
		"field_type": String(field.get("field_type", "")),
		"position": Vector2(field.get("position", Vector2.ZERO)),
		"radius": float(field.get("radius", 0.0)),
		"shape": String(field.get("shape", "circle")),
		"size": Vector2(field.get("size", Vector2.ZERO)),
		"intensity": float(field.get("intensity", 0.0)),
		"duration": float(field.get("duration", 0.0)),
		"elapsed": float(field.get("elapsed", 0.0)),
		"tick_interval": float(field.get("tick_interval", 0.0)),
		"tags": Array(field.get("tags", [])).duplicate(true),
		"source": field.get("source", "")
	}
