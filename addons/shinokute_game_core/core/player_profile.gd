class_name PlayerProfile
extends Node

signal username_required
signal profile_ready(username: String)
signal username_changed(username: String)

var config: Resource
var save_store: Node

func configure(core_config: Resource, store: Node) -> void:
	config = core_config
	save_store = store

func ensure_profile_ready() -> void:
	var username := _current_username()
	if username.is_empty() and config != null and config.is_username_required():
		username_required.emit()
		return
	if username.is_empty() and config != null and config.allow_skip_username:
		skip_username()
		return
	profile_ready.emit(_current_username())

func validate_username(username: String) -> Array[String]:
	if config == null:
		return ["GameCoreConfig is not configured."]
	return config.validate_username(username)

func commit_username(username: String) -> bool:
	if save_store == null:
		return false
	var errors := validate_username(username)
	if not errors.is_empty():
		return false
	var clean := username.strip_edges()
	save_store.set_username(clean)
	username_changed.emit(clean)
	profile_ready.emit(clean)
	return true

func skip_username() -> bool:
	if config == null or save_store == null or not config.allow_skip_username:
		return false
	var username := create_default_username()
	save_store.set_username(username)
	username_changed.emit(username)
	profile_ready.emit(username)
	return true

func create_default_username() -> String:
	var prefix := "Player"
	if config != null and not config.default_username_prefix.strip_edges().is_empty():
		prefix = config.default_username_prefix.strip_edges()
	var suffix := "00000"
	if save_store != null:
		suffix = save_store.get_device_uuid().substr(0, 5)
	return "%s_%s" % [prefix, suffix]

func _current_username() -> String:
	if save_store == null:
		return ""
	return save_store.get_username().strip_edges()
