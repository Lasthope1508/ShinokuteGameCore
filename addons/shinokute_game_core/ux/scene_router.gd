class_name ShinokuteSceneRouter
extends Node

signal route_requested(key: String, path: String, payload: Dictionary)

var scene_routes: Dictionary = {}
var current_route: String = ""
var last_payload: Dictionary = {}

func configure(routes: Dictionary = {}) -> void:
	scene_routes = routes.duplicate(true)

func get_scene_path(key: String) -> String:
	return String(scene_routes.get(key, ""))

func has_route(key: String) -> bool:
	return not get_scene_path(key).is_empty()

func request_route(key: String, payload: Dictionary = {}) -> int:
	var path := get_scene_path(key)
	if path.is_empty():
		return ERR_DOES_NOT_EXIST
	current_route = key
	last_payload = payload.duplicate(true)
	route_requested.emit(key, path, last_payload)
	return OK

func change_scene(key: String, payload: Dictionary = {}) -> int:
	var err := request_route(key, payload)
	if err != OK:
		return err
	return get_tree().change_scene_to_file(get_scene_path(key))
