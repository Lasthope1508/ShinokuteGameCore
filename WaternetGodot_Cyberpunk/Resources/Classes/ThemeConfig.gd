class_name ThemeConfig extends Resource

var _cell_bg_texture_cache: Dictionary = {}

@export_group("Theme Info")
@export var theme_name: String = "default"
@export var theme_title: String = "GLYPHFLOW ARRAYS"
@export var theme_subtitle: String = "Connection Puzzle"

@export_group("Brand Colors")
@export var text_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var accent_color: Color = Color(0.0, 1.0, 1.0, 1.0) # Used for source tile and HUD accent
@export var alert_color: Color = Color(1.0, 0.0, 0.5, 1.0)  # Used for target tile

@export_group("UI Button Styles")
@export var button_normal_bg: Color = Color(0.05, 0.05, 0.1, 1.0)
@export var button_hover_bg: Color = Color(0.1, 0.1, 0.2, 1.0)
@export var button_pressed_bg: Color = Color(0.0, 0.15, 0.3, 1.0)
@export var button_border_color: Color = Color(0.0, 1.0, 1.0, 1.0)
@export var button_corner_radius: float = 8.0
@export var button_border_width: int = 2

@export_group("UI Panel Styles")
@export var panel_bg_color: Color = Color(0.02, 0.02, 0.06, 1.0)
@export var panel_border_color: Color = Color(0.0, 1.0, 1.0, 1.0)
@export var popup_corner_radius: float = 8.0
@export var popup_border_width: int = 2

@export_group("Typography")
@export var custom_font: Font

@export_group("Layout Specs")
@export var menu_margin_x: float = 40.0
@export var menu_margin_y: float = 100.0
@export var menu_button_width: float = 300.0
@export var play_button_height: float = 70.0
@export var ui_main_menu_secondary_button_height: float = 60.0
@export var utility_button_height: float = 50.0
@export var level_button_size: float = 100.0
@export var grid_columns: int = 4
@export var levels_per_page: int = 20
@export var ui_level_select_button_font_size: int = 24
@export var ui_level_select_locked_alpha: float = 0.4
@export var ui_level_select_pagination_button_width: float = 60.0
@export var ui_level_select_grid_h_separation: int = 20
@export var ui_level_select_grid_v_separation: int = 20
@export var ui_main_menu_gap: int = 30
@export var ui_main_menu_title_font_size: int = 48
@export var ui_main_menu_subtitle_font_size: int = 24
@export var ui_main_menu_primary_button_font_size: int = 28
@export var ui_main_menu_secondary_button_font_size: int = 20
@export var ui_main_menu_copyright_font_size: int = 14
@export var ui_main_menu_logo_size: float = 160.0
@export var ui_level_select_title_font_size: int = 36
@export var ui_level_select_gap: int = 25
@export var ui_level_select_pagination_gap: int = 30
@export var ui_splash_gap: int = 15
@export var ui_splash_studio_font_size: int = 42
@export var ui_splash_presents_font_size: int = 20
@export var ui_splash_fade_in_duration: float = 1.2
@export var ui_splash_hold_duration: float = 1.5
@export var ui_splash_fade_out_duration: float = 0.8
@export var game_top_margin: float = 160.0
@export var game_landscape_top_margin: float = 0.0
@export var game_bottom_margin: float = 200.0
@export var game_side_padding: float = 40.0
@export var ui_landscape_board_avoid_top_tray_enabled: bool = true
@export var ui_landscape_board_top_tray_gap: float = 24.0
@export var ui_landscape_board_bottom_safe_margin: float = 24.0
@export var ui_top_tray_height: float = 118.0
@export var ui_top_tray_layer_height: float = 132.0
@export var ui_top_tray_width_ratio: float = 0.76
@export var ui_top_tray_landscape_width_height_ratio: float = 0.76
@export var ui_top_tray_portrait_height_ratio: float = 0.20
@export var ui_top_tray_landscape_height_ratio: float = 0.16
@export var ui_top_tray_generated_object_stretch: String = "keep_aspect_centered"
@export var ui_top_tray_capsule_width_ratio: float = 0.74
@export var ui_top_tray_logo_size: float = 78.0
@export var ui_top_tray_icon_button_size: float = 42.0
@export var ui_top_tray_button_icon_scale: float = 0.48
@export var ui_top_tray_button_icon_color: Color = Color(1.0, 1.0, 1.0, 0.96)
@export var ui_top_tray_button_icon_paths: Dictionary = {
	"left_floating_menu": "res://Assets/Icons/menuList.png",
	"right_floating_replay": "res://Assets/Icons/return.png"
}
@export var ui_top_tray_stat_height: float = 34.0
@export var ui_top_tray_stat_side_slot_width_ratio: float = 0.29
@export var ui_top_tray_stat_center_slot_width_ratio: float = 0.42
@export var ui_top_tray_stat_font_size: int = 18
@export var ui_top_tray_stat_min_font_size: int = 8
@export var ui_top_tray_stat_line_height_ratio: float = 1.05
@export var ui_top_tray_stat_fit_width_ratio: float = 0.94
@export var ui_top_tray_time_font_path: String = "res://Assets/Fonts/Poppins-Bold.ttf"
@export var ui_top_tray_default_username: String = "PLAYER"
@export var ui_top_tray_best_wave_label_prefix: String = "BEST WAVE"
@export var ui_top_tray_moves_label_prefix: String = "MOVES"
@export var ui_top_tray_time_color: Color = Color(0.52, 1.0, 0.18, 1.0)
@export var ui_top_tray_time_outline_color: Color = Color(0.0, 0.03, 0.02, 0.96)
@export var ui_top_tray_time_shadow_color: Color = Color(0.1, 1.0, 0.82, 0.44)
@export var ui_top_tray_time_outline_size: int = 4
@export var ui_top_tray_time_fit_padding_ratio: float = 0.12
@export var ui_top_tray_logo_center_y_ratio: float = 0.43
@export var ui_project_logo_alpha_bbox: Vector4 = Vector4(0, 0, 423, 485)
@export var ui_top_tray_regions: Dictionary = {
	"left_floating_menu": Vector4(0.0544, 0.7751, 0.0688, 0.2167),
	"left_floating_menu_icon": Vector4(0.0862, 0.84, 0.0331, 0.0868),
	"left_stats_readout": Vector4(0.147, 0.3494, 0.1843, 0.1843),
	"logo_core": Vector4(0.3908, 0.3076, 0.2122, 0.3988),
	"right_floating_replay": Vector4(0.8768, 0.7751, 0.0688, 0.2167),
	"right_floating_replay_icon": Vector4(0.9043, 0.84, 0.0331, 0.0868),
	"right_stats_readout": Vector4(0.6145, 0.3409, 0.0977, 0.1794),
	"total_play_time_readout": Vector4(0.6687, 0.3494, 0.1843, 0.1843)
}
@export var ui_top_tray_region_sets: Dictionary = {
	"dark": {
		"left_floating_menu": Vector4(0.0544, 0.7751, 0.0688, 0.2167),
		"left_floating_menu_icon": Vector4(0.0862, 0.84, 0.0331, 0.0868),
		"left_stats_readout": Vector4(0.147, 0.3494, 0.1843, 0.1843),
		"logo_core": Vector4(0.3908, 0.3076, 0.2122, 0.3988),
		"right_floating_replay": Vector4(0.8768, 0.7751, 0.0688, 0.2167),
		"right_floating_replay_icon": Vector4(0.9043, 0.84, 0.0331, 0.0868),
		"right_stats_readout": Vector4(0.6145, 0.3409, 0.0977, 0.1794),
		"total_play_time_readout": Vector4(0.6687, 0.3494, 0.1843, 0.1843)
	},
	"light": {
		"left_floating_menu": Vector4(0.1433, 0.8066, 0.0742, 0.1934),
		"left_floating_menu_icon": Vector4(0.163958, 0.849153, 0.035616, 0.092832),
		"left_stats_readout": Vector4(0.1542, 0.4166, 0.1683, 0.129),
		"logo_core": Vector4(0.41, 0.29, 0.18, 0.36),
		"right_floating_replay": Vector4(0.7817, 0.8084, 0.0767, 0.1916),
		"right_floating_replay_icon": Vector4(0.798786, 0.850601, 0.036816, 0.091968),
		"right_stats_readout": Vector4(0.6767, 0.4219, 0.1608, 0.1219),
		"total_play_time_readout": Vector4(0.6767, 0.4219, 0.1608, 0.1219)
	}
}
@export var ui_top_tray_art_stack: Array = ["top_tray_layer"]
@export var ui_top_tray_art_node_names: Dictionary = {
	"top_tray_layer": "GeneratedTopTrayLayer",
	"stats_capsule": "GeneratedStatsCapsule",
	"logo_socket": "GeneratedLogoSocket"
}
@export var ui_top_tray_region_source_size: Vector2 = Vector2(2032, 774)
@export var ui_top_tray_region_source_sizes: Dictionary = {
	"dark": Vector2(2032, 774),
	"light": Vector2(1829, 860)
}
@export var ui_top_tray_region_pixel_rects: Dictionary = {
	"left_floating_menu": Vector4(111, 600, 140, 168),
	"left_floating_menu_icon": Vector4(175, 650, 67, 67),
	"left_stats_readout": Vector4(299, 270, 374, 143),
	"logo_core": Vector4(794, 238, 431, 309),
	"right_floating_replay": Vector4(1782, 600, 140, 168),
	"right_floating_replay_icon": Vector4(1838, 650, 67, 67),
	"right_stats_readout": Vector4(1249, 264, 199, 139),
	"total_play_time_readout": Vector4(1359, 270, 374, 143)
}
@export var ui_top_tray_region_pixel_rect_sets: Dictionary = {
	"dark": {
		"left_floating_menu": Vector4(111, 600, 140, 168),
		"left_floating_menu_icon": Vector4(175, 650, 67, 67),
		"left_stats_readout": Vector4(299, 270, 374, 143),
		"logo_core": Vector4(794, 238, 431, 309),
		"right_floating_replay": Vector4(1782, 600, 140, 168),
		"right_floating_replay_icon": Vector4(1838, 650, 67, 67),
		"right_stats_readout": Vector4(1249, 264, 199, 139),
		"total_play_time_readout": Vector4(1359, 270, 374, 143)
	},
	"light": {
		"left_floating_menu": Vector4(262, 694, 136, 166),
		"left_floating_menu_icon": Vector4(300, 730, 65, 80),
		"left_stats_readout": Vector4(282, 358, 308, 111),
		"logo_core": Vector4(750, 249, 329, 310),
		"right_floating_replay": Vector4(1430, 695, 140, 165),
		"right_floating_replay_icon": Vector4(1461, 732, 67, 79),
		"right_stats_readout": Vector4(1238, 363, 294, 105),
		"total_play_time_readout": Vector4(1238, 363, 294, 105)
	}
}
@export var ui_top_tray_board_gap: float = 22.0
@export var ui_playboard_region_sets: Dictionary = {
	"light": {
		"landscape": {
			"board_backplate_rect": Vector4(0.319277, 0.210843, 0.350699, 0.623465),
			"playboard_rect": Vector4(0.329825, 0.229594, 0.329604, 0.585963)
		}
	}
}
@export var ui_playboard_region_source_sizes: Dictionary = {
	"landscape": Vector2(1280, 720)
}
@export var ui_playboard_region_pixel_rect_sets: Dictionary = {
	"light": {
		"landscape": {
			"board_backplate_rect": Vector4(409, 152, 449, 449),
			"playboard_rect": Vector4(422, 165, 422, 422)
		}
	}
}
@export var ui_bottom_reserve_width_ratio: float = 0.76
@export var ui_bottom_reserve_height_ratio: float = 0.105
@export var ui_bottom_reserve_bottom_margin_ratio: float = 0.018
@export var ui_bottom_reserve_min_height: float = 72.0
@export var ui_bottom_reserve_max_height: float = 138.0
@export var ui_top_tray_bg_color: Color = Color(0.04, 0.12, 0.14, 0.92)
@export var ui_top_tray_border_color: Color = Color(0.2, 0.9, 1.0, 0.88)
@export var ui_top_tray_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.55)
@export var ui_top_tray_glow_color: Color = Color(0.18, 1.0, 0.86, 0.28)
@export var ui_top_tray_menu_color: Color = Color(0.72, 0.12, 1.0, 1.0)
@export var ui_top_tray_replay_color: Color = Color(1.0, 0.72, 0.08, 1.0)
@export var ui_hud_margin_left: float = 22.0
@export var ui_hud_margin_top: float = 24.0
@export var ui_hud_margin_right: float = 22.0
@export var ui_hud_margin_bottom: float = 32.0
@export var ui_background_depth_enabled: bool = true
@export var ui_background_top_color: Color = Color(0.05, 0.02, 0.14, 1.0)
@export var ui_background_bottom_color: Color = Color(0.0, 0.02, 0.05, 1.0)
@export var ui_background_vignette_color: Color = Color(0.0, 0.0, 0.0, 0.55)
@export var ui_background_star_color: Color = Color(0.4, 1.0, 0.85, 0.35)
@export var ui_generated_asset_mode: String = "dark"
@export var ui_cell_texture_strict_mode_paths: bool = false
@export var ui_cell_texture_paths: Dictionary = {}
@export var ui_generated_asset_paths: Dictionary = {}
@export var ui_generated_asset_geometry: Dictionary = {}
@export var ui_board_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.38)
@export var ui_modal_width_ratio: float = 0.58
@export var ui_modal_height_ratio: float = 0.42
@export var ui_modal_landscape_width_ratio: float = 0.32
@export var ui_modal_landscape_height_ratio: float = 0.46
@export var ui_modal_close_button_size: float = 44.0
@export var ui_modal_close_button_padding: float = 8.0
@export var ui_modal_action_button_height: float = 54.0
@export var ui_modal_content_gap: float = 16.0
@export var ui_modal_content_margin_x: int = 28
@export var ui_modal_content_margin_top: int = 52
@export var ui_modal_content_margin_bottom: int = 28
@export var ui_profile_popup_content_margin_x: int = 30
@export var ui_profile_popup_content_margin_top: int = 58
@export var ui_profile_popup_content_margin_bottom: int = 30
@export var ui_profile_popup_title_font_size: int = 28
@export var ui_profile_popup_field_gap: int = 15
@export var ui_profile_popup_list_gap: int = 10
@export var ui_profile_popup_save_button_width: float = 80.0
@export var ui_profile_popup_score_font_size: int = 18
@export var pipe_line_width_ratio: float = 0.06
@export var pipe_center_dot_ratio: float = 0.07
@export var arrow_tip_ratio: float = 0.42
@export var arrow_base_ratio: float = 0.18

@export_group("Fake 3D Visuals")
@export var fake_3d_enabled: bool = false
@export var texture_native_size: Vector2 = Vector2(256.0, 256.0)
@export var cell_inset_ratio: float = 0.0
@export var cell_bevel_width_ratio: float = 0.0
@export var cell_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.0)
@export var cell_highlight_color: Color = Color(1.0, 1.0, 1.0, 0.0)
@export var cell_border_width_ratio: float = 0.0
@export var pipe_shadow_offset_ratio: Vector2 = Vector2.ZERO
@export var pipe_shadow_alpha: float = 0.0
@export var pipe_dry_modulate: Color = Color(0.08, 0.08, 0.08, 1.0)
@export var pipe_powered_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var pipe_powered_fallback_modulate: Color = Color(0.85, 0.95, 1.0, 1.0)
@export var target_dry_modulate: Color = Color(0.32, 0.34, 0.34, 1.0)
@export var target_powered_modulate: Color = Color(1.25, 1.35, 1.2, 1.0)
@export var target_core_idle_color: Color = Color(0.24, 1.0, 0.08, 1.0)
@export var target_core_powered_color: Color = Color(0.52, 1.0, 0.12, 1.0)
@export var target_core_idle_alpha_min: float = 0.1
@export var target_core_idle_alpha_max: float = 0.24
@export var target_core_powered_alpha_min: float = 0.72
@export var target_core_powered_alpha_max: float = 1.0
@export var target_core_idle_radius_px: float = 18.0
@export var target_core_powered_radius_px: float = 58.0
@export var target_core_blink_period: float = 0.78

@export_group("Energy Animation")
@export var energy_sheet_frame_count: int = 8
@export var energy_sheet_frame_size: Vector2 = Vector2(512.0, 512.0)
@export var energy_default_frame_duration: float = 0.055
@export var energy_frame_duration_by_asset_key: Dictionary = {}
@export var energy_sheet_root: String = "res://Assets/Themes/cyberpunk_theme/energy_sheets"
@export var energy_texture_prefix: String = "res://Assets/Themes/cyberpunk_theme/"
@export var energy_sheet_manifest_path: String = "res://Assets/Themes/cyberpunk_theme/energy_sheets/manifest.json"
@export var energy_overlay_draw_enabled: bool = true
@export var target_energy_overlay_draw_enabled: bool = true

@export_group("Audio")
@export var bgm_path: String = ""
@export var bgm_manifest_path: String = ""
@export var bgm_mobile_sample_rate: int = 44100
@export var bgm_mobile_channels: int = 1
@export var bgm_vorbis_quality: int = 0
@export var sfx_event_paths: Dictionary = {}
@export var sfx_event_volume_offsets: Dictionary = {}
@export var sfx_event_pitch_variation: Dictionary = {}

@export_group("VFX Visuals")
@export var vfx_enabled: bool = true
@export var vfx_debug_visible: bool = false
@export var vfx_debug_line_color: Color = Color(0.22, 1.0, 0.08, 0.7)
@export var vfx_debug_line_width_ratio: float = 0.018
@export var vfx_contact_spark_color: Color = Color(0.22, 1.0, 0.08, 0.9)
@export var vfx_contact_spark_duration: float = 0.22
@export var vfx_contact_spark_radius_ratio: float = 0.13
@export var vfx_trail_color: Color = Color(0.22, 1.0, 0.08, 0.62)
@export var vfx_trail_draw_enabled: bool = true
@export var vfx_trail_duration: float = 0.34
@export var vfx_trail_width_ratio: float = 0.045
@export var vfx_trail_min_alpha: float = 0.28
@export var vfx_path_wave_color: Color = Color(0.65, 1.0, 0.22, 0.82)
@export var vfx_path_wave_draw_enabled: bool = true
@export var vfx_path_wave_period: float = 0.95
@export var vfx_path_wave_segment_ratio: float = 0.22
@export var vfx_path_wave_width_ratio: float = 0.026
@export var vfx_path_wave_alpha: float = 0.72
@export var vfx_path_wave_max_effects: int = 80
@export var vfx_path_wave_min_particles_per_output: int = 1
@export var vfx_path_wave_max_particles_per_output: int = 4
@export var vfx_path_wave_density_curve: float = 1.35
@export var vfx_path_wave_order_phase_offset: float = 0.11
@export var vfx_energy_stream_enabled: bool = true
@export var vfx_energy_stream_color: Color = Color(0.36, 1.0, 0.78, 0.9)
@export var vfx_energy_stream_period: float = 0.7
@export var vfx_energy_stream_alpha: float = 0.7
@export var vfx_energy_stream_width_ratio: float = 0.032
@export var vfx_energy_stream_glow_width_ratio: float = 0.13
@export var vfx_energy_stream_shimmer_width_ratio: float = 0.052
@export var vfx_energy_stream_shimmer_segment_ratio: float = 0.34
@export var vfx_energy_stream_pulse_alpha_ratio: float = 0.28
@export var vfx_energy_stream_order_phase_offset: float = 0.09
@export var vfx_energy_stream_max_effects: int = 120
@export var vfx_target_pulse_color: Color = Color(0.22, 1.0, 0.08, 0.82)
@export var vfx_target_pulse_duration: float = 0.48
@export var vfx_target_pulse_radius_ratio: float = 0.28
@export var vfx_target_pulse_ring_width_ratio: float = 0.035
@export var vfx_source_emission_color: Color = Color(0.22, 1.0, 0.08, 0.78)
@export var vfx_source_emission_duration: float = 0.42
@export var vfx_source_emission_radius_ratio: float = 0.24
@export var vfx_source_emission_ring_width_ratio: float = 0.032
@export var vfx_idle_hum_color: Color = Color(0.22, 1.0, 0.08, 0.34)
@export var vfx_idle_hum_delay: float = 0.72
@export var vfx_idle_hum_alpha: float = 0.34
@export var vfx_idle_hum_width_ratio: float = 0.018
@export var vfx_idle_hum_glow_width_ratio: float = 0.14
@export var vfx_idle_hum_core_width_ratio: float = 0.045
@export var vfx_idle_hum_radius_ratio: float = 0.23
@export var vfx_idle_hum_period: float = 0.75
@export var vfx_idle_hum_radius_pulse_ratio: float = 0.35
@export var vfx_idle_hum_alpha_pulse_ratio: float = 0.72
@export var vfx_disconnect_decay_color: Color = Color(0.22, 1.0, 0.08, 0.32)
@export var vfx_disconnect_decay_duration: float = 0.32
@export var vfx_disconnect_decay_alpha: float = 0.28
@export var vfx_error_spark_color: Color = Color(1.0, 0.28, 0.08, 0.82)
@export var vfx_error_spark_duration: float = 0.18
@export var vfx_error_spark_radius_ratio: float = 0.1
@export var vfx_rotation_spark_color: Color = Color(0.92, 1.0, 0.18, 0.86)
@export var vfx_rotation_spark_duration: float = 0.26
@export var vfx_rotation_spark_radius_ratio: float = 0.31
@export var vfx_rotation_spark_ray_count: int = 8
@export var vfx_rotation_spark_width_ratio: float = 0.018
@export var vfx_win_burst_color: Color = Color(0.32, 1.0, 0.96, 0.9)
@export var vfx_win_burst_duration: float = 0.9
@export var vfx_win_burst_radius_ratio: float = 0.34
@export var vfx_win_burst_ring_width_ratio: float = 0.028
@export var vfx_win_burst_max_cells: int = 36
@export var vfx_lightning_enabled: bool = true
@export var vfx_lightning_texture: Texture2D
@export var vfx_lightning_frame_size: Vector2i = Vector2i(256, 256)
@export var vfx_lightning_columns: int = 16
@export var vfx_lightning_rows: int = 16
@export var vfx_lightning_frame_count: int = 250
@export var vfx_lightning_period: float = 4.1666667
@export var vfx_lightning_contact_period: float = 0.4
@export var vfx_lightning_color: Color = Color(0.72, 0.92, 1.0, 0.86)
@export var vfx_lightning_alpha: float = 0.72
@export var vfx_lightning_scale_ratio: float = 0.78
@export var vfx_lightning_max_arcs: int = 10
@export var vfx_lightning_cell_stride: int = 3
@export var vfx_lightning_min_order_progress: float = 0.18
@export var vfx_lightning_contact_bias: float = 0.68
@export var vfx_debug_anchor_color: Color = Color(1.0, 1.0, 1.0, 0.8)
@export var vfx_debug_input_color: Color = Color(1.0, 0.32, 0.08, 0.85)
@export var vfx_debug_output_color: Color = Color(0.22, 1.0, 0.08, 0.85)
@export var vfx_debug_order_color: Color = Color(0.1, 0.75, 1.0, 0.85)

@export_group("Asset Geometry")
@export var cell_geometry: Resource
@export var source_geometry: Resource
@export var target_geometry: Resource
@export var pipe_cap_geometry: Resource
@export var pipe_i_geometry: Resource
@export var pipe_l_geometry: Resource
@export var pipe_t_geometry: Resource
@export var pipe_x_geometry: Resource

func get_required_asset_keys() -> Array:
	return ["cell", "source", "target", "cap", "I", "L", "T", "X"]

func get_all_asset_geometries() -> Dictionary:
	return {
		"cell": cell_geometry,
		"source": source_geometry,
		"target": target_geometry,
		"cap": pipe_cap_geometry,
		"I": pipe_i_geometry,
		"L": pipe_l_geometry,
		"T": pipe_t_geometry,
		"X": pipe_x_geometry
	}

func get_asset_geometry(asset_key: String) -> Resource:
	return get_all_asset_geometries().get(asset_key, null)

func get_ui_generated_asset_path(mode: String, asset_key: String) -> String:
	var mode_paths: Dictionary = ui_generated_asset_paths.get(mode, {})
	return String(mode_paths.get(asset_key, ""))

func get_ui_generated_asset_texture(mode: String, asset_key: String) -> Texture2D:
	var path := get_ui_generated_asset_path(mode, asset_key)
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		return load(path)
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		return null
	return ImageTexture.create_from_image(image)

func get_cell_bg_texture_path(mode: String) -> String:
	if ui_cell_texture_paths.has(mode):
		return String(ui_cell_texture_paths.get(mode, ""))
	if ui_cell_texture_strict_mode_paths:
		return ""
	if ui_cell_texture_paths.has("default"):
		return String(ui_cell_texture_paths.get("default", ""))
	return ""

func get_cell_bg_texture_for_mode(mode: String) -> Texture2D:
	var path := get_cell_bg_texture_path(mode)
	if path.is_empty():
		if ui_cell_texture_strict_mode_paths:
			return null
		return cell_bg_texture
	if _cell_bg_texture_cache.has(path):
		return _cell_bg_texture_cache[path]
	if ResourceLoader.exists(path):
		var loaded_texture: Texture2D = load(path)
		var materialized := _materialize_cell_texture(loaded_texture)
		if materialized != null:
			_cell_bg_texture_cache[path] = materialized
			return materialized
		if ui_cell_texture_strict_mode_paths:
			return null
		return cell_bg_texture
	if not FileAccess.file_exists(path):
		if ui_cell_texture_strict_mode_paths:
			return null
		return cell_bg_texture
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		if ui_cell_texture_strict_mode_paths:
			return null
		return cell_bg_texture
	var image_texture := ImageTexture.create_from_image(image)
	_cell_bg_texture_cache[path] = image_texture
	return image_texture

func _materialize_cell_texture(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null
	var image := texture.get_image()
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func get_ui_generated_asset_geometry(asset_key: String) -> Dictionary:
	return ui_generated_asset_geometry.get(asset_key, {})

func validate_ui_generated_assets() -> Array:
	var errors := []
	for mode in ["dark", "light"]:
		if not ui_generated_asset_paths.has(mode):
			errors.append("generated UI asset mode missing: %s" % mode)
			continue
		var mode_paths: Dictionary = ui_generated_asset_paths.get(mode, {})
		for asset_key in ui_generated_asset_geometry.keys():
			if not mode_paths.has(asset_key):
				errors.append("%s generated UI asset path missing: %s" % [mode, asset_key])
				continue
			var path := String(mode_paths.get(asset_key, ""))
			if path.is_empty():
				errors.append("%s generated UI asset path empty: %s" % [mode, asset_key])
			elif not path.begins_with("res://Assets/UI/cyberpunk_theme/generated/production/%s/" % mode):
				errors.append("%s generated UI asset outside canonical root: %s" % [mode, path])
			elif not FileAccess.file_exists(path):
				errors.append("%s generated UI asset file missing: %s" % [mode, path])
	for asset_key in ui_generated_asset_geometry.keys():
		var geometry: Dictionary = ui_generated_asset_geometry.get(asset_key, {})
		if String(geometry.get("anchor", "")).is_empty():
			errors.append("%s generated UI geometry anchor missing" % asset_key)
		if String(geometry.get("scale_policy", "")).is_empty():
			errors.append("%s generated UI geometry scale_policy missing" % asset_key)
	return errors

func validate_geometry_manifest() -> Array:
	var errors := []
	var geometries := get_all_asset_geometries()
	for asset_key in get_required_asset_keys():
		var geometry: Resource = geometries.get(asset_key, null)
		if geometry == null:
			errors.append("%s geometry is missing" % asset_key)
			continue
		errors.append_array(_validate_asset_geometry(asset_key, geometry))
	return errors

func _validate_asset_geometry(asset_key: String, geometry: Resource) -> Array:
	var errors := []
	if String(geometry.get("asset_key")) != String(asset_key):
		errors.append("%s geometry asset_key mismatch" % asset_key)
	var frame_size: Vector2 = geometry.get("frame_size")
	var draw_origin: Vector2 = geometry.get("draw_origin")
	var center: Vector2 = geometry.get("center")
	var route_junction: Vector2 = geometry.get("route_junction")
	var core_center: Vector2 = geometry.get("core_center")
	var content_rect: Rect2 = geometry.get("content_rect")
	var energy_rect: Rect2 = geometry.get("energy_rect")
	if frame_size.x <= 0.0 or frame_size.y <= 0.0:
		errors.append("%s frame_size must be positive" % asset_key)
	if not _point_in_frame(draw_origin, frame_size):
		errors.append("%s draw_origin must stay inside frame" % asset_key)
	if not _point_in_frame(center, frame_size):
		errors.append("%s center must stay inside frame" % asset_key)
	if not _point_in_frame(route_junction, frame_size):
		errors.append("%s route_junction must stay inside frame" % asset_key)
	if not _point_in_frame(core_center, frame_size):
		errors.append("%s core_center must stay inside frame" % asset_key)
	if not _rect_in_frame(content_rect, frame_size):
		errors.append("%s content_rect must stay inside frame" % asset_key)
	if not _rect_in_frame(energy_rect, frame_size):
		errors.append("%s energy_rect must stay inside frame" % asset_key)
	for port_name in ["north_port", "east_port", "south_port", "west_port"]:
		var port: Vector2 = geometry.get(port_name)
		if not _point_on_frame_edge(port, frame_size):
			errors.append("%s %s must sit on frame edge" % [asset_key, port_name])
	return errors

func _point_in_frame(point: Vector2, frame_size: Vector2) -> bool:
	return point.x >= 0.0 and point.y >= 0.0 and point.x <= frame_size.x and point.y <= frame_size.y

func _rect_in_frame(rect: Rect2, frame_size: Vector2) -> bool:
	if rect.position.x < 0.0 or rect.position.y < 0.0:
		return false
	if rect.size.x < 0.0 or rect.size.y < 0.0:
		return false
	return rect.end.x <= frame_size.x and rect.end.y <= frame_size.y

func _point_on_frame_edge(point: Vector2, frame_size: Vector2) -> bool:
	if not _point_in_frame(point, frame_size):
		return false
	return is_equal_approx(point.x, 0.0) or is_equal_approx(point.y, 0.0) or is_equal_approx(point.x, frame_size.x) or is_equal_approx(point.y, frame_size.y)

func get_energy_frame_duration(asset_key: String = "") -> float:
	if energy_frame_duration_by_asset_key.has(asset_key):
		return max(0.001, float(energy_frame_duration_by_asset_key[asset_key]))
	return max(0.001, energy_default_frame_duration)

func get_energy_animation_duration(asset_key: String = "") -> float:
	return get_energy_frame_duration(asset_key) * float(max(0, energy_sheet_frame_count - 1))

func get_energy_sheet_expected_size() -> Vector2:
	return Vector2(energy_sheet_frame_size.x * float(max(1, energy_sheet_frame_count)), energy_sheet_frame_size.y)

func validate_energy_sheet_manifest() -> Array:
	var errors := []
	if energy_sheet_manifest_path.is_empty() or not FileAccess.file_exists(energy_sheet_manifest_path):
		return ["energy sheet manifest is missing: %s" % energy_sheet_manifest_path]
	var file := FileAccess.open(energy_sheet_manifest_path, FileAccess.READ)
	if file == null:
		return ["energy sheet manifest cannot be opened: %s" % energy_sheet_manifest_path]
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return ["energy sheet manifest is not a JSON object"]
	var manifest: Dictionary = parsed
	if int(manifest.get("frame_count", -1)) != energy_sheet_frame_count:
		errors.append("manifest frame_count mismatch")
	if int(manifest.get("frame_width", -1)) != int(energy_sheet_frame_size.x):
		errors.append("manifest frame_width mismatch")
	if int(manifest.get("frame_height", -1)) != int(energy_sheet_frame_size.y):
		errors.append("manifest frame_height mismatch")
	var sheets: Array = manifest.get("sheets", [])
	if sheets.is_empty():
		errors.append("manifest sheets list is empty")
	var seen_sheets := {}
	for raw_sheet in sheets:
		if typeof(raw_sheet) != TYPE_DICTIONARY:
			errors.append("manifest sheet entry is not an object")
			continue
		var sheet: Dictionary = raw_sheet
		var sheet_path := String(sheet.get("sheet", ""))
		if sheet_path.is_empty():
			errors.append("manifest sheet path is empty")
			continue
		if sheet_path.contains("energy_sheets_ai"):
			errors.append("%s uses forbidden fallback root" % sheet_path)
		if not sheet_path.begins_with(energy_sheet_root + "/"):
			errors.append("%s is outside canonical energy sheet root" % sheet_path)
		if seen_sheets.has(sheet_path):
			errors.append("%s appears more than once" % sheet_path)
		seen_sheets[sheet_path] = true
		if not ResourceLoader.exists(sheet_path):
			errors.append("%s does not exist" % sheet_path)
		if int(sheet.get("frames", -1)) != energy_sheet_frame_count:
			errors.append("%s frame count mismatch" % sheet_path)
		if int(sheet.get("frame_width", -1)) != int(energy_sheet_frame_size.x):
			errors.append("%s frame width mismatch" % sheet_path)
		if int(sheet.get("frame_height", -1)) != int(energy_sheet_frame_size.y):
			errors.append("%s frame height mismatch" % sheet_path)
	return errors

func get_bgm_path() -> String:
	return bgm_path

func get_sfx_path(event_name: String) -> String:
	return String(sfx_event_paths.get(event_name, ""))

func get_sfx_volume_offset(event_name: String) -> float:
	return float(sfx_event_volume_offsets.get(event_name, 0.0))

func get_sfx_pitch_variation(event_name: String) -> float:
	return float(sfx_event_pitch_variation.get(event_name, 0.0))

@export_group("Custom Textures")
@export var cell_bg_texture: Texture2D
@export var pipe_cap_texture: Texture2D
@export var pipe_cap_texture_watered: Texture2D
@export var pipe_i_texture: Texture2D
@export var pipe_i_texture_watered: Texture2D
@export var pipe_l_texture: Texture2D
@export var pipe_l_texture_watered: Texture2D
@export var pipe_t_texture: Texture2D
@export var pipe_t_texture_watered: Texture2D
@export var pipe_x_texture: Texture2D
@export var pipe_x_texture_watered: Texture2D
@export var source_texture: Texture2D
@export var target_texture: Texture2D
@export var target_texture_watered: Texture2D

@export var cross_slices: Array[PipeSliceConfig] = []
@export var t_slices: Array[PipeSliceConfig] = []
@export var l_slices: Array[PipeSliceConfig] = []
@export var i_slices: Array[PipeSliceConfig] = []
