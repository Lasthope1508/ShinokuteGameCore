extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var theme := load("res://Resources/Data/Themes/cyberpunk_theme.tres").duplicate(true) as ThemeConfig
	theme.ui_generated_asset_mode = "light"
	var scene: Node = load("res://Scenes/Gameplay/GameScene.tscn").instantiate()
	scene.set("active_theme_override", theme)
	scene.set("solved_popup", scene.get_node("HUD/SolvedPopup"))
	scene.set("popup_title", scene.get_node("HUD/SolvedPopup/MarginContainer/VBoxContainer/PopupTitle"))
	scene.set("popup_moves", scene.get_node("HUD/SolvedPopup/MarginContainer/VBoxContainer/PopupMoves"))
	scene.call("_apply_result_modal_style", theme)
	var button := scene.get_node_or_null("HUD/SolvedPopup/MarginContainer/VBoxContainer/NextBtn") as Button
	var passed := true
	if button == null:
		passed = false
	else:
		var style := button.get_theme_stylebox("normal") as StyleBoxFlat
		var expected_bg: Color = theme.ui_result_modal_button_bg_by_mode.get("light")
		var expected_text: Color = theme.ui_result_modal_button_text_color_by_mode.get("light")
		print("runtime result button bg=", style.bg_color if style != null else null, " expected=", expected_bg)
		print("runtime result button font=", button.get_theme_color("font_color"), " expected=", expected_text)
		passed = style != null and style.bg_color == expected_bg and button.get_theme_color("font_color") == expected_text
	scene.free()
	if passed:
		print("test_result_modal_runtime_style: PASS")
		quit(0)
	else:
		print("test_result_modal_runtime_style: FAIL")
		quit(1)
