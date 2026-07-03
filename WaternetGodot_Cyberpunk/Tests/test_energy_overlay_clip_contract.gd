extends SceneTree

const GAME_SCENE_SCRIPT = preload("res://Scenes/Gameplay/GameScene.gd")
const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var scene = GAME_SCENE_SCRIPT.new()
	var l_geometry = theme.pipe_l_geometry
	var source_geometry = theme.source_geometry

	passed = passed and _assert_true(scene.has_method("_get_energy_frame_region_for_geometry"), "GameScene should expose energy atlas region helper")
	passed = passed and _assert_true(scene.has_method("_get_energy_draw_rect_for_geometry"), "GameScene should expose energy draw rect helper")
	passed = passed and _assert_true(scene.has_method("_get_energy_overlay_texture_for_draw"), "GameScene should expose clipped energy overlay texture helper")

	if scene.has_method("_get_energy_frame_region_for_geometry"):
		var l_region: Rect2 = scene._get_energy_frame_region_for_geometry(l_geometry, 3)
		passed = passed and _assert_equal(l_region, Rect2(1726, 0, 322, 322), "L energy frame region should use geometry energy_rect plus frame offset")
		var source_region: Rect2 = scene._get_energy_frame_region_for_geometry(source_geometry, 7)
		passed = passed and _assert_equal(source_region, Rect2(3680, 48, 320, 416), "source energy frame region should use geometry energy_rect plus frame offset")

	if scene.has_method("_get_energy_draw_rect_for_geometry"):
		var l_draw_rect: Rect2 = scene._get_energy_draw_rect_for_geometry(l_geometry)
		passed = passed and _assert_equal(l_draw_rect, Rect2(-66, -256, 322, 322), "L energy draw rect should be relative to draw origin")
		var source_draw_rect: Rect2 = scene._get_energy_draw_rect_for_geometry(source_geometry)
		passed = passed and _assert_equal(source_draw_rect, Rect2(-160, -208, 320, 416), "source energy draw rect should be relative to draw origin")

	if scene.has_method("_get_energy_overlay_texture_for_draw"):
		var overlay: Texture2D = scene._get_energy_overlay_texture_for_draw(theme.l_slices[1].texture, Vector2i(1, 1), true, l_geometry)
		passed = passed and _assert_true(overlay is AtlasTexture, "watered L slice overlay should use clipped atlas texture")
		if overlay is AtlasTexture:
			passed = passed and _assert_equal((overlay as AtlasTexture).region.size, l_geometry.energy_rect.size, "watered L slice overlay atlas region should match L energy_rect")
		var dry_overlay: Texture2D = scene._get_energy_overlay_texture_for_draw(theme.l_slices[1].texture, Vector2i(1, 1), false, l_geometry)
		passed = passed and _assert_equal(dry_overlay, null, "dry tile should not draw energy overlay")

	scene.free()

	if passed:
		print("test_energy_overlay_clip_contract: PASS")
		quit(0)
	else:
		print("test_energy_overlay_clip_contract: FAIL")
		quit(1)

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
