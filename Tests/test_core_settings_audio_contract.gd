extends SceneTree

const ConfigScript := preload("res://addons/shinokute_game_core/core/game_core_config.gd")
const CoreScript := preload("res://addons/shinokute_game_core/core/game_core.gd")
const LocalSaveStoreScript := preload("res://addons/shinokute_game_core/core/local_save_store.gd")
const AudioHapticsScript := preload("res://addons/shinokute_game_core/services/audio_haptics_manager.gd")

const SETTINGS_SCRIPT_PATH := "res://addons/shinokute_game_core/services/settings_manager.gd"
const SAVE_PATH := "user://shinokute_core_settings_audio_test.cfg"

var _passed := true
var _changes: Array = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var cfg = ConfigScript.new()
	cfg.game_id = "settings_contract"
	cfg.firebase_project_id = "demo"
	cfg.firestore_api_key = "demo"
	cfg.leaderboard_collections = {"classic": "settings_contract_classic"}
	_assert_true("settings_defaults" in cfg, "config should expose settings_defaults")
	_assert_true(cfg.has_method("get_setting_default"), "config should expose get_setting_default")
	if "settings_defaults" in cfg:
		cfg.settings_defaults = {
			"sfx_enabled": false,
			"bgm_enabled": true,
			"shift_lock_enabled": true
		}
	if cfg.has_method("get_setting_default"):
		_assert_eq(bool(cfg.get_setting_default("sfx_enabled", true)), false, "config default sfx")
		_assert_eq(bool(cfg.get_setting_default("bgm_enabled", false)), true, "config default bgm")
		_assert_eq(bool(cfg.get_setting_default("shift_lock_enabled", false)), true, "config default shift lock")

	var store = LocalSaveStoreScript.new()
	root.add_child(store)
	store.save_path = SAVE_PATH
	store.load_store()
	store.wipe_all()

	_assert_true(ResourceLoader.exists(SETTINGS_SCRIPT_PATH), "settings manager service should exist")
	if ResourceLoader.exists(SETTINGS_SCRIPT_PATH):
		var settings_script = load(SETTINGS_SCRIPT_PATH)
		var settings = settings_script.new()
		root.add_child(settings)
		settings.setting_changed.connect(func(key: String, value): _changes.append({"key": key, "value": value}))
		settings.configure(cfg, store)
		_assert_true(settings.is_sfx_enabled() == false, "sfx should read configured default")
		_assert_true(settings.is_bgm_enabled(), "bgm should read configured default")
		_assert_true(settings.is_shift_lock_enabled(), "shift lock should read configured default")
		settings.set_sfx_enabled(true)
		_assert_eq(_changes.back()["key"], "sfx_enabled", "sfx change signal key")
		_assert_true(store.get_setting("sfx_enabled", false) == true, "sfx setting persists")
		var reloaded = settings_script.new()
		root.add_child(reloaded)
		reloaded.configure(cfg, store)
		_assert_true(reloaded.is_sfx_enabled(), "sfx setting reloads from save")
		settings.free()
		reloaded.free()

	var audio = AudioHapticsScript.new()
	root.add_child(audio)
	_assert_true(audio.has_method("set_sfx_enabled"), "audio exposes set_sfx_enabled")
	_assert_true(audio.has_method("set_bgm_enabled"), "audio exposes set_bgm_enabled")
	if audio.has_method("set_sfx_enabled") and audio.has_method("set_bgm_enabled"):
		audio.set_sfx_enabled(false)
		audio.set_bgm_enabled(true)
		_assert_true(not audio.is_sfx_enabled(), "audio exposes sfx gate")
		_assert_true(audio.is_bgm_enabled(), "audio exposes bgm gate")
		_assert_eq(audio.play_event("missing"), ERR_SKIP, "disabled sfx skips event playback")
	audio.free()

	var core = CoreScript.new()
	root.add_child(core)
	core.configure(cfg, SAVE_PATH)
	await process_frame
	_assert_true("settings" in core, "game core should expose settings manager")
	if "settings" in core:
		_assert_true(core.settings != null, "game core wires settings manager")
		_assert_true(core.settings.is_shift_lock_enabled(), "game core exposes shift lock default")
	core.save_store.wipe_all()
	core.free()
	store.free()
	_report("test_core_settings_audio_contract")

func _assert_true(value: bool, label: String) -> void:
	if not value:
		_passed = false
		push_error(label)

func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_passed = false
		push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])

func _report(name: String) -> void:
	if _passed:
		print("%s: PASS" % name)
		quit(0)
	else:
		print("%s: FAIL" % name)
		quit(1)
