extends SceneTree

const PROFILE_POPUP_SCRIPT := "res://Scenes/Common/ProfilePopup.gd"
const PROFILE_POPUP_SCENE := "res://Scenes/Common/ProfilePopup.tscn"
const LEADERBOARD_POPUP_SCRIPT := "res://Scenes/Common/LeaderboardPopup.gd"
const LEADERBOARD_POPUP_SCENE := "res://Scenes/Common/LeaderboardPopup.tscn"
const GAME_SCENE_SCRIPT := "res://Scenes/Gameplay/GameScene.gd"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	var profile_source := FileAccess.get_file_as_string(PROFILE_POPUP_SCRIPT)
	var leaderboard_source := FileAccess.get_file_as_string(LEADERBOARD_POPUP_SCRIPT)
	var game_scene_source := FileAccess.get_file_as_string(GAME_SCENE_SCRIPT)
	var profile_scene: PackedScene = load(PROFILE_POPUP_SCENE)
	var leaderboard_scene: PackedScene = load(LEADERBOARD_POPUP_SCENE)

	passed = passed and _assert_true(profile_scene != null, "Profile popup scene should load")
	passed = passed and _assert_true(leaderboard_scene != null, "Leaderboard popup scene should load")
	passed = passed and _assert_true(not profile_source.contains("fetch_leaderboard"), "Profile popup should not fetch leaderboard")
	passed = passed and _assert_true(not profile_source.contains("leaderboard_loaded"), "Profile popup should not own leaderboard signal")
	passed = passed and _assert_true(not profile_source.contains("ScoreList"), "Profile popup should not contain leaderboard rows")
	passed = passed and _assert_true(leaderboard_source.contains("fetch_leaderboard"), "Leaderboard popup should fetch leaderboard")
	passed = passed and _assert_true(leaderboard_source.contains("ScoreList"), "Leaderboard popup should own score list")
	passed = passed and _assert_true(game_scene_source.contains("LEADERBOARD_POPUP_SCENE_PATH"), "GameScene should use a dedicated leaderboard popup scene")
	passed = passed and _assert_true(not game_scene_source.contains("PROFILE_POPUP_SCENE_PATH"), "GameScene leaderboard should not mount profile popup")

	if profile_scene != null:
		var profile_popup = profile_scene.instantiate()
		root.add_child(profile_popup)
		passed = passed and _assert_true(profile_popup.get_node_or_null("MarginContainer/VBoxContainer/HBoxEdit/UsernameEdit") is LineEdit, "Profile popup should own username editor")
		passed = passed and _assert_true(profile_popup.get_node_or_null("MarginContainer/VBoxContainer/ScrollContainer/ScoreList") == null, "Profile popup scene should not contain leaderboard score list")
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
