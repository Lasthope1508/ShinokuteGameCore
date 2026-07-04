extends SceneTree

const GAME_SCENE_PATH := "res://Scenes/Gameplay/GameScene.tscn"
const THEME_PATH := "res://Resources/Data/Themes/cyberpunk_theme.tres"
const REQUIRED_GLYPHS := ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", "."]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	var theme: ThemeConfig = load(THEME_PATH)
	passed = passed and _assert_true(theme != null, "Cyber theme should load")
	if theme != null:
		for property_name in [
			"ui_bottom_timer_enabled",
			"ui_bottom_timer_atlas_path",
			"ui_bottom_timer_glyph_order",
			"ui_bottom_timer_glyph_rects",
			"ui_bottom_timer_region",
			"ui_bottom_timer_spacing_ratio",
			"ui_bottom_timer_pixel_height_ratio"
		]:
			passed = passed and _assert_true(_has_property(theme, property_name), "ThemeConfig should expose bottom timer SSOT property %s" % property_name)
		passed = passed and _assert_true(bool(theme.get("ui_bottom_timer_enabled")), "Bottom sprite timer should be enabled for cyber theme")
		var atlas_path := String(theme.get("ui_bottom_timer_atlas_path"))
		passed = passed and _assert_true(atlas_path == "res://Assets/UI/cyberpunk_theme/generated/production/dark/bottom_timer_digits/timer_digits_dark_atlas.png", "Bottom timer atlas path should be canonical production path")
		passed = passed and _assert_true(FileAccess.file_exists(atlas_path), "Bottom timer atlas file should exist")
		var atlas_image := Image.new()
		var atlas_error := atlas_image.load(atlas_path)
		passed = passed and _assert_true(atlas_error == OK and not atlas_image.is_empty(), "Bottom timer atlas image should load")
		var atlas_size := Vector2(atlas_image.get_width(), atlas_image.get_height())
		passed = passed and _assert_true(String(theme.get("ui_bottom_timer_glyph_order")) == "0123456789:.", "Bottom timer glyph order should be canonical")
		var glyph_rects: Dictionary = theme.get("ui_bottom_timer_glyph_rects")
		for glyph in REQUIRED_GLYPHS:
			passed = passed and _assert_true(glyph_rects.has(glyph), "Bottom timer glyph rect should exist for %s" % glyph)
			if glyph_rects.has(glyph):
				passed = passed and _assert_rect_inside_atlas(glyph_rects[glyph], atlas_size, "Bottom timer glyph rect should stay inside atlas for %s" % glyph)

	var scene: PackedScene = load(GAME_SCENE_PATH)
	passed = passed and _assert_true(scene != null, "GameScene should load")
	if scene != null and theme != null:
		root.size = Vector2i(720, 1280)
		var instance = scene.instantiate()
		instance.active_theme_override = theme
		root.add_child(instance)
		await process_frame
		instance._apply_top_tray_theme(theme)
		instance._apply_generated_ui_assets(theme)
		instance._reset_level_timer(10.0)
		instance._update_total_play_time_label(83.0)
		var bottom_timer = instance.bottom_reserve_layer.get_node_or_null("BottomTimerDigits")
		passed = passed and _assert_true(bottom_timer != null, "Bottom tray should contain BottomTimerDigits")
		if bottom_timer != null:
			passed = passed and _assert_true(bottom_timer.has_method("set_time_text"), "BottomTimerDigits should expose set_time_text")
			passed = passed and _assert_true(String(bottom_timer.get("time_text")) == "01:13", "Bottom timer should receive formatted elapsed time")
		passed = passed and _assert_true(instance.total_play_time_label.visible, "Top-right move readout should stay visible when bottom sprite timer is enabled")
		passed = passed and _assert_true(instance.total_play_time_label.text == "MOVES 0", "Top-right move readout should not duplicate elapsed time")
		passed = passed and _assert_true(instance._format_duration_seconds(0) == "00:00", "Duration formatter should keep 00:00")
		passed = passed and _assert_true(instance._format_duration_seconds(73) == "01:13", "Duration formatter should keep minute-second output")
		root.remove_child(instance)
		instance.free()
		await process_frame

	if passed:
		print("test_bottom_timer_digit_ssot: PASS")
		quit(0)
	else:
		print("test_bottom_timer_digit_ssot: FAIL")
		quit(1)

func _has_property(resource: Resource, property_name: String) -> bool:
	for info in resource.get_property_list():
		if info.get("name", "") == property_name:
			return true
	return false

func _assert_rect_inside_atlas(rect_value, atlas_size: Vector2, message: String) -> bool:
	if not (rect_value is Vector4):
		push_error("%s: expected Vector4" % message)
		return false
	var rect: Vector4 = rect_value
	var ok := rect.x >= 0.0 and rect.y >= 0.0 and rect.z > 0.0 and rect.w > 0.0 and rect.x + rect.z <= atlas_size.x and rect.y + rect.w <= atlas_size.y
	if not ok:
		push_error("%s: rect %s outside atlas %s" % [message, str(rect), str(atlas_size)])
	return ok

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
