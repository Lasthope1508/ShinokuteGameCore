extends SceneTree

const PROFILE_POPUP_SCRIPT := "res://Scenes/Common/ProfilePopup.gd"
const PROFILE_POPUP_SCENE := "res://Scenes/Common/ProfilePopup.tscn"
const LEADERBOARD_POPUP_SCRIPT := "res://Scenes/Common/LeaderboardPopup.gd"
const LEADERBOARD_POPUP_SCENE := "res://Scenes/Common/LeaderboardPopup.tscn"
const GAME_SCENE_SCRIPT := "res://Scenes/Gameplay/GameScene.gd"
const THEME_PATH := "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	var profile_source := FileAccess.get_file_as_string(PROFILE_POPUP_SCRIPT)
	var leaderboard_source := FileAccess.get_file_as_string(LEADERBOARD_POPUP_SCRIPT)
	var game_scene_source := FileAccess.get_file_as_string(GAME_SCENE_SCRIPT)
	var profile_scene: PackedScene = load(PROFILE_POPUP_SCENE)
	var leaderboard_scene: PackedScene = load(LEADERBOARD_POPUP_SCENE)
	var theme: ThemeConfig = load(THEME_PATH)

	passed = passed and _assert_true(profile_scene != null, "Profile popup scene should load")
	passed = passed and _assert_true(leaderboard_scene != null, "Leaderboard popup scene should load")
	passed = passed and _assert_true(theme != null, "Cyber theme should load")
	passed = passed and _assert_true(not profile_source.contains("fetch_leaderboard"), "Profile popup should not fetch leaderboard")
	passed = passed and _assert_true(not profile_source.contains("leaderboard_loaded"), "Profile popup should not own leaderboard signal")
	passed = passed and _assert_true(not profile_source.contains("ScoreList"), "Profile popup should not contain leaderboard rows")
	passed = passed and _assert_true(leaderboard_source.contains("fetch_leaderboard"), "Leaderboard popup should fetch leaderboard")
	passed = passed and _assert_true(leaderboard_source.contains("ScoreList"), "Leaderboard popup should own score list")
	passed = passed and _assert_true(game_scene_source.contains("LEADERBOARD_POPUP_SCENE_PATH"), "GameScene should use a dedicated leaderboard popup scene")
	passed = passed and _assert_true(not game_scene_source.contains("PROFILE_POPUP_SCENE_PATH"), "GameScene leaderboard should not mount profile popup")
	passed = passed and _assert_true(profile_source.contains("ui_profile_popup_field_min_height"), "Profile username field height should come from ThemeConfig")
	passed = passed and _assert_true(profile_source.contains("ui_profile_popup_field_frame_asset_key"), "Profile username field frame should choose an existing generated UI asset through ThemeConfig")
	passed = passed and _assert_true(not profile_source.contains("_make_username_field_style"), "Profile username field should not draw a new procedural frame when generated UI assets exist")

	if profile_scene != null and theme != null:
		var profile_popup = profile_scene.instantiate()
		root.add_child(profile_popup)
		passed = passed and _assert_true(profile_popup.get_node_or_null("MarginContainer/VBoxContainer/UsernameFieldRoot/HBoxEdit/UsernameEdit") is LineEdit, "Profile popup should own username editor inside field frame")
		passed = passed and _assert_true(profile_popup.get_node_or_null("MarginContainer/VBoxContainer/UsernameFieldRoot/UsernameFieldFrame") is TextureRect, "Profile popup should own generated asset field frame")
		passed = passed and _assert_true(profile_popup.get_node_or_null("MarginContainer/VBoxContainer/ScrollContainer/ScoreList") == null, "Profile popup scene should not contain leaderboard score list")
		if profile_popup.has_method("apply_generated_ui_theme"):
			profile_popup.apply_generated_ui_theme(theme)
		await process_frame
		var username_edit := profile_popup.get_node_or_null("MarginContainer/VBoxContainer/UsernameFieldRoot/HBoxEdit/UsernameEdit") as LineEdit
		var username_frame := profile_popup.get_node_or_null("MarginContainer/VBoxContainer/UsernameFieldRoot/UsernameFieldFrame") as TextureRect
		if username_edit != null:
			var normal_style := username_edit.get_theme_stylebox("normal") as StyleBoxFlat
			passed = passed and _assert_true(username_edit.custom_minimum_size.y >= theme.ui_profile_popup_field_min_height, "Username field should reserve owner-approved field height")
			passed = passed and _assert_true(normal_style != null and normal_style.bg_color.a == 0.0, "Username LineEdit should be transparent so existing field asset owns the box")
		if username_frame != null:
			passed = passed and _assert_true(username_frame.texture != null, "Username field frame should render an existing generated asset texture")
			passed = passed and _assert_true(theme.ui_profile_popup_field_frame_asset_key == "profile_username_field_frame", "Username field should use a role-specific single-field frame, not the multi-panel top tray stats_capsule")
			var field_geometry: Dictionary = theme.get_ui_generated_asset_geometry(theme.ui_profile_popup_field_frame_asset_key)
			passed = passed and _assert_equal(String(field_geometry.get("anchor", "")), "profile.username_field", "Username field geometry should use a profile-specific anchor")
			passed = passed and _assert_equal(String(field_geometry.get("runtime_region", "")), "alpha_bbox", "Username field frame should render the trimmed single-field crop")
			passed = passed and _assert_true(username_frame.expand_mode == TextureRect.EXPAND_IGNORE_SIZE, "Username field frame should obey the owner rect instead of keeping source texture size")
			passed = passed and _assert_true(username_frame.stretch_mode == TextureRect.STRETCH_SCALE, "Username field frame should scale the single-field crop without aspect-cover cropping")
		root.remove_child(profile_popup)
		profile_popup.free()

	if leaderboard_scene != null:
		var leaderboard_popup = leaderboard_scene.instantiate()
		root.add_child(leaderboard_popup)
		passed = passed and _assert_true(leaderboard_popup.get_node_or_null("MarginContainer/VBoxContainer/HBoxEdit/UsernameEdit") == null, "Leaderboard popup should not contain username editor")
		passed = passed and _assert_true(leaderboard_popup.get_node_or_null("MarginContainer/VBoxContainer/ScrollContainer/ScoreList") is VBoxContainer, "Leaderboard popup should contain score list")
		if leaderboard_popup.has_method("_on_leaderboard_loaded"):
			leaderboard_popup._on_leaderboard_loaded("world", [], "classic")
			await process_frame
			var score_list := leaderboard_popup.get_node_or_null("MarginContainer/VBoxContainer/ScrollContainer/ScoreList") as VBoxContainer
			if score_list != null and score_list.get_child_count() == 1:
				var empty_row := score_list.get_child(0) as Label
				passed = passed and _assert_true(empty_row != null, "Leaderboard empty state should create a label row")
				if empty_row != null:
					passed = passed and _assert_true(empty_row.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "Leaderboard empty state should be centered in the list area")
					passed = passed and _assert_true((empty_row.size_flags_horizontal & Control.SIZE_EXPAND_FILL) == Control.SIZE_EXPAND_FILL, "Leaderboard empty state should fill the list width instead of sizing from text")
					passed = passed and _assert_true(empty_row.clip_text, "Leaderboard empty state should clip inside the modal")
		root.remove_child(leaderboard_popup)
		leaderboard_popup.free()

	if passed:
		print("test_profile_leaderboard_ui_split_contract: PASS")
		quit(0)
	else:
		print("test_profile_leaderboard_ui_split_contract: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
