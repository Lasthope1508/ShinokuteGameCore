extends Resource
class_name QuantumThemeConfig

@export var theme_name := ""
@export var display_name := ""

@export_group("Palette")
@export var palette_sky := Color("#79C7F2")
@export var palette_surface := Color("#FFF2C7")
@export var palette_primary := Color("#FF6F61")
@export var palette_accent := Color("#7BE0AD")
@export var palette_text := Color("#273043")

@export_group("HUD")
@export_file("*.png", "*.webp") var hud_coin_icon_path := "res://sprites/coin.png"
@export_file("*.ttf", "*.otf") var hud_font_path := "res://fonts/lilita_one_regular.ttf"
@export var hud_text_owner_rect := Rect2(144.0, 64.0, 224.0, 59.0)
@export var hud_text_padding := Vector4(0.0, 0.0, 0.0, 0.0)
@export var hud_font_size := 48

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

@export_group("World")
@export_file("*.png", "*.webp") var skybox_path := "res://sprites/skybox.png"
@export var platform_material_color := Color("#FFF2C7")
@export var coin_material_color := Color("#FF6F61")
@export var coin_rim_color := Color("#7BE0AD")
@export var trail_particle_color := Color("#7BE0AD")
@export var cloud_material_color := Color("#FFFFFF")

@export_group("Audio")
@export var audio_event_paths := {
	"jump": "res://sounds/jump.ogg",
	"land": "res://sounds/land.ogg",
	"coin": "res://sounds/coin.ogg",
	"walking": "res://sounds/walking.ogg"
}

func validate() -> Array[String]:
	var errors: Array[String] = []
	if theme_name.strip_edges().is_empty():
		errors.append("theme_name is required")
	if display_name.strip_edges().is_empty():
		errors.append("display_name is required")
	for path in [hud_coin_icon_path, hud_font_path, player_root_asset_path, skybox_path]:
		if path.strip_edges().is_empty():
			errors.append("asset path is empty")
		elif not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
			errors.append("missing asset path: %s" % path)
	if hud_text_owner_rect.size.x <= 0.0 or hud_text_owner_rect.size.y <= 0.0:
		errors.append("hud_text_owner_rect must have positive size")
	for key in ["jump", "land", "coin", "walking"]:
		if not audio_event_paths.has(key):
			errors.append("missing audio event: %s" % key)
	return errors
