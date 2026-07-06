extends SceneTree

const ConfigScript := preload("res://shared/ShinokuteGameCore/addons/shinokute_game_core/core/game_core_config.gd")
const CoreScript := preload("res://shared/ShinokuteGameCore/addons/shinokute_game_core/core/game_core.gd")
const PROFILE_POPUP_SCENE := "res://Scenes/Common/ProfilePopup.tscn"
const THEME_PATH := "res://Resources/Data/Themes/cyberpunk_theme.tres"
const SAVE_PATH := "user://glyph_profile_score_persistence_test.cfg"

var _passed := true

class FakeLeaderboard:
	extends Node
	var submitted: Array = []

	func submit_score(score: int, mode: String = "classic") -> int:
		submitted.append({"score": score, "mode": mode})
		return OK

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var cfg: GameCoreConfig = _make_config()
	var core: GameCore = _make_core(cfg)
	core.save_store.wipe_all()
	_assert_eq(core.submit_score({"mode": "classic", "value": 14}), ERR_UNAVAILABLE, "score without username should request profile instead of submitting")
	_assert_eq(core.save_store.get_best_score("classic"), 14, "first solved score should persist as local best")
	_assert_eq(core.save_store.get_pending_score("classic"), 14, "first solved score should persist as pending submit")
	_assert_eq(core.submit_score({"mode": "classic", "value": 8}), ERR_UNAVAILABLE, "better score without username should remain pending")
	_assert_eq(core.save_store.get_best_score("classic"), 8, "lower moves should replace local best")
	_assert_eq(core.save_store.get_pending_score("classic"), 8, "lower moves should replace pending score")

	root.remove_child(core)
	core.free()
	core = _make_core(cfg)
	_assert_eq(core.save_store.get_best_score("classic"), 8, "local best should survive app close and reopen")
	_assert_eq(core.save_store.get_pending_score("classic"), 8, "pending score should survive app close and reopen")

	var fake_leaderboard := FakeLeaderboard.new()
	core.add_child(fake_leaderboard)
	core.leaderboard = fake_leaderboard
	_assert_true(core.profile.commit_username("TesterOne"), "username commit should pass validation")
	await process_frame
	_assert_eq(fake_leaderboard.submitted.size(), 1, "username commit should flush one pending score")
	if fake_leaderboard.submitted.size() == 1:
		_assert_eq(int(fake_leaderboard.submitted[0]["score"]), 8, "flushed score should be best pending score")

	_assert_profile_input_focus_contract()
	core.save_store.wipe_all()
	root.remove_child(core)
	core.free()
	_report("test_profile_score_persistence_flow")

func _make_config() -> GameCoreConfig:
	var cfg := ConfigScript.new()
	cfg.game_id = "glyphflow_arrays"
	cfg.firebase_project_id = "foodapp-7ff6b"
	cfg.firestore_api_key = "test"
	cfg.leaderboard_collections = {"classic": "glyphflow_arrays_leaderboard"}
	cfg.score_sort_directions = {"classic": "ASCENDING"}
	cfg.score_labels = {"classic": "moves"}
	cfg.username_min_length = 3
	cfg.username_max_length = 16
	cfg.allow_skip_username = false
	cfg.require_username_on_first_launch = true
	return cfg

func _make_core(cfg: GameCoreConfig) -> GameCore:
	var core := CoreScript.new()
	root.add_child(core)
	core.configure(cfg, SAVE_PATH)
	return core

func _assert_profile_input_focus_contract() -> void:
	var scene: PackedScene = load(PROFILE_POPUP_SCENE)
	var theme: ThemeConfig = load(THEME_PATH)
	_assert_true(scene != null, "profile popup scene should load")
	_assert_true(theme != null, "theme should load")
	if scene == null or theme == null:
		return
	var popup := scene.instantiate()
	root.add_child(popup)
	if popup.has_method("apply_generated_ui_theme"):
		popup.apply_generated_ui_theme(theme)
	await process_frame
	var username_edit := popup.get_node_or_null("MarginContainer/VBoxContainer/UsernameFieldRoot/HBoxEdit/UsernameEdit") as LineEdit
	var username_frame := popup.get_node_or_null("MarginContainer/VBoxContainer/UsernameFieldRoot/UsernameFieldFrame") as TextureRect
	_assert_true(username_edit != null, "profile popup should contain username LineEdit")
	_assert_true(username_frame != null, "profile popup should contain username frame art")
	if username_frame != null:
		_assert_eq(username_frame.mouse_filter, Control.MOUSE_FILTER_IGNORE, "username frame art should not intercept clicks")
	if username_edit != null:
		_assert_true(username_edit.caret_blink, "username LineEdit should blink caret")
		_assert_eq(username_edit.focus_mode, Control.FOCUS_ALL, "username LineEdit should accept focus")
		username_edit.grab_focus()
		await process_frame
		_assert_true(root.gui_get_focus_owner() == username_edit, "username LineEdit should become focused")
	root.remove_child(popup)
	popup.free()

func _assert_true(value: bool, label: String) -> void:
	if not value:
		_passed = false
		push_error(label)

func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_passed = false
		push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])

func _report(test_name: String) -> void:
	if _passed:
		print("%s: PASS" % test_name)
		quit(0)
	else:
		print("%s: FAIL" % test_name)
		quit(1)
