extends Node

const GameCoreScript := preload("res://addons/shinokute_game_core/core/game_core.gd")
const InputRouterScript := preload("res://addons/shinokute_game_core/services/input_router.gd")

signal profile_ready(username: String)
signal leaderboard_loaded(tab: String, scores: Array, mode: String)
signal score_submitted(success: bool, mode: String)
signal settings_changed(key: String, value: Variant)

@export var core_config: Resource
@export var username_prompt_scene: PackedScene
@export var progression_path := NodePath("../GameProgression")
@export var view_path := NodePath("../View")
@export var save_path := "user://candy_sky_islands_core.cfg"
@export var score_mode := "classic"

var core: Node
var input_router: Node
var _username_prompt: Node

func _ready() -> void:
	if core_config == null:
		push_error("CandyGameCoreBridge missing core_config")
		return
	if core_config.has_method("validate_config"):
		var errors: Array = core_config.validate_config()
		for error in errors:
			push_error(error)
		if not errors.is_empty():
			return
	core = GameCoreScript.new()
	add_child(core)
	_ensure_input_router()
	core.configure(core_config, save_path)
	core.username_required.connect(_on_username_required)
	core.profile_ready.connect(func(username: String): profile_ready.emit(username))
	core.leaderboard_loaded.connect(func(tab: String, scores: Array, mode: String): leaderboard_loaded.emit(tab, scores, mode))
	core.score_submitted.connect(func(success: bool, mode: String): score_submitted.emit(success, mode))
	if core.settings != null:
		core.settings.setting_changed.connect(_on_core_setting_changed)
		_apply_all_settings()
	core.ensure_profile_ready()
	_connect_progression()

func _ensure_input_router() -> void:
	if input_router != null:
		return
	input_router = InputRouterScript.new()
	input_router.name = "ShinokuteInputRouter"
	add_child(input_router)

func submit_score(value: int) -> int:
	if core == null:
		return ERR_UNAVAILABLE
	return core.submit_score({"mode": score_mode, "value": value})

func fetch_leaderboard(tab: String = "world") -> int:
	if core == null:
		return ERR_UNAVAILABLE
	return core.fetch_leaderboard(tab, score_mode)

func is_sfx_enabled() -> bool:
	if core == null or core.settings == null:
		return true
	return core.settings.is_sfx_enabled()

func set_sfx_enabled(value: bool) -> void:
	if core != null and core.settings != null:
		core.settings.set_sfx_enabled(value)

func is_bgm_enabled() -> bool:
	if core == null or core.settings == null:
		return true
	return core.settings.is_bgm_enabled()

func set_bgm_enabled(value: bool) -> void:
	if core != null and core.settings != null:
		core.settings.set_bgm_enabled(value)

func is_shift_lock_enabled() -> bool:
	if core == null or core.settings == null:
		return true
	return core.settings.is_shift_lock_enabled()

func set_shift_lock_enabled(value: bool) -> void:
	if core != null and core.settings != null:
		core.settings.set_shift_lock_enabled(value)

func _connect_progression() -> void:
	var progression := get_node_or_null(progression_path)
	if progression == null or not progression.has_signal("level_completed"):
		return
	var callable := Callable(self, "_on_level_completed")
	if not progression.is_connected("level_completed", callable):
		progression.connect("level_completed", callable)

func _on_level_completed(level_index: int, level: Resource) -> void:
	submit_score(_score_for_completed_level(level_index, level))

func _score_for_completed_level(level_index: int, level: Resource) -> int:
	if level != null and "difficulty_tier" in level:
		return max(1, int(level.difficulty_tier))
	return max(1, level_index + 1)

func _on_username_required() -> void:
	if username_prompt_scene == null or core == null:
		return
	if _username_prompt != null and is_instance_valid(_username_prompt):
		return
	_username_prompt = username_prompt_scene.instantiate()
	add_child(_username_prompt)
	if _username_prompt.has_method("configure"):
		_username_prompt.configure(core.profile)

func _on_core_setting_changed(key: String, value: Variant) -> void:
	_apply_setting(key, value)
	settings_changed.emit(key, value)

func _apply_all_settings() -> void:
	_apply_setting("sfx_enabled", is_sfx_enabled())
	_apply_setting("bgm_enabled", is_bgm_enabled())
	_apply_setting("shift_lock_enabled", is_shift_lock_enabled())

func _apply_setting(key: String, value: Variant) -> void:
	if key == "sfx_enabled" and Audio.has_method("set_sfx_enabled"):
		Audio.set_sfx_enabled(bool(value))
	elif key == "bgm_enabled" and Audio.has_method("set_bgm_enabled"):
		Audio.set_bgm_enabled(bool(value))
	elif key == "shift_lock_enabled":
		var view := get_node_or_null(view_path)
		if view != null and view.has_method("set_shift_lock_enabled"):
			view.set_shift_lock_enabled(bool(value))
