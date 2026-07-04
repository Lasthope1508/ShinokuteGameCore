extends SceneTree

func _init() -> void:
	var passed := true
	var theme_text := FileAccess.get_file_as_string("res://Resources/Classes/ThemeConfig.gd")
	var scene_text := FileAccess.get_file_as_string("res://Scenes/Gameplay/GameScene.gd")
	var theme_resource_text := FileAccess.get_file_as_string("res://Resources/Data/Themes/cyberpunk_theme.tres")
	var generic_modal_action_body := _extract_function_body(scene_text, "func _style_modal_action_buttons")
	var result_modal_action_body := _extract_function_body(scene_text, "func _style_result_modal_action_buttons")

	passed = passed and _assert_true(theme_text.contains("ui_result_modal_width_ratio"), "ThemeConfig should define result modal portrait width SSOT")
	passed = passed and _assert_true(theme_text.contains("ui_result_modal_height_ratio"), "ThemeConfig should define result modal portrait height SSOT")
	passed = passed and _assert_true(theme_text.contains("ui_result_modal_landscape_width_ratio"), "ThemeConfig should define result modal landscape width SSOT")
	passed = passed and _assert_true(theme_text.contains("ui_result_modal_landscape_height_ratio"), "ThemeConfig should define result modal landscape height SSOT")
	passed = passed and _assert_true(theme_text.contains("ui_result_modal_content_margin_x"), "ThemeConfig should define result modal margin SSOT")
	passed = passed and _assert_true(theme_text.contains("ui_result_modal_action_button_width"), "ThemeConfig should define result modal action width SSOT")
	passed = passed and _assert_true(theme_text.contains("ui_result_modal_title_font_size"), "ThemeConfig should define result modal title font size SSOT")
	passed = passed and _assert_true(theme_text.contains("ui_result_modal_text_color_by_mode"), "ThemeConfig should define result modal text colors per mode")
	passed = passed and _assert_true(theme_text.contains("ui_result_modal_button_bg_by_mode"), "ThemeConfig should define result modal button backgrounds per mode")
	passed = passed and _assert_true(theme_resource_text.contains("ui_result_modal_width_ratio"), "cyberpunk theme should override result modal width")
	passed = passed and _assert_true(theme_resource_text.contains("ui_result_modal_action_button_width"), "cyberpunk theme should override result modal action width")
	passed = passed and _assert_true(theme_resource_text.contains("ui_result_modal_button_bg_by_mode"), "cyberpunk theme should override result modal mode button backgrounds")
	passed = passed and _assert_true(scene_text.contains("_apply_result_modal_theme"), "GameScene should route solved popup through result modal role helper")
	passed = passed and _assert_true(scene_text.contains("_apply_result_modal_text_style"), "GameScene should route solved popup labels through result modal style helper")
	passed = passed and _assert_true(scene_text.contains("_get_result_modal_mode_color"), "GameScene should resolve result colors by active UI mode")
	passed = passed and _assert_true(not scene_text.contains("_apply_modal_rect(solved_popup, modal_width, modal_height)"), "SolvedPopup must not reuse generic modal dimensions")
	passed = passed and _assert_true(scene_text.contains("theme.ui_result_modal_action_button_height"), "SolvedPopup button height should use result modal role token")
	passed = passed and _assert_true(scene_text.contains("theme.ui_result_modal_action_button_width"), "SolvedPopup button width should use result modal role token")
	passed = passed and _assert_true(scene_text.contains("button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER"), "SolvedPopup button should shrink to compact centered width")
	passed = passed and _assert_true(scene_text.contains("theme.ui_result_modal_button_bg_by_mode"), "SolvedPopup button should use result mode button backgrounds")
	passed = passed and _assert_true(scene_text.contains("_make_button_style(theme, state, bg_color)"), "SolvedPopup button should pass result background into stylebox builder")
	passed = passed and _assert_true(not generic_modal_action_body.contains("ui_result_modal_"), "Generic modal buttons must not depend on result modal SSOT tokens")
	passed = passed and _assert_true(result_modal_action_body.contains("theme.ui_result_modal_button_bg_by_mode"), "Result modal button style must own result mode background tokens")
	passed = passed and _assert_true(result_modal_action_body.contains("theme.ui_result_modal_button_text_color_by_mode"), "Result modal button style must own result mode text color tokens")
	passed = passed and _assert_true(result_modal_action_body.contains("theme.ui_result_modal_button_font_size"), "Result modal button style must own result font size token")

	if passed:
		print("test_result_modal_role_contract: PASS")
		quit(0)
	else:
		print("test_result_modal_role_contract: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true

func _extract_function_body(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + signature.length())
	if next < 0:
		return source.substr(start)
	return source.substr(start, next - start)
