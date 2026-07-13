extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"
const CHECKLIST := "res://docs/reskin_checklist.md"
const MANIFEST := "res://docs/asset_manifest.md"
const STATE := "res://docs/reskin_state.md"
const THEME := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	var packed_scene := load(MAIN_SCENE) as PackedScene
	var theme := load(THEME)
	passed = _assert_true(packed_scene != null, "Main scene should load") and passed
	passed = _assert_true(theme != null, "Candy theme should load") and passed
	if packed_scene == null:
		_finish(false)
		return

	var scene := packed_scene.instantiate()
	_disable_audio_autoplay(scene)
	root.add_child(scene)
	root.size = Vector2i(1280, 720)
	await process_frame

	var frame := scene.get_node_or_null("HUD/CandyScoreFrame") as TextureRect
	passed = _assert_true(frame != null, "HUD CandyScoreFrame should exist") and passed
	if frame != null:
		passed = _assert_true(frame.expand_mode == TextureRect.EXPAND_IGNORE_SIZE, "HUD frame should ignore natural texture size") and passed
		passed = _assert_true(frame.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "HUD frame should preserve aspect inside explicit rect") and passed
		passed = _assert_true(frame.size.x <= 360.0 and frame.size.y <= 160.0, "HUD frame rect should stay compact, got %s" % frame.size) and passed
		if theme != null:
			passed = _assert_true(theme.hud_score_frame_rect == Rect2(40.0, 45.0, 313.0, 127.0), "HUD frame rect should live in theme SSOT") and passed
			passed = _assert_true(frame.position == theme.hud_score_frame_rect.position, "HUD frame position should match theme SSOT") and passed
			passed = _assert_true(frame.size == theme.hud_score_frame_rect.size, "HUD frame size should match theme SSOT") and passed
		if frame.texture != null:
			passed = _assert_true(frame.texture.get_width() > frame.size.x * 2.0, "HUD test should cover oversized source texture") and passed

	var coins := scene.get_node_or_null("HUD/Coins") as Label
	passed = _assert_true(coins != null, "HUD coin label should exist") and passed
	if coins != null:
		passed = _assert_true(coins.size.x <= 240.0 and coins.size.y <= 80.0, "HUD coin label should stay compact, got %s" % coins.size) and passed
		if frame != null:
			var frame_rect := Rect2(frame.position, frame.size)
			var text_rect := Rect2(coins.position, coins.size)
			passed = _assert_true(frame_rect.encloses(text_rect), "HUD coin label should stay inside score frame, got text %s frame %s" % [text_rect, frame_rect]) and passed
			passed = _assert_true(text_rect.position.x >= frame_rect.position.x + 118.0, "HUD coin label should start after star icon area, got x=%s" % text_rect.position.x) and passed
			passed = _assert_true(text_rect.position.y >= frame_rect.position.y + 28.0, "HUD coin label should be vertically centered in frame, got y=%s" % text_rect.position.y) and passed
			passed = _assert_true(text_rect.end.x <= frame_rect.end.x - 26.0, "HUD coin label should keep right padding, got end x=%s" % text_rect.end.x) and passed
			passed = _assert_true(text_rect.end.y <= frame_rect.end.y - 20.0, "HUD coin label should keep bottom padding, got end y=%s" % text_rect.end.y) and passed
		if theme != null:
			passed = _assert_true(theme.hud_text_owner_rect == Rect2(160.0, 88.0, 160.0, 54.0), "HUD text owner rect should be tuned for cleaned frame visual baseline") and passed
			passed = _assert_true(theme.hud_font_size <= 44, "HUD font size should fit cleaned frame, got %s" % theme.hud_font_size) and passed
			passed = _assert_true(coins.get_theme_color("font_color") == theme.palette_text, "HUD coin label theme color should use palette text") and passed
			passed = _assert_true(coins.label_settings != null and coins.label_settings.font_color == theme.palette_text, "HUD coin label settings should not remain default white") and passed
			passed = _assert_true(coins.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "HUD coin label should center number horizontally inside owner rect") and passed
			passed = _assert_true(coins.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "HUD coin label should center number vertically inside owner rect") and passed

	var level := scene.get_node_or_null("HUD/Level") as Label
	passed = _assert_true(level != null, "HUD level label should exist") and passed
	if level != null:
		passed = _assert_true(level.text == "LEVEL 1", "HUD level label should show current level number") and passed
		passed = _assert_true(level.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "HUD level label should center text horizontally") and passed
		passed = _assert_true(level.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "HUD level label should center text vertically") and passed
		passed = _assert_true(level.label_settings != null and level.label_settings.font_size <= 28, "HUD level label font should be compact and not reuse score size") and passed
		passed = _assert_true(level.label_settings != null and _contrast_ratio(level.label_settings.font_color, Color("#273043")) >= 4.5, "HUD level label text must stay readable over dark gameplay background") and passed
		passed = _assert_true(level.label_settings != null and level.label_settings.outline_size >= 4, "HUD level label must use dark outline because it floats over gameplay, not a light frame") and passed
		passed = _assert_true(level.label_settings != null and _contrast_ratio(level.label_settings.font_color, level.label_settings.outline_color) >= 4.5, "HUD level label text and outline must have readable contrast") and passed
		if frame != null:
			var frame_rect := Rect2(frame.position, frame.size)
			var level_rect := Rect2(level.position, level.size)
			passed = _assert_true(not frame_rect.intersects(level_rect), "HUD level label should not overlap score frame, got level %s frame %s" % [level_rect, frame_rect]) and passed
		if theme != null:
			passed = _assert_true("hud_level_rect" in theme, "Candy theme should own HUD level label rect in SSOT") and passed
			passed = _assert_true("hud_level_font_size" in theme, "Candy theme should own HUD level font size in SSOT") and passed
			passed = _assert_true("hud_level_font_color" in theme, "Candy theme should own HUD level font color in SSOT") and passed
			passed = _assert_true("hud_level_outline_color" in theme, "Candy theme should own HUD level outline color in SSOT") and passed
			passed = _assert_true("hud_level_outline_size" in theme, "Candy theme should own HUD level outline size in SSOT") and passed

	passed = _assert_file_contains(CHECKLIST, "ignore natural texture size", "Checklist should include HUD natural-size rule") and passed
	passed = _assert_file_contains(MANIFEST, "hud_score_frame_rect", "Manifest should record HUD frame SSOT rect") and passed
	passed = _assert_file_contains(STATE, "HUD layout contract", "State should record HUD layout validation") and passed

	_stop_audio_streams(scene)
	root.remove_child(scene)
	scene.free()
	await process_frame
	_finish(passed)

func _stop_audio_streams(node: Node) -> void:
	if node is AudioStreamPlayer:
		var player := node as AudioStreamPlayer
		player.stop()
		player.stream = null
	for child in node.get_children():
		_stop_audio_streams(child)

func _disable_audio_autoplay(node: Node) -> void:
	if node is AudioStreamPlayer:
		var player := node as AudioStreamPlayer
		player.autoplay = false
		player.stop()
		player.stream = null
	for child in node.get_children():
		_disable_audio_autoplay(child)

func _assert_file_contains(path: String, needle: String, message: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("%s: missing %s" % [message, path])
		return false
	var text := FileAccess.get_file_as_string(path)
	if not text.contains(needle):
		push_error("%s: missing '%s'" % [message, needle])
		return false
	return true

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true

func _contrast_ratio(a: Color, b: Color) -> float:
	var lighter := maxf(_relative_luminance(a), _relative_luminance(b))
	var darker := minf(_relative_luminance(a), _relative_luminance(b))
	return (lighter + 0.05) / (darker + 0.05)

func _relative_luminance(color: Color) -> float:
	return 0.2126 * _linear_channel(color.r) + 0.7152 * _linear_channel(color.g) + 0.0722 * _linear_channel(color.b)

func _linear_channel(value: float) -> float:
	if value <= 0.03928:
		return value / 12.92
	return pow((value + 0.055) / 1.055, 2.4)

func _finish(passed: bool) -> void:
	if passed:
		print("test_hud_layout_contract: PASS")
		quit(0)
	else:
		print("test_hud_layout_contract: FAIL")
		quit(1)
