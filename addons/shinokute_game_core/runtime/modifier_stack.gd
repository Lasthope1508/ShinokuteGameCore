class_name ShinokuteModifierStack
extends RefCounted

var _modifiers: Array = []

func add_modifier(modifier: Dictionary) -> void:
	var target_key := String(modifier.get("target_key", ""))
	var operation := String(modifier.get("operation", ""))
	if target_key.is_empty() or operation.is_empty():
		return
	_modifiers.append(modifier.duplicate(true))

func remove_source(source: String) -> void:
	var kept: Array = []
	for item in _modifiers:
		var modifier := Dictionary(item)
		if String(modifier.get("source", "")) != source:
			kept.append(modifier)
	_modifiers = kept

func tick(delta: float) -> void:
	var kept: Array = []
	for item in _modifiers:
		var modifier := Dictionary(item).duplicate(true)
		if modifier.has("duration"):
			var remaining := float(modifier.get("duration", 0.0)) - delta
			if remaining <= 0.0:
				continue
			modifier["duration"] = remaining
		kept.append(modifier)
	_modifiers = kept

func modifiers() -> Array:
	return _modifiers.duplicate(true)

func resolve(base_values: Dictionary) -> Dictionary:
	var resolved := base_values.duplicate(true)
	for item in _modifiers:
		var modifier := Dictionary(item)
		var key := String(modifier.get("target_key", ""))
		var operation := String(modifier.get("operation", ""))
		var current = resolved.get(key, 0.0)
		var value = modifier.get("value", 0.0)
		match operation:
			"add":
				resolved[key] = float(current) + float(value)
			"multiply":
				resolved[key] = float(current) * float(value)
			"set":
				resolved[key] = value
	return resolved
