extends SceneTree

const THEME_PATH := "res://Resources/Data/Themes/cyberpunk_theme.tres"
const MODE := "light"
const CASES := [
	{
		"asset_key": "floating_menu_button_default",
		"button_region": "left_floating_menu",
		"icon_region": "left_floating_menu_icon"
	},
	{
		"asset_key": "floating_replay_button_default",
		"button_region": "right_floating_replay",
		"icon_region": "right_floating_replay_icon"
	}
]
const CENTER_TOLERANCE_PX := 10.0

func _init() -> void:
	var passed := true
	var theme: Resource = load(THEME_PATH)
	passed = passed and _assert_true(theme != null, "Theme should load")
	if theme != null:
		for test_case in CASES:
			passed = passed and _assert_shell_visual_center_near_icon(theme, test_case)

	if passed:
		print("test_light_top_tray_button_shell_alignment: PASS")
		quit(0)
	else:
		print("test_light_top_tray_button_shell_alignment: FAIL")
		quit(1)

func _assert_shell_visual_center_near_icon(theme: Resource, test_case: Dictionary) -> bool:
	var asset_key := String(test_case["asset_key"])
	var button_region_key := String(test_case["button_region"])
	var icon_region_key := String(test_case["icon_region"])
	var pixel_sets: Dictionary = theme.get("ui_top_tray_region_pixel_rect_sets")
	var mode_regions: Dictionary = pixel_sets.get(MODE, {})
	var button_region: Vector4 = mode_regions.get(button_region_key, Vector4.ZERO)
	var icon_region: Vector4 = mode_regions.get(icon_region_key, Vector4.ZERO)
	var geometry: Dictionary = theme.get_ui_generated_asset_geometry(asset_key)
	var source_path: String = theme.get_ui_generated_asset_path(MODE, asset_key)
	var image := Image.new()
	var load_error: Error = image.load(ProjectSettings.globalize_path(source_path))
	var passed := true
	passed = passed and _assert_true(load_error == OK, "%s should load source PNG" % asset_key)
	passed = passed and _assert_true(button_region.z > 0.0 and button_region.w > 0.0, "%s button region should be positive" % asset_key)
	passed = passed and _assert_true(icon_region.z > 0.0 and icon_region.w > 0.0, "%s icon region should be positive" % asset_key)
	if not passed:
		return false

	var alpha_bboxes: Dictionary = geometry.get("alpha_bbox", {})
	var alpha_bbox: Vector4 = alpha_bboxes.get(MODE, Vector4.ZERO)
	passed = passed and _assert_true(alpha_bbox.z > 0.0 and alpha_bbox.w > 0.0, "%s should define light alpha_bbox" % asset_key)
	var runtime_region := _get_runtime_region_for_mode(geometry, MODE)
	passed = passed and _assert_equal(runtime_region, "alpha_bbox", "%s light shell should use alpha_bbox runtime crop to remove PhotoRoom padding" % asset_key)
	if not passed:
		return false

	var source_size := Vector2(float(image.get_width()), float(image.get_height()))
	var render_source_size: Vector2 = source_size
	var visual_center_in_source := Vector2(alpha_bbox.x + alpha_bbox.z * 0.5, alpha_bbox.y + alpha_bbox.w * 0.5)
	if runtime_region == "alpha_bbox":
		render_source_size = Vector2(alpha_bbox.z, alpha_bbox.w)
		visual_center_in_source = render_source_size * 0.5

	var button_rect := Rect2(Vector2(button_region.x, button_region.y), Vector2(button_region.z, button_region.w))
	var scale: float = min(button_rect.size.x / render_source_size.x, button_rect.size.y / render_source_size.y)
	var draw_size: Vector2 = render_source_size * scale
	var draw_origin: Vector2 = button_rect.position + (button_rect.size - draw_size) * 0.5
	var visual_center: Vector2 = draw_origin + visual_center_in_source * scale
	var icon_center := Vector2(icon_region.x + icon_region.z * 0.5, icon_region.y + icon_region.w * 0.5)
	var delta: float = visual_center.distance_to(icon_center)
	passed = passed and _assert_true(
		delta <= CENTER_TOLERANCE_PX,
		"%s visual center should align with owner icon region, delta %.2f px" % [asset_key, delta]
	)
	return passed

func _get_runtime_region_for_mode(geometry: Dictionary, mode: String) -> String:
	var by_mode: Dictionary = geometry.get("runtime_region_by_mode", {})
	if by_mode.has(mode):
		return String(by_mode[mode])
	return String(geometry.get("runtime_region", "alpha_bbox"))

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
