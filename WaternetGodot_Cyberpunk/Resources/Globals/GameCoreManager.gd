extends Node

signal username_required
signal profile_ready(username: String)
signal username_changed(username: String)
signal leaderboard_loaded(tab: String, scores: Array, mode: String)
signal score_submitted(success: bool, mode: String)

const GameCoreScript := preload("res://shared/ShinokuteGameCore/addons/shinokute_game_core/core/game_core.gd")
const GAME_CORE_CONFIG_PATH := "res://Resources/Data/glyphflow_game_core_config.tres"
const SAVE_PATH := "user://save.cfg"

var core: Node
var config: Resource

func _ready() -> void:
	_configure_core()
	call_deferred("ensure_profile_ready")

func ensure_profile_ready() -> void:
	if core == null or core.profile == null:
		return
	core.ensure_profile_ready()

func get_username() -> String:
	if core == null or core.save_store == null:
		return ""
	return String(core.save_store.get_username()).strip_edges()

func has_username() -> bool:
	return not get_username().is_empty()

func validate_username(username: String) -> Array:
	if core == null or core.profile == null:
		return ["Profile service is not configured."]
	return core.profile.validate_username(username)

func commit_username(username: String) -> bool:
	if core == null or core.profile == null:
		return false
	var ok: bool = core.profile.commit_username(username)
	if ok:
		_sync_legacy_profile()
		username_changed.emit(get_username())
	return ok

func skip_username() -> bool:
	if core == null or core.profile == null:
		return false
	var ok: bool = core.profile.skip_username()
	if ok:
		_sync_legacy_profile()
		username_changed.emit(get_username())
	return ok

func submit_score(score: int, mode: String = "classic") -> int:
	if core == null:
		return ERR_UNAVAILABLE
	return core.submit_score({"mode": mode, "value": score})

func fetch_leaderboard(tab: String, mode: String = "classic") -> int:
	if core == null:
		return ERR_UNAVAILABLE
	return core.fetch_leaderboard(tab, mode)

func resolve_geolocation() -> int:
	if core == null or core.geo_service == null:
		return ERR_UNAVAILABLE
	return core.geo_service.resolve_geolocation()

func _configure_core() -> void:
	config = load(GAME_CORE_CONFIG_PATH)
	if config == null:
		push_error("GameCoreManager: missing GameCoreConfig at %s" % GAME_CORE_CONFIG_PATH)
		return
	if config.has_method("validate_config"):
		var errors: Array = config.validate_config()
		if not errors.is_empty():
			push_error("GameCoreManager: invalid GameCoreConfig: %s" % ", ".join(errors))
			return
	core = GameCoreScript.new()
	add_child(core)
	core.configure(config, SAVE_PATH)
	core.username_required.connect(func(): username_required.emit())
	core.profile_ready.connect(func(username: String): profile_ready.emit(username))
	core.leaderboard_loaded.connect(func(tab: String, scores: Array, mode: String): leaderboard_loaded.emit(tab, scores, mode))
	if core.profile != null and core.profile.has_signal("username_changed"):
		core.profile.username_changed.connect(func(username: String): username_changed.emit(username))
	if core.leaderboard != null and core.leaderboard.has_signal("score_submitted"):
		core.leaderboard.score_submitted.connect(func(success: bool, mode: String): score_submitted.emit(success, mode))
	if core.geo_service != null:
		core.geo_service.resolve_geolocation()

func _sync_legacy_profile() -> void:
	if not has_node("/root/SaveManager"):
		return
	SaveManager.set_username(get_username())
