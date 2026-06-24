## Title screen with a Play button. Settings and Best score are reachable
## from here so the user can tweak audio before starting the first run.
extends Control

const GAME_SCENE_PATH := "res://Scenes/Game/Game.tscn"
const SETTINGS_OVERLAY := preload("res://Scenes/Game/Component/Overlays/SettingsOverlay.tscn")
const LEADERBOARD_OVERLAY := preload("res://Scenes/Game/Component/Overlays/LeaderboardOverlay.tscn")
const USERNAME_PROMPT_OVERLAY := preload("res://Scenes/Game/Component/Overlays/UsernamePromptOverlay.tscn")

# Branding shown in the bottom-left corner of the menu.
@export var project_name: String = "BloxChain"
@export var version: String = ""

@onready var play_button: Button = $Center/VBox/PlayButton
@onready var settings_button: Button = $Center/VBox/SettingsButton
@onready var leaderboard_button: Button = $Center/VBox/LeaderboardButton
@onready var best_label: Label = $Center/VBox/BestLabel
@onready var version_label: Label = $VersionLabel
@onready var title_label: Label = $Center/VBox/Title
@onready var subtitle_label: Label = $Center/VBox/Subtitle
@onready var background_rect: ColorRect = $Background
@onready var background_texture_rect: TextureRect = $BackgroundTexture
@onready var logo_rect: TextureRect = $Center/VBox/Logo


func _ready() -> void:
	best_label.text = "Best Score:\n %d" % GameState.best_score
	
	var display_version = version
	if display_version == "":
		display_version = ProjectSettings.get_setting("application/config/version", "1.0.0")
	version_label.text = "%s v%s" % [project_name, display_version]
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	leaderboard_button.pressed.connect(_on_leaderboard_pressed)
	GameState.best_changed.connect(func(value: int) -> void:
		best_label.text = "Best: %d" % value
	)
	
	ThemeManager.theme_changed.connect(_on_theme_changed)
	resized.connect(_update_background_layout)
	_update_theme()
	
	if SaveManager.get_username() == "":
		_show_username_prompt()


func _show_username_prompt() -> void:
	await get_tree().process_frame
	var prompt = USERNAME_PROMPT_OVERLAY.instantiate()
	add_child(prompt)
	prompt.open()


func _update_theme() -> void:
	var active_theme = ThemeManager.get_active_theme()
	if active_theme:
		if active_theme.logo_texture:
			logo_rect.texture = active_theme.logo_texture
			logo_rect.custom_minimum_size = Vector2(440, 220)
			logo_rect.visible = true
			title_label.visible = false
			subtitle_label.visible = false
		else:
			logo_rect.texture = null
			logo_rect.visible = false
			title_label.visible = true
			subtitle_label.visible = true
			title_label.text = active_theme.theme_title
			title_label.add_theme_color_override("font_color", active_theme.theme_title_color)
			title_label.add_theme_color_override("font_outline_color", active_theme.theme_title_color.darkened(0.8))
			title_label.add_theme_constant_override("outline_size", 16)
			
			subtitle_label.text = active_theme.theme_subtitle
			subtitle_label.add_theme_color_override("font_color", active_theme.theme_subtitle_color)
			subtitle_label.add_theme_color_override("font_outline_color", active_theme.theme_subtitle_color.darkened(0.8))
			subtitle_label.add_theme_constant_override("outline_size", 10)
		
		best_label.add_theme_color_override("font_color", active_theme.accent_color)
		best_label.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.8))
		best_label.add_theme_constant_override("outline_size", 12)
		
		version_label.add_theme_color_override("font_color", active_theme.text_color.darkened(0.3))
		version_label.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.8))
		version_label.add_theme_constant_override("outline_size", 4)
		
		play_button.add_theme_color_override("font_color", active_theme.text_color)
		play_button.add_theme_color_override("font_hover_color", active_theme.accent_color)
		
		settings_button.add_theme_color_override("font_color", active_theme.text_color)
		settings_button.add_theme_color_override("font_hover_color", active_theme.accent_color)
		
		leaderboard_button.add_theme_color_override("font_color", active_theme.text_color)
		leaderboard_button.add_theme_color_override("font_hover_color", active_theme.accent_color)
		
		# Background image or solid color fallback
		var bg_tex = ThemeManager.shared_background_texture
		if bg_tex:
			background_texture_rect.texture = bg_tex
			background_texture_rect.visible = true
		else:
			background_texture_rect.texture = null
			background_texture_rect.visible = false
			
		background_rect.color = Color(0.08, 0.06, 0.15, 1.0)
		
		_update_background_layout()


func _update_background_layout() -> void:
	if not is_inside_tree() or background_texture_rect == null or background_texture_rect.texture == null:
		return
		
	background_texture_rect.anchor_left = 0
	background_texture_rect.anchor_top = 0
	background_texture_rect.anchor_right = 0
	background_texture_rect.anchor_bottom = 0
	
	background_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	
	var parent_size = size
	var texture_size = background_texture_rect.texture.get_size()
	if texture_size.x == 0 or texture_size.y == 0:
		return
		
	var aspect_parent = parent_size.x / parent_size.y
	var aspect_tex = texture_size.x / texture_size.y
	
	if aspect_parent > aspect_tex:
		var scale_factor = parent_size.x / texture_size.x
		var new_width = parent_size.x
		var new_height = texture_size.y * scale_factor
		background_texture_rect.size = Vector2(new_width, new_height)
		background_texture_rect.position = Vector2(0, parent_size.y - new_height)
	else:
		var scale_factor = parent_size.y / texture_size.y
		var new_width = texture_size.x * scale_factor
		var new_height = parent_size.y
		background_texture_rect.size = Vector2(new_width, new_height)
		background_texture_rect.position = Vector2((parent_size.x - new_width) / 2.0, 0)


func _on_theme_changed(_name: String, _config: ThemeConfig) -> void:
	_update_theme()


const START_OPTION_OVERLAY := preload("res://Scenes/Game/Component/Overlays/StartOptionOverlay.tscn")


func _on_play_pressed() -> void:
	AudioManager.play_sfx("button")
	if not SaveManager.is_tutorial_completed() or SaveManager.has_saved_game():
		SceneRouter.change_scene(GAME_SCENE_PATH)
		return
		
	var overlay = START_OPTION_OVERLAY.instantiate()
	add_child(overlay)
	overlay.mode_selected.connect(func(mode: String):
		GameState.start_mode = mode
		SceneRouter.change_scene(GAME_SCENE_PATH)
	)
	overlay.open()


func _on_settings_pressed() -> void:
	AudioManager.play_sfx("button")
	var overlay := SETTINGS_OVERLAY.instantiate()
	add_child(overlay)
	overlay.open()


func _on_leaderboard_pressed() -> void:
	AudioManager.play_sfx("button")
	var overlay := LEADERBOARD_OVERLAY.instantiate()
	add_child(overlay)
