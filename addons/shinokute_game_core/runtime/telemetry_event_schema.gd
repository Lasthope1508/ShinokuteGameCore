class_name ShinokuteTelemetryEventSchema
extends RefCounted

var _schemas: Dictionary = {}

func configure(schemas: Dictionary) -> void:
	_schemas = schemas.duplicate(true)

func validate(event_name: String, payload: Dictionary) -> Dictionary:
	var errors: Array = []
	var schema := Dictionary(_schemas.get(event_name, {}))
	if schema.is_empty():
		errors.append({"code": "unknown_event", "event": event_name})
		return {"valid": false, "errors": errors}
	for field in Array(schema.get("required", [])):
		var field_name := String(field)
		if not payload.has(field_name):
			errors.append({"code": "missing_required", "field": field_name})
	for field_name in Dictionary(schema.get("types", {})).keys():
		if not payload.has(field_name):
			continue
		var expected_type := int(Dictionary(schema.get("types", {})).get(field_name, TYPE_NIL))
		if expected_type != TYPE_NIL and typeof(payload.get(field_name)) != expected_type:
			errors.append({"code": "type_mismatch", "field": field_name, "expected": expected_type, "actual": typeof(payload.get(field_name))})
	return {"valid": errors.is_empty(), "errors": errors}

func normalize(event_name: String, payload: Dictionary) -> Dictionary:
	var schema := Dictionary(_schemas.get(event_name, {}))
	var normalized: Dictionary = {}
	for field in Array(schema.get("required", [])):
		var field_name := String(field)
		if payload.has(field_name):
			normalized[field_name] = payload.get(field_name)
	for field_name in Dictionary(schema.get("types", {})).keys():
		if payload.has(field_name):
			normalized[field_name] = payload.get(field_name)
	return normalized
