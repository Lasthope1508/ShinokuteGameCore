## Persists user-level data to user://save.cfg using ConfigFile.
## Stores the best score and audio volumes. Compatible with HTML5 export
## (Godot maps user:// to IndexedDB on the web).
extends Node

const SAVE_PATH := "user://save.cfg"
const SECTION_PROGRESS := "progress"
const SECTION_AUDIO := "audio"
const SECTION_GAME := "game"

var _config: ConfigFile = ConfigFile.new()


func _ready() -> void:
	_load()


# Debug-only: pressing Q wipes the save and reloads the splash. Disabled in release builds.
func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_Q:
		_debug_wipe_and_reload()


func wipe_all() -> void:
	_config.clear()
	_save()
	push_warning("SaveManager: all save data wiped")


func _debug_wipe_and_reload() -> void:
	wipe_all()
	GameState.best_score = 0
	GameState.current_score = 0
	GameState.ad_rewards_used = 0
	GameState.is_game_over = false
	GameState.score_changed.emit(0, 0)
	GameState.best_changed.emit(0)
	GameState.game_reset.emit()
	if Engine.has_singleton("AudioManager") or get_node_or_null("/root/AudioManager"):
		AudioManager.apply_saved_volumes()
	# SceneRouter may not have spawned its fade overlay yet during early boot.
	if get_node_or_null("/root/SceneRouter"):
		SceneRouter.change_scene("res://Scenes/Main/Main.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Main/Main.tscn")


func get_best_score(mode: String = "classic") -> int:
	if mode == "chaos":
		return int(_config.get_value(SECTION_PROGRESS, "best_score_chaos", 0))
	else:
		if _config.has_section_key(SECTION_PROGRESS, "best_score_classic"):
			return int(_config.get_value(SECTION_PROGRESS, "best_score_classic", 0))
		return int(_config.get_value(SECTION_PROGRESS, "best_score", 0))


func set_best_score(value: int, mode: String = "classic") -> void:
	if mode == "chaos":
		_config.set_value(SECTION_PROGRESS, "best_score_chaos", value)
	else:
		_config.set_value(SECTION_PROGRESS, "best_score_classic", value)
		_config.set_value(SECTION_PROGRESS, "best_score", value)
	_save()


func get_volume(bus_name: String, default_value: float = 1.0) -> float:
	return float(_config.get_value(SECTION_AUDIO, bus_name, default_value))


func set_volume(bus_name: String, value: float) -> void:
	_config.set_value(SECTION_AUDIO, bus_name, value)
	_save()


func reset_progress() -> void:
	_config.set_value(SECTION_PROGRESS, "best_score", 0)
	_config.set_value(SECTION_PROGRESS, "best_score_classic", 0)
	_config.set_value(SECTION_PROGRESS, "best_score_chaos", 0)
	_config.set_value(SECTION_PROGRESS, "last_submitted_score", 0)
	_config.set_value(SECTION_PROGRESS, "last_submitted_score_classic", 0)
	_config.set_value(SECTION_PROGRESS, "last_submitted_score_chaos", 0)
	_save()


# ---- Tutorial completion flag ------------------------------------------

func is_tutorial_completed() -> bool:
	return bool(_config.get_value(SECTION_PROGRESS, "tutorial_completed", false))


func set_tutorial_completed(value: bool) -> void:
	_config.set_value(SECTION_PROGRESS, "tutorial_completed", value)
	_save()


# ---- In-progress run save ----------------------------------------------

func has_saved_game() -> bool:
	return bool(_config.get_value(SECTION_GAME, "valid", false))


# Persists a run snapshot. Expected keys: "score" (int), "grid" (Array of
# {x, y, color}), "slots" (Array of 3 null or {cells, color}), "assists_used" (int).
func save_game(state: Dictionary) -> void:
	_config.set_value(SECTION_GAME, "valid", true)
	_config.set_value(SECTION_GAME, "score", int(state.get("score", 0)))
	_config.set_value(SECTION_GAME, "grid", state.get("grid", []))
	_config.set_value(SECTION_GAME, "slots", state.get("slots", []))
	_config.set_value(SECTION_GAME, "assists_used", int(state.get("assists_used", 0)))
	_save()


# Returns the saved snapshot, or {} if none.
func load_game() -> Dictionary:
	if not has_saved_game():
		return {}
	return {
		"score": int(_config.get_value(SECTION_GAME, "score", 0)),
		"grid": _config.get_value(SECTION_GAME, "grid", []),
		"slots": _config.get_value(SECTION_GAME, "slots", []),
		"assists_used": int(_config.get_value(SECTION_GAME, "assists_used", 0)),
	}


func clear_saved_game() -> void:
	if _config.has_section(SECTION_GAME):
		_config.erase_section(SECTION_GAME)
	_save()


func _load() -> void:
	# Missing file is expected on first run.
	var err := _config.load(SAVE_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("SaveManager: failed to load save file (err %d)" % err)


func _save() -> void:
	var err := _config.save(SAVE_PATH)
	if err != OK:
		push_warning("SaveManager: failed to write save file (err %d)" % err)


func get_setting(key: String, default_value: Variant = null) -> Variant:
	return _config.get_value("settings", key, default_value)


func set_setting(key: String, value: Variant) -> void:
	_config.set_value("settings", key, value)
	_save()


const SECTION_PROFILE := "profile"
const SECTION_GEOLOCATION := "geolocation"

func get_username() -> String:
	return _config.get_value(SECTION_PROFILE, "username", "")

func set_username(value: String) -> void:
	_config.set_value(SECTION_PROFILE, "username", value.strip_edges())
	_save()

func get_device_uuid() -> String:
	var uuid = _config.get_value(SECTION_PROFILE, "device_uuid", "")
	if uuid == "":
		uuid = ""
		for i in 16:
			uuid += "%02x" % (randi() % 256)
		_config.set_value(SECTION_PROFILE, "device_uuid", uuid)
		_save()
	return uuid

func get_country_code() -> String:
	return _config.get_value(SECTION_GEOLOCATION, "country_code", "")

func set_country_code(value: String) -> void:
	_config.set_value(SECTION_GEOLOCATION, "country_code", value)
	_save()

func get_country_name() -> String:
	return _config.get_value(SECTION_GEOLOCATION, "country_name", "")

func set_country_name(value: String) -> void:
	_config.set_value(SECTION_GEOLOCATION, "country_name", value)
	_save()

func get_continent_code() -> String:
	return _config.get_value(SECTION_GEOLOCATION, "continent_code", "")

func set_continent_code(value: String) -> void:
	_config.set_value(SECTION_GEOLOCATION, "continent_code", value)
	_save()

func get_last_submitted_score(mode: String = "classic") -> int:
	if mode == "chaos":
		return int(_config.get_value(SECTION_PROGRESS, "last_submitted_score_chaos", 0))
	else:
		if _config.has_section_key(SECTION_PROGRESS, "last_submitted_score_classic"):
			return int(_config.get_value(SECTION_PROGRESS, "last_submitted_score_classic", 0))
		return int(_config.get_value(SECTION_PROGRESS, "last_submitted_score", 0))

func set_last_submitted_score(value: int, mode: String = "classic") -> void:
	if mode == "chaos":
		_config.set_value(SECTION_PROGRESS, "last_submitted_score_chaos", value)
	else:
		_config.set_value(SECTION_PROGRESS, "last_submitted_score_classic", value)
		_config.set_value(SECTION_PROGRESS, "last_submitted_score", value)
	_save()

func is_country_changed_manually() -> bool:
	return bool(_config.get_value(SECTION_GEOLOCATION, "country_changed_manually", false))

func set_country_changed_manually(value: bool) -> void:
	_config.set_value(SECTION_GEOLOCATION, "country_changed_manually", value)
	_save()


