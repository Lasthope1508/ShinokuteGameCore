class_name ShinokuteRemoteConfigService
extends Node

signal config_updated(values: Dictionary)

var _defaults: Dictionary = {}
var _overrides: Dictionary = {}

func configure_defaults(values: Dictionary) -> void:
	_defaults = values.duplicate(true)

func apply_overrides(values: Dictionary) -> void:
	_overrides = values.duplicate(true)
	config_updated.emit(get_all())

func get_value(key: String, default_value: Variant = null) -> Variant:
	if _overrides.has(key):
		return _overrides[key]
	if _defaults.has(key):
		return _defaults[key]
	return default_value

func get_bool(key: String, default_value: bool = false) -> bool:
	return bool(get_value(key, default_value))

func get_int(key: String, default_value: int = 0) -> int:
	return int(get_value(key, default_value))

func get_float(key: String, default_value: float = 0.0) -> float:
	return float(get_value(key, default_value))

func get_string(key: String, default_value: String = "") -> String:
	return String(get_value(key, default_value))

func get_all() -> Dictionary:
	var merged := _defaults.duplicate(true)
	for key in _overrides.keys():
		merged[key] = _overrides[key]
	return merged
