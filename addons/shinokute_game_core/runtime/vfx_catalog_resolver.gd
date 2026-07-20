class_name ShinokuteVfxCatalogResolver
extends RefCounted

var _allowed_layers: Array = []
var _allowed_anchors: Array = []
var _param_schema: Dictionary = {}

func configure(config: Dictionary = {}) -> void:
	_allowed_layers = Array(config.get("allowed_layers", [])).duplicate(true)
	_allowed_anchors = Array(config.get("allowed_anchors", [])).duplicate(true)
	_param_schema = Dictionary(config.get("param_schema", {})).duplicate(true)

func validate_catalog(catalog: Dictionary) -> Dictionary:
	var errors: Array = []
	var effects := Dictionary(catalog.get("effects", {}))
	var routes := Dictionary(catalog.get("routes", {}))
	for route_name in routes.keys():
		var route_effect_ids := Array(routes.get(route_name, []))
		if route_effect_ids.is_empty():
			errors.append({"code": "missing_route", "route": route_name})
		for effect_id in route_effect_ids:
			if not effects.has(effect_id):
				errors.append({"code": "missing_effect", "route": route_name, "effect_id": effect_id})
	for effect_id in effects.keys():
		var effect := Dictionary(effects.get(effect_id, {}))
		_validate_effect(effect_id, effect, errors)
	return {"valid": errors.is_empty(), "errors": errors}

func resolve_event(event_name: String, catalog: Dictionary, context: Dictionary = {}) -> Dictionary:
	var routes := Dictionary(catalog.get("routes", {}))
	if not routes.has(event_name):
		return {"status": "blocked", "reason": "missing_route", "event": event_name, "effects": []}
	var effects := Dictionary(catalog.get("effects", {}))
	var resolved: Array = []
	for effect_id in Array(routes.get(event_name, [])):
		if not effects.has(effect_id):
			return {"status": "blocked", "reason": "missing_effect", "event": event_name, "effect_id": effect_id, "effects": resolved}
		var effect := Dictionary(effects.get(effect_id, {}))
		var validation_errors: Array = []
		_validate_effect(effect_id, effect, validation_errors)
		if not validation_errors.is_empty():
			return {"status": "blocked", "reason": String(Dictionary(validation_errors[0]).get("code", "invalid_effect")), "event": event_name, "effect_id": effect_id, "effects": resolved}
		resolved.append({
			"id": effect_id,
			"layer": String(effect.get("layer", "")),
			"anchor": String(effect.get("anchor", "")),
			"scene_key": String(effect.get("scene_key", "")),
			"params": _resolved_params(Dictionary(effect.get("params", {}))),
			"context": context.duplicate(true)
		})
	return {"status": "resolved", "event": event_name, "effects": resolved}

func _validate_effect(effect_id: String, effect: Dictionary, errors: Array) -> void:
	var layer := String(effect.get("layer", ""))
	if layer.is_empty():
		errors.append({"code": "missing_layer", "effect_id": effect_id})
	elif not _allowed_layers.is_empty() and not _allowed_layers.has(layer):
		errors.append({"code": "bad_layer", "effect_id": effect_id, "layer": layer})
	var anchor := String(effect.get("anchor", ""))
	if anchor.is_empty():
		errors.append({"code": "missing_anchor", "effect_id": effect_id})
	elif not _allowed_anchors.is_empty() and not _allowed_anchors.has(anchor):
		errors.append({"code": "bad_anchor", "effect_id": effect_id, "anchor": anchor})
	var scene_key := String(effect.get("scene_key", ""))
	if scene_key.is_empty():
		errors.append({"code": "missing_scene_key", "effect_id": effect_id})
	var params := Dictionary(effect.get("params", {}))
	for param_key in _param_schema.keys():
		var expected_type := int(_param_schema.get(param_key, TYPE_NIL))
		if not params.has(param_key):
			errors.append({"code": "missing_param", "effect_id": effect_id, "param": param_key})
			continue
		var value = params.get(param_key)
		if expected_type != TYPE_NIL and typeof(value) != expected_type:
			errors.append({"code": "type_mismatch", "effect_id": effect_id, "param": param_key, "expected": expected_type, "actual": typeof(value)})

func _resolved_params(params: Dictionary) -> Dictionary:
	return params.duplicate(true)
