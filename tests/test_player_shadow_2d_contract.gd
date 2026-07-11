extends SceneTree

const SHADOW_PATH := "res://assets/themes/candy_sky_islands/player_shadow_soft.png"
const PLAYER_SCENE := "res://objects/player.tscn"
const THEME_PATH := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"

func _init() -> void:
	var passed := true
	passed = _assert_shadow_image() and passed
	passed = _assert_player_scene() and passed
	passed = _assert_theme_role() and passed
	if passed:
		print("test_player_shadow_2d_contract: PASS")
		quit(0)
	else:
		print("test_player_shadow_2d_contract: FAIL")
		quit(1)

func _assert_shadow_image() -> bool:
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(SHADOW_PATH))
	if error != OK:
		push_error("Player shadow image should load: %s" % SHADOW_PATH)
		return false
	var alpha_extrema := _alpha_extrema(image)
	return _assert_true(image.get_width() == 256 and image.get_height() == 256, "Player shadow must preserve 256x256 baseline") \
		and _assert_true(alpha_extrema.x == 0, "Player shadow alpha must include transparent pixels") \
		and _assert_true(alpha_extrema.y >= 180, "Player shadow alpha must have enough opacity for Decal read") \
		and _assert_true(_edge_alpha_ratio(image) == 0.0, "Player shadow must not touch crop edges")

func _assert_player_scene() -> bool:
	var text := FileAccess.get_file_as_string(PLAYER_SCENE)
	var passed := true
	passed = _assert_true(text.contains(SHADOW_PATH), "Player scene should use Candy shadow texture") and passed
	passed = _assert_true(not text.contains("texture_albedo = ExtResource(\"3_0c7wt\")") or not text.contains("res://sprites/blob_shadow.png"), "Player scene should not route Shadow decal to legacy texture") and passed
	passed = _assert_true(text.contains("size = Vector3(1, 2, 1)"), "Player shadow Decal size must preserve Vector3(1, 2, 1)") and passed
	return passed

func _assert_theme_role() -> bool:
	var theme := load(THEME_PATH)
	if theme == null:
		push_error("Candy theme should load")
		return false
	var role = theme.get("player_shadow_role")
	if role == null:
		push_error("player_shadow_role should exist")
		return false
	return _assert_true(role.legacy_path == "res://sprites/blob_shadow.png", "player_shadow_role should preserve legacy source path") \
		and _assert_true(role.replacement_path == SHADOW_PATH, "player_shadow_role should point at Candy replacement") \
		and _assert_true(role.mode == "replacement", "player_shadow_role should be replacement mode") \
		and _assert_true(role.active_path() == SHADOW_PATH, "player_shadow_role active path should use Candy shadow")

func _alpha_extrema(image: Image) -> Vector2i:
	var min_alpha := 255
	var max_alpha := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var alpha := image.get_pixel(x, y).a8
			min_alpha = min(min_alpha, alpha)
			max_alpha = max(max_alpha, alpha)
	return Vector2i(min_alpha, max_alpha)

func _edge_alpha_ratio(image: Image) -> float:
	var edge_count := 0
	var active_count := 0
	for x in range(image.get_width()):
		edge_count += 2
		if image.get_pixel(x, 0).a8 > 8:
			active_count += 1
		if image.get_pixel(x, image.get_height() - 1).a8 > 8:
			active_count += 1
	for y in range(image.get_height()):
		edge_count += 2
		if image.get_pixel(0, y).a8 > 8:
			active_count += 1
		if image.get_pixel(image.get_width() - 1, y).a8 > 8:
			active_count += 1
	return float(active_count) / float(edge_count)

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true
