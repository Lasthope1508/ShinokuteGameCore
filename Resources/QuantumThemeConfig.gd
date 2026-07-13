extends Resource
class_name QuantumThemeConfig

const QuantumAssetRole := preload("res://Resources/QuantumAssetRole.gd")

@export var theme_name := ""
@export var display_name := ""

@export_group("Palette")
@export var palette_sky := Color("#79C7F2")
@export var palette_surface := Color("#FFF2C7")
@export var palette_primary := Color("#FF6F61")
@export var palette_accent := Color("#7BE0AD")
@export var palette_text := Color("#273043")

@export_group("HUD")
@export_file("*.png", "*.webp") var hud_coin_icon_path := "res://assets/themes/candy_sky_islands/star_collectible.png"
@export_file("*.ttf", "*.otf") var hud_font_path := "res://fonts/lilita_one_regular.ttf"
@export var hud_score_frame_rect := Rect2(40.0, 45.0, 313.0, 127.0)
@export var hud_text_owner_rect := Rect2(160.0, 88.0, 160.0, 54.0)
@export var hud_text_padding := Vector4(0.0, 0.0, 0.0, 0.0)
@export var hud_font_size := 44
@export var hud_level_rect := Rect2(52.0, 178.0, 208.0, 36.0)
@export var hud_level_font_size := 28
@export var hud_level_font_color := Color("#FFF2C7")
@export var hud_level_outline_color := Color("#273043")
@export var hud_level_outline_size := 6

@export_group("Function Skin UI")
@export_file("*.png", "*.webp") var ui_leaderboard_button_path := "res://assets/themes/candy_sky_islands/ui/ui_leaderboard_button.png"
@export_file("*.png", "*.webp") var ui_leaderboard_panel_path := "res://assets/themes/candy_sky_islands/ui/ui_leaderboard_panel.png"
@export_file("*.png", "*.webp") var ui_leaderboard_row_path := "res://assets/themes/candy_sky_islands/ui/ui_leaderboard_row.png"
@export_file("*.png", "*.webp") var ui_leaderboard_tab_path := "res://assets/themes/candy_sky_islands/ui/ui_leaderboard_tab.png"
@export_file("*.png", "*.webp") var ui_leaderboard_close_path := "res://assets/themes/candy_sky_islands/ui/ui_leaderboard_close.png"
@export_file("*.png", "*.webp") var ui_username_panel_path := "res://assets/themes/candy_sky_islands/ui/ui_username_panel.png"
@export_file("*.png", "*.webp") var ui_username_input_path := "res://assets/themes/candy_sky_islands/ui/ui_username_input.png"
@export_file("*.png", "*.webp") var ui_button_primary_path := "res://assets/themes/candy_sky_islands/ui/ui_button_primary.png"
@export_file("*.png", "*.webp") var ui_button_secondary_path := "res://assets/themes/candy_sky_islands/ui/ui_button_secondary.png"
@export_file("*.png", "*.webp") var ui_settings_panel_path := "res://assets/themes/candy_sky_islands/ui/ui_leaderboard_panel.png"
@export_file("*.png", "*.webp") var ui_settings_row_path := "res://assets/themes/candy_sky_islands/ui/ui_leaderboard_row.png"
@export_file("*.png", "*.webp") var ui_settings_toggle_on_path := "res://assets/themes/candy_sky_islands/ui/ui_button_primary.png"
@export_file("*.png", "*.webp") var ui_settings_toggle_off_path := "res://assets/themes/candy_sky_islands/ui/ui_button_secondary.png"
@export var ui_panel_texture_margins := Vector4(72.0, 72.0, 72.0, 72.0)
@export var ui_button_texture_margins := Vector4(44.0, 32.0, 44.0, 32.0)
@export var ui_row_texture_margins := Vector4(44.0, 24.0, 44.0, 24.0)

@export_group("Player")
@export_file("*.png", "*.webp") var player_root_asset_path := "res://assets/themes/candy_sky_islands/root_asset_marshmallow_runner_concept.png"
@export var player_body_material_color := Color("#FFF2C7")
@export var player_cap_material_color := Color("#FFF2C7")
@export var player_left_glove_material_color := Color("#FF6F61")
@export var player_right_glove_material_color := Color("#7BE0AD")
@export var player_left_boot_material_color := Color("#7BE0AD")
@export var player_right_boot_material_color := Color("#FF6F61")
@export var player_face_material_color := Color("#273043")

@export_group("Asset Family")
@export_file("*.png", "*.webp") var asset_family_concept_sheet_path := "res://assets/themes/candy_sky_islands/asset_family_concept_sheet.png"
@export_file("*.png", "*.webp") var hud_score_frame_path := ""
@export_file("*.png", "*.webp") var candy_skybox_path := ""
@export var collectible_star_body_color := Color("#FF6F61")
@export var collectible_star_rim_color := Color("#7BE0AD")
@export var platform_top_material_color := Color("#FFF2C7")
@export var platform_edge_material_color := Color("#FF6F61")
@export var hud_score_frame_color := Color("#FFF2C7")
@export var skybox_tint_color := Color("#79C7F2")
@export var obstacle_wafer_material_color := Color("#FFB38C")
@export var goal_pennant_material_color := Color("#7BE0AD")
@export var cloud_shadow_material_color := Color("#DDF5FF")

@export_group("Branding")
@export var branding_display_name := "Candy Sky Islands"
@export_file("*.png", "*.webp") var branding_icon_source_path := "res://assets/themes/candy_sky_islands/branding/app_icon_source.png"
@export_file("*.png", "*.webp") var branding_splash_path := "res://assets/themes/candy_sky_islands/branding/splash_candy_sky_islands.png"
@export_file("*.png", "*.webp") var branding_logo_path := "res://assets/themes/candy_sky_islands/branding/logo_candy_sky_islands.png"

@export_group("Deep Reskin Roles")
@export var player_model_role: QuantumAssetRole
@export var player_shadow_role: QuantumAssetRole
@export var player_trail_mesh_role: QuantumAssetRole
@export var collectible_model_role: QuantumAssetRole
@export var collectible_particle_role: QuantumAssetRole
@export var hud_icon_role: QuantumAssetRole
@export var platform_small_role: QuantumAssetRole
@export var platform_medium_role: QuantumAssetRole
@export var platform_falling_role: QuantumAssetRole
@export var platform_round_role: QuantumAssetRole
@export var platform_large_unused_role: QuantumAssetRole
@export var block_coin_unused_role: QuantumAssetRole
@export var obstacle_brick_role: QuantumAssetRole
@export var obstacle_brick_particle_role: QuantumAssetRole
@export var goal_flag_role: QuantumAssetRole
@export var prop_cloud_role: QuantumAssetRole
@export var prop_grass_role: QuantumAssetRole
@export var prop_grass_small_role: QuantumAssetRole
@export var skybox_role: QuantumAssetRole
@export var colormap_role: QuantumAssetRole

@export_group("World")
@export_file("*.png", "*.webp") var skybox_path := "res://assets/themes/candy_sky_islands/sky_panel_islands.png"
@export var platform_material_color := Color("#FFF2C7")
@export var coin_material_color := Color("#FF6F61")
@export var coin_rim_color := Color("#7BE0AD")
@export var trail_particle_color := Color("#7BE0AD")
@export var cloud_material_color := Color("#FFFFFF")

@export_group("Audio")
@export_file("*.ogg", "*.wav", "*.mp3") var bgm_track_path := "res://sounds/candy_sky_islands/bgm_candy_island_main.ogg"
@export var bgm_volume_db := -14.0
@export var sfx_volume_db := -10.0
@export var audio_event_paths := {
	"jump": "res://sounds/candy_sky_islands/sfx_jump.ogg",
	"land": "res://sounds/candy_sky_islands/sfx_land.ogg",
	"coin": "res://sounds/candy_sky_islands/sfx_coin.ogg",
	"walking": "res://sounds/candy_sky_islands/sfx_walking.ogg",
	"break": "res://sounds/candy_sky_islands/sfx_break.ogg",
	"fall": "res://sounds/candy_sky_islands/sfx_fall.ogg"
}

func validate() -> Array[String]:
	var errors: Array[String] = []
	if theme_name.strip_edges().is_empty():
		errors.append("theme_name is required")
	if display_name.strip_edges().is_empty():
		errors.append("display_name is required")
	for path in [
		hud_coin_icon_path,
		hud_font_path,
		ui_leaderboard_button_path,
		ui_leaderboard_panel_path,
		ui_leaderboard_row_path,
		ui_leaderboard_tab_path,
		ui_leaderboard_close_path,
		ui_username_panel_path,
		ui_username_input_path,
		ui_button_primary_path,
		ui_button_secondary_path,
		ui_settings_panel_path,
		ui_settings_row_path,
		ui_settings_toggle_on_path,
		ui_settings_toggle_off_path,
		player_root_asset_path,
		skybox_path,
		bgm_track_path
	]:
		if path.strip_edges().is_empty():
			errors.append("asset path is empty")
		elif not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
			errors.append("missing asset path: %s" % path)
	if hud_text_owner_rect.size.x <= 0.0 or hud_text_owner_rect.size.y <= 0.0:
		errors.append("hud_text_owner_rect must have positive size")
	if hud_score_frame_rect.size.x <= 0.0 or hud_score_frame_rect.size.y <= 0.0:
		errors.append("hud_score_frame_rect must have positive size")
	if hud_level_rect.size.x <= 0.0 or hud_level_rect.size.y <= 0.0:
		errors.append("hud_level_rect must have positive size")
	if hud_level_font_size <= 0:
		errors.append("hud_level_font_size must be positive")
	if hud_level_outline_size < 0:
		errors.append("hud_level_outline_size must not be negative")
	for key in ["jump", "land", "coin", "walking", "break", "fall"]:
		if not audio_event_paths.has(key):
			errors.append("missing audio event: %s" % key)
	for role in [
		player_model_role,
		player_shadow_role,
		player_trail_mesh_role,
		collectible_model_role,
		collectible_particle_role,
		hud_icon_role,
		platform_small_role,
		platform_medium_role,
		platform_falling_role,
		platform_round_role,
		platform_large_unused_role,
		block_coin_unused_role,
		obstacle_brick_role,
		obstacle_brick_particle_role,
		goal_flag_role,
		prop_cloud_role,
		prop_grass_role,
		prop_grass_small_role,
		skybox_role,
		colormap_role
	]:
		if role == null:
			errors.append("deep reskin role is missing")
		else:
			errors.append_array(role.validate_role())
	return errors
