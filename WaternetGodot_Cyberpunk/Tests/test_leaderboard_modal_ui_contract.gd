extends SceneTree

const LEADERBOARD_POPUP_PATH := "res://Scenes/Common/LeaderboardPopup.tscn"
const LEADERBOARD_POPUP_SCRIPT := "res://Scenes/Common/LeaderboardPopup.gd"
const THEME_PATH := "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	var scene: PackedScene = load(LEADERBOARD_POPUP_PATH)
	var theme = load(THEME_PATH)
	var source := FileAccess.get_file_as_string(LEADERBOARD_POPUP_SCRIPT)
	passed = passed and _assert_true(scene != null, "LeaderboardPopup scene should load")
	passed = passed and _assert_true(theme != null, "Cyber theme should load")
	passed = passed and _assert_true(source.contains("ui_leaderboard_popup_content_margin_top"), "LeaderboardPopup should use leaderboard-specific top safe margin")
	passed = passed and _assert_true(not source.contains("ui_profile_popup_content_margin_top"), "LeaderboardPopup should not reuse profile top margin")
	passed = passed and _assert_true(source.contains("UiTextLayout.apply_label_role(title_label, theme_config, \"leaderboard_title\""), "Leaderboard title should use text role gate")
	if scene != null and theme != null:
		var popup = scene.instantiate()
		root.add_child(popup)
		passed = passed and _assert_true(not (popup is Container), "LeaderboardPopup root should not be a Container because generated modal frame and close button use anchors")
		passed = passed and _assert_true(popup.has_method("apply_generated_ui_theme"), "LeaderboardPopup should expose generated UI theme hook")
		if popup.has_method("apply_generated_ui_theme"):
			popup.apply_generated_ui_theme(theme)
		await process_frame
		var frame = popup.get_node_or_null("GeneratedModalFrame")
		var close_btn = popup.get_node_or_null("CloseBtn")
		var title_label := popup.get_node_or_null("MarginContainer/VBoxContainer/TitleLabel") as Label
		var margin_container := popup.get_node_or_null("MarginContainer") as MarginContainer
		passed = passed and _assert_true(frame is TextureRect, "LeaderboardPopup should create generated modal frame texture")
		if frame is TextureRect:
			passed = passed and _assert_true((frame as TextureRect).stretch_mode == TextureRect.STRETCH_SCALE, "LeaderboardPopup modal frame should fill modal rect until 9-slice pass")
		if margin_container != null:
			passed = passed and _assert_equal(margin_container.get_theme_constant("margin_top"), theme.ui_leaderboard_popup_content_margin_top, "Leaderboard content should use title-safe top margin")
		if title_label != null:
			var popup_rect: Rect2 = (popup as Control).get_global_rect()
			var title_rect: Rect2 = title_label.get_global_rect()
			var safe_top: float = popup_rect.position.y + float(theme.ui_leaderboard_popup_content_margin_top) - 2.0
			passed = passed and _assert_true(title_rect.position.y >= safe_top, "Leaderboard title should start below generated frame top safe area")
			passed = passed and _assert_true(title_rect.end.x <= popup_rect.end.x - float(theme.ui_leaderboard_popup_content_margin_x) + 2.0, "Leaderboard title should stay inside horizontal owner rect")
		passed = passed and _assert_true(close_btn is Button, "LeaderboardPopup should own a corner CloseBtn")
		if close_btn is Button:
			passed = passed and _assert_true((close_btn as Button).size.x <= theme.ui_modal_close_button_size + 4.0, "LeaderboardPopup close button should stay utility-sized")
			passed = passed and _assert_true((close_btn as Button).size.y <= theme.ui_modal_close_button_size + 4.0, "LeaderboardPopup close button should stay utility-sized")
			passed = passed and _assert_true((close_btn as Button).anchor_left == 1.0 and (close_btn as Button).anchor_right == 1.0, "LeaderboardPopup close button should anchor to top-right")
		root.remove_child(popup)
		popup.free()
		await process_frame

	if passed:
		print("test_leaderboard_modal_ui_contract: PASS")
		quit(0)
	else:
		print("test_leaderboard_modal_ui_contract: FAIL")
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
