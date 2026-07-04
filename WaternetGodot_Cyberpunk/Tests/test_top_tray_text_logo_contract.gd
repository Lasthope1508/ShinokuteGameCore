extends SceneTree

const GAME_SCENE_PATH := "res://Scenes/Gameplay/GameScene.tscn"
const THEME_PATH := "res://Resources/Data/Themes/cyberpunk_theme.tres"
const LOGO_PATH := "res://Assets/Icons/logo.png"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	var scene: PackedScene = load(GAME_SCENE_PATH)
	var theme: ThemeConfig = load(THEME_PATH)
	passed = passed and _assert_true(scene != null, "GameScene should load")
	passed = passed and _assert_true(theme != null, "Cyber theme should load")
	if scene != null and theme != null:
		root.size = Vector2i(720, 1280)
		var instance = scene.instantiate()
		instance.active_theme_override = theme
		root.add_child(instance)
		await process_frame
		passed = passed and _assert_true(instance.top_tray_layer.get_node_or_null("StatsCapsule/StatsReadout/LevelLabel") == null, "Legacy LevelLabel should not exist")
		passed = passed and _assert_true(instance.top_tray_layer.get_node_or_null("StatsCapsule/StatsReadout/MovesLabel") == null, "Legacy MovesLabel should not exist")
		passed = passed and _assert_true(instance.top_tray_layer.get_node_or_null("StatsCapsule/StatsReadout/BestLabel") == null, "Legacy BestLabel should not exist")
		instance.level_id = 16
		instance.moves = 0
		instance._update_hud()
		instance._apply_generated_ui_assets(theme)
		instance._apply_top_tray_theme(theme)
		passed = passed and _assert_true(instance.top_tray_layer.get_node_or_null("TopLeftStatLabel") == null, "TopLeftStatLabel should not exist in icon-only top tray")
		passed = passed and _assert_true(instance.top_tray_layer.get_node_or_null("TopRightStatLabel") == null, "TopRightStatLabel should not exist in icon-only top tray")
		passed = passed and _assert_true(instance.left_stats_label is Label, "LeftStatsLabel should exist for player/best wave")
		passed = passed and _assert_true(instance.total_play_time_label is Label, "TotalPlayTimeLabel should exist as the top-right moves readout")
		passed = passed and _assert_true(instance._format_left_stats_text("NEONFOX", 23) == "NEONFOX\nBEST WAVE 23", "Left stats should format name over best wave")
		passed = passed and _assert_true(instance.logo_core.visible, "LogoCore should render after owner-approved placement")
		passed = passed and _assert_logo_uses_project_atlas(instance.logo_core, "LogoCore should use trimmed project logo atlas")
		passed = passed and _assert_true(instance.total_play_time_label.visible, "Top-right moves readout should render after owner-approved placement")
		instance.level_start_time_sec = 100.0
		instance.level_finished_time_sec = -1.0
		instance._update_total_play_time_label(100.0)
		passed = passed and _assert_true(instance.total_play_time_label.text == "MOVES 0", "Top-right readout should show moves only after elapsed timer moves to bottom tray")
		passed = passed and _assert_true(instance.top_tray_layer.get_node_or_null("GeneratedStatsCapsule") == null, "Stats capsule should stay inactive unless ui_top_tray_art_stack enables it")
		passed = passed and _assert_true(instance.top_tray_layer.get_node_or_null("GeneratedLogoSocket") == null, "Logo socket should stay inactive unless ui_top_tray_art_stack enables it")
		passed = passed and _assert_true(instance.left_floating_menu.text.is_empty(), "Menu button should be icon-only")
		passed = passed and _assert_true(instance.right_floating_replay.text.is_empty(), "Replay button should be icon-only")
		passed = passed and _assert_true(theme.ui_top_tray_button_icon_source == "baked_texture", "Top tray floating button icons should be baked into generated button PNGs")
		passed = passed and _assert_baked_button_texture(instance.left_floating_menu, "GeneratedMenuButton", theme.get_ui_generated_asset_path(String(theme.ui_generated_asset_mode), "floating_menu_button_default"), "Menu button should use baked icon button texture")
		passed = passed and _assert_baked_button_texture(instance.right_floating_replay, "GeneratedReplayButton", theme.get_ui_generated_asset_path(String(theme.ui_generated_asset_mode), "floating_replay_button_default"), "Replay button should use baked icon button texture")
		var logo_size := _read_png_size(LOGO_PATH)
		passed = passed and _assert_true(logo_size == Vector2i(423, 485), "Project logo should be physically trimmed to 423x485")
		if logo_size == Vector2i(423, 485):
			passed = passed and _assert_true(theme.ui_project_logo_alpha_bbox == Vector4(0, 0, 423, 485), "Logo bbox should cover full trimmed image")
		var basis: Rect2 = instance._get_top_tray_region_basis(theme, instance.top_tray_root.custom_minimum_size)
		var regions: Dictionary = theme.ui_top_tray_regions
		passed = passed and _assert_region_rect(instance.left_floating_menu, regions["left_floating_menu"], basis, "Menu should occupy left_floating_menu")
		passed = passed and _assert_region_rect(instance.right_floating_replay, regions["right_floating_replay"], basis, "Replay should occupy right_floating_replay")
		passed = passed and _assert_true(instance.left_floating_menu.get_node_or_null("GeneratedButtonIcon") == null, "Menu button should not create runtime icon overlay when icon is baked")
		passed = passed and _assert_true(instance.right_floating_replay.get_node_or_null("GeneratedButtonIcon") == null, "Replay button should not create runtime icon overlay when icon is baked")
		passed = passed and _assert_region_rect(instance.logo_core, regions["logo_core"], basis, "Logo should occupy owner-approved logo_core")
		passed = passed and _assert_region_rect(instance.left_stats_label, regions["left_stats_readout"], basis, "Left stats should occupy owner-approved left_stats_readout")
		passed = passed and _assert_left_stats_label_style(instance.left_stats_label, theme, "Left stats should use cyber info typography from SSOT")
		passed = passed and _assert_true(instance.left_stats_label.clip_contents, "Left stats owner region should hard-clip visual glyph overflow")
		passed = passed and _assert_info_label_visual_bounds(instance.left_stats_label, theme, "Left stats glyph bounds should stay inside owner region")
		passed = passed and _assert_region_rect(instance.total_play_time_label, regions["total_play_time_readout"], basis, "Top-right moves should occupy owner-approved total_play_time_readout")
		passed = passed and _assert_time_label_style(instance.total_play_time_label, theme, "Top-right moves should use cyber time typography from SSOT")
		passed = passed and _assert_true(instance.total_play_time_label.clip_contents, "Top-right moves owner region should hard-clip visual glyph overflow")
		passed = passed and _assert_info_label_visual_bounds(instance.total_play_time_label, theme, "Top-right moves glyph bounds should stay inside owner region")
		instance.level_start_time_sec = 10.0
		instance.level_finished_time_sec = -1.0
		instance._update_total_play_time_label(83.0)
		passed = passed and _assert_true(instance.total_play_time_label.text == "MOVES 0", "Top-right moves should not duplicate running elapsed seconds")
		instance.level_finished_time_sec = 95.0
		instance.moves = 7
		instance._update_top_right_stats_label()
		passed = passed and _assert_true(instance.total_play_time_label.text == "MOVES 7", "Top-right moves should reflect solved round moves")
		root.remove_child(instance)
		instance.free()
		var audio_manager := root.get_node_or_null("AudioManager")
		if audio_manager != null and audio_manager.has_method("stop_music"):
			audio_manager.stop_music()
			var music_player = audio_manager.get("_music_player")
			if music_player is AudioStreamPlayer:
				(music_player as AudioStreamPlayer).stream = null
		await process_frame
	if passed:
		print("test_top_tray_text_logo_contract: PASS")
		quit(0)
	else:
		print("test_top_tray_text_logo_contract: FAIL")
		quit(1)

func _assert_region_rect(control: Control, region: Vector4, basis: Rect2, message: String) -> bool:
	if control == null:
		push_error("%s: control missing" % message)
		return false
	var expected := Rect2(
		basis.position + Vector2(region.x * basis.size.x, region.y * basis.size.y),
		Vector2(region.z * basis.size.x, region.w * basis.size.y)
	)
	var actual := Rect2(Vector2(control.offset_left, control.offset_top), Vector2(control.offset_right - control.offset_left, control.offset_bottom - control.offset_top))
	if actual.position.distance_to(expected.position) > 1.0 or actual.size.distance_to(expected.size) > 1.0:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true

func _assert_baked_button_texture(button: Button, rect_name: String, expected_path: String, message: String) -> bool:
	if button == null:
		push_error("%s: expected button" % message)
		return false
	var texture_rect := button.get_node_or_null(rect_name) as TextureRect
	if texture_rect == null:
		push_error("%s: expected %s" % [message, rect_name])
		return false
	if not _texture_uses_path(texture_rect.texture, expected_path):
		push_error("%s: expected %s" % [message, expected_path])
		return false
	if button.get_node_or_null("GeneratedButtonIcon") != null:
		push_error("%s: runtime icon overlay should not exist" % message)
		return false
	return true

func _texture_uses_path(texture: Texture2D, expected_path: String) -> bool:
	if texture == null:
		return false
	if texture.resource_path == expected_path:
		return true
	if texture is AtlasTexture:
		var atlas := texture as AtlasTexture
		return atlas.atlas != null and atlas.atlas.resource_path == expected_path
	return false

func _assert_time_label_style(label: Label, theme: ThemeConfig, message: String) -> bool:
	if label == null:
		push_error("%s: expected Label" % message)
		return false
	if label.horizontal_alignment != HORIZONTAL_ALIGNMENT_RIGHT or label.vertical_alignment != VERTICAL_ALIGNMENT_CENTER:
		push_error("%s: expected right/center alignment" % message)
		return false
	if label.get_theme_color("font_color") != theme.ui_top_tray_time_color:
		push_error("%s: expected time font color from ThemeConfig" % message)
		return false
	if label.get_theme_color("font_outline_color") != theme.ui_top_tray_time_outline_color:
		push_error("%s: expected time outline color from ThemeConfig" % message)
		return false
	if label.get_theme_constant("outline_size") != theme.ui_top_tray_time_outline_size:
		push_error("%s: expected time outline size from ThemeConfig" % message)
		return false
	var font := label.get_theme_font("font")
	if font == null or font.resource_path != theme.ui_top_tray_time_font_path:
		push_error("%s: expected time font %s" % [message, theme.ui_top_tray_time_font_path])
		return false
	return true

func _assert_left_stats_label_style(label: Label, theme: ThemeConfig, message: String) -> bool:
	if label == null:
		push_error("%s: expected Label" % message)
		return false
	if label.horizontal_alignment != HORIZONTAL_ALIGNMENT_LEFT or label.vertical_alignment != VERTICAL_ALIGNMENT_CENTER:
		push_error("%s: expected left/center alignment" % message)
		return false
	if label.get_theme_color("font_color") != theme.ui_top_tray_time_color:
		push_error("%s: expected info font color from ThemeConfig" % message)
		return false
	if label.get_theme_color("font_outline_color") != theme.ui_top_tray_time_outline_color:
		push_error("%s: expected info outline color from ThemeConfig" % message)
		return false
	var font := label.get_theme_font("font")
	if font == null or font.resource_path != theme.ui_top_tray_time_font_path:
		push_error("%s: expected info font %s" % [message, theme.ui_top_tray_time_font_path])
		return false
	return true

func _assert_info_label_visual_bounds(label: Label, theme: ThemeConfig, message: String) -> bool:
	if label == null:
		push_error("%s: expected Label" % message)
		return false
	var font := label.get_theme_font("font")
	if font == null:
		push_error("%s: expected font" % message)
		return false
	var font_size := label.get_theme_font_size("font_size")
	var outline := label.get_theme_constant("outline_size")
	var rect_size := Vector2(label.offset_right - label.offset_left, label.offset_bottom - label.offset_top)
	var usable: Vector2 = rect_size * (1.0 - theme.ui_top_tray_time_fit_padding_ratio * 2.0)
	var lines := String(label.text).split("\n")
	var max_width := 0.0
	for line in lines:
		max_width = max(max_width, font.get_string_size(String(line), HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x)
	var line_height: float = float(font_size) * max(0.1, theme.ui_top_tray_stat_line_height_ratio) * float(max(1, lines.size()))
	if max_width + float(outline * 2) > usable.x + 0.5:
		push_error("%s: width expected <= %s, got %s" % [message, str(usable.x), str(max_width + float(outline * 2))])
		return false
	if line_height + float(outline * 2) > usable.y + 0.5:
		push_error("%s: height expected <= %s, got %s" % [message, str(usable.y), str(line_height + float(outline * 2))])
		return false
	return true

func _assert_logo_uses_project_atlas(texture_rect: TextureRect, message: String) -> bool:
	if texture_rect == null:
		push_error("%s: expected TextureRect" % message)
		return false
	if not (texture_rect.texture is AtlasTexture):
		push_error("%s: expected AtlasTexture" % message)
		return false
	var atlas := texture_rect.texture as AtlasTexture
	if atlas.atlas == null or atlas.atlas.resource_path != LOGO_PATH:
		push_error("%s: expected atlas source %s" % [message, LOGO_PATH])
		return false
	if atlas.region.size.x <= 0.0 or atlas.region.size.y <= 0.0:
		push_error("%s: expected non-empty atlas region" % message)
		return false
	return true

func _read_png_size(path: String) -> Vector2i:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return Vector2i.ZERO
	if file.get_length() < 24:
		return Vector2i.ZERO
	file.big_endian = true
	file.seek(16)
	var width := file.get_32()
	var height := file.get_32()
	return Vector2i(width, height)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
