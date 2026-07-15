class_name ShinokuteProjectileBlueprintComposer2D
extends RefCounted

func compose(base_blueprint: Dictionary, modifiers: Array = []) -> Dictionary:
	var resolved := base_blueprint.duplicate(true)
	for item in modifiers:
		if item is Dictionary:
			_apply_modifier(resolved, Dictionary(item))
	return resolved

func compose_many(base_blueprints: Array, modifiers_by_id: Dictionary = {}) -> Array:
	var composed: Array = []
	for item in base_blueprints:
		if not (item is Dictionary):
			continue
		var base := Dictionary(item)
		var id := String(base.get("id", ""))
		var modifiers: Array = Array(modifiers_by_id.get(id, []))
		composed.append(compose(base, modifiers))
	return composed

func _apply_modifier(target: Dictionary, modifier: Dictionary) -> void:
	var key := String(modifier.get("target_key", ""))
	var operation := String(modifier.get("operation", ""))
	if key.is_empty() or operation.is_empty():
		return
	var value = modifier.get("value")
	var current = target.get(key)
	match operation:
		"add":
			target[key] = _numeric_result(current, value, float(current if target.has(key) else 0.0) + float(value))
		"multiply":
			target[key] = _numeric_result(current, value, float(current if target.has(key) else 1.0) * float(value))
		"set":
			target[key] = value
		"max", "set_if_greater":
			target[key] = _numeric_result(current, value, max(float(current if target.has(key) else value), float(value)))
		"min", "set_if_lower":
			target[key] = _numeric_result(current, value, min(float(current if target.has(key) else value), float(value)))
		"append":
			var values := Array(target.get(key, [])).duplicate(true)
			if value is Array:
				values.append_array(value)
			else:
				values.append(value)
			target[key] = values
		"append_unique":
			var unique_values := Array(target.get(key, [])).duplicate(true)
			var incoming: Array = []
			if value is Array:
				incoming = Array(value)
			else:
				incoming = [value]
			for entry in incoming:
				if not unique_values.has(entry):
					unique_values.append(entry)
			target[key] = unique_values

func _numeric_result(current, value, result: float):
	if typeof(current) == TYPE_FLOAT or typeof(value) == TYPE_FLOAT:
		return result
	if is_equal_approx(result, round(result)):
		return int(round(result))
	return result
