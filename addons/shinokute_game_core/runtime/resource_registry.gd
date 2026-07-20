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
	var entry = entries.get(key, {})
	if typeof(entry) != TYPE_DICTIONARY:
		return ""
	if entry.has("fallback_key"):
		push_error("resource_registry.%s uses forbidden fallback_key" % key)
		return ""
	return String(entry.get("path", ""))

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
		errors.append_array(_validate_key(key))
	return errors

func _validate_key(key: String) -> Array:
	var errors: Array = []
	var entry = entries.get(key, null)
	if typeof(entry) != TYPE_DICTIONARY:
		errors.append("resource_registry.%s must be a Dictionary" % key)
		return errors
	if entry.has("fallback_key"):
		errors.append("resource_registry.%s fallback_key is forbidden; declare path directly" % key)
		return errors
	var resource_path: String = String(entry.get("path", ""))
	var required: bool = bool(entry.get("required", false))
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
