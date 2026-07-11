class_name LocalSaveStore
extends Node

@export var save_path: String = "user://shinokute_game_core.cfg"

const SECTION_PROFILE := "profile"
const SECTION_GEOLOCATION := "geolocation"
const SECTION_PROGRESS := "progress"
const SECTION_SETTINGS := "settings"

var _config := ConfigFile.new()
var _loaded := false

func _ready() -> void:
	if not _loaded:
		load_store()

func load_store() -> void:
	var err := _config.load(save_path)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("LocalSaveStore: failed to load %s err=%d" % [save_path, err])
	_loaded = true

func save_store() -> void:
	var err := _config.save(save_path)
	if err != OK:
		push_warning("LocalSaveStore: failed to save %s err=%d" % [save_path, err])

func wipe_all() -> void:
	_config.clear()
	save_store()

func get_username() -> String:
	return String(_config.get_value(SECTION_PROFILE, "username", ""))

func set_username(value: String) -> void:
	_config.set_value(SECTION_PROFILE, "username", value.strip_edges())
	save_store()

func get_device_uuid() -> String:
	var uuid := String(_config.get_value(SECTION_PROFILE, "device_uuid", ""))
	if uuid.is_empty():
		uuid = _generate_uuid_hex()
		_config.set_value(SECTION_PROFILE, "device_uuid", uuid)
		save_store()
	return uuid

func set_geolocation(country_code: String, country_name: String, continent_code: String) -> void:
	_config.set_value(SECTION_GEOLOCATION, "country_code", country_code)
	_config.set_value(SECTION_GEOLOCATION, "country_name", country_name)
	_config.set_value(SECTION_GEOLOCATION, "continent_code", continent_code)
	save_store()

func get_country_code() -> String:
	return String(_config.get_value(SECTION_GEOLOCATION, "country_code", ""))

func get_country_name() -> String:
	return String(_config.get_value(SECTION_GEOLOCATION, "country_name", ""))

func get_continent_code() -> String:
	return String(_config.get_value(SECTION_GEOLOCATION, "continent_code", ""))

func get_best_score(mode: String = "classic") -> int:
	return int(_config.get_value(SECTION_PROGRESS, _mode_key("best_score", mode), 0))

func set_best_score(value: int, mode: String = "classic") -> void:
	_config.set_value(SECTION_PROGRESS, _mode_key("best_score", mode), value)
	save_store()

func get_last_submitted_score(mode: String = "classic") -> int:
	return int(_config.get_value(SECTION_PROGRESS, _mode_key("last_submitted_score", mode), 0))

func set_last_submitted_score(value: int, mode: String = "classic") -> void:
	_config.set_value(SECTION_PROGRESS, _mode_key("last_submitted_score", mode), value)
	save_store()

func get_pending_score(mode: String = "classic") -> int:
	return int(_config.get_value(SECTION_PROGRESS, _mode_key("pending_score", mode), 0))

func set_pending_score(value: int, mode: String = "classic") -> void:
	_config.set_value(SECTION_PROGRESS, _mode_key("pending_score", mode), value)
	save_store()

func clear_pending_score(mode: String = "classic") -> void:
	_config.erase_section_key(SECTION_PROGRESS, _mode_key("pending_score", mode))
	save_store()

func get_setting(key: String, default_value: Variant = null) -> Variant:
	return _config.get_value(SECTION_SETTINGS, key, default_value)

func set_setting(key: String, value: Variant) -> void:
	_config.set_value(SECTION_SETTINGS, key, value)
	save_store()

func _mode_key(prefix: String, mode: String) -> String:
	return "%s_%s" % [prefix, mode.strip_edges()]

func _generate_uuid_hex() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var uuid := ""
	for _i in range(16):
		uuid += "%02x" % rng.randi_range(0, 255)
	return uuid
