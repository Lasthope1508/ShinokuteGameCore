extends Node2D

const LevelDataScript = preload("res://Scripts/level_data.gd")
const PipeGridScript = preload("res://Scripts/pipe_grid.gd")
const ConnectionSolverScript = preload("res://Scripts/connection_solver.gd")
const PipeVisualMapping = preload("res://Scripts/pipe_visual_mapping.gd")
const FlowVisualStateScript = preload("res://Scripts/flow_visual_state.gd")
const PipeVfxLayerScript = preload("res://Scripts/pipe_vfx_layer.gd")
const VfxTransitionStateScript = preload("res://Scripts/vfx_transition_state.gd")
const LevelGeneratorScript = preload("res://Scripts/level_generator.gd")
const BottomTimerDigitsScript = preload("res://Scripts/bottom_timer_digits.gd")
const UiModalPresenter = preload("res://Scripts/ui_modal_presenter.gd")
const LEADERBOARD_POPUP_SCENE_PATH := "res://Scenes/Common/LeaderboardPopup.tscn"
const PROJECT_LOGO_PATH := "res://Assets/Icons/logo.png"
const UI_MODE_SAVE_KEY := "cyber_ui_generated_asset_mode"

var level_data: RefCounted
var grid: RefCounted
var solver: RefCounted

var CELL_SIZE := 120.0
var GRID_OFFSET := Vector2(100.0, 200.0)
var layout_safe_rect := Rect2()
var is_solved := false

const ENERGY_SHEET_FRAME_COUNT := 8
const ENERGY_SHEET_FRAME_SIZE := Vector2(512.0, 512.0)
const ENERGY_FRAME_DURATION := 0.055
const ENERGY_SHEET_ROOT := "res://Assets/Themes/cyberpunk_theme/energy_sheets"
const ENERGY_THEME_TEXTURE_PREFIX := "res://Assets/Themes/cyberpunk_theme/"

var moves := 0
var level_id := 1
var debug_white_background := false
var debug_white_cells := false
var debug_last_cell_texture_mode := ""
var debug_last_cell_texture_path := ""
var debug_last_cell_texture_luminance := -1.0
var debug_last_cell_has_textures := false
var debug_last_cell_fallback_color := Color.TRANSPARENT

var visual_rotations: Array = []
var flow_visual_state: Dictionary = {}
var pipe_vfx_layer: Node2D
var active_theme_override: ThemeConfig
var active_tweens: Dictionary = {}
var energy_flow_start_times: Dictionary = {}
var energy_sheet_texture_cache: Dictionary = {}
var energy_frame_texture_cache: Dictionary = {}
var generated_ui_texture_cache: Dictionary = {}
var generated_ui_rects: Dictionary = {}
var level_start_time_sec := 0.0
var level_finished_time_sec := -1.0

# HUD node references
@onready var hud_layer: CanvasLayer = $HUD
@onready var hud_margin_container: MarginContainer = $HUD/MarginContainer
@onready var top_tray_root: MarginContainer = $HUD/MarginContainer/VBoxContainer/TopTrayRoot
@onready var top_tray_layer: Panel = $HUD/MarginContainer/VBoxContainer/TopTrayRoot/TopTrayLayer
@onready var stats_capsule: PanelContainer = $HUD/MarginContainer/VBoxContainer/TopTrayRoot/TopTrayLayer/StatsCapsule
@onready var logo_core: TextureRect = $HUD/MarginContainer/VBoxContainer/TopTrayRoot/TopTrayLayer/LogoCore
@onready var left_stats_label: Label = $HUD/MarginContainer/VBoxContainer/TopTrayRoot/TopTrayLayer/LeftStatsLabel
@onready var total_play_time_label: Label = $HUD/MarginContainer/VBoxContainer/TopTrayRoot/TopTrayLayer/TotalPlayTimeLabel
@onready var left_floating_menu: Button = $HUD/MarginContainer/VBoxContainer/TopTrayRoot/TopTrayLayer/LeftFloatingMenu
@onready var right_floating_replay: Button = $HUD/MarginContainer/VBoxContainer/TopTrayRoot/TopTrayLayer/RightFloatingReplay
@onready var bottom_reserve_layer: Panel = $HUD/BottomReserveLayer
var bottom_timer_digits: Control
@onready var stats_readout: Control = $HUD/MarginContainer/VBoxContainer/TopTrayRoot/TopTrayLayer/StatsCapsule/StatsReadout
@onready var solved_popup: Panel = $HUD/SolvedPopup
@onready var popup_title: Label = $HUD/SolvedPopup/MarginContainer/VBoxContainer/PopupTitle
@onready var popup_moves: Label = $HUD/SolvedPopup/MarginContainer/VBoxContainer/PopupMoves
@onready var next_btn: Button = $HUD/SolvedPopup/MarginContainer/VBoxContainer/NextBtn
@onready var settings_overlay: Panel = $HUD/SettingsOverlay
@onready var settings_master_audio_btn: Button = $HUD/SettingsOverlay/MarginContainer/VBoxContainer/MasterAudioBtn
@onready var settings_music_btn: Button = $HUD/SettingsOverlay/MarginContainer/VBoxContainer/MusicBtn
@onready var settings_sfx_btn: Button = $HUD/SettingsOverlay/MarginContainer/VBoxContainer/SfxBtn
@onready var settings_theme_mode_btn: Button = $HUD/SettingsOverlay/MarginContainer/VBoxContainer/ThemeModeBtn
@onready var settings_close_btn: Button = $HUD/SettingsOverlay/CloseBtn
@onready var leaderboard_overlay_root: Control = $HUD/LeaderboardOverlayRoot

func _ready() -> void:
	var game_state = _get_autoload("GameState")
	if game_state:
		level_id = game_state.current_level_id
	
	var lvl = LevelGeneratorScript.generate_level(level_id)
	
	grid = PipeGridScript.new()
	grid.initialize(lvl)
	
	solver = ConnectionSolverScript.new()
	is_solved = solver.check_connection(grid)
	_reset_level_timer()
	_reset_energy_animation()
	
	_init_visual_rotations()
	_ensure_vfx_layer()
	
	# Connect to window size changes
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	var theme_manager = _get_autoload("ThemeManager")
	if theme_manager and active_theme_override == null:
		theme_manager.theme_changed.connect(_on_theme_changed)
		_on_theme_changed(theme_manager.active_theme_name, theme_manager.active_theme)
	elif active_theme_override == null:
		_apply_saved_ui_mode(_get_active_theme())
	
	_recalculate_layout()
	_prime_vfx_visual_state()
	_update_hud()
	_apply_top_tray_theme(_get_active_theme())
	_apply_generated_ui_assets(_get_active_theme())
	_update_mute_button()
	_update_settings_buttons()

	
	# Hide solved popup initially
	solved_popup.visible = false
	settings_overlay.visible = false
	leaderboard_overlay_root.visible = false
	
	var audio_manager = _get_autoload("AudioManager")
	if audio_manager:
		audio_manager.play_music()
		audio_manager.set_music_mode("relax")


func _process(_delta: float) -> void:
	if grid == null or solver == null:
		return
	var watered_tiles = solver.get_watered_tiles(grid)
	_sync_energy_flow_starts(watered_tiles)
	_update_flow_visual_state()
	_sync_vfx_layer()
	_update_total_play_time_label()
	if _has_active_energy_animation(watered_tiles) or _has_active_target_core_blink():
		queue_redraw()


func _on_theme_changed(_theme_name: String, config: ThemeConfig) -> void:
	if config == null:
		return
	_apply_saved_ui_mode(config)
	_apply_top_tray_theme(config)
	_apply_generated_ui_assets(config)
		
	# Dynamic sizing using utility_button_height from active theme config (SSOT sizing)
	if right_floating_replay and config:
		var btn_size := config.ui_top_tray_icon_button_size
		right_floating_replay.custom_minimum_size = Vector2(btn_size, btn_size)
		
	_update_mute_button()
	queue_redraw()

func _recalculate_layout() -> void:
	if grid == null:
		return
		
	# Determine safe area
	var safe_rect: Rect2
	if OS.has_feature("mobile"):
		var safe_screen = DisplayServer.get_display_safe_area()
		var window_size = DisplayServer.window_get_size()
		var viewport_size = get_viewport_rect().size
		var scale_factor = viewport_size / Vector2(window_size)
		safe_rect = Rect2(
			Vector2(safe_screen.position) * scale_factor,
			Vector2(safe_screen.size) * scale_factor
		)
	else:
		safe_rect = get_viewport_rect()
		
	_recalculate_layout_for_safe_rect(safe_rect)

func _recalculate_layout_for_safe_rect(safe_rect: Rect2) -> void:
	if grid == null:
		return
	layout_safe_rect = safe_rect
	var theme = _get_active_theme()
	if theme:
		var playboard_rect := _get_playboard_region_rect(theme, safe_rect, "playboard_rect")
		if playboard_rect.size.x > 0.0 and playboard_rect.size.y > 0.0:
			CELL_SIZE = min(playboard_rect.size.x / float(grid.width), playboard_rect.size.y / float(grid.height))
			var grid_size := Vector2(float(grid.width) * CELL_SIZE, float(grid.height) * CELL_SIZE)
			GRID_OFFSET = playboard_rect.position + (playboard_rect.size - grid_size) * 0.5
			_sync_vfx_layer()
			queue_redraw()
			return
	var padding_x: float = theme.game_side_padding if theme else 40.0
	var max_w: float = safe_rect.size.x - padding_x
	
	var top_margin: float = theme.game_top_margin if theme else 160.0
	if theme:
		var is_landscape := safe_rect.size.x > safe_rect.size.y
		if is_landscape and theme.game_landscape_top_margin > 0.0:
			top_margin = theme.game_landscape_top_margin
		top_margin = max(top_margin, theme.ui_hud_margin_top + theme.ui_top_tray_layer_height + theme.ui_top_tray_board_gap)
		if is_landscape and theme.ui_landscape_board_avoid_top_tray_enabled:
			var top_tray_safe_bottom := _get_top_tray_safe_bottom()
			var top_tray_gap: float = max(theme.ui_top_tray_board_gap, theme.ui_landscape_board_top_tray_gap)
			top_margin = max(top_margin, top_tray_safe_bottom - safe_rect.position.y + top_tray_gap)
	var bottom_margin: float = theme.game_bottom_margin if theme else 200.0
	if theme and safe_rect.size.x > safe_rect.size.y and theme.ui_landscape_board_avoid_top_tray_enabled:
		bottom_margin = theme.ui_landscape_board_bottom_safe_margin
	if theme:
		var bottom_reserve_safe_top := _get_bottom_reserve_safe_top()
		if bottom_reserve_safe_top > 0.0:
			var bottom_gap: float = max(theme.ui_top_tray_board_gap, theme.ui_landscape_board_bottom_safe_margin)
			bottom_margin = max(bottom_margin, safe_rect.end.y - bottom_reserve_safe_top + bottom_gap)
	var max_h = safe_rect.size.y - safe_rect.position.y - top_margin - bottom_margin
	
	var cell_w = max_w / grid.width
	var cell_h = max_h / grid.height
	CELL_SIZE = min(cell_w, cell_h)
	
	var grid_w = grid.width * CELL_SIZE
	var grid_h = grid.height * CELL_SIZE
	GRID_OFFSET.x = safe_rect.position.x + (safe_rect.size.x - grid_w) / 2.0
	GRID_OFFSET.y = safe_rect.position.y + top_margin + (max_h - grid_h) / 2.0
	_sync_vfx_layer()
	
	queue_redraw()

func _on_viewport_size_changed() -> void:
	var theme := _get_active_theme()
	if theme != null:
		_apply_top_tray_theme(theme)
		_apply_generated_ui_assets(theme)
	_recalculate_layout()

func _get_top_tray_safe_bottom() -> float:
	var safe_bottom := 0.0
	if top_tray_root != null:
		safe_bottom = max(safe_bottom, top_tray_root.get_global_rect().end.y)
	if left_floating_menu != null:
		safe_bottom = max(safe_bottom, left_floating_menu.get_global_rect().end.y)
	if right_floating_replay != null:
		safe_bottom = max(safe_bottom, right_floating_replay.get_global_rect().end.y)
	return safe_bottom

func _get_bottom_reserve_safe_top() -> float:
	if bottom_reserve_layer == null:
		return 0.0
	return bottom_reserve_layer.get_global_rect().position.y

func _get_playboard_region_rect(theme: ThemeConfig, basis: Rect2, region_key: String) -> Rect2:
	if theme == null or basis.size.x <= 0.0 or basis.size.y <= 0.0:
		return Rect2()
	var regions := _get_playboard_regions(theme, basis.size)
	if not regions.has(region_key):
		return Rect2()
	var region = regions.get(region_key)
	if not (region is Vector4):
		return Rect2()
	if region.z <= 0.0 or region.w <= 0.0:
		return Rect2()
	return Rect2(
		basis.position + Vector2(region.x * basis.size.x, region.y * basis.size.y),
		Vector2(region.z * basis.size.x, region.w * basis.size.y)
	)

func _get_playboard_regions(theme: ThemeConfig, viewport_size: Vector2) -> Dictionary:
	if theme == null:
		return {}
	var mode := String(theme.ui_generated_asset_mode)
	if not theme.ui_playboard_region_sets.has(mode):
		return {}
	var mode_regions = theme.ui_playboard_region_sets.get(mode)
	if not (mode_regions is Dictionary):
		return {}
	var orientation := "landscape" if viewport_size.x > viewport_size.y else "portrait"
	var orientation_regions = (mode_regions as Dictionary).get(orientation)
	if orientation_regions is Dictionary:
		return orientation_regions
	return {}

func get_board_rect() -> Rect2:
	if grid == null:
		return Rect2()
	return Rect2(GRID_OFFSET, Vector2(float(grid.width) * CELL_SIZE, float(grid.height) * CELL_SIZE))

func get_board_backplate_rect() -> Rect2:
	var theme := _get_active_theme()
	if theme == null:
		return get_board_rect().grow(CELL_SIZE * 0.32)
	var basis := layout_safe_rect if layout_safe_rect.size.x > 0.0 and layout_safe_rect.size.y > 0.0 else get_viewport_rect()
	var configured_rect := _get_playboard_region_rect(theme, basis, "board_backplate_rect")
	if configured_rect.size.x > 0.0 and configured_rect.size.y > 0.0:
		return configured_rect
	return get_board_rect().grow(CELL_SIZE * 0.32)

func get_cell_rect(cell_pos: Vector2i) -> Rect2:
	return Rect2(GRID_OFFSET + Vector2(cell_pos) * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE))

func get_endpoint_cell_positions() -> Dictionary:
	if grid == null:
		return {"source": Vector2i.ZERO, "target": Vector2i.ZERO}
	return {
		"source": grid.source_pos,
		"target": grid.target_pos
	}

func get_cell_at_screen_position(screen_position: Vector2) -> Vector2i:
	if grid == null or CELL_SIZE <= 0.0:
		return Vector2i(-1, -1)
	var mouse_pos := screen_position - GRID_OFFSET
	var x := int(mouse_pos.x / CELL_SIZE)
	var y := int(mouse_pos.y / CELL_SIZE)
	var cell_pos := Vector2i(x, y)
	if not grid.is_valid_pos(cell_pos):
		return Vector2i(-1, -1)
	return cell_pos

func try_rotate_cell(cell_pos: Vector2i, animate: bool = true) -> bool:
	if grid == null or solver == null or is_solved:
		return false
	if _is_modal_overlay_visible():
		return false
	if not grid.is_valid_pos(cell_pos):
		return false
	var previous_flow_state := flow_visual_state.duplicate(true)
	if previous_flow_state.is_empty():
		previous_flow_state = FlowVisualStateScript.build(grid, energy_flow_start_times, Time.get_ticks_msec() / 1000.0)

	var audio_manager = _get_autoload("AudioManager")
	if audio_manager:
		audio_manager.play_sfx("pipe_rotate")

	grid.rotate_tile(cell_pos.x, cell_pos.y)
	_reset_energy_animation()
	moves += 1
	_update_hud()

	if animate and is_inside_tree():
		_animate_visual_rotation(cell_pos)
	else:
		_sync_visual_rotation(cell_pos)

	if moves > 15 and audio_manager:
		audio_manager.set_music_mode("danger")

	is_solved = solver.check_connection(grid)
	_update_flow_visual_state()
	_set_vfx_transition_state(previous_flow_state, flow_visual_state, cell_pos)
	_set_vfx_rotation_event(cell_pos)
	if is_solved:
		_set_vfx_win_state()
	_sync_vfx_layer()
	queue_redraw()
	if is_solved:
		_on_level_solved()
	return true

func reset_current_level(is_randomized: bool = true) -> bool:
	if grid == null:
		grid = PipeGridScript.new()
	if solver == null:
		solver = ConnectionSolverScript.new()
	var level_dict := LevelGeneratorScript.generate_level(level_id, is_randomized)
	grid.initialize(level_dict)
	moves = 0
	_reset_level_timer()
	_reset_energy_animation()
	_init_visual_rotations()
	is_solved = solver.check_connection(grid)
	if solved_popup:
		solved_popup.visible = false
	if pipe_vfx_layer != null and pipe_vfx_layer.has_method("clear_transition_state"):
		pipe_vfx_layer.clear_transition_state()
	if pipe_vfx_layer != null and pipe_vfx_layer.has_method("clear_runtime_events"):
		pipe_vfx_layer.clear_runtime_events()
	_update_hud()
	_sync_vfx_layer()
	queue_redraw()
	return true

func _animate_visual_rotation(cell_pos: Vector2i) -> void:
	var x := cell_pos.x
	var y := cell_pos.y
	if not (visual_rotations.size() > y and visual_rotations[y].size() > x):
		return
	var key := str(x) + "," + str(y)
	if active_tweens.has(key) and active_tweens[key].is_valid():
		active_tweens[key].kill()
	var old_rot = visual_rotations[y][x]
	var target_rot = round(old_rot / (PI / 2.0)) * (PI / 2.0) + PI / 2.0
	var tween = create_tween()
	active_tweens[key] = tween
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_method(
		func(val: float):
			visual_rotations[y][x] = val
			queue_redraw(),
		old_rot,
		target_rot,
		0.18
	)

func _sync_visual_rotation(cell_pos: Vector2i) -> void:
	var x := cell_pos.x
	var y := cell_pos.y
	if not (visual_rotations.size() > y and visual_rotations[y].size() > x):
		return
	var theme := _get_active_theme()
	if theme == null:
		return
	var tile_info := _get_tile_texture_and_rotation(x, y, theme)
	visual_rotations[y][x] = tile_info.get("rotation", visual_rotations[y][x])
	queue_redraw()

func _get_autoload(node_name: String) -> Node:
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/" + node_name)

func _get_active_theme() -> ThemeConfig:
	if active_theme_override != null:
		return active_theme_override
	var theme_manager = _get_autoload("ThemeManager")
	if theme_manager and theme_manager.has_method("get_active_theme"):
		return theme_manager.get_active_theme()
	return null

func _apply_saved_ui_mode(theme: ThemeConfig) -> void:
	if theme == null:
		return
	var save_manager = _get_autoload("SaveManager")
	if save_manager == null or not save_manager.has_method("get_setting"):
		return
	var saved_mode := String(save_manager.get_setting(UI_MODE_SAVE_KEY, ""))
	if saved_mode.is_empty():
		return
	if not _theme_supports_ui_mode(theme, saved_mode):
		push_error("Saved UI generated asset mode is not present in theme SSOT: %s" % saved_mode)
		return
	theme.ui_generated_asset_mode = saved_mode

func _theme_supports_ui_mode(theme: ThemeConfig, mode: String) -> bool:
	return theme != null and not mode.is_empty() and theme.ui_generated_asset_paths.has(mode)

func _get_next_ui_mode(theme: ThemeConfig) -> String:
	if theme == null:
		return ""
	var modes := theme.ui_generated_asset_paths.keys()
	modes.sort()
	if modes.is_empty():
		push_error("Theme has no generated UI asset modes in SSOT")
		return String(theme.ui_generated_asset_mode)
	var current_mode := String(theme.ui_generated_asset_mode)
	var current_index := modes.find(current_mode)
	if current_index < 0:
		push_error("Active UI generated asset mode is not present in theme SSOT: %s" % current_mode)
		return current_mode
	return String(modes[(current_index + 1) % modes.size()])

func _set_active_ui_mode(mode: String, persist: bool = true) -> void:
	var theme := _get_active_theme()
	if theme == null:
		return
	if not _theme_supports_ui_mode(theme, mode):
		push_error("Requested UI generated asset mode is not present in theme SSOT: %s" % mode)
		return
	if String(theme.ui_generated_asset_mode) == mode:
		_update_settings_buttons()
		return
	theme.ui_generated_asset_mode = mode
	if persist:
		var save_manager = _get_autoload("SaveManager")
		if save_manager != null and save_manager.has_method("set_setting"):
			save_manager.set_setting(UI_MODE_SAVE_KEY, mode)
	_refresh_ui_for_generated_mode(theme)

func _refresh_ui_for_generated_mode(theme: ThemeConfig) -> void:
	if theme == null:
		return
	generated_ui_texture_cache.clear()
	_apply_top_tray_theme(theme)
	_apply_generated_ui_assets(theme)
	_recalculate_layout()
	_update_hud()
	if leaderboard_overlay_root != null and leaderboard_overlay_root.visible:
		for child in leaderboard_overlay_root.get_children():
			_configure_leaderboard_popup(child, theme)
	_update_settings_buttons()
	_sync_vfx_layer()
	queue_redraw()

func _update_hud() -> void:
	_update_left_stats_label()
	_update_top_right_stats_label()
	_update_total_play_time_label()

func _apply_top_tray_theme(theme: ThemeConfig, viewport_size_override: Vector2 = Vector2.ZERO) -> void:
	if theme == null or top_tray_root == null:
		return
	if hud_margin_container:
		hud_margin_container.add_theme_constant_override("margin_left", int(theme.ui_hud_margin_left))
		hud_margin_container.add_theme_constant_override("margin_top", int(theme.ui_hud_margin_top))
		hud_margin_container.add_theme_constant_override("margin_right", int(theme.ui_hud_margin_right))
		hud_margin_container.add_theme_constant_override("margin_bottom", int(theme.ui_hud_margin_bottom))
	var viewport_size := viewport_size_override if viewport_size_override.x > 0.0 and viewport_size_override.y > 0.0 else get_viewport_rect().size
	var viewport_width := viewport_size.x
	var tray_height := theme.ui_top_tray_layer_height
	if viewport_size.y > 0.0:
		var height_ratio := theme.ui_top_tray_landscape_height_ratio if viewport_size.x > viewport_size.y else theme.ui_top_tray_portrait_height_ratio
		tray_height = max(tray_height, viewport_size.y * height_ratio)
	var tray_width: float = max(320.0, viewport_width * theme.ui_top_tray_width_ratio)
	if viewport_width > 0.0:
		tray_width = min(tray_width, viewport_width - (theme.game_side_padding * 2.0))
	if viewport_size.x > viewport_size.y and viewport_size.y > 0.0:
		tray_width = min(tray_width, viewport_size.y * theme.ui_top_tray_landscape_width_height_ratio)
	top_tray_root.custom_minimum_size = Vector2(tray_width, tray_height)
	if top_tray_layer:
		if _has_generated_ui_asset(theme, "top_tray_layer"):
			top_tray_layer.add_theme_stylebox_override("panel", _make_transparent_control_style(10, 6, 10, 6))
		else:
			top_tray_layer.add_theme_stylebox_override("panel", _make_panel_style(
				theme.ui_top_tray_bg_color,
				Color.TRANSPARENT,
				theme.ui_top_tray_shadow_color,
				theme.ui_top_tray_glow_color,
				0,
				0,
				10
			))
	if stats_capsule:
		stats_capsule.anchor_left = 0.0
		stats_capsule.anchor_top = 0.0
		stats_capsule.anchor_right = 0.0
		stats_capsule.anchor_bottom = 0.0
		stats_capsule.offset_left = 0.0
		stats_capsule.offset_top = 0.0
		stats_capsule.offset_right = tray_width
		stats_capsule.offset_bottom = tray_height
		if _has_generated_ui_asset(theme, "stats_capsule"):
			stats_capsule.add_theme_stylebox_override("panel", _make_transparent_control_style(10, 6, 10, 6))
		else:
			stats_capsule.add_theme_stylebox_override("panel", _make_panel_style(
				theme.ui_top_tray_bg_color.lightened(0.08),
				theme.ui_top_tray_border_color,
				theme.ui_top_tray_shadow_color,
				theme.ui_top_tray_glow_color,
				12,
				1,
				12
			))
	if settings_overlay:
		if _has_generated_ui_asset(theme, "modal_frame"):
			settings_overlay.add_theme_stylebox_override("panel", _make_transparent_control_style(10, 6, 10, 6))
		else:
			settings_overlay.add_theme_stylebox_override("panel", _make_panel_style(
				theme.panel_bg_color,
				theme.ui_top_tray_border_color,
				theme.ui_top_tray_shadow_color,
				theme.ui_top_tray_glow_color,
				12,
				2,
				10
			))
	if solved_popup:
		if _has_generated_ui_asset(theme, "modal_frame"):
			solved_popup.add_theme_stylebox_override("panel", _make_transparent_control_style(10, 6, 10, 6))
		else:
			solved_popup.add_theme_stylebox_override("panel", _make_panel_style(
				theme.panel_bg_color,
				theme.ui_top_tray_border_color,
				theme.ui_top_tray_shadow_color,
				theme.ui_top_tray_glow_color,
				12,
				2,
				10
			))
	_apply_modal_theme(theme, viewport_size)
	_apply_bottom_reserve_theme(theme, viewport_size)
	if logo_core:
		_apply_project_logo_texture(theme)
		logo_core.visible = true
		logo_core.mouse_filter = Control.MOUSE_FILTER_IGNORE
		logo_core.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_apply_top_tray_region(logo_core, theme, "logo_core", Vector2(tray_width, tray_height))
		logo_core.move_to_front()
	if left_stats_label:
		left_stats_label.visible = true
		left_stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		left_stats_label.clip_contents = true
		_apply_top_tray_region(left_stats_label, theme, "left_stats_readout", Vector2(tray_width, tray_height))
		_style_left_stats_label(left_stats_label, theme)
		_update_left_stats_label()
		left_stats_label.move_to_front()
	if total_play_time_label:
		total_play_time_label.visible = true
		total_play_time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		total_play_time_label.clip_contents = true
		_apply_top_tray_region(total_play_time_label, theme, "total_play_time_readout", Vector2(tray_width, tray_height))
		_style_total_play_time_label(total_play_time_label, theme)
		_update_top_right_stats_label()
		total_play_time_label.move_to_front()
	var icon_size := theme.ui_top_tray_icon_button_size
	_style_single_button(left_floating_menu, theme, icon_size, theme.ui_top_tray_menu_color, _has_generated_ui_asset(theme, "floating_menu_button_default"))
	_style_single_button(right_floating_replay, theme, icon_size, theme.ui_top_tray_replay_color, _has_generated_ui_asset(theme, "floating_replay_button_default"))
	_apply_top_tray_region(left_floating_menu, theme, "left_floating_menu", Vector2(tray_width, tray_height))
	_apply_top_tray_region(right_floating_replay, theme, "right_floating_replay", Vector2(tray_width, tray_height))
	if left_floating_menu:
		left_floating_menu.move_to_front()
		_apply_top_tray_button_icon_policy(left_floating_menu, theme, "left_floating_menu", Vector2(tray_width, tray_height))
	if right_floating_replay:
		right_floating_replay.move_to_front()
		_apply_top_tray_button_icon_policy(right_floating_replay, theme, "right_floating_replay", Vector2(tray_width, tray_height))
	if settings_overlay:
		var modal_margin := settings_overlay.get_node_or_null("MarginContainer") as MarginContainer
		if modal_margin:
			modal_margin.add_theme_constant_override("margin_left", theme.ui_modal_content_margin_x)
			modal_margin.add_theme_constant_override("margin_top", theme.ui_modal_content_margin_top)
			modal_margin.add_theme_constant_override("margin_right", theme.ui_modal_content_margin_x)
			modal_margin.add_theme_constant_override("margin_bottom", theme.ui_modal_content_margin_bottom)
		var modal_content := settings_overlay.get_node_or_null("MarginContainer/VBoxContainer")
		if modal_content:
			modal_content.add_theme_constant_override("separation", int(theme.ui_modal_content_gap))
			_style_modal_action_buttons(modal_content, theme)
		_style_single_button(settings_close_btn, theme, theme.ui_modal_close_button_size)
	if solved_popup:
		var solved_margin := solved_popup.get_node_or_null("MarginContainer") as MarginContainer
		if solved_margin:
			solved_margin.add_theme_constant_override("margin_left", theme.ui_result_modal_content_margin_x)
			solved_margin.add_theme_constant_override("margin_top", theme.ui_result_modal_content_margin_top)
			solved_margin.add_theme_constant_override("margin_right", theme.ui_result_modal_content_margin_x)
			solved_margin.add_theme_constant_override("margin_bottom", theme.ui_result_modal_content_margin_bottom)
		var solved_content := solved_popup.get_node_or_null("MarginContainer/VBoxContainer")
		if solved_content:
			solved_content.add_theme_constant_override("separation", int(theme.ui_result_modal_content_gap))
			_style_result_modal_action_buttons(solved_content, theme)
		_apply_result_modal_text_style(theme)
	if stats_readout:
		stats_readout.anchor_left = 0.0
		stats_readout.anchor_top = 0.0
		stats_readout.anchor_right = 1.0
		stats_readout.anchor_bottom = 1.0
		stats_readout.offset_left = 0.0
		stats_readout.offset_top = 0.0
		stats_readout.offset_right = 0.0
		stats_readout.offset_bottom = 0.0
		stats_readout.custom_minimum_size = Vector2(0.0, theme.ui_top_tray_stat_height)

func _apply_generated_ui_assets(theme: ThemeConfig) -> void:
	if theme == null:
		return
	var mode := String(theme.ui_generated_asset_mode)
	_apply_generated_top_tray_art_stack(theme, mode)
	var menu_asset := _set_generated_rect_texture(left_floating_menu, "GeneratedMenuButton", theme.get_ui_generated_asset_texture(mode, "floating_menu_button_default"), true, theme, "floating_menu_button_default")
	var replay_asset := _set_generated_rect_texture(right_floating_replay, "GeneratedReplayButton", theme.get_ui_generated_asset_texture(mode, "floating_replay_button_default"), true, theme, "floating_replay_button_default")
	if menu_asset:
		menu_asset.show_behind_parent = true
	if replay_asset:
		replay_asset.show_behind_parent = true
	_set_generated_rect_texture(bottom_reserve_layer, "GeneratedBottomReserveLayer", theme.get_ui_generated_asset_texture(mode, "bottom_reserve_layer"), true, theme, "bottom_reserve_layer")
	_set_generated_rect_texture(settings_overlay, "GeneratedModalFrame", theme.get_ui_generated_asset_texture(mode, "modal_frame"), true, theme, "modal_frame")
	_set_generated_rect_texture(solved_popup, "GeneratedSolvedModalFrame", theme.get_ui_generated_asset_texture(mode, "modal_frame"), true, theme, "modal_frame")
	_apply_result_modal_style(theme)
	_apply_bottom_timer_theme(theme)

func _apply_result_modal_style(theme: ThemeConfig) -> void:
	if theme == null:
		return
	var solved_content := solved_popup.get_node_or_null("MarginContainer/VBoxContainer") if solved_popup != null else null
	if solved_content:
		_style_result_modal_action_buttons(solved_content, theme)
	_apply_result_modal_text_style(theme)

func _apply_generated_top_tray_art_stack(theme: ThemeConfig, mode: String) -> void:
	if theme == null or top_tray_layer == null:
		return
	var active_rect_names := {}
	var stack_index := 0
	for asset_key_candidate in theme.ui_top_tray_art_stack:
		var asset_key := String(asset_key_candidate)
		if not theme.ui_top_tray_art_node_names.has(asset_key):
			push_error("Top tray art node name missing from ThemeConfig.ui_top_tray_art_node_names: %s" % asset_key)
			continue
		var rect_name := String(theme.ui_top_tray_art_node_names.get(asset_key))
		var art_asset := _set_generated_top_tray_stack_texture(
			top_tray_layer,
			rect_name,
			theme.get_ui_generated_asset_texture(mode, asset_key),
			theme,
			asset_key
		)
		active_rect_names[rect_name] = true
		if art_asset:
			art_asset.z_index = -40 + stack_index * 10
		stack_index += 1
	for rect_name_candidate in theme.ui_top_tray_art_node_names.values():
		var rect_name := String(rect_name_candidate)
		if not active_rect_names.has(rect_name):
			_remove_generated_ui_texture_rect(top_tray_layer, rect_name)

func _set_generated_top_tray_stack_texture(parent: Control, rect_name: String, texture: Texture2D, theme: ThemeConfig, asset_key: String) -> TextureRect:
	return _set_generated_rect_texture(parent, rect_name, texture, true, theme, asset_key)

func _set_generated_top_tray_regions_texture(parent: Control, rect_name: String, texture: Texture2D, theme: ThemeConfig, asset_key: String, region_keys: Array) -> TextureRect:
	if parent == null or texture == null or theme == null:
		return null
	var tray_size := _get_generated_ui_region_layout_size(parent)
	var rect := _get_top_tray_regions_rect(theme, tray_size, region_keys)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return null
	var texture_rect := _set_generated_rect_texture(parent, rect_name, texture, false, theme, asset_key)
	if texture_rect == null:
		return null
	texture_rect.anchor_left = 0.0
	texture_rect.anchor_top = 0.0
	texture_rect.anchor_right = 0.0
	texture_rect.anchor_bottom = 0.0
	texture_rect.offset_left = rect.position.x
	texture_rect.offset_top = rect.position.y
	texture_rect.offset_right = rect.end.x
	texture_rect.offset_bottom = rect.end.y
	return texture_rect

func _get_top_tray_regions_rect(theme: ThemeConfig, tray_size: Vector2, region_keys: Array) -> Rect2:
	if theme == null or region_keys.is_empty():
		return Rect2()
	var basis := _get_top_tray_region_basis(theme, tray_size)
	var regions := _get_top_tray_regions(theme)
	var union_rect := Rect2()
	var has_rect := false
	for region_key in region_keys:
		if not regions.has(region_key):
			push_error("Top tray region %s missing from active ThemeConfig top tray region set" % String(region_key))
			continue
		var candidate = regions.get(region_key)
		if not (candidate is Vector4):
			push_error("Top tray region %s should be Vector4" % String(region_key))
			continue
		var region: Vector4 = candidate
		var current := Rect2(
			basis.position + Vector2(region.x * basis.size.x, region.y * basis.size.y),
			Vector2(region.z * basis.size.x, region.w * basis.size.y)
		)
		if not has_rect:
			union_rect = current
			has_rect = true
		else:
			union_rect = union_rect.merge(current)
	return union_rect

func _get_generated_ui_region_layout_size(control: Control) -> Vector2:
	if control == null:
		return Vector2.ZERO
	if control.size.x > 0.0 and control.size.y > 0.0:
		return control.size
	if control.custom_minimum_size.x > 0.0 and control.custom_minimum_size.y > 0.0:
		return control.custom_minimum_size
	if control == top_tray_layer and top_tray_root != null and top_tray_root.custom_minimum_size.x > 0.0 and top_tray_root.custom_minimum_size.y > 0.0:
		return top_tray_root.custom_minimum_size
	return Vector2.ZERO

func _apply_bottom_reserve_theme(theme: ThemeConfig, viewport_size: Vector2) -> void:
	if bottom_reserve_layer == null or theme == null:
		return
	var reserve_width: float = viewport_size.x * theme.ui_bottom_reserve_width_ratio
	if viewport_size.x > 0.0:
		reserve_width = min(reserve_width, viewport_size.x - (theme.game_side_padding * 2.0))
	var reserve_height: float = clampf(
		viewport_size.y * theme.ui_bottom_reserve_height_ratio,
		theme.ui_bottom_reserve_min_height,
		theme.ui_bottom_reserve_max_height
	)
	var bottom_margin: float = max(theme.ui_hud_margin_bottom, viewport_size.y * theme.ui_bottom_reserve_bottom_margin_ratio)
	bottom_reserve_layer.anchor_left = 0.5
	bottom_reserve_layer.anchor_right = 0.5
	bottom_reserve_layer.anchor_top = 1.0
	bottom_reserve_layer.anchor_bottom = 1.0
	bottom_reserve_layer.offset_left = -reserve_width * 0.5
	bottom_reserve_layer.offset_right = reserve_width * 0.5
	bottom_reserve_layer.offset_bottom = -bottom_margin
	bottom_reserve_layer.offset_top = bottom_reserve_layer.offset_bottom - reserve_height
	bottom_reserve_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_reserve_layer.z_index = -1
	if _has_generated_ui_asset(theme, "bottom_reserve_layer"):
		bottom_reserve_layer.add_theme_stylebox_override("panel", _make_transparent_control_style(10, 6, 10, 6))
	else:
		bottom_reserve_layer.add_theme_stylebox_override("panel", _make_panel_style(
			theme.ui_top_tray_bg_color,
			theme.ui_top_tray_border_color,
			theme.ui_top_tray_shadow_color,
			theme.ui_top_tray_glow_color,
			8,
			1,
			8
		))
	_apply_bottom_timer_theme(theme)

func _apply_bottom_timer_theme(theme: ThemeConfig) -> void:
	if bottom_reserve_layer == null or theme == null:
		return
	var timer := _ensure_bottom_timer_digits()
	if timer == null:
		return
	timer.visible = theme.ui_bottom_timer_enabled
	if not theme.ui_bottom_timer_enabled:
		return
	var atlas := theme.get_bottom_timer_atlas_texture()
	if atlas == null:
		push_error("Bottom timer atlas missing from ThemeConfig.ui_bottom_timer_atlas_path: %s" % theme.ui_bottom_timer_atlas_path)
		timer.visible = false
		return
	timer.call("configure", atlas, theme.ui_bottom_timer_glyph_rects, theme.ui_bottom_timer_spacing_ratio, theme.ui_bottom_timer_pixel_height_ratio)
	_apply_bottom_timer_region(timer, theme.ui_bottom_timer_region)
	timer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer.move_to_front()

func _ensure_bottom_timer_digits() -> Control:
	if bottom_reserve_layer == null:
		return null
	if bottom_timer_digits != null and is_instance_valid(bottom_timer_digits):
		return bottom_timer_digits
	var existing := bottom_reserve_layer.get_node_or_null("BottomTimerDigits") as Control
	if existing != null:
		bottom_timer_digits = existing
		return bottom_timer_digits
	var timer := BottomTimerDigitsScript.new() as Control
	timer.name = "BottomTimerDigits"
	timer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_reserve_layer.add_child(timer)
	bottom_timer_digits = timer
	return bottom_timer_digits

func _apply_bottom_timer_region(timer: Control, region: Vector4) -> void:
	if timer == null:
		return
	timer.anchor_left = region.x
	timer.anchor_top = region.y
	timer.anchor_right = region.x + region.z
	timer.anchor_bottom = region.y + region.w
	timer.offset_left = 0.0
	timer.offset_top = 0.0
	timer.offset_right = 0.0
	timer.offset_bottom = 0.0

func _apply_modal_theme(theme: ThemeConfig, viewport_size: Vector2) -> void:
	if theme == null:
		return
	var width_ratio := theme.ui_modal_landscape_width_ratio if viewport_size.x > viewport_size.y else theme.ui_modal_width_ratio
	var height_ratio := theme.ui_modal_landscape_height_ratio if viewport_size.x > viewport_size.y else theme.ui_modal_height_ratio
	var modal_width: float = viewport_size.x * width_ratio
	var modal_height: float = viewport_size.y * height_ratio
	_apply_modal_rect(settings_overlay, modal_width, modal_height)
	_apply_result_modal_theme(theme, viewport_size)
	if settings_close_btn:
		var close_padding := theme.ui_modal_close_button_padding
		settings_close_btn.offset_left = -theme.ui_modal_close_button_size - close_padding
		settings_close_btn.offset_top = close_padding
		settings_close_btn.offset_right = -close_padding
		settings_close_btn.offset_bottom = close_padding + theme.ui_modal_close_button_size

func _apply_result_modal_theme(theme: ThemeConfig, viewport_size: Vector2) -> void:
	if theme == null:
		return
	var width_ratio := theme.ui_result_modal_landscape_width_ratio if viewport_size.x > viewport_size.y else theme.ui_result_modal_width_ratio
	var height_ratio := theme.ui_result_modal_landscape_height_ratio if viewport_size.x > viewport_size.y else theme.ui_result_modal_height_ratio
	_apply_modal_rect(solved_popup, viewport_size.x * width_ratio, viewport_size.y * height_ratio)

func _apply_result_modal_text_style(theme: ThemeConfig) -> void:
	if theme == null:
		return
	var text_color := _get_result_modal_mode_color(theme, theme.ui_result_modal_text_color_by_mode, theme.text_color)
	var outline_color := _get_result_modal_mode_color(theme, theme.ui_result_modal_outline_color_by_mode, Color(0.0, 0.0, 0.0, 0.8))
	var outline_size := int(theme.ui_result_modal_outline_size_by_mode.get(String(theme.ui_generated_asset_mode), 1))
	if popup_title:
		popup_title.add_theme_color_override("font_color", text_color)
		popup_title.add_theme_color_override("font_outline_color", outline_color)
		popup_title.add_theme_constant_override("outline_size", outline_size)
		popup_title.add_theme_font_size_override("font_size", theme.ui_result_modal_title_font_size)
	if popup_moves:
		popup_moves.add_theme_color_override("font_color", text_color)
		popup_moves.add_theme_color_override("font_outline_color", outline_color)
		popup_moves.add_theme_constant_override("outline_size", outline_size)
		popup_moves.add_theme_font_size_override("font_size", theme.ui_result_modal_moves_font_size)

func _get_result_modal_mode_color(theme: ThemeConfig, source: Dictionary, fallback: Color) -> Color:
	if theme == null:
		return fallback
	var mode := String(theme.ui_generated_asset_mode)
	var value = source.get(mode, fallback)
	return value if value is Color else fallback

func _apply_modal_rect(control: Control, modal_width: float, modal_height: float) -> void:
	if control == null:
		return
	control.anchor_left = 0.5
	control.anchor_top = 0.5
	control.anchor_right = 0.5
	control.anchor_bottom = 0.5
	control.offset_left = -modal_width * 0.5
	control.offset_right = modal_width * 0.5
	control.offset_top = -modal_height * 0.5
	control.offset_bottom = modal_height * 0.5

func _set_generated_rect_texture(parent: Control, rect_name: String, texture: Texture2D, full_rect: bool, theme: ThemeConfig = null, asset_key: String = "") -> TextureRect:
	if parent == null or texture == null:
		return null
	var rect := _ensure_generated_ui_texture_rect(parent, rect_name)
	rect.texture = _get_generated_ui_region_texture(theme, asset_key, texture)
	rect.visible = true
	rect.stretch_mode = _get_generated_ui_stretch_mode(theme, asset_key)
	if full_rect:
		rect.anchor_left = 0.0
		rect.anchor_top = 0.0
		rect.anchor_right = 1.0
		rect.anchor_bottom = 1.0
		rect.offset_left = 0.0
		rect.offset_top = 0.0
		rect.offset_right = 0.0
		rect.offset_bottom = 0.0
	rect.move_to_front()
	parent.move_child(rect, 0)
	return rect

func _get_generated_ui_region_texture(theme: ThemeConfig, asset_key: String, texture: Texture2D) -> Texture2D:
	if theme == null or asset_key.is_empty():
		return texture
	var geometry := theme.get_ui_generated_asset_geometry(asset_key)
	if _get_generated_ui_runtime_region(theme, geometry) == "full_source":
		return texture
	var bboxes: Dictionary = geometry.get("alpha_bbox", {})
	var bbox = bboxes.get(String(theme.ui_generated_asset_mode), null)
	if not (bbox is Vector4):
		return texture
	var rect := Rect2(Vector2(bbox.x, bbox.y), Vector2(bbox.z, bbox.w))
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = rect
	return atlas

func _get_generated_ui_runtime_region(theme: ThemeConfig, geometry: Dictionary) -> String:
	var runtime_region := String(geometry.get("runtime_region", "alpha_bbox"))
	var by_mode: Dictionary = geometry.get("runtime_region_by_mode", {})
	var mode := String(theme.ui_generated_asset_mode)
	if by_mode.has(mode):
		return String(by_mode[mode])
	return runtime_region

func _get_generated_ui_stretch_mode(theme: ThemeConfig, asset_key: String = "") -> int:
	if theme == null:
		return TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var stretch_mode := String(theme.ui_top_tray_generated_object_stretch)
	if not asset_key.is_empty():
		var geometry := theme.get_ui_generated_asset_geometry(asset_key)
		stretch_mode = String(geometry.get("runtime_stretch_mode", stretch_mode))
	match stretch_mode:
		"keep_aspect_centered":
			return TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		"keep_aspect":
			return TextureRect.STRETCH_KEEP_ASPECT
		"scale":
			return TextureRect.STRETCH_SCALE
	return TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _ensure_generated_ui_texture_rect(parent: Control, rect_name: String) -> TextureRect:
	var existing := parent.get_node_or_null(rect_name)
	if existing is TextureRect:
		return existing as TextureRect
	var rect := TextureRect.new()
	rect.name = rect_name
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.z_index = -10
	parent.add_child(rect)
	generated_ui_rects[rect_name] = rect
	return rect

func _remove_generated_ui_texture_rect(parent: Control, rect_name: String) -> void:
	if parent == null:
		return
	var existing := parent.get_node_or_null(rect_name)
	if existing != null:
		existing.queue_free()
	generated_ui_rects.erase(rect_name)

func _apply_top_tray_button_icon_policy(button: Button, theme: ThemeConfig, region_key: String, tray_size: Vector2) -> void:
	if theme == null or button == null:
		return
	if String(theme.ui_top_tray_button_icon_source) == "baked_texture":
		_clear_top_tray_button_icon(button)
		return
	_apply_top_tray_button_icon(button, theme, region_key, tray_size)

func _clear_top_tray_button_icon(button: Button) -> void:
	if button == null:
		return
	button.icon = null
	var existing := button.get_node_or_null("GeneratedButtonIcon")
	if existing != null:
		existing.queue_free()

func _apply_top_tray_button_icon(button: Button, theme: ThemeConfig, region_key: String, tray_size: Vector2) -> void:
	if button == null or theme == null:
		return
	button.icon = null
	var path := String(theme.ui_top_tray_button_icon_paths.get(region_key, ""))
	if path.is_empty():
		push_error("Top tray button icon path missing: %s" % region_key)
		return
	var texture: Texture2D = load(path)
	if texture == null:
		push_error("Top tray button icon cannot load: %s" % path)
		return
	var icon_rect := _ensure_child_texture_rect(button, "GeneratedButtonIcon")
	icon_rect.texture = texture
	icon_rect.visible = true
	icon_rect.modulate = theme.ui_top_tray_button_icon_color
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.z_index = 80
	var icon_region_key := "%s_icon" % region_key
	var regions := _get_top_tray_regions(theme)
	if not regions.has(icon_region_key):
		push_error("Top tray button icon region missing: %s" % icon_region_key)
		icon_rect.visible = false
		return
	var candidate = regions.get(icon_region_key)
	if not (candidate is Vector4):
		push_error("Top tray button icon region should be Vector4: %s" % icon_region_key)
		icon_rect.visible = false
		return
	var region: Vector4 = candidate
	var basis := _get_top_tray_region_basis(theme, tray_size)
	var button_rect := Rect2(Vector2(button.offset_left, button.offset_top), Vector2(button.offset_right - button.offset_left, button.offset_bottom - button.offset_top))
	var icon_rect_global := Rect2(
		basis.position + Vector2(region.x * basis.size.x, region.y * basis.size.y),
		Vector2(region.z * basis.size.x, region.w * basis.size.y)
	)
	icon_rect.anchor_left = 0.0
	icon_rect.anchor_top = 0.0
	icon_rect.anchor_right = 0.0
	icon_rect.anchor_bottom = 0.0
	icon_rect.offset_left = icon_rect_global.position.x - button_rect.position.x
	icon_rect.offset_top = icon_rect_global.position.y - button_rect.position.y
	icon_rect.offset_right = icon_rect.offset_left + icon_rect_global.size.x
	icon_rect.offset_bottom = icon_rect.offset_top + icon_rect_global.size.y
	icon_rect.move_to_front()

func _ensure_child_texture_rect(parent: Control, rect_name: String) -> TextureRect:
	var existing := parent.get_node_or_null(rect_name)
	if existing is TextureRect:
		return existing as TextureRect
	var rect := TextureRect.new()
	rect.name = rect_name
	parent.add_child(rect)
	return rect

func _copy_control_rect(target: Control, source: Control, grow: float = 0.0) -> void:
	target.anchor_left = source.anchor_left
	target.anchor_top = source.anchor_top
	target.anchor_right = source.anchor_right
	target.anchor_bottom = source.anchor_bottom
	target.offset_left = source.offset_left - grow
	target.offset_top = source.offset_top - grow
	target.offset_right = source.offset_right + grow
	target.offset_bottom = source.offset_bottom + grow

func _has_generated_ui_asset(theme: ThemeConfig, asset_key: String) -> bool:
	if theme == null:
		return false
	var mode := String(theme.ui_generated_asset_mode)
	return not theme.get_ui_generated_asset_path(mode, asset_key).is_empty()

func _apply_top_tray_region(control: Control, theme: ThemeConfig, region_key: String, tray_size: Vector2) -> void:
	if control == null:
		return
	if theme == null:
		push_error("Top tray region %s missing theme" % region_key)
		return
	var regions := _get_top_tray_regions(theme)
	if not regions.has(region_key):
		push_error("Top tray region %s missing from active ThemeConfig top tray region set" % region_key)
		return
	var candidate = regions.get(region_key)
	if not (candidate is Vector4):
		push_error("Top tray region %s should be Vector4" % region_key)
		return
	var region: Vector4 = candidate
	var basis := _get_top_tray_region_basis(theme, tray_size)
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = basis.position.x + region.x * basis.size.x
	control.offset_top = basis.position.y + region.y * basis.size.y
	control.offset_right = control.offset_left + region.z * basis.size.x
	control.offset_bottom = control.offset_top + region.w * basis.size.y

func _get_top_tray_regions(theme: ThemeConfig) -> Dictionary:
	if theme == null:
		return {}
	var mode := String(theme.ui_generated_asset_mode)
	if theme.ui_top_tray_region_sets.has(mode):
		var mode_regions = theme.ui_top_tray_region_sets.get(mode)
		if mode_regions is Dictionary:
			return mode_regions
	return theme.ui_top_tray_regions

func _get_top_tray_region_basis(theme: ThemeConfig, tray_size: Vector2) -> Rect2:
	if theme == null:
		return Rect2(Vector2.ZERO, tray_size)
	var source_size := Vector2.ZERO
	var texture := theme.get_ui_generated_asset_texture(String(theme.ui_generated_asset_mode), "top_tray_layer")
	if texture != null:
		source_size = Vector2(float(texture.get_width()), float(texture.get_height()))
	else:
		var geometry := theme.get_ui_generated_asset_geometry("top_tray_layer")
		var source_sizes: Dictionary = geometry.get("source_size", {})
		var source_candidate = source_sizes.get(String(theme.ui_generated_asset_mode), null)
		if source_candidate is Vector2:
			source_size = source_candidate
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		push_error("Top tray generated asset source size missing")
		return Rect2(Vector2.ZERO, tray_size)
	var scale: float = min(tray_size.x / source_size.x, tray_size.y / source_size.y)
	var draw_size := source_size * scale
	return Rect2((tray_size - draw_size) * 0.5, draw_size)

func _apply_project_logo_texture(theme: ThemeConfig) -> void:
	if logo_core == null or theme == null:
		return
	var logo_texture: Texture2D = load(PROJECT_LOGO_PATH)
	if logo_texture == null:
		return
	var bbox := theme.ui_project_logo_alpha_bbox
	if bbox.z <= 0.0 or bbox.w <= 0.0:
		logo_core.texture = logo_texture
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = logo_texture
	atlas.region = Rect2(Vector2(bbox.x, bbox.y), Vector2(bbox.z, bbox.w))
	logo_core.texture = atlas

func _style_total_play_time_label(label: Label, theme: ThemeConfig) -> void:
	if label == null or theme == null:
		return
	var font: Font = load(theme.ui_top_tray_time_font_path)
	if font == null:
		push_error("Top tray time font missing: %s" % theme.ui_top_tray_time_font_path)
		return
	label.add_theme_font_override("font", font)
	label.add_theme_color_override("font_color", theme.ui_top_tray_time_color)
	label.add_theme_color_override("font_outline_color", theme.ui_top_tray_time_outline_color)
	label.add_theme_color_override("font_shadow_color", theme.ui_top_tray_time_shadow_color)
	label.add_theme_constant_override("outline_size", theme.ui_top_tray_time_outline_size)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("line_spacing", 0)
	_fit_time_label_to_region(label, theme, theme.ui_top_tray_moves_font_size)

func _style_left_stats_label(label: Label, theme: ThemeConfig) -> void:
	if label == null or theme == null:
		return
	var font: Font = load(theme.ui_top_tray_time_font_path)
	if font == null:
		push_error("Top tray info font missing: %s" % theme.ui_top_tray_time_font_path)
		return
	label.add_theme_font_override("font", font)
	label.add_theme_color_override("font_color", theme.ui_top_tray_time_color)
	label.add_theme_color_override("font_outline_color", theme.ui_top_tray_time_outline_color)
	label.add_theme_color_override("font_shadow_color", theme.ui_top_tray_time_shadow_color)
	label.add_theme_constant_override("outline_size", theme.ui_top_tray_time_outline_size)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("line_spacing", 0)
	_fit_left_stats_label_to_region(label, theme)

func _update_left_stats_label() -> void:
	if left_stats_label == null:
		return
	var theme := _get_active_theme()
	if theme == null:
		return
	left_stats_label.text = _format_left_stats_text(_get_top_tray_username(theme), _get_best_wave())
	_fit_left_stats_label_to_region(left_stats_label, theme)

func _format_left_stats_text(username: String, best_wave: int) -> String:
	var theme := _get_active_theme()
	var prefix := "BEST WAVE"
	var default_username := "PLAYER"
	if theme != null:
		prefix = theme.ui_top_tray_best_wave_label_prefix
		default_username = theme.ui_top_tray_default_username
	var display_name := username.strip_edges()
	if display_name.is_empty():
		display_name = default_username
	return "%s\n%s %d" % [display_name.to_upper(), prefix, max(1, best_wave)]

func _update_top_right_stats_label() -> void:
	if total_play_time_label == null:
		return
	var theme := _get_active_theme()
	if theme == null:
		return
	total_play_time_label.visible = true
	total_play_time_label.text = _format_top_right_stats_text(moves, theme)
	_fit_time_label_to_region(total_play_time_label, theme, theme.ui_top_tray_moves_font_size)

func _format_top_right_stats_text(current_moves: int, theme: ThemeConfig = null) -> String:
	var prefix := "MOVES"
	if theme != null:
		prefix = theme.ui_top_tray_moves_label_prefix
	return "%s %d" % [prefix, max(0, current_moves)]

func _get_top_tray_username(theme: ThemeConfig) -> String:
	var save_manager = _get_autoload("SaveManager")
	if save_manager != null and save_manager.has_method("get_username"):
		var saved_name := String(save_manager.get_username()).strip_edges()
		if not saved_name.is_empty():
			return saved_name
	return theme.ui_top_tray_default_username if theme != null else "PLAYER"

func _get_best_wave() -> int:
	var save_manager = _get_autoload("SaveManager")
	if save_manager != null and save_manager.has_method("get_setting"):
		return max(1, int(save_manager.get_setting("max_unlocked_level_id", level_id)))
	return max(1, level_id)

func _reset_level_timer(now: float = -1.0) -> void:
	level_start_time_sec = _resolve_sample_time(now)
	level_finished_time_sec = -1.0
	_update_total_play_time_label(level_start_time_sec)

func _mark_level_finished(now: float = -1.0) -> void:
	if level_finished_time_sec < 0.0:
		level_finished_time_sec = _resolve_sample_time(now)
	_update_total_play_time_label(level_finished_time_sec)

func _update_total_play_time_label(now: float = -1.0) -> void:
	var theme := _get_active_theme()
	if theme == null:
		return
	var sample_time := _resolve_sample_time(now)
	var end_time := level_finished_time_sec if level_finished_time_sec >= 0.0 else sample_time
	var elapsed_seconds: int = max(0, int(floor(end_time - level_start_time_sec)))
	var time_text := _format_duration_seconds(elapsed_seconds)
	_update_bottom_timer_digits(time_text, theme)

func _update_bottom_timer_digits(time_text: String, theme: ThemeConfig) -> void:
	if theme == null or not theme.ui_bottom_timer_enabled:
		return
	var timer := _ensure_bottom_timer_digits()
	if timer == null:
		return
	if not timer.visible:
		_apply_bottom_timer_theme(theme)
	timer.call("set_time_text", time_text)

func _resolve_sample_time(now: float = -1.0) -> float:
	if now >= 0.0:
		return now
	return Time.get_ticks_msec() / 1000.0

func _format_duration_seconds(total_seconds: int) -> String:
	var seconds: int = max(0, total_seconds)
	var hours := seconds / 3600
	var minutes := (seconds / 60) % 60
	var remaining_seconds := seconds % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, remaining_seconds]
	return "%02d:%02d" % [minutes, remaining_seconds]

func _fit_time_label_to_region(label: Label, theme: ThemeConfig, max_font_size: int = -1) -> void:
	if label == null or theme == null:
		return
	var rect_height: float = max(1.0, label.offset_bottom - label.offset_top)
	var rect_width: float = max(1.0, label.offset_right - label.offset_left)
	var padding_ratio: float = clampf(theme.ui_top_tray_time_fit_padding_ratio, 0.0, 0.45)
	var usable_width: float = max(1.0, rect_width * (1.0 - padding_ratio * 2.0))
	var usable_height: float = max(1.0, rect_height * (1.0 - padding_ratio * 2.0))
	var outline_size: int = max(0, theme.ui_top_tray_time_outline_size)
	var line_height_ratio: float = max(0.1, theme.ui_top_tray_stat_line_height_ratio)
	var lines := String(label.text).split("\n")
	var final_size := max_font_size if max_font_size > 0 else theme.ui_top_tray_stat_font_size
	var font: Font = label.get_theme_font("font")
	while final_size > theme.ui_top_tray_stat_min_font_size:
		var visual_height: float = float(final_size) * line_height_ratio * float(max(1, lines.size())) + float(outline_size * 2)
		var fits := visual_height <= usable_height
		if fits and font != null:
			for line in lines:
				var visual_width := font.get_string_size(String(line), HORIZONTAL_ALIGNMENT_LEFT, -1.0, final_size).x + float(outline_size * 2)
				if visual_width > usable_width:
					fits = false
					break
		if fits:
			break
		final_size -= 1
	label.add_theme_font_size_override("font_size", final_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.clip_contents = true

func _fit_left_stats_label_to_region(label: Label, theme: ThemeConfig) -> void:
	if label == null or theme == null:
		return
	_fit_time_label_to_region(label, theme)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

func _fit_stat_label_to_region(label: Label, theme: ThemeConfig) -> void:
	if label == null or theme == null:
		return
	var rect_height: float = max(1.0, label.offset_bottom - label.offset_top)
	var rect_width: float = max(1.0, label.offset_right - label.offset_left)
	var line_count: int = max(1, String(label.text).split("\n").size())
	var line_height_ratio: float = max(0.1, theme.ui_top_tray_stat_line_height_ratio)
	var fitted_size: float = floor(rect_height / (float(line_count) * line_height_ratio))
	var final_size: int = clampi(int(fitted_size), theme.ui_top_tray_stat_min_font_size, theme.ui_top_tray_stat_font_size)
	var font: Font = label.get_theme_font("font")
	if font != null:
		var fit_width: float = rect_width * clampf(theme.ui_top_tray_stat_fit_width_ratio, 0.1, 1.0)
		var lines := String(label.text).split("\n")
		while final_size > theme.ui_top_tray_stat_min_font_size:
			var fits_width := true
			for line in lines:
				if font.get_string_size(String(line), HORIZONTAL_ALIGNMENT_LEFT, -1.0, final_size).x > fit_width:
					fits_width = false
					break
			if fits_width:
				break
			final_size -= 1
	label.add_theme_font_size_override("font_size", final_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true

func _style_button_group(group: Node, theme: ThemeConfig, icon_size: float) -> void:
	if group == null:
		return
	for child in group.get_children():
		if child is Button:
			_style_single_button(child as Button, theme, icon_size)

func _style_single_button(button: Button, theme: ThemeConfig, size: float, bg_override: Color = Color.TRANSPARENT, transparent_hitbox: bool = false) -> void:
	if button == null:
		return
	button.text = ""
	button.custom_minimum_size = Vector2(size, size)
	button.add_theme_color_override("font_color", theme.text_color)
	button.add_theme_color_override("icon_normal_color", theme.text_color)
	button.add_theme_color_override("icon_hover_color", theme.accent_color)
	button.add_theme_color_override("icon_pressed_color", theme.accent_color)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := _make_transparent_control_style(6, 6, 6, 6) if transparent_hitbox else _make_button_style(theme, state, bg_override)
		button.add_theme_stylebox_override(state, style)

func _style_modal_action_buttons(group: Node, theme: ThemeConfig) -> void:
	if group == null:
		return
	for child in group.get_children():
		if child is Button:
			var button: Button = child as Button
			button.custom_minimum_size = Vector2(0.0, theme.ui_modal_action_button_height)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.icon = null
			button.expand_icon = false
			button.alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			button.clip_contents = true
			button.add_theme_color_override("font_color", theme.text_color)
			button.add_theme_color_override("icon_normal_color", theme.text_color)
			button.add_theme_color_override("icon_hover_color", theme.accent_color)
			button.add_theme_color_override("icon_pressed_color", theme.accent_color)
			for state in ["normal", "hover", "pressed", "focus", "disabled"]:
				button.add_theme_stylebox_override(state, _make_button_style(theme, state))

func _style_result_modal_action_buttons(group: Node, theme: ThemeConfig) -> void:
	if group == null:
		return
	for child in group.get_children():
		if child is Button:
			var button: Button = child as Button
			button.custom_minimum_size = Vector2(theme.ui_result_modal_action_button_width, theme.ui_result_modal_action_button_height)
			button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			button.icon = null
			button.expand_icon = false
			button.alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			button.clip_contents = true
			var text_color := _get_result_modal_mode_color(theme, theme.ui_result_modal_button_text_color_by_mode, theme.text_color)
			var bg_color := _get_result_modal_mode_color(theme, theme.ui_result_modal_button_bg_by_mode, theme.button_normal_bg)
			button.add_theme_font_size_override("font_size", theme.ui_result_modal_button_font_size)
			button.add_theme_color_override("font_color", text_color)
			button.add_theme_color_override("icon_normal_color", text_color)
			button.add_theme_color_override("icon_hover_color", theme.accent_color)
			button.add_theme_color_override("icon_pressed_color", theme.accent_color)
			for state in ["normal", "hover", "pressed", "focus", "disabled"]:
				button.add_theme_stylebox_override(state, _make_button_style(theme, state, bg_color))

func _make_button_style(theme: ThemeConfig, state: String, bg_override: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var bg := theme.button_normal_bg
	if bg_override.a > 0.0:
		bg = bg_override
	if state == "hover" or state == "focus":
		bg = bg.lightened(0.12) if bg_override.a > 0.0 else theme.button_hover_bg
	elif state == "pressed":
		bg = bg.darkened(0.18) if bg_override.a > 0.0 else theme.button_pressed_bg
	style.bg_color = bg
	style.border_color = theme.ui_top_tray_border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.shadow_color = theme.ui_top_tray_shadow_color
	style.shadow_size = 5
	style.shadow_offset = Vector2(0.0, 5.0)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _make_panel_style(
	bg_color: Color,
	border_color: Color,
	shadow_color: Color,
	glow_color: Color,
	corner_radius: int,
	border_width: int,
	shadow_size: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color.lerp(glow_color, 0.35)
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.shadow_color = shadow_color
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0.0, float(shadow_size))
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _make_transparent_control_style(left_margin: float, top_margin: float, right_margin: float, bottom_margin: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	style.set_corner_radius_all(0)
	style.shadow_color = Color.TRANSPARENT
	style.shadow_size = 0
	style.shadow_offset = Vector2.ZERO
	style.content_margin_left = left_margin
	style.content_margin_top = top_margin
	style.content_margin_right = right_margin
	style.content_margin_bottom = bottom_margin
	return style

func _draw_cyber_background(viewport_size: Vector2, theme: ThemeConfig) -> void:
	if debug_white_background:
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color.WHITE)
		return
	if theme == null or not theme.ui_background_depth_enabled:
		draw_rect(Rect2(Vector2.ZERO, viewport_size), theme.panel_bg_color if theme else Color(0.05, 0.05, 0.1))
		return
	var generated_bg := _get_generated_background_texture(theme, viewport_size)
	if generated_bg:
		_draw_texture_cover(generated_bg, Rect2(Vector2.ZERO, viewport_size))
		return
	var steps := 128
	for i in range(steps):
		var t := float(i) / float(max(1, steps - 1))
		var y0 := viewport_size.y * t
		var y1 := viewport_size.y * float(i + 1) / float(steps)
		var color := theme.ui_background_top_color.lerp(theme.ui_background_bottom_color, t)
		draw_rect(Rect2(0.0, y0, viewport_size.x, y1 - y0 + 1.0), color)
	var center := viewport_size * 0.5
	var radius: float = max(viewport_size.x, viewport_size.y) * 0.65
	draw_circle(center, radius, Color(theme.ui_background_vignette_color.r, theme.ui_background_vignette_color.g, theme.ui_background_vignette_color.b, theme.ui_background_vignette_color.a * 0.35))
	for i in range(34):
		var x := fposmod(float(i * 97), max(1.0, viewport_size.x))
		var y := fposmod(float(i * 53), max(1.0, viewport_size.y * 0.86))
		var alpha := theme.ui_background_star_color.a * (0.35 + 0.65 * fposmod(float(i * 17), 10.0) / 10.0)
		draw_circle(Vector2(x, y), 1.0 + fposmod(float(i), 3.0) * 0.45, Color(theme.ui_background_star_color.r, theme.ui_background_star_color.g, theme.ui_background_star_color.b, alpha))
	if grid != null:
		var board_rect := get_board_rect().grow(CELL_SIZE * 0.2)
		draw_rect(board_rect, theme.ui_board_shadow_color, true)

func _get_generated_background_texture(theme: ThemeConfig, viewport_size: Vector2) -> Texture2D:
	if theme == null:
		return null
	var mode := String(theme.ui_generated_asset_mode)
	var key := "background_full_landscape" if viewport_size.x >= viewport_size.y else "background_full_portrait"
	return _get_cached_generated_texture(theme, mode, key)

func _get_cached_generated_texture(theme: ThemeConfig, mode: String, asset_key: String) -> Texture2D:
	var cache_key := "%s/%s" % [mode, asset_key]
	if generated_ui_texture_cache.has(cache_key):
		return generated_ui_texture_cache[cache_key]
	var texture := theme.get_ui_generated_asset_texture(mode, asset_key)
	if texture:
		generated_ui_texture_cache[cache_key] = texture
	return texture

func _draw_texture_cover(texture: Texture2D, target_rect: Rect2) -> void:
	if texture == null or target_rect.size.x <= 0.0 or target_rect.size.y <= 0.0:
		return
	var native := texture.get_size()
	if native.x <= 0.0 or native.y <= 0.0:
		return
	var scale: float = max(target_rect.size.x / native.x, target_rect.size.y / native.y)
	var draw_size := native * scale
	var draw_pos := target_rect.position + (target_rect.size - draw_size) * 0.5
	draw_texture_rect(texture, Rect2(draw_pos, draw_size), false)

func _draw_cell_bg_texture(texture: Texture2D, target_rect: Rect2) -> void:
	if texture == null or target_rect.size.x <= 0.0 or target_rect.size.y <= 0.0:
		return
	var native := texture.get_size()
	if native.x <= 0.0 or native.y <= 0.0:
		return
	draw_texture_rect_region(texture, target_rect, Rect2(Vector2.ZERO, native))

func _draw() -> void:
	if grid == null:
		return
		
	var theme = _get_active_theme()
	
	# Draw background covering the viewport
	var viewport_size = get_viewport_rect().size
	_draw_cyber_background(viewport_size, theme)
	if theme != null and grid != null:
		var backplate := _get_cached_generated_texture(theme, String(theme.ui_generated_asset_mode), "board_backplate")
		if backplate:
			_draw_texture_cover(backplate, get_board_backplate_rect())
	
	var cell_texture_mode := String(theme.ui_generated_asset_mode) if theme else ""
	debug_last_cell_texture_mode = cell_texture_mode
	debug_last_cell_texture_path = theme.get_cell_bg_texture_path(cell_texture_mode) if theme else ""
	var cell_bg_texture: Texture2D = theme.get_cell_bg_texture_for_mode(cell_texture_mode) if theme else null
	debug_last_cell_texture_luminance = -1.0
	if cell_bg_texture != null:
		var cell_debug_image := cell_bg_texture.get_image()
		if cell_debug_image != null:
			debug_last_cell_texture_luminance = cell_debug_image.get_pixel(cell_debug_image.get_width() / 2, cell_debug_image.get_height() / 2).get_luminance()
	var has_textures = theme and cell_bg_texture != null and theme.pipe_i_texture != null
	debug_last_cell_has_textures = bool(has_textures)
	var fake_3d_enabled = theme and theme.fake_3d_enabled
	
	var bg_cell_color = theme.panel_bg_color.lightened(0.05) if theme else Color(0.2, 0.2, 0.2)
	debug_last_cell_fallback_color = bg_cell_color
	var border_color = theme.panel_border_color if theme else Color(0.4, 0.4, 0.4)
	var text_color = theme.text_color if theme else Color(0.9, 0.9, 0.9)
	var source_color = theme.accent_color if theme else Color(0.1, 0.3, 0.6)
	var target_color = theme.alert_color if theme else Color(0.6, 0.1, 0.1)
	
	var dot_ratio = theme.pipe_center_dot_ratio if theme else 0.07
	var line_ratio = theme.pipe_line_width_ratio if theme else 0.06
	var tip_ratio = theme.arrow_tip_ratio if theme else 0.42
	var base_ratio = theme.arrow_base_ratio if theme else 0.18
	var cell_inset = CELL_SIZE * theme.cell_inset_ratio if theme else 0.0
	var cell_bevel_width = max(1.0, CELL_SIZE * theme.cell_bevel_width_ratio) if theme else 2.0
	var cell_border_width = max(1.0, CELL_SIZE * theme.cell_border_width_ratio) if theme else 1.0
	
	var line_width: float = CELL_SIZE * line_ratio
	var ext := CELL_SIZE / 2.0
	
	# Get currently watered tiles for real-time flow visual feedback
	var watered_tiles = solver.get_watered_tiles(grid)
	
	# PASS 1: Draw board cells
	for y in range(grid.height):
		for x in range(grid.width):
			var cell_rect := Rect2(GRID_OFFSET + Vector2(x, y) * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE))
			
			if debug_white_cells:
				draw_rect(cell_rect, Color.WHITE)
				draw_rect(cell_rect, Color(0.78, 0.78, 0.78), false, 1.0)
			else:
				var draw_rect_area = cell_rect.grow(-cell_inset) if fake_3d_enabled else cell_rect
				if fake_3d_enabled:
					draw_rect(cell_rect, theme.cell_shadow_color)
				if has_textures:
					_draw_cell_bg_texture(cell_bg_texture, draw_rect_area)
				else:
					draw_rect(draw_rect_area, bg_cell_color)

				if fake_3d_enabled:
					draw_line(draw_rect_area.position, Vector2(draw_rect_area.end.x, draw_rect_area.position.y), theme.cell_highlight_color, cell_bevel_width)
					draw_line(draw_rect_area.position, Vector2(draw_rect_area.position.x, draw_rect_area.end.y), theme.cell_highlight_color, cell_bevel_width)
					draw_line(Vector2(draw_rect_area.position.x, draw_rect_area.end.y), draw_rect_area.end, theme.cell_shadow_color, cell_bevel_width)
					draw_line(Vector2(draw_rect_area.end.x, draw_rect_area.position.y), draw_rect_area.end, theme.cell_shadow_color, cell_bevel_width)

				var cell_border_color = border_color
				var border_w = cell_border_width
				if Vector2i(x, y) == grid.source_pos:
					cell_border_color = source_color
					border_w = cell_border_width * 2.0
				elif Vector2i(x, y) == grid.target_pos:
					cell_border_color = target_color
					border_w = cell_border_width * 2.0
					
				draw_rect(draw_rect_area, cell_border_color, false, border_w)
				
	# PASS 2 & 3: Draw conduits and energy endpoints
	if has_textures:
		for y in range(grid.height):
			for x in range(grid.width):
				var cell_pos := Vector2i(x, y)
				var tile = grid.get_tile(x, y)
				var center := GRID_OFFSET + Vector2(x, y) * CELL_SIZE + Vector2(CELL_SIZE/2, CELL_SIZE/2)
				var tr = _get_tile_texture_and_rotation(x, y, theme)
				
				if tr.texture != null:
					var tex: Texture2D = tr.texture
					var base_tex: Texture2D = tr.get("base_texture", tex)
					var geometry: Resource = tr.get("geometry", null)
					var asset_key := String(geometry.get("asset_key")) if geometry != null else ""
					var is_watered = watered_tiles.has(cell_pos)
					var draw_tex: Texture2D = _get_pipe_draw_texture_for_state(tr, is_watered, theme)
					var energy_overlay_source_tex: Texture2D = base_tex if asset_key == "target" else tex
					var draw_energy_overlay := _should_draw_energy_overlay_for_asset(asset_key, theme)
					var overlay_tex: Texture2D = _get_energy_overlay_texture_for_draw(energy_overlay_source_tex, cell_pos, is_watered, geometry) if draw_energy_overlay else null
					var draw_tex_size = draw_tex.get_size()
					var draw_rect = geometry.get_draw_rect() if geometry != null and geometry.has_method("get_draw_rect") else Rect2(-draw_tex_size / 2.0, draw_tex_size)
					var draw_scale_factor = geometry.get_frame_scale(CELL_SIZE) if geometry != null and geometry.has_method("get_frame_scale") else Vector2(CELL_SIZE / draw_tex_size.x, CELL_SIZE / draw_tex_size.y)
					var mod_color = _get_pipe_modulate_for_state(asset_key, is_watered, theme)
					
					var rot = visual_rotations[y][x] if visual_rotations.size() > y and visual_rotations[y].size() > x else tr.rotation
					
					var base_offset = Vector2.ZERO
					var anchor_offset = Vector2.ZERO
					var visual_scale = 1.0
					if tile != null and tile.has("type"):
						var type = tile["type"]
						var ports = grid.get_tile_ports(x, y)
						var active_count = 0
						for p in ports:
							if p: active_count += 1
						base_offset = PipeVisualMapping.get_tile_offset("Cap" if active_count == 1 else type, active_count)
						if type == "L" and active_count == 2:
							visual_scale = PipeVisualMapping.get_l_visual_scale()
							anchor_offset = PipeVisualMapping.get_l_anchor_offset(ports, CELL_SIZE, visual_scale)
							
					var scale_offset = base_offset * draw_scale_factor
					var rotated_offset = scale_offset.rotated(rot)
					draw_scale_factor *= visual_scale
					rotated_offset += anchor_offset
					
					if theme.pipe_shadow_alpha > 0.0:
						var shadow_ratio = theme.pipe_shadow_offset_ratio
						var shadow_offset = Vector2(CELL_SIZE * shadow_ratio.x, CELL_SIZE * shadow_ratio.y)
						draw_set_transform(center + shadow_offset + rotated_offset, rot, draw_scale_factor)
						draw_texture_rect(base_tex, draw_rect, false, Color(0, 0, 0, theme.pipe_shadow_alpha))
						draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
					
					# Draw main pipe
					draw_set_transform(center + rotated_offset, rot, draw_scale_factor)
					draw_texture_rect(draw_tex, draw_rect, false, mod_color)
					if draw_energy_overlay and overlay_tex != null and geometry != null:
						draw_texture_rect(overlay_tex, _get_energy_draw_rect_for_geometry(geometry), false, Color(1.0, 1.0, 1.0, 1.0))
					if asset_key == "target" and geometry != null:
						_draw_target_core_overlay(geometry, is_watered, theme)
					draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
					
					# Water flow glowing vector overlay removed as requested
					pass
	else:
		# PASS 2: Draw Pipe Outlines (creates thick dark contours for physical depth)
		var outline_color = Color(0.0, 0.0, 0.0, 0.75)
		var outline_width = line_width * 1.6
		for y in range(grid.height):
			for x in range(grid.width):
				var center := GRID_OFFSET + Vector2(x, y) * CELL_SIZE + Vector2(CELL_SIZE/2, CELL_SIZE/2)
				var ports = grid.get_tile_ports(x, y)
				var is_source = Vector2i(x, y) == grid.source_pos
				var is_target = Vector2i(x, y) == grid.target_pos
				
				if not (is_source or is_target):
					if ports[0]:
						draw_line(center, center + Vector2(0, -ext), outline_color, outline_width)
					if ports[1]:
						draw_line(center, center + Vector2(ext, 0), outline_color, outline_width)
					if ports[2]:
						draw_line(center, center + Vector2(0, ext), outline_color, outline_width)
					if ports[3]:
						draw_line(center, center + Vector2(-ext, 0), outline_color, outline_width)
					draw_circle(center, CELL_SIZE * dot_ratio * 1.3, outline_color)
					
		# PASS 3: Draw Pipe Cores and Source/Target Arrow HUDs
		for y in range(grid.height):
			for x in range(grid.width):
				var cell_pos := Vector2i(x, y)
				var center := GRID_OFFSET + Vector2(x, y) * CELL_SIZE + Vector2(CELL_SIZE/2, CELL_SIZE/2)
				var ports = grid.get_tile_ports(x, y)
				var is_source = cell_pos == grid.source_pos
				var is_target = cell_pos == grid.target_pos
				
				# Live watered path coloring
				var is_watered = watered_tiles.has(cell_pos)
				var pipe_color = source_color if is_watered else text_color
				
				if is_source or is_target:
					var directions_vec = [
						Vector2(0, -1), # Top
						Vector2(1, 0),  # Right
						Vector2(0, 1),  # Bottom
						Vector2(-1, 0)  # Left
					]
					var arrow_color = text_color if not is_watered else text_color.lightened(0.3)
					
					var circle_bg = theme.button_normal_bg if theme else Color(0.05, 0.05, 0.1)
					if is_watered:
						circle_bg = text_color.darkened(0.7)
					draw_circle(center, CELL_SIZE * dot_ratio, circle_bg)
					
					for i in range(4):
						if ports[i]:
							var dir_vec = directions_vec[i]
							var tip = center + dir_vec * (CELL_SIZE * tip_ratio)
							var perp = Vector2(-dir_vec.y, dir_vec.x)
							var base = center + dir_vec * (CELL_SIZE * base_ratio)
							var left_p = base + perp * (CELL_SIZE * 0.12)
							var right_p = base - perp * (CELL_SIZE * 0.12)
							
							draw_line(center, base, arrow_color, line_width)
							draw_polygon(
								PackedVector2Array([tip, left_p, right_p]),
								PackedColorArray([arrow_color])
							)
				else:
					if ports[0]:
						draw_line(center, center + Vector2(0, -ext), pipe_color, line_width)
					if ports[1]:
						draw_line(center, center + Vector2(ext, 0), pipe_color, line_width)
					if ports[2]:
						draw_line(center, center + Vector2(0, ext), pipe_color, line_width)
					if ports[3]:
						draw_line(center, center + Vector2(-ext, 0), pipe_color, line_width)
					draw_circle(center, CELL_SIZE * dot_ratio, pipe_color)

func _unhandled_input(event: InputEvent) -> void:
	if is_solved or grid == null:
		return
	if _is_modal_overlay_visible():
		return
		
	if event is InputEventMouseButton and event.pressed:
		try_rotate_cell(get_cell_at_screen_position(event.position), true)

func _on_level_solved() -> void:
	_mark_level_finished()
	# Play levelup sfx
	var audio_manager = _get_autoload("AudioManager")
	if audio_manager:
		audio_manager.set_music_mode("relax")
		audio_manager.play_sfx("target_reached")

		
	# Update save progress
	var save_manager = _get_autoload("SaveManager")
	if save_manager:
		var max_unlocked = save_manager.get_setting("max_unlocked_level_id", 1)
		if level_id >= max_unlocked:
			save_manager.set_setting("max_unlocked_level_id", level_id + 1)
	_update_left_stats_label()
			
	# Submit high score to LeaderboardManager
	var leaderboard_manager = _get_autoload("LeaderboardManager")
	if leaderboard_manager:
		leaderboard_manager.submit_score(moves, "classic")
		
	# Trigger AdManager interstitial ad
	var ad_manager = _get_autoload("AdManager")
	if ad_manager:
		ad_manager.show_interstitial()
		
	# Populate solved popup
	if popup_moves:
		popup_moves.text = "MOVES USED: %d" % moves
	
	# With procedural levels, there is always a next level
	if next_btn:
		next_btn.text = "NEXT LEVEL"
		
	if solved_popup:
		solved_popup.visible = true

func _on_reset_btn_pressed() -> void:
	if is_solved:
		return
	var audio_manager = _get_autoload("AudioManager")
	if audio_manager:
		audio_manager.set_music_mode("relax")
		audio_manager.play_sfx("reset")
	reset_current_level(true)

func _on_back_btn_pressed() -> void:
	var scene_router = _get_autoload("SceneRouter")
	if scene_router:
		scene_router.change_scene("res://Scenes/Main/LevelSelect.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Main/LevelSelect.tscn")

func _on_mute_btn_pressed() -> void:
	var audio_manager = _get_autoload("AudioManager")
	if audio_manager:
		audio_manager.toggle_master_mute()
		_update_mute_button()
		_update_settings_buttons()

func _on_settings_btn_pressed() -> void:
	_play_ui_sfx("ui_popup")
	_close_leaderboard_overlay()
	if settings_overlay:
		settings_overlay.visible = true
	_update_settings_buttons()

func _on_settings_close_btn_pressed() -> void:
	_play_ui_sfx("ui_button")
	if settings_overlay:
		settings_overlay.visible = false

func _on_settings_master_audio_btn_pressed() -> void:
	var audio_manager = _get_autoload("AudioManager")
	if audio_manager:
		audio_manager.toggle_master_mute()
		if not audio_manager.is_master_muted():
			audio_manager.play_sfx("ui_button")
	_update_settings_buttons()

func _on_settings_music_btn_pressed() -> void:
	var audio_manager = _get_autoload("AudioManager")
	if audio_manager:
		audio_manager.toggle_music_mute()
		audio_manager.play_sfx("ui_button")
	_update_settings_buttons()

func _on_settings_sfx_btn_pressed() -> void:
	var audio_manager = _get_autoload("AudioManager")
	if audio_manager:
		var current: float = float(audio_manager.get_bus_volume("SFX"))
		audio_manager.set_bus_volume("SFX", 0.65 if current <= 0.0001 else 0.0)
		audio_manager.play_sfx("ui_button")
	_update_settings_buttons()

func _on_settings_theme_mode_btn_pressed() -> void:
	var theme := _get_active_theme()
	if theme == null:
		return
	var next_mode := _get_next_ui_mode(theme)
	if next_mode.is_empty() or next_mode == String(theme.ui_generated_asset_mode):
		return
	_play_ui_sfx("ui_button")
	_set_active_ui_mode(next_mode, true)

func _on_settings_restart_btn_pressed() -> void:
	if settings_overlay:
		settings_overlay.visible = false
	_on_reset_btn_pressed()

func _on_settings_level_select_btn_pressed() -> void:
	_play_ui_sfx("ui_button")
	_on_back_btn_pressed()

func _on_leaderboard_btn_pressed() -> void:
	_play_ui_sfx("ui_popup")
	if settings_overlay:
		settings_overlay.visible = false
	if leaderboard_overlay_root == null:
		return
	leaderboard_overlay_root.visible = true
	for child in leaderboard_overlay_root.get_children():
		child.queue_free()
	var leaderboard_popup_scene: PackedScene = load(LEADERBOARD_POPUP_SCENE_PATH) as PackedScene
	if leaderboard_popup_scene == null:
		return
	var popup := leaderboard_popup_scene.instantiate()
	if popup.has_signal("dismissed"):
		popup.connect("dismissed", Callable(self, "_on_leaderboard_popup_dismissed"))
	_configure_leaderboard_popup(popup, _get_active_theme())

func _configure_leaderboard_popup(popup: Node, theme: ThemeConfig) -> void:
	UiModalPresenter.show_leaderboard_modal(leaderboard_overlay_root, popup, theme)

func _close_leaderboard_overlay() -> void:
	if leaderboard_overlay_root == null:
		return
	UiModalPresenter.hide_modal_root(leaderboard_overlay_root)

func _on_leaderboard_popup_dismissed() -> void:
	if leaderboard_overlay_root == null:
		return
	leaderboard_overlay_root.visible = false

func _is_modal_overlay_visible() -> bool:
	var settings_visible := settings_overlay != null and settings_overlay.visible
	var leaderboard_visible := leaderboard_overlay_root != null and leaderboard_overlay_root.visible
	var solved_visible := solved_popup != null and solved_popup.visible
	return settings_visible or leaderboard_visible or solved_visible

func _play_ui_sfx(event_name: String) -> void:
	var audio_manager = _get_autoload("AudioManager")
	if audio_manager:
		audio_manager.play_sfx(event_name)

func _update_settings_buttons() -> void:
	var audio_manager = _get_autoload("AudioManager")
	if audio_manager != null and settings_master_audio_btn:
		settings_master_audio_btn.text = "MASTER AUDIO OFF" if audio_manager.is_master_muted() else "MASTER AUDIO ON"
	if audio_manager != null and settings_music_btn:
		settings_music_btn.text = "MUSIC OFF" if audio_manager.is_music_muted() else "MUSIC ON"
	if audio_manager != null and settings_sfx_btn:
		settings_sfx_btn.text = "SFX OFF" if audio_manager.get_bus_volume("SFX") <= 0.0001 else "SFX ON"
	if settings_theme_mode_btn:
		var theme := _get_active_theme()
		var mode := String(theme.ui_generated_asset_mode).to_upper() if theme != null else ""
		settings_theme_mode_btn.text = "THEME: %s" % mode if not mode.is_empty() else "THEME"

func _update_mute_button() -> void:
	_update_settings_buttons()





func _on_next_btn_pressed() -> void:
	var next_lvl = level_id + 1
	var game_state = _get_autoload("GameState")
	if game_state:
		game_state.current_level_id = next_lvl
	var scene_router = _get_autoload("SceneRouter")
	if scene_router:
		scene_router.change_scene("res://Scenes/Gameplay/GameScene.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Gameplay/GameScene.tscn")

# Helper to determine which texture and rotation angle to draw for a tile at (x, y)
# Helper to determine which texture and rotation angle to draw for a tile at (x, y)
func _get_cell_key(cell_pos: Vector2i) -> String:
	return "%d,%d" % [cell_pos.x, cell_pos.y]

func _reset_energy_animation() -> void:
	energy_flow_start_times.clear()
	flow_visual_state.clear()

func _update_flow_visual_state(now: float = -1.0) -> void:
	if grid == null:
		flow_visual_state.clear()
		return
	var sample_time := now
	if sample_time < 0.0:
		sample_time = Time.get_ticks_msec() / 1000.0
	flow_visual_state = FlowVisualStateScript.build(grid, energy_flow_start_times, sample_time)

func _prime_vfx_visual_state() -> void:
	if grid == null or solver == null:
		_sync_vfx_layer()
		return
	_update_flow_visual_state()
	_sync_vfx_layer()

func _ensure_vfx_layer() -> void:
	if pipe_vfx_layer != null:
		return
	pipe_vfx_layer = PipeVfxLayerScript.new()
	pipe_vfx_layer.name = "PipeVfxLayer"
	pipe_vfx_layer.z_index = 80
	add_child(pipe_vfx_layer)

func _sync_vfx_layer() -> void:
	if pipe_vfx_layer == null:
		return
	var theme = _get_active_theme()
	var geometry_by_cell := {}
	if grid != null and theme != null:
		var cells_to_map := {}
		for raw_cell_pos in flow_visual_state.keys():
			cells_to_map[raw_cell_pos] = true
		if pipe_vfx_layer.has_method("get_transition_state"):
			var transition: Dictionary = pipe_vfx_layer.get_transition_state()
			for raw_lost_cell in transition.get("lost_cells", []):
				cells_to_map[raw_lost_cell] = true
			for raw_contact in transition.get("lost_contacts", []):
				var contact: Dictionary = raw_contact
				cells_to_map[contact.get("cell_pos", Vector2i(-1, -1))] = true
		var rotation_state = pipe_vfx_layer.get("rotation_event_state")
		if typeof(rotation_state) == TYPE_DICTIONARY:
			var rotation_cell: Vector2i = rotation_state.get("cell_pos", Vector2i(-1, -1))
			cells_to_map[rotation_cell] = true
		for raw_cell_pos in cells_to_map.keys():
			var cell_pos: Vector2i = raw_cell_pos
			if not grid.is_valid_pos(cell_pos):
				continue
			var tile_info := _get_tile_texture_and_rotation(cell_pos.x, cell_pos.y, theme)
			var geometry: Resource = tile_info.get("geometry", null)
			if geometry != null:
				geometry_by_cell[cell_pos] = geometry
	pipe_vfx_layer.set_visual_context(flow_visual_state, geometry_by_cell, GRID_OFFSET, CELL_SIZE)
	if theme != null and pipe_vfx_layer.has_method("apply_theme_config"):
		pipe_vfx_layer.apply_theme_config(theme, CELL_SIZE)

func _set_vfx_transition_state(previous_flow_state: Dictionary, current_flow_state: Dictionary, changed_cell: Vector2i) -> void:
	if pipe_vfx_layer == null or not pipe_vfx_layer.has_method("set_transition_state"):
		return
	var transition := VfxTransitionStateScript.build(previous_flow_state, current_flow_state, changed_cell, Time.get_ticks_msec() / 1000.0)
	pipe_vfx_layer.set_transition_state(transition)

func _set_vfx_rotation_event(cell_pos: Vector2i) -> void:
	if pipe_vfx_layer == null or not pipe_vfx_layer.has_method("set_rotation_event"):
		return
	pipe_vfx_layer.set_rotation_event(cell_pos, Time.get_ticks_msec() / 1000.0)

func _set_vfx_win_state() -> void:
	if pipe_vfx_layer == null or not pipe_vfx_layer.has_method("set_win_state"):
		return
	pipe_vfx_layer.set_win_state({"event_time": Time.get_ticks_msec() / 1000.0})

func _sync_energy_flow_starts(watered_tiles: Dictionary) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var stale_keys := []
	for key in energy_flow_start_times.keys():
		var parts = String(key).split(",")
		if parts.size() != 2:
			stale_keys.append(key)
			continue
		var cell_pos := Vector2i(int(parts[0]), int(parts[1]))
		if not watered_tiles.has(cell_pos):
			stale_keys.append(key)
	for key in stale_keys:
		energy_flow_start_times.erase(key)
	for raw_cell_pos in watered_tiles.keys():
		var cell_pos: Vector2i = raw_cell_pos
		var key := _get_cell_key(cell_pos)
		if not energy_flow_start_times.has(key):
			energy_flow_start_times[key] = now

func _has_active_energy_animation(watered_tiles: Dictionary) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	var theme := _get_active_theme()
	var full_duration := _get_energy_animation_duration("", theme)
	for raw_cell_pos in watered_tiles.keys():
		var cell_pos: Vector2i = raw_cell_pos
		var key := _get_cell_key(cell_pos)
		if not energy_flow_start_times.has(key):
			return true
		if now - float(energy_flow_start_times[key]) < full_duration:
			return true
	return false

func _has_active_target_core_blink() -> bool:
	var theme := _get_active_theme()
	return theme != null and float(theme.target_core_blink_period) > 0.0

func _get_energy_frame_index(cell_pos: Vector2i, is_watered: bool, asset_key: String = "") -> int:
	if not is_watered:
		return 0
	var age := _get_energy_age_for_cell(cell_pos)
	return _get_energy_frame_index_for_age(age, asset_key)

func _get_energy_age_for_cell(cell_pos: Vector2i) -> float:
	if flow_visual_state.has(cell_pos):
		var entry: Dictionary = flow_visual_state[cell_pos]
		return max(0.0, float(entry.get("age", 0.0)))
	var key := _get_cell_key(cell_pos)
	if not energy_flow_start_times.has(key):
		energy_flow_start_times[key] = Time.get_ticks_msec() / 1000.0
	return max(0.0, Time.get_ticks_msec() / 1000.0 - float(energy_flow_start_times[key]))

func _get_energy_frame_index_for_age(age: float, asset_key: String = "") -> int:
	var theme := _get_active_theme()
	var frame_duration := _get_energy_frame_duration(asset_key, theme)
	var frame_count := _get_energy_frame_count(theme)
	return clampi(int(floor(max(0.0, age) / frame_duration)), 0, frame_count - 1)

func _get_energy_sheet_relative_path(texture_path: String) -> String:
	var theme := _get_active_theme()
	var texture_prefix := _get_energy_texture_prefix(theme)
	if not texture_path.begins_with(texture_prefix):
		return ""
	var relative_path := texture_path.trim_prefix(texture_prefix)
	if relative_path == "pipe_cap.png":
		return "cap/pipe_cap_sheet.png"
	if relative_path == "source.png":
		return "source/source_sheet.png"
	if relative_path == "target.png":
		return "target/target_sheet.png"
	if not relative_path.ends_with(".png"):
		return ""
	return relative_path.trim_suffix(".png") + "_sheet.png"

func _get_energy_sheet_path_for_texture(texture_path: String) -> String:
	var relative_sheet_path := _get_energy_sheet_relative_path(texture_path)
	if relative_sheet_path.is_empty():
		return ""
	var theme := _get_active_theme()
	var sheet_root := _get_energy_sheet_root(theme)
	var sheet_path := sheet_root + "/" + relative_sheet_path
	if ResourceLoader.exists(sheet_path):
		return sheet_path
	return ""

func _get_energy_frame_texture(sheet_path: String, frame_index: int) -> Texture2D:
	var frame_key := "%s#%d" % [sheet_path, frame_index]
	if energy_frame_texture_cache.has(frame_key):
		return energy_frame_texture_cache[frame_key]
	var sheet_tex: Texture2D = energy_sheet_texture_cache.get(sheet_path) as Texture2D
	if sheet_tex == null:
		sheet_tex = load(sheet_path)
		if sheet_tex == null:
			return null
		energy_sheet_texture_cache[sheet_path] = sheet_tex
	var expected_size := _get_energy_sheet_expected_size(_get_active_theme())
	if sheet_tex.get_size() != expected_size:
		push_warning("Energy sheet has wrong size: %s got %s expected %s" % [sheet_path, str(sheet_tex.get_size()), str(expected_size)])
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet_tex
	var frame_size := _get_energy_sheet_frame_size(_get_active_theme())
	atlas.region = Rect2(Vector2(frame_size.x * frame_index, 0.0), frame_size)
	energy_frame_texture_cache[frame_key] = atlas
	return atlas

func _get_energy_frame_region_for_geometry(geometry: Resource, frame_index: int) -> Rect2:
	var frame_size := _get_energy_sheet_frame_size(_get_active_theme())
	if geometry == null:
		return Rect2(Vector2(frame_size.x * frame_index, 0.0), frame_size)
	return Rect2(
		Vector2(frame_size.x * frame_index + geometry.energy_rect.position.x, geometry.energy_rect.position.y),
		geometry.energy_rect.size
	)

func _get_energy_draw_rect_for_geometry(geometry: Resource) -> Rect2:
	if geometry == null:
		var frame_size := _get_energy_sheet_frame_size(_get_active_theme())
		return Rect2(-frame_size / 2.0, frame_size)
	return Rect2(geometry.energy_rect.position - geometry.draw_origin, geometry.energy_rect.size)

func _get_energy_overlay_texture_for_draw(base_texture: Texture2D, cell_pos: Vector2i, is_watered: bool, geometry: Resource) -> Texture2D:
	if base_texture == null or geometry == null or not is_watered:
		return null
	var sheet_path := _get_energy_sheet_path_for_texture(base_texture.resource_path)
	if sheet_path.is_empty():
		return null
	var frame_index := _get_energy_frame_index(cell_pos, is_watered, String(geometry.get("asset_key")))
	var frame_key := "%s#%d#%s" % [sheet_path, frame_index, geometry.asset_key]
	if energy_frame_texture_cache.has(frame_key):
		return energy_frame_texture_cache[frame_key]
	var sheet_tex: Texture2D = energy_sheet_texture_cache.get(sheet_path) as Texture2D
	if sheet_tex == null:
		sheet_tex = load(sheet_path)
		if sheet_tex == null:
			return null
		energy_sheet_texture_cache[sheet_path] = sheet_tex
	var expected_size := _get_energy_sheet_expected_size(_get_active_theme())
	if sheet_tex.get_size() != expected_size:
		push_warning("Energy sheet has wrong size: %s got %s expected %s" % [sheet_path, str(sheet_tex.get_size()), str(expected_size)])
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet_tex
	atlas.region = _get_energy_frame_region_for_geometry(geometry, frame_index)
	energy_frame_texture_cache[frame_key] = atlas
	return atlas

func _is_energy_overlay_draw_enabled(theme: ThemeConfig) -> bool:
	if theme == null:
		return false
	return bool(theme.get("energy_overlay_draw_enabled"))

func _should_draw_energy_overlay_for_asset(asset_key: String, theme: ThemeConfig) -> bool:
	if theme == null:
		return false
	if _is_energy_overlay_draw_enabled(theme):
		return true
	if asset_key == "target":
		return bool(theme.get("target_energy_overlay_draw_enabled"))
	return false

func _get_target_core_alpha(is_watered: bool, theme: ThemeConfig, now: float = -1.0) -> float:
	if theme == null:
		return 0.0
	var sample_time := now
	if sample_time < 0.0:
		sample_time = Time.get_ticks_msec() / 1000.0
	var period: float = max(0.001, theme.target_core_blink_period)
	var pulse := (sin((sample_time / period) * TAU) + 1.0) * 0.5
	var min_alpha := theme.target_core_powered_alpha_min if is_watered else theme.target_core_idle_alpha_min
	var max_alpha := theme.target_core_powered_alpha_max if is_watered else theme.target_core_idle_alpha_max
	return lerpf(min_alpha, max_alpha, pulse)

func _get_target_core_radius_px(is_watered: bool, theme: ThemeConfig) -> float:
	if theme == null:
		return 0.0
	return theme.target_core_powered_radius_px if is_watered else theme.target_core_idle_radius_px

func _draw_target_core_overlay(geometry: Resource, is_watered: bool, theme: ThemeConfig) -> void:
	var radius := _get_target_core_radius_px(is_watered, theme)
	var alpha := _get_target_core_alpha(is_watered, theme)
	if radius <= 0.0 or alpha <= 0.0:
		return
	var core_center: Vector2 = geometry.get("core_center") if geometry != null else Vector2(256.0, 256.0)
	var draw_origin: Vector2 = geometry.get("draw_origin") if geometry != null else Vector2(256.0, 256.0)
	var local_center := core_center - draw_origin
	var base_color: Color = theme.target_core_powered_color if is_watered else theme.target_core_idle_color
	base_color.a *= alpha
	draw_circle(local_center, radius * 1.25, Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.14))
	draw_circle(local_center, radius * 0.78, Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.34))
	draw_circle(local_center, radius * 0.42, base_color)
	draw_arc(local_center, radius * 0.72, 0.0, TAU, 32, Color(base_color.r, base_color.g, base_color.b, base_color.a * 0.7), max(2.0, radius * 0.08))

func _get_pipe_draw_texture_for_state(tile_info: Dictionary, is_watered: bool, theme: ThemeConfig) -> Texture2D:
	var texture: Texture2D = tile_info.get("texture", null)
	var base_texture: Texture2D = tile_info.get("base_texture", texture)
	var geometry: Resource = tile_info.get("geometry", null)
	var asset_key := String(geometry.get("asset_key")) if geometry != null else ""
	if asset_key == "target" and is_watered and theme != null and theme.target_texture_watered != null:
		return texture
	return base_texture

func _get_pipe_modulate_for_state(asset_key: String, is_watered: bool, theme: ThemeConfig) -> Color:
	if theme == null:
		return Color.WHITE
	if asset_key == "target":
		return theme.target_powered_modulate if is_watered else theme.target_dry_modulate
	if is_watered:
		if theme.get("pipe_i_texture_watered") == null:
			return theme.pipe_powered_fallback_modulate
		return theme.pipe_powered_modulate
	if theme.get("pipe_i_texture_watered") != null:
		return theme.pipe_dry_modulate
	return Color.WHITE

func _get_energy_texture_for_draw(base_texture: Texture2D, cell_pos: Vector2i, is_watered: bool, asset_key: String = "") -> Texture2D:
	if base_texture == null or not is_watered:
		return null
	var sheet_path := _get_energy_sheet_path_for_texture(base_texture.resource_path)
	if sheet_path.is_empty():
		return null
	var frame_index := _get_energy_frame_index(cell_pos, is_watered, asset_key)
	var frame_texture := _get_energy_frame_texture(sheet_path, frame_index)
	return frame_texture

func _get_energy_frame_count(theme: ThemeConfig) -> int:
	if theme != null:
		return max(1, int(theme.energy_sheet_frame_count))
	return ENERGY_SHEET_FRAME_COUNT

func _get_energy_sheet_frame_size(theme: ThemeConfig) -> Vector2:
	if theme != null:
		return theme.energy_sheet_frame_size
	return ENERGY_SHEET_FRAME_SIZE

func _get_energy_frame_duration(asset_key: String, theme: ThemeConfig) -> float:
	if theme != null and theme.has_method("get_energy_frame_duration"):
		return theme.get_energy_frame_duration(asset_key)
	return ENERGY_FRAME_DURATION

func _get_energy_animation_duration(asset_key: String, theme: ThemeConfig) -> float:
	if theme != null and theme.has_method("get_energy_animation_duration"):
		return theme.get_energy_animation_duration(asset_key)
	return ENERGY_FRAME_DURATION * float(max(0, ENERGY_SHEET_FRAME_COUNT - 1))

func _get_energy_sheet_expected_size(theme: ThemeConfig) -> Vector2:
	if theme != null and theme.has_method("get_energy_sheet_expected_size"):
		return theme.get_energy_sheet_expected_size()
	return Vector2(ENERGY_SHEET_FRAME_SIZE.x * ENERGY_SHEET_FRAME_COUNT, ENERGY_SHEET_FRAME_SIZE.y)

func _get_energy_sheet_root(theme: ThemeConfig) -> String:
	if theme != null and theme.energy_sheet_root != "":
		return theme.energy_sheet_root
	return ENERGY_SHEET_ROOT

func _get_energy_texture_prefix(theme: ThemeConfig) -> String:
	if theme != null and theme.energy_texture_prefix != "":
		return theme.energy_texture_prefix
	return ENERGY_THEME_TEXTURE_PREFIX

func _get_tile_texture_and_rotation(x: int, y: int, theme: ThemeConfig) -> Dictionary:
	if theme == null:
		return {"texture": null, "rotation": 0.0}
	var ports = grid.get_tile_ports(x, y)
	var is_source = Vector2i(x, y) == grid.source_pos
	var is_target = Vector2i(x, y) == grid.target_pos
	
	# Get watered state
	var watered_tiles = solver.get_watered_tiles(grid)
	var is_watered = watered_tiles.has(Vector2i(x, y))
	
	# Compute global flow mask: Top=1, Right=2, Bottom=4, Left=8
	var global_flow_mask = 0
	if is_watered or is_source:
		var dirs = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
		for i in range(4):
			if ports[i]:
				var neighbor_pos = Vector2i(x, y) + dirs[i]
				if is_source:
					if grid.is_valid_pos(neighbor_pos) and watered_tiles.has(neighbor_pos):
						var neighbor_ports = grid.get_tile_ports(neighbor_pos.x, neighbor_pos.y)
						var opposite_port = (i + 2) % 4
						if neighbor_ports[opposite_port]:
							global_flow_mask |= (1 << i)
				else:
					if grid.is_valid_pos(neighbor_pos) and watered_tiles.has(neighbor_pos):
						var neighbor_ports = grid.get_tile_ports(neighbor_pos.x, neighbor_pos.y)
						var opposite_port = (i + 2) % 4
						if neighbor_ports[opposite_port]:
							global_flow_mask |= (1 << i)

	if is_source:
		var rot = 0.0
		for i in range(4):
			if ports[i]:
				rot = i * PI / 2.0
				break
		var dirs = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
		for i in range(4):
			if ports[i]:
				var neighbor_pos = Vector2i(x, y) + dirs[i]
				if grid.is_valid_pos(neighbor_pos) and watered_tiles.has(neighbor_pos):
					var neighbor_ports = grid.get_tile_ports(neighbor_pos.x, neighbor_pos.y)
					var opposite_port = (i + 2) % 4
					if neighbor_ports[opposite_port]:
						rot = i * PI / 2.0
						break
		return {"texture": theme.source_texture, "base_texture": theme.source_texture, "rotation": rot, "geometry": theme.get_asset_geometry("source")}
		
	if is_target:
		var rot = 0.0
		for i in range(4):
			if ports[i]:
				rot = i * PI / 2.0
				break
		if is_watered:
			var dirs = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
			for i in range(4):
				if ports[i]:
					var neighbor_pos = Vector2i(x, y) + dirs[i]
					if grid.is_valid_pos(neighbor_pos) and watered_tiles.has(neighbor_pos):
						var neighbor_ports = grid.get_tile_ports(neighbor_pos.x, neighbor_pos.y)
						var opposite_port = (i + 2) % 4
						if neighbor_ports[opposite_port]:
							rot = i * PI / 2.0
							break
		var tex = theme.target_texture
		if is_watered and theme.get("target_texture_watered") != null:
			tex = theme.target_texture_watered
		return {"texture": tex, "base_texture": theme.target_texture, "rotation": rot, "geometry": theme.get_asset_geometry("target")}
		
	var active_indices = []
	for i in range(4):
		if ports[i]:
			active_indices.append(i)
			
	var count = active_indices.size()
	
	if count == 0:
		return {"texture": null, "rotation": 0.0}
	elif count == 1:
		# Cap pipe
		var rot = PipeVisualMapping.get_rotation_index_for_ports(ports) * PI / 2.0
		var tex = theme.pipe_cap_texture
		if is_watered and theme.get("pipe_cap_texture_watered") != null:
			tex = theme.pipe_cap_texture_watered
		return {"texture": tex, "base_texture": theme.pipe_cap_texture, "rotation": rot, "geometry": theme.get_asset_geometry("cap")}
	elif count == 2:
		var diff = abs(active_indices[0] - active_indices[1])
		var is_l = (diff != 2)
		if not is_l:
			# Straight pipe (I)
			var rot_index = PipeVisualMapping.get_rotation_index_for_ports(ports)
			var rot = rot_index * PI / 2.0
			var local_flow_mask = PipeVisualMapping.get_local_flow_mask(global_flow_mask, rot_index)
					
			var tex = theme.pipe_i_texture
			if theme.get("i_slices") != null and theme.i_slices.size() > 0:
				for slice in theme.i_slices:
					if slice != null and slice.flow_mask == local_flow_mask:
						tex = slice.texture
						break
			elif is_watered and theme.get("pipe_i_texture_watered") != null:
				tex = theme.pipe_i_texture_watered
				
			return {"texture": tex, "base_texture": theme.pipe_i_texture, "rotation": rot, "geometry": theme.get_asset_geometry("I")}
		else:
			# Corner L-pipe
			var rot_index = PipeVisualMapping.get_rotation_index_for_ports(ports)
			var visual_rot_index = PipeVisualMapping.get_l_visual_rotation_index(rot_index)
			var rot = visual_rot_index * PI / 2.0
			var local_flow_mask = PipeVisualMapping.get_l_local_flow_mask(global_flow_mask, rot_index)
					
			var tex = theme.pipe_l_texture
			if theme.get("l_slices") != null and theme.l_slices.size() > 0:
				for slice in theme.l_slices:
					if slice != null and slice.flow_mask == local_flow_mask:
						tex = slice.texture
						break
			elif is_watered and theme.get("pipe_l_texture_watered") != null:
				tex = theme.pipe_l_texture_watered
				
			return {"texture": tex, "base_texture": theme.pipe_l_texture, "rotation": rot, "geometry": theme.get_asset_geometry("L")}
	elif count == 3:
		# T-junction
		var rot_index = PipeVisualMapping.get_rotation_index_for_ports(ports)
		var rot = rot_index * PI / 2.0
		var local_flow_mask = PipeVisualMapping.get_local_flow_mask(global_flow_mask, rot_index)
				
		var tex = theme.pipe_t_texture
		if theme.get("t_slices") != null and theme.t_slices.size() > 0:
			for slice in theme.t_slices:
				if slice != null and slice.flow_mask == local_flow_mask:
					tex = slice.texture
					break
		elif is_watered and theme.get("pipe_t_texture_watered") != null:
			tex = theme.pipe_t_texture_watered
			
		return {"texture": tex, "base_texture": theme.pipe_t_texture, "rotation": rot, "geometry": theme.get_asset_geometry("T")}
	elif count == 4:
		# Cross (rotation dynamically synced with logic)
		var rot_index = PipeVisualMapping.get_rotation_index_for_ports(ports)
		var rot = rot_index * PI / 2.0
		var local_flow_mask = PipeVisualMapping.get_local_flow_mask(global_flow_mask, rot_index)
				
		var tex = theme.pipe_x_texture
		if theme.get("cross_slices") != null and theme.cross_slices.size() > 0:
			for slice in theme.cross_slices:
				if slice != null and slice.flow_mask == local_flow_mask:
					tex = slice.texture
					break
		elif is_watered and theme.get("pipe_x_texture_watered") != null:
			tex = theme.pipe_x_texture_watered
		return {"texture": tex, "base_texture": theme.pipe_x_texture, "rotation": rot, "geometry": theme.get_asset_geometry("X")}
		
	return {"texture": null, "rotation": 0.0}

func _init_visual_rotations() -> void:
	visual_rotations.clear()
	var theme = _get_active_theme()
	if grid == null:
		return
	for y in range(grid.height):
		var row = []
		for x in range(grid.width):
			var tr = _get_tile_texture_and_rotation(x, y, theme)
			row.append(tr.rotation)
		visual_rotations.append(row)
