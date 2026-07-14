class_name ShinokuteScenePreloadCache
extends Node

signal resource_preloaded(path: String, resource: Resource)

var _resources: Dictionary = {}

func preload_resource(path: String) -> int:
	var key := path.strip_edges()
	if key.is_empty():
		return ERR_INVALID_PARAMETER
	if _resources.has(key):
		return OK
	if not ResourceLoader.exists(key):
		return ERR_FILE_NOT_FOUND
	var resource := ResourceLoader.load(key)
	if resource == null:
		return ERR_CANT_OPEN
	_resources[key] = resource
	resource_preloaded.emit(key, resource)
	return OK

func preload_many(paths: Array) -> int:
	var status := OK
	for path in paths:
		var err := preload_resource(String(path))
		if err != OK:
			status = err
	return status

func has_resource(path: String) -> bool:
	return _resources.has(path.strip_edges())

func get_resource(path: String) -> Resource:
	return _resources.get(path.strip_edges(), null)

func clear() -> void:
	_resources.clear()
