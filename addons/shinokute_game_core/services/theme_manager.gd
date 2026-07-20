class_name ShinokuteThemeManager
extends Node

signal theme_changed(theme_id: String, save_key: String)

var theme_config: Resource
var save_key := "theme"
var token_schema: Dictionary = {}

func configure(config: Resource, options: Dictionary = {}) -> void:
	theme_config = config
	save_key = String(options.get("save_key", save_key))
	token_schema = Dictionary(options.get("token_schema", token_schema)).duplicate(true)
	_emit_theme_changed()

func has_theme() -> bool:
	return theme_config != null

func get_theme_id() -> String:
	return _theme_id(theme_config)

func get_save_key() -> String:
	return save_key

func get_color(key: String, default_color: Color = Color.WHITE) -> Color:
	return _resolve_value("colors", key, default_color)

func get_font_path(key: String) -> String:
	return String(_resolve_value("fonts", key, ""))

func get_asset_path(key: String) -> String:
	return String(_resolve_value("assets", key, ""))

func get_audio_path(key: String) -> String:
	return String(_resolve_value("audio", key, ""))

func get_metric(key: String, default_value: Variant = null) -> Variant:
	return _resolve_value("metrics", key, default_value)

func resolve_token_set(requests: Array) -> Dictionary:
	var resolved: Dictionary = {}
	for request in requests:
		if not (request is Dictionary):
			continue
		var entry := Dictionary(request)
		var id := String(entry.get("id", ""))
		if id.is_empty():
			continue
		var category := String(entry.get("category", ""))
		var key := String(entry.get("key", ""))
		var default_value := entry.get("default", null)
		var has_primary := _has_token(theme_config, category, key)
		var value := _resolve_value(category, key, default_value)
		resolved[id] = {
			"id": id,
			"category": category,
			"key": key,
			"value": value,
			"source": "primary" if has_primary else "missing",
			"found": has_primary
		}
	return resolved

func validate_tokens() -> Array:
	var errors: Array = []
	for category in token_schema.keys():
		var entries := Dictionary(token_schema.get(category, {}))
		for key in entries.keys():
			var expected_type := int(entries.get(key, TYPE_NIL))
			var value := _resolve_value(String(category), String(key), null)
			if value == null:
				errors.append({"code": "missing_token", "category": category, "key": key})
				continue
			if expected_type != TYPE_NIL and typeof(value) != expected_type:
				errors.append({"code": "type_mismatch", "category": category, "key": key, "expected": expected_type, "actual": typeof(value)})
	return errors

func _resolve_value(category: String, key: String, default_value: Variant) -> Variant:
	var primary := _read_value(theme_config, category, key, null)
	if primary != null:
		return primary
	return default_value

func _read_value(config: Resource, category: String, key: String, default_value: Variant) -> Variant:
	if config == null:
		return default_value
	var table := _dictionary_for_category(config, category)
	if table.has(key):
		return table.get(key)
	var method := _method_for_category(category)
	if method.is_empty() or not config.has_method(method):
		return default_value
	match category:
		"colors":
			return config.call(method, key, default_value)
		"metrics":
			return config.call(method, key, default_value)
		_:
			var value = config.call(method, key)
			if value is String and String(value).is_empty():
				return default_value
			return value

func _has_token(config: Resource, category: String, key: String) -> bool:
	if config == null:
		return false
	var table := _dictionary_for_category(config, category)
	return table.has(key)

func _dictionary_for_category(config: Resource, category: String) -> Dictionary:
	if config == null:
		return {}
	var property := ""
	match category:
		"colors":
			property = "colors"
		"fonts":
			property = "fonts"
		"assets":
			property = "asset_paths"
		"audio":
			property = "audio_events"
		"metrics":
			property = "ui_metrics"
		_:
			property = ""
	if property.is_empty():
		return {}
	var value = config.get(property)
	if value is Dictionary:
		return Dictionary(value)
	return {}

func _method_for_category(category: String) -> String:
	match category:
		"colors":
			return "get_color"
		"fonts":
			return "get_font_path"
		"assets":
			return "get_asset_path"
		"audio":
			return "get_audio_path"
		"metrics":
			return "get_metric"
		_:
			return ""

func _emit_theme_changed() -> void:
	theme_changed.emit(get_theme_id(), save_key)

func _theme_id(config: Resource) -> String:
	if config != null:
		return String(config.get("theme_id"))
	return ""
