class_name ShinokuteOverlayManager
extends Node

signal overlay_requested(key: String, payload: Dictionary)
signal overlay_hidden(key: String)

var overlay_scenes: Dictionary = {}
var active_overlays: Dictionary = {}

func configure(overlays: Dictionary = {}) -> void:
	overlay_scenes = overlays.duplicate(true)

func has_overlay(key: String) -> bool:
	return overlay_scenes.has(key) and not String(overlay_scenes[key]).is_empty()

func get_overlay_path(key: String) -> String:
	return String(overlay_scenes.get(key, ""))

func request_overlay(key: String, payload: Dictionary = {}) -> int:
	if not has_overlay(key):
		return ERR_DOES_NOT_EXIST
	active_overlays[key] = payload.duplicate(true)
	overlay_requested.emit(key, active_overlays[key])
	return OK

func hide_overlay(key: String) -> void:
	active_overlays.erase(key)
	overlay_hidden.emit(key)

func hide_all() -> void:
	for key in active_overlays.keys():
		overlay_hidden.emit(String(key))
	active_overlays.clear()
