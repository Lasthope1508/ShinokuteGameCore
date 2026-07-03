extends SceneTree

const GAME_SCENE_SCRIPT := "res://Scenes/Gameplay/GameScene.gd"
const GAME_SCENE_PATH := "res://Scenes/Gameplay/GameScene.tscn"
const THEME_PATH := "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	var file := FileAccess.open(GAME_SCENE_SCRIPT, FileAccess.READ)
	passed = passed and _assert_true(file != null, "GameScene script should open")
	var source := file.get_as_text() if file != null else ""
	for required_text in [
		"_apply_generated_ui_assets",
		"_apply_generated_top_tray_art_stack",
		"_ensure_generated_ui_texture_rect",
		"get_ui_generated_asset_texture",
		"ui_generated_asset_mode",
		"ui_top_tray_art_stack",
		"ui_top_tray_button_icon_paths",
		"_set_generated_top_tray_stack_texture",
		"_apply_top_tray_button_icon",
		"_set_generated_top_tray_regions_texture",
		"_get_top_tray_regions_rect",
		"top_tray_layer",
		"stats_capsule",
		"logo_core",
		"left_stats_label",
		"_update_left_stats_label",
		"_format_left_stats_text",
		"total_play_time_label",
		"_update_total_play_time_label",
		"_format_duration_seconds",
		"floating_menu_button_default",
		"floating_replay_button_default",
		"bottom_reserve_layer",
		"modal_frame"
	]:
		passed = passed and _assert_true(source.contains(required_text), "GameScene should contain generated UI hook %s" % required_text)
	passed = passed and _assert_true(not source.contains("func _apply_top_tray_region(control: Control, theme: ThemeConfig, region_key: String, fallback: Vector4"), "Top tray region placement should not accept hardcoded fallback rectangles")
	passed = passed and _assert_true(not source.contains("_apply_top_tray_region(logo_core, theme, \"logo_core\", Vector4"), "Logo region should come from ThemeConfig.ui_top_tray_regions only")
	passed = passed and _assert_true(not source.contains("_apply_top_tray_region(left_floating_menu, theme, \"left_floating_menu\", Vector4"), "Menu region should come from ThemeConfig.ui_top_tray_regions only")
	passed = passed and _assert_true(not source.contains("_apply_top_tray_region(right_floating_replay, theme, \"right_floating_replay\", Vector4"), "Replay region should come from ThemeConfig.ui_top_tray_regions only")
	passed = passed and _assert_true(not source.contains("_apply_top_tray_region(left_stats_label, theme, \"left_stats_readout\", Vector4"), "Left stats region should come from ThemeConfig.ui_top_tray_regions only")
	passed = passed and _assert_true(not source.contains("_apply_top_tray_region(total_play_time_label, theme, \"total_play_time_readout\", Vector4"), "Total play time region should come from ThemeConfig.ui_top_tray_regions only")
	passed = passed and _assert_true(not source.contains("_apply_top_tray_region(level_label, theme, \"left_stats_readout\", Vector4"), "Left stat region should come from ThemeConfig.ui_top_tray_regions only")
	passed = passed and _assert_true(not source.contains("_apply_top_tray_region(best_label, theme, \"right_stats_readout\", Vector4"), "Right stat region should come from ThemeConfig.ui_top_tray_regions only")
	passed = passed and _assert_true(not source.contains("level_label"), "Top tray text should not keep legacy LevelLabel script references")
	passed = passed and _assert_true(not source.contains("@onready var moves_label") and not source.contains("/MovesLabel"), "Top tray text should not keep legacy MovesLabel script references")
	passed = passed and _assert_true(not source.contains("best_label"), "Top tray text should not keep legacy BestLabel script references")

	var scene: PackedScene = load(GAME_SCENE_PATH)
	var theme = load(THEME_PATH)
	passed = passed and _assert_true(scene != null, "GameScene scene should load")
	passed = passed and _assert_true(theme != null, "Cyber theme should load")
	if scene != null and theme != null:
		root.size = Vector2i(1280, 720)
		var instance = scene.instantiate()
		instance.hud_margin_container = instance.get_node("HUD/MarginContainer")
		instance.top_tray_root = instance.get_node("HUD/MarginContainer/VBoxContainer/TopTrayRoot")
		instance.top_tray_layer = instance.get_node("HUD/MarginContainer/VBoxContainer/TopTrayRoot/TopTrayLayer")
		instance.stats_capsule = instance.get_node("HUD/MarginContainer/VBoxContainer/TopTrayRoot/TopTrayLayer/StatsCapsule")
		instance.logo_core = instance.get_node("HUD/MarginContainer/VBoxContainer/TopTrayRoot/TopTrayLayer/LogoCore")
		instance.left_stats_label = instance.get_node("HUD/MarginContainer/VBoxContainer/TopTrayRoot/TopTrayLayer/LeftStatsLabel")
		instance.total_play_time_label = instance.get_node("HUD/MarginContainer/VBoxContainer/TopTrayRoot/TopTrayLayer/TotalPlayTimeLabel")
		instance.left_floating_menu = instance.get_node("HUD/MarginContainer/VBoxContainer/TopTrayRoot/TopTrayLayer/LeftFloatingMenu")
		instance.right_floating_replay = instance.get_node("HUD/MarginContainer/VBoxContainer/TopTrayRoot/TopTrayLayer/RightFloatingReplay")
		instance.bottom_reserve_layer = instance.get_node("HUD/BottomReserveLayer")
		instance.settings_overlay = instance.get_node("HUD/SettingsOverlay")
		instance.solved_popup = instance.get_node("HUD/SolvedPopup")
		instance.leaderboard_overlay_root = instance.get_node("HUD/LeaderboardOverlayRoot")
		instance.active_theme_override = theme
		root.add_child(instance)
		passed = passed and _assert_true(not (instance.top_tray_layer is Container), "TopTrayLayer should not be a Container because floating children use anchors")
		passed = passed and _assert_true(not (instance.settings_overlay is Container), "SettingsOverlay should not be a Container because modal frame, close button, and content use anchors")
		passed = passed and _assert_true(not (instance.solved_popup is Container), "SolvedPopup should not be a Container because generated modal frame uses anchors")
		instance.level_id = 16
		instance.moves = 0
		instance._update_hud()
		passed = passed and _assert_true(instance.top_tray_layer.get_node_or_null("StatsCapsule/StatsReadout/LevelLabel") == null, "Legacy LevelLabel should be removed from the top tray")
		passed = passed and _assert_true(instance.top_tray_layer.get_node_or_null("StatsCapsule/StatsReadout/MovesLabel") == null, "Legacy MovesLabel should be removed from the top tray")
		passed = passed and _assert_true(instance.top_tray_layer.get_node_or_null("StatsCapsule/StatsReadout/BestLabel") == null, "Legacy BestLabel should be removed from the top tray")
		var direct_left_stat = instance.top_tray_layer.get_node_or_null("TopLeftStatLabel") as Label
		var direct_right_stat = instance.top_tray_layer.get_node_or_null("TopRightStatLabel") as Label
		passed = passed and _assert_true(direct_left_stat == null, "Icon-only top tray should not render left stat text")
		passed = passed and _assert_true(direct_right_stat == null, "Icon-only top tray should not render right stat text")
		instance._apply_generated_ui_assets(theme)
		passed = passed and _assert_true(instance.top_tray_layer.get_node_or_null("GeneratedTopTrayLayer") is TextureRect, "Top tray generated asset rect should exist")
		passed = passed and _assert_true(instance.top_tray_layer.get_node_or_null("GeneratedStatsCapsule") == null, "Stats capsule should not render when omitted from ui_top_tray_art_stack")
		passed = passed and _assert_true(instance.top_tray_layer.get_node_or_null("GeneratedLogoSocket") == null, "Logo socket should not render when omitted from ui_top_tray_art_stack")
		passed = passed and _assert_true(instance.logo_core is TextureRect, "Logo core should exist as a direct child of the top tray")
		passed = passed and _assert_true(instance.left_stats_label is Label, "Left stats should exist as a direct child of the top tray")
		passed = passed and _assert_true(instance.total_play_time_label is Label, "Total play time should exist as a direct child of the top tray")
		passed = passed and _assert_true(instance.bottom_reserve_layer.get_node_or_null("GeneratedBottomReserveLayer") is TextureRect, "Bottom reserve generated asset rect should exist")
		passed = passed and _assert_true(instance.settings_overlay.get_node_or_null("GeneratedModalFrame") is TextureRect, "Modal frame generated asset rect should exist")
		passed = passed and _assert_true(instance.solved_popup.get_node_or_null("GeneratedSolvedModalFrame") is TextureRect, "Solved popup generated modal frame should exist")
		var modal_asset = instance.settings_overlay.get_node_or_null("GeneratedModalFrame") as TextureRect
		var top_tray_asset = instance.top_tray_layer.get_node_or_null("GeneratedTopTrayLayer") as TextureRect
		var menu_asset = instance.left_floating_menu.get_node_or_null("GeneratedMenuButton") as TextureRect
		var replay_asset = instance.right_floating_replay.get_node_or_null("GeneratedReplayButton") as TextureRect
		passed = passed and _assert_true(top_tray_asset.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "Top tray generated object should fit/center, not cover/crop")
		passed = passed and _assert_true(menu_asset != null and not (menu_asset.texture is AtlasTexture), "Menu button shell should render owner-approved full PhotoRoom PNG, not alpha_bbox crop")
		passed = passed and _assert_true(replay_asset != null and not (replay_asset.texture is AtlasTexture), "Replay button shell should render owner-approved full PhotoRoom PNG, not alpha_bbox crop")
		passed = passed and _assert_true(modal_asset.stretch_mode == TextureRect.STRETCH_SCALE, "Modal frame should fill the modal rect until 9-slice slicing is implemented")
		passed = passed and _assert_true(instance._has_generated_ui_asset(theme, "top_tray_layer"), "Top tray generated asset path should be visible to GameScene")
		instance._apply_top_tray_theme(theme)
		if _has_property(theme, "ui_top_tray_landscape_width_height_ratio"):
			var viewport_height = instance.get_viewport_rect().size.y
			passed = passed and _assert_true(instance.top_tray_root.custom_minimum_size.x <= viewport_height * float(theme.get("ui_top_tray_landscape_width_height_ratio")) + 1.0, "Landscape top tray should be width-capped by SSOT so object asset is not stretched into a strip")
		if _has_property(theme, "ui_modal_landscape_width_ratio") and _has_property(theme, "ui_modal_landscape_height_ratio"):
			var viewport_size = instance.get_viewport_rect().size
			var expected_modal_width = viewport_size.x * float(theme.get("ui_modal_landscape_width_ratio"))
			var expected_modal_height = viewport_size.y * float(theme.get("ui_modal_landscape_height_ratio"))
			passed = passed and _assert_true(abs(instance.settings_overlay.size.x - expected_modal_width) <= 4.0, "Landscape settings modal width should come from SSOT ratio")
			passed = passed and _assert_true(abs(instance.settings_overlay.size.y - expected_modal_height) <= 4.0, "Landscape settings modal height should come from SSOT ratio")
		if _has_property(theme, "ui_top_tray_regions"):
			var regions: Dictionary = theme.get("ui_top_tray_regions")
			var logo_bbox: Vector4 = theme.get("ui_project_logo_alpha_bbox")
			var project_logo: Texture2D = load("res://Assets/Icons/logo.png")
			passed = passed and _assert_true(project_logo != null, "Project logo should load")
			if project_logo != null:
				passed = passed and _assert_true(logo_bbox == Vector4(0, 0, project_logo.get_width(), project_logo.get_height()), "Project logo should be physically trimmed; bbox should cover the full logo image")
			var tray_size = instance.top_tray_root.custom_minimum_size
			var region_basis: Rect2 = instance._get_top_tray_region_basis(theme, tray_size)
			passed = passed and _assert_true(not regions.has("stats_readout"), "Stats should not use one combined top tray region")
			direct_left_stat = instance.top_tray_layer.get_node_or_null("TopLeftStatLabel") as Label
			direct_right_stat = instance.top_tray_layer.get_node_or_null("TopRightStatLabel") as Label
			passed = passed and _assert_true(direct_left_stat == null, "Icon-only top tray should keep left stats absent after theme apply")
			passed = passed and _assert_true(direct_right_stat == null, "Icon-only top tray should keep right stats absent after theme apply")
			passed = passed and _assert_true(instance.logo_core.visible, "Top tray should render project logo after logo placement approval")
			passed = passed and _assert_logo_uses_project_atlas(instance.logo_core, "LogoCore should use trimmed project logo atlas")
			passed = passed and _assert_true(instance.left_stats_label.visible, "Top tray should render left stats after owner placement approval")
			passed = passed and _assert_true(instance.left_stats_label.text.contains("\n" + String(theme.ui_top_tray_best_wave_label_prefix)), "Left stats should include SSOT best wave prefix on second line")
			passed = passed and _assert_left_stats_label_style(instance.left_stats_label, theme, "Left stats should use cyber info style")
			passed = passed and _assert_true(instance.left_stats_label.clip_contents, "Left stats should clip to owner region")
			passed = passed and _assert_true(instance.total_play_time_label.visible, "Top tray should render total play time after owner placement approval")
			passed = passed and _assert_true(instance.total_play_time_label.text.contains("\n" + String(theme.ui_top_tray_moves_label_prefix)), "Total play time should include SSOT moves prefix on second line")
			passed = passed and _assert_time_label_style(instance.total_play_time_label, theme, "Total play time should use cyber time style")
			passed = passed and _assert_true(instance.total_play_time_label.clip_contents, "Total play time should clip to owner region")
			passed = passed and _assert_true(instance.left_floating_menu.text.is_empty(), "Menu should be icon-only")
			passed = passed and _assert_true(instance.right_floating_replay.text.is_empty(), "Replay should be icon-only")
			passed = passed and _assert_button_icon(instance.left_floating_menu, "res://Assets/Icons/menuList.png", "Menu button should render settings/menu symbol overlay")
			passed = passed and _assert_button_icon(instance.right_floating_replay, "res://Assets/Icons/return.png", "Replay button should render replay symbol overlay")
			passed = passed and _assert_true(theme.ui_top_tray_art_stack == ["top_tray_layer"], "Current cyber top tray stack should use top_tray_layer only")
			passed = passed and _assert_region_rect(instance.left_floating_menu, regions.get("left_floating_menu", Vector4.ZERO), region_basis, "Menu button should use top tray left_floating_menu region")
			passed = passed and _assert_region_rect(instance.right_floating_replay, regions.get("right_floating_replay", Vector4.ZERO), region_basis, "Replay button should use top tray right_floating_replay region")
			passed = passed and _assert_child_region_rect(instance.left_floating_menu.get_node_or_null("GeneratedButtonIcon") as Control, instance.left_floating_menu, regions.get("left_floating_menu_icon", Vector4.ZERO), region_basis, "Menu icon should use top tray left_floating_menu_icon region")
			passed = passed and _assert_child_region_rect(instance.right_floating_replay.get_node_or_null("GeneratedButtonIcon") as Control, instance.right_floating_replay, regions.get("right_floating_replay_icon", Vector4.ZERO), region_basis, "Replay icon should use top tray right_floating_replay_icon region")
			passed = passed and _assert_region_rect(instance.logo_core, regions.get("logo_core", Vector4.ZERO), region_basis, "Logo should use top tray logo_core region")
			passed = passed and _assert_region_rect(instance.left_stats_label, regions.get("left_stats_readout", Vector4.ZERO), region_basis, "Left stats should use top tray left_stats_readout region")
			passed = passed and _assert_region_rect(instance.total_play_time_label, regions.get("total_play_time_readout", Vector4.ZERO), region_basis, "Total play time should use top tray total_play_time_readout region")
		passed = passed and _assert_generated_style_transparent(instance.top_tray_layer.get_theme_stylebox("panel"), "Top tray panel should not paint legacy procedural backing in generated UI mode")
		passed = passed and _assert_generated_style_transparent(instance.stats_capsule.get_theme_stylebox("panel"), "Stats capsule panel should not paint legacy procedural backing in generated UI mode")
		passed = passed and _assert_generated_style_transparent(instance.bottom_reserve_layer.get_theme_stylebox("panel"), "Bottom reserve panel should not paint legacy procedural backing in generated UI mode")
		passed = passed and _assert_generated_style_transparent(instance.settings_overlay.get_theme_stylebox("panel"), "Settings modal shell should not paint legacy procedural backing when modal frame asset exists")
		passed = passed and _assert_generated_style_transparent(instance.solved_popup.get_theme_stylebox("panel"), "Solved popup shell should not paint legacy procedural backing when modal frame asset exists")
		passed = passed and _assert_generated_style_transparent(instance.left_floating_menu.get_theme_stylebox("normal"), "Menu button should use transparent hitbox when generated button asset exists")
		passed = passed and _assert_generated_style_transparent(instance.right_floating_replay.get_theme_stylebox("normal"), "Replay button should use transparent hitbox when generated button asset exists")
		passed = passed and _assert_true(instance.settings_close_btn.size.x <= theme.ui_modal_close_button_size + 4.0 and instance.settings_close_btn.size.y <= theme.ui_modal_close_button_size + 4.0, "Settings close button should stay a corner utility button")
		instance._on_leaderboard_btn_pressed()
		passed = passed and _assert_true(instance.leaderboard_overlay_root.visible, "Leaderboard overlay root should become visible")
		passed = passed and _assert_true(instance.leaderboard_overlay_root.get_child_count() == 1, "Leaderboard overlay should contain one popup")
		if instance.leaderboard_overlay_root.get_child_count() == 1:
			var leaderboard_popup = instance.leaderboard_overlay_root.get_child(0)
			passed = passed and _assert_true(leaderboard_popup.get_node_or_null("GeneratedModalFrame") is TextureRect, "Leaderboard popup should receive generated modal frame")
			var viewport_size_for_leaderboard = instance.get_viewport_rect().size
			passed = passed and _assert_true(abs((leaderboard_popup as Control).size.x - viewport_size_for_leaderboard.x * theme.ui_modal_landscape_width_ratio) <= 4.0, "Leaderboard popup width should use modal SSOT")
			passed = passed and _assert_true(abs((leaderboard_popup as Control).size.y - viewport_size_for_leaderboard.y * theme.ui_modal_landscape_height_ratio) <= 4.0, "Leaderboard popup height should use modal SSOT")
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
		print("test_game_scene_generated_ui_hooks: PASS")
		quit(0)
	else:
		print("test_game_scene_generated_ui_hooks: FAIL")
		quit(1)

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

func _has_property(resource: Resource, property_name: String) -> bool:
	if resource == null:
		return false
	for info in resource.get_property_list():
		if info.get("name", "") == property_name:
			return true
	return false

func _assert_generated_style_transparent(style: StyleBox, message: String) -> bool:
	if not (style is StyleBoxFlat):
		push_error("%s: expected StyleBoxFlat" % message)
		return false
	var flat := style as StyleBoxFlat
	if flat.bg_color.a > 0.01:
		push_error("%s: bg alpha expected <= 0.01, got %s" % [message, str(flat.bg_color.a)])
		return false
	if flat.border_color.a > 0.01:
		push_error("%s: border alpha expected <= 0.01, got %s" % [message, str(flat.border_color.a)])
		return false
	if flat.shadow_color.a > 0.01 or flat.shadow_size > 0:
		push_error("%s: shadow expected disabled, got alpha=%s size=%s" % [message, str(flat.shadow_color.a), str(flat.shadow_size)])
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
	if atlas.atlas == null or atlas.atlas.resource_path != "res://Assets/Icons/logo.png":
		push_error("%s: expected atlas source res://Assets/Icons/logo.png" % message)
		return false
	if atlas.region.size.x <= 0.0 or atlas.region.size.y <= 0.0:
		push_error("%s: expected non-empty alpha bbox region" % message)
		return false
	return true

func _assert_region_rect(control: Control, region, basis: Rect2, message: String) -> bool:
	if control == null:
		push_error("%s: expected control" % message)
		return false
	if not (region is Vector4):
		push_error("%s: expected Vector4 region" % message)
		return false
	var expected := Rect2(
		basis.position + Vector2(region.x * basis.size.x, region.y * basis.size.y),
		Vector2(region.z * basis.size.x, region.w * basis.size.y)
	)
	if abs(control.offset_left - expected.position.x) > 2.0:
		push_error("%s: left expected %s, got %s" % [message, str(expected.position.x), str(control.offset_left)])
		return false
	if abs(control.offset_top - expected.position.y) > 2.0:
		push_error("%s: top expected %s, got %s" % [message, str(expected.position.y), str(control.offset_top)])
		return false
	if abs(control.offset_right - expected.end.x) > 2.0:
		push_error("%s: right expected %s, got %s" % [message, str(expected.end.x), str(control.offset_right)])
		return false
	if abs(control.offset_bottom - expected.end.y) > 2.0:
		push_error("%s: bottom expected %s, got %s" % [message, str(expected.end.y), str(control.offset_bottom)])
		return false
	return true

func _assert_child_region_rect(control: Control, parent: Control, region, basis: Rect2, message: String) -> bool:
	if control == null:
		push_error("%s: expected control" % message)
		return false
	if parent == null:
		push_error("%s: expected parent" % message)
		return false
	if not (region is Vector4):
		push_error("%s: expected Vector4 region" % message)
		return false
	var expected_global := Rect2(
		basis.position + Vector2(region.x * basis.size.x, region.y * basis.size.y),
		Vector2(region.z * basis.size.x, region.w * basis.size.y)
	)
	var parent_global := Rect2(Vector2(parent.offset_left, parent.offset_top), Vector2(parent.offset_right - parent.offset_left, parent.offset_bottom - parent.offset_top))
	var expected := Rect2(expected_global.position - parent_global.position, expected_global.size)
	if abs(control.offset_left - expected.position.x) > 2.0:
		push_error("%s: left expected %s, got %s" % [message, str(expected.position.x), str(control.offset_left)])
		return false
	if abs(control.offset_top - expected.position.y) > 2.0:
		push_error("%s: top expected %s, got %s" % [message, str(expected.position.y), str(control.offset_top)])
		return false
	if abs(control.offset_right - expected.end.x) > 2.0:
		push_error("%s: right expected %s, got %s" % [message, str(expected.end.x), str(control.offset_right)])
		return false
	if abs(control.offset_bottom - expected.end.y) > 2.0:
		push_error("%s: bottom expected %s, got %s" % [message, str(expected.end.y), str(control.offset_bottom)])
		return false
	return true

func _assert_union_region_rect(control: Control, regions: Array, basis: Rect2, message: String) -> bool:
	if control == null:
		push_error("%s: expected control" % message)
		return false
	var expected := Rect2()
	var has_rect := false
	for region in regions:
		if not (region is Vector4):
			push_error("%s: expected Vector4 region" % message)
			return false
		var current := Rect2(
			basis.position + Vector2(region.x * basis.size.x, region.y * basis.size.y),
			Vector2(region.z * basis.size.x, region.w * basis.size.y)
		)
		if not has_rect:
			expected = current
			has_rect = true
		else:
			expected = expected.merge(current)
	if not has_rect:
		push_error("%s: expected at least one region" % message)
		return false
	var actual := Rect2(Vector2(control.offset_left, control.offset_top), Vector2(control.offset_right - control.offset_left, control.offset_bottom - control.offset_top))
	if actual.position.distance_to(expected.position) > 2.0 or actual.size.distance_to(expected.size) > 2.0:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true

func _assert_full_parent_rect(control: Control, message: String) -> bool:
	if control == null:
		push_error("%s: expected control" % message)
		return false
	if control.anchor_left != 0.0 or control.anchor_top != 0.0 or control.anchor_right != 1.0 or control.anchor_bottom != 1.0:
		push_error("%s: expected full parent anchors, got (%s, %s, %s, %s)" % [message, str(control.anchor_left), str(control.anchor_top), str(control.anchor_right), str(control.anchor_bottom)])
		return false
	var offset_sum: float = abs(control.offset_left) + abs(control.offset_top) + abs(control.offset_right) + abs(control.offset_bottom)
	if offset_sum > 1.0:
		push_error("%s: expected zero offsets, got (%s, %s, %s, %s)" % [message, str(control.offset_left), str(control.offset_top), str(control.offset_right), str(control.offset_bottom)])
		return false
	return true

func _assert_button_icon(button: Button, expected_path: String, message: String) -> bool:
	if button == null:
		push_error("%s: expected button" % message)
		return false
	var icon_rect := button.get_node_or_null("GeneratedButtonIcon") as TextureRect
	if icon_rect == null:
		push_error("%s: expected GeneratedButtonIcon TextureRect" % message)
		return false
	if icon_rect.texture == null:
		push_error("%s: expected icon texture" % message)
		return false
	if icon_rect.texture.resource_path != expected_path:
		push_error("%s: expected %s, got %s" % [message, expected_path, icon_rect.texture.resource_path])
		return false
	if not icon_rect.visible:
		push_error("%s: expected visible icon" % message)
		return false
	if icon_rect.size.x <= 0.0 or icon_rect.size.y <= 0.0:
		push_error("%s: expected non-empty icon rect" % message)
		return false
	return true

func _assert_time_label_style(label: Label, theme: ThemeConfig, message: String) -> bool:
	if label == null:
		push_error("%s: expected Label" % message)
		return false
	if label.get_theme_color("font_color") != theme.ui_top_tray_time_color:
		push_error("%s: expected font color from ThemeConfig" % message)
		return false
	if label.get_theme_color("font_outline_color") != theme.ui_top_tray_time_outline_color:
		push_error("%s: expected outline color from ThemeConfig" % message)
		return false
	if label.horizontal_alignment != HORIZONTAL_ALIGNMENT_RIGHT:
		push_error("%s: expected right alignment" % message)
		return false
	var font := label.get_theme_font("font")
	if font == null or font.resource_path != theme.ui_top_tray_time_font_path:
		push_error("%s: expected font %s" % [message, theme.ui_top_tray_time_font_path])
		return false
	return true

func _assert_left_stats_label_style(label: Label, theme: ThemeConfig, message: String) -> bool:
	if label == null:
		push_error("%s: expected Label" % message)
		return false
	if label.horizontal_alignment != HORIZONTAL_ALIGNMENT_LEFT:
		push_error("%s: expected left alignment" % message)
		return false
	if label.get_theme_color("font_color") != theme.ui_top_tray_time_color:
		push_error("%s: expected font color from ThemeConfig" % message)
		return false
	if label.get_theme_color("font_outline_color") != theme.ui_top_tray_time_outline_color:
		push_error("%s: expected outline color from ThemeConfig" % message)
		return false
	var font := label.get_theme_font("font")
	if font == null or font.resource_path != theme.ui_top_tray_time_font_path:
		push_error("%s: expected font %s" % [message, theme.ui_top_tray_time_font_path])
		return false
	return true

func _assert_stat_label_centered_and_fitted(label: Label, region, basis: Rect2, theme: ThemeConfig, message: String) -> bool:
	if label == null:
		push_error("%s: expected label" % message)
		return false
	if not (region is Vector4):
		push_error("%s: expected Vector4 region" % message)
		return false
	if label.horizontal_alignment != HORIZONTAL_ALIGNMENT_CENTER:
		push_error("%s: expected horizontal center alignment" % message)
		return false
	if label.vertical_alignment != VERTICAL_ALIGNMENT_CENTER:
		push_error("%s: expected vertical center alignment" % message)
		return false
	var rect_size := Vector2(region.z * basis.size.x, region.w * basis.size.y)
	var font_size: int = label.get_theme_font_size("font_size")
	var line_count: int = max(1, String(label.text).split("\n").size())
	if font_size * line_count > rect_size.y:
		push_error("%s: font block height expected <= %s, got %s" % [message, str(rect_size.y), str(font_size * line_count)])
		return false
	if theme != null and font_size > int(theme.get("ui_top_tray_stat_font_size")):
		push_error("%s: font size expected <= SSOT max" % message)
		return false
	var font: Font = label.get_theme_font("font")
	if font != null:
		var fit_width := rect_size.x * float(theme.get("ui_top_tray_stat_fit_width_ratio"))
		for line in String(label.text).split("\n"):
			if font.get_string_size(String(line), HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > fit_width:
				push_error("%s: line '%s' expected to fit width %s" % [message, String(line), str(fit_width)])
				return false
	return true
