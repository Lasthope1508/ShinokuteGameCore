class_name ShinokuteAnalyticsTracker
extends Node

signal event_tracked(name: String, params: Dictionary)

var enabled := true
var event_prefix: String = ""
var _last_events: Array = []

func configure(config: Dictionary = {}) -> void:
	enabled = bool(config.get("enabled", enabled))
	event_prefix = String(config.get("event_prefix", event_prefix))

func set_enabled(value: bool) -> void:
	enabled = value

func track(event_name: String, params: Dictionary = {}) -> int:
	var clean_name := event_name.strip_edges()
	if clean_name.is_empty():
		return ERR_INVALID_PARAMETER
	if not enabled:
		return ERR_SKIP
	var final_name := clean_name if event_prefix.is_empty() else "%s_%s" % [event_prefix, clean_name]
	var payload := params.duplicate(true)
	_last_events.append({"name": final_name, "params": payload})
	event_tracked.emit(final_name, payload)
	return OK

func get_last_events() -> Array:
	return _last_events.duplicate(true)
