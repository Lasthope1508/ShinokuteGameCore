extends SceneTree

const PROFILE_POPUP_PATH := "res://Scenes/Common/ProfilePopup.tscn"
const THEME_PATH := "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	var scene: PackedScene = load(PROFILE_POPUP_PATH)
	var theme = load(THEME_PATH)
	passed = passed and _assert_true(scene != null, "ProfilePopup scene should load")
	passed = passed and _assert_true(theme != null, "Cyber theme should load")
	if scene != null and theme != null:
		var popup = scene.instantiate()
		root.add_child(popup)
		passed = passed and _assert_true(not (popup is Container), "ProfilePopup root should not be a Container because generated modal frame and close button use anchors")
		passed = passed and _assert_true(popup.has_method("apply_generated_ui_theme"), "ProfilePopup should expose generated UI theme hook")
		if popup.has_method("apply_generated_ui_theme"):
			popup.apply_generated_ui_theme(theme)
		var frame = popup.get_node_or_null("GeneratedModalFrame")
		var close_btn = popup.get_node_or_null("CloseBtn")
		passed = passed and _assert_true(frame is TextureRect, "ProfilePopup should create generated modal frame texture")
		if frame is TextureRect:
			passed = passed and _assert_true((frame as TextureRect).stretch_mode == TextureRect.STRETCH_SCALE, "ProfilePopup modal frame should fill modal rect until 9-slice pass")
		passed = passed and _assert_true(close_btn is Button, "ProfilePopup should own a corner CloseBtn")
		if close_btn is Button:
			passed = passed and _assert_true((close_btn as Button).size.x <= theme.ui_modal_close_button_size + 4.0, "ProfilePopup close button should stay utility-sized")
			passed = passed and _assert_true((close_btn as Button).size.y <= theme.ui_modal_close_button_size + 4.0, "ProfilePopup close button should stay utility-sized")
			passed = passed and _assert_true((close_btn as Button).anchor_left == 1.0 and (close_btn as Button).anchor_right == 1.0, "ProfilePopup close button should anchor to top-right")
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
