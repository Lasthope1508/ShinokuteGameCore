class_name ShinokuteResourceRegistry
extends Node

var entries: Dictionary = {}
var _cache: Dictionary = {}

func configure(resource_entries: Dictionary = {}) -> void:
	entries = resource_entries.duplicate(true)
	_cache.clear()

func has_resource_key(key: String) -> bool:
	return entries.has(key)

func get_entry(key: String) -> Dictionary:
	var entry = entries.get(key, {})
	if typeof(entry) == TYPE_DICTIONARY:
		return entry.duplicate(true)
	return {}

func get_resource_path(key: String) -> String:
	return _get_resource_path_internal(key, [])

func get_resource(key: String):
	var resource_path: String = get_resource_path(key)
	if resource_path.is_empty():
		return null
	if _cache.has(resource_path):
		return _cache[resource_path]
	var resource = load(resource_path)
	if resource != null:
		_cache[resource_path] = resource
	return resource

func validate() -> Array:
	var errors: Array = []
	for raw_key in entries.keys():
		var key: String = String(raw_key)
		errors.append_array(_validate_key(key, []))
	return errors

func _get_resource_path_internal(key: String, visited: Array) -> String:
	if visited.has(key):
		return ""
	var entry = entries.get(key, {})
	if typeof(entry) != TYPE_DICTIONARY:
		return ""
	var resource_path: String = String(entry.get("path", ""))
	if not resource_path.is_empty():
		return resource_path
	var fallback_key: String = String(entry.get("fallback_key", ""))
	if fallback_key.is_empty():
		return ""
	var next_visited: Array = visited.duplicate()
	next_visited.append(key)
	return _get_resource_path_internal(fallback_key, next_visited)

func _validate_key(key: String, visited: Array) -> Array:
	var errors: Array = []
	if visited.has(key):
		errors.append("resource_registry.%s fallback cycle" % key)
		return errors
	var entry = entries.get(key, null)
	if typeof(entry) != TYPE_DICTIONARY:
		errors.append("resource_registry.%s must be a Dictionary" % key)
		return errors
	var resource_path: String = String(entry.get("path", ""))
	var fallback_key: String = String(entry.get("fallback_key", ""))
	var required: bool = bool(entry.get("required", false))
	if resource_path.is_empty() and not fallback_key.is_empty():
		if not entries.has(fallback_key):
			errors.append("resource_registry.%s fallback_key %s is missing" % [key, fallback_key])
		else:
			var next_visited: Array = visited.duplicate()
			next_visited.append(key)
			errors.append_array(_validate_key(fallback_key, next_visited))
		return errors
	if resource_path.is_empty():
		if required:
			errors.append("resource_registry.%s required path is empty" % key)
		return errors
	if not ResourceLoader.exists(resource_path) and not FileAccess.file_exists(resource_path):
		if required:
			errors.append("resource_registry.%s required path does not exist: %s" % [key, resource_path])
		return errors
	var expected_type: String = String(entry.get("type", ""))
	if expected_type.is_empty() or expected_type == "Resource":
		return errors
	var resource = load(resource_path)
	if resource == null:
		if required:
			errors.append("resource_registry.%s could not load: %s" % [key, resource_path])
		return errors
	if not resource.is_class(expected_type):
		errors.append("resource_registry.%s expected %s got %s" % [key, expected_type, resource.get_class()])
	return errors
