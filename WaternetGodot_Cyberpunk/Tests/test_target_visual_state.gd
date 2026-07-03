extends SceneTree

const GAME_SCENE_SCRIPT = preload("res://Scenes/Gameplay/GameScene.gd")
const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const TARGET_SHEET_PATH = "res://Assets/Themes/cyberpunk_theme/energy_sheets/target/target_sheet.png"

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var scene = GAME_SCENE_SCRIPT.new()

	passed = passed and _assert_true(_has_property(theme, "target_dry_modulate"), "Theme should own target dry brightness")
	passed = passed and _assert_true(_has_property(theme, "target_powered_modulate"), "Theme should own target powered brightness")
	passed = passed and _assert_true(_has_property(theme, "target_energy_overlay_draw_enabled"), "Theme should own target energy overlay draw toggle")
	passed = passed and _assert_true(_has_property(theme, "target_core_idle_alpha_min"), "Theme should own idle target core alpha min")
	passed = passed and _assert_true(_has_property(theme, "target_core_idle_alpha_max"), "Theme should own idle target core alpha max")
	passed = passed and _assert_true(_has_property(theme, "target_core_powered_alpha_min"), "Theme should own powered target core alpha min")
	passed = passed and _assert_true(_has_property(theme, "target_core_powered_alpha_max"), "Theme should own powered target core alpha max")
	passed = passed and _assert_true(_has_property(theme, "target_core_idle_radius_px"), "Theme should own idle target core radius")
	passed = passed and _assert_true(_has_property(theme, "target_core_powered_radius_px"), "Theme should own powered target core radius")
	passed = passed and _assert_true(_has_property(theme, "target_core_blink_period"), "Theme should own target core blink period")
	passed = passed and _assert_true(_has_property(theme.target_geometry, "core_center"), "Target geometry should own core center coordinate")
	if _has_property(theme, "target_dry_modulate"):
		var dry_modulate: Color = theme.get("target_dry_modulate")
		passed = passed and _assert_true(dry_modulate.r >= 0.45 and dry_modulate.g >= 0.45 and dry_modulate.b >= 0.45, "Dry target should be visible, not black")
	if _has_property(theme, "target_powered_modulate"):
		var powered_modulate: Color = theme.get("target_powered_modulate")
		passed = passed and _assert_true(powered_modulate.r > theme.target_dry_modulate.r and powered_modulate.g > theme.target_dry_modulate.g, "Powered target should be brighter than dry target")
	if _has_property(theme, "target_energy_overlay_draw_enabled"):
		passed = passed and _assert_equal(theme.get("target_energy_overlay_draw_enabled"), true, "Cyber target should keep core energy overlay enabled")
	if _has_property(theme, "target_core_idle_alpha_min") and _has_property(theme, "target_core_idle_alpha_max"):
		passed = passed and _assert_true(theme.target_core_idle_alpha_min > 0.0 and theme.target_core_idle_alpha_max > theme.target_core_idle_alpha_min, "Idle target core should blink weakly")
	if _has_property(theme, "target_core_powered_alpha_min") and _has_property(theme, "target_core_powered_alpha_max"):
		passed = passed and _assert_true(theme.target_core_powered_alpha_min > theme.target_core_idle_alpha_max and theme.target_core_powered_alpha_max > theme.target_core_powered_alpha_min, "Powered target core should blink brighter than idle")
	if _has_property(theme, "target_core_idle_radius_px") and _has_property(theme, "target_core_powered_radius_px"):
		passed = passed and _assert_true(theme.target_core_powered_radius_px > theme.target_core_idle_radius_px, "Powered target core should fill more of the socket")
	if _has_property(theme.target_geometry, "core_center"):
		passed = passed and _assert_equal(theme.target_geometry.core_center, Vector2(256, 288), "Target core center should match socket center")

	var dry_info := {
		"texture": theme.target_texture,
		"base_texture": theme.target_texture,
		"geometry": theme.target_geometry
	}
	var powered_info := {
		"texture": theme.target_texture_watered,
		"base_texture": theme.target_texture,
		"geometry": theme.target_geometry
	}

	passed = passed and _assert_true(scene.has_method("_get_pipe_draw_texture_for_state"), "GameScene should expose draw texture state helper")
	passed = passed and _assert_true(scene.has_method("_get_pipe_modulate_for_state"), "GameScene should expose draw modulate state helper")
	passed = passed and _assert_true(scene.has_method("_should_draw_energy_overlay_for_asset"), "GameScene should expose per-asset energy overlay draw gate")
	passed = passed and _assert_true(scene.has_method("_get_target_core_alpha"), "GameScene should expose target core blink alpha helper")
	passed = passed and _assert_true(scene.has_method("_get_target_core_radius_px"), "GameScene should expose target core radius helper")
	if scene.has_method("_get_pipe_draw_texture_for_state"):
		passed = passed and _assert_equal(scene._get_pipe_draw_texture_for_state(dry_info, false, theme), theme.target_texture, "Dry target should draw base target texture")
		passed = passed and _assert_equal(scene._get_pipe_draw_texture_for_state(powered_info, true, theme), theme.target_texture_watered, "Powered target should draw lit target texture")
	if scene.has_method("_get_pipe_modulate_for_state"):
		passed = passed and _assert_equal(scene._get_pipe_modulate_for_state("target", false, theme), theme.target_dry_modulate, "Dry target should use target dry modulate")
		passed = passed and _assert_equal(scene._get_pipe_modulate_for_state("target", true, theme), theme.target_powered_modulate, "Powered target should draw lit texture with target powered boost")
	if scene.has_method("_should_draw_energy_overlay_for_asset"):
		passed = passed and _assert_equal(scene._should_draw_energy_overlay_for_asset("I", theme), false, "Pipe energy overlay should stay hidden in cyber gameplay")
		passed = passed and _assert_equal(scene._should_draw_energy_overlay_for_asset("target", theme), true, "Target energy overlay should draw core green when powered")
	if scene.has_method("_get_target_core_alpha"):
		var idle_alpha: float = scene._get_target_core_alpha(false, theme, 0.25)
		var powered_alpha: float = scene._get_target_core_alpha(true, theme, 0.25)
		passed = passed and _assert_true(powered_alpha > idle_alpha, "Powered target blink should be brighter than idle blink at same phase")
	if scene.has_method("_get_target_core_radius_px"):
		passed = passed and _assert_true(scene._get_target_core_radius_px(true, theme) > scene._get_target_core_radius_px(false, theme), "Powered target core radius should be larger than idle radius")
	var overlay: Texture2D = scene._get_energy_overlay_texture_for_draw(theme.target_texture, Vector2i(2, 0), true, theme.target_geometry)
	passed = passed and _assert_true(overlay is AtlasTexture, "Powered target should resolve canonical target energy sheet overlay")
	passed = passed and _assert_true(FileAccess.file_exists(TARGET_SHEET_PATH), "Target energy sheet should exist")
	if FileAccess.file_exists(TARGET_SHEET_PATH):
		var image := Image.new()
		var load_err := image.load(TARGET_SHEET_PATH)
		passed = passed and _assert_equal(load_err, OK, "Target energy sheet should load")
		if load_err == OK:
			passed = passed and _assert_equal(image.get_size(), Vector2i(4096, 512), "Target energy sheet should keep 8x512 frame layout")
			var frame_greens := []
			for frame_index in range(8):
				frame_greens.append(_average_core_green(image, frame_index))
			passed = passed and _assert_true(float(frame_greens[7]) - float(frame_greens[0]) >= 85.0, "Target core should brighten strongly across 8 frames")
			passed = passed and _assert_true(float(frame_greens[7]) >= 120.0, "Final target core should be bright green, not a thin line")
			for frame_index in range(1, 8):
				passed = passed and _assert_true(float(frame_greens[frame_index]) + 3.0 >= float(frame_greens[frame_index - 1]), "Target core brightness should not drop between frames")

	scene.free()
	if passed:
		print("test_target_visual_state: PASS")
		quit(0)
	else:
		print("test_target_visual_state: FAIL")
		quit(1)

func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if property.get("name", "") == property_name:
			return true
	return false

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

func _average_core_green(image: Image, frame_index: int) -> float:
	var center := Vector2i(frame_index * 512 + 256, 288)
	var radius := 58
	var total := 0.0
	var count := 0
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if Vector2(float(x - center.x), float(y - center.y)).length() > float(radius):
				continue
			var pixel := image.get_pixel(x, y)
			total += pixel.g * 255.0
			count += 1
	if count == 0:
		return 0.0
	return total / float(count)
