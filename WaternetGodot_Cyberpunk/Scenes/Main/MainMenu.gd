extends Control

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $MarginContainer/VBoxContainer/SubtitleLabel
@onready var vbox_container: VBoxContainer = $MarginContainer/VBoxContainer
@onready var logo_rect: TextureRect = $MarginContainer/VBoxContainer/LogoRect
@onready var play_btn: Button = $MarginContainer/VBoxContainer/PlayBtn
@onready var leader_btn: Button = $MarginContainer/VBoxContainer/LeaderboardBtn
@onready var mute_btn: Button = $MarginContainer/VBoxContainer/HBoxVolume/MuteBtn

func _ready() -> void:
	# Register theme change signal
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_on_theme_changed(ThemeManager.active_theme_name, ThemeManager.active_theme)
	
	# Load volume states
	_update_mute_button()
	
	if has_node("/root/AudioManager"):
		AudioManager.play_music()

func _on_theme_changed(_theme_name: String, config: ThemeConfig) -> void:
	if title_label:
		title_label.text = "GLYPHFLOW ARRAYS"
		title_label.add_theme_color_override("font_color", config.text_color)
		title_label.add_theme_font_size_override("font_size", config.ui_main_menu_title_font_size)
	if subtitle_label:
		subtitle_label.text = config.theme_subtitle.to_upper()
		subtitle_label.add_theme_color_override("font_color", config.accent_color)
		subtitle_label.add_theme_font_size_override("font_size", config.ui_main_menu_subtitle_font_size)
		
	var copyright_label = get_node_or_null("MarginContainer/VBoxContainer/CopyrightLabel")
	if copyright_label:
		copyright_label.add_theme_color_override("font_color", config.text_color.darkened(0.2))
		copyright_label.add_theme_font_size_override("font_size", config.ui_main_menu_copyright_font_size)
		
	# Redraw background ColorRect
	$Background.color = config.panel_bg_color
	if vbox_container:
		vbox_container.add_theme_constant_override("separation", config.ui_main_menu_gap)
	if logo_rect:
		logo_rect.custom_minimum_size = Vector2(config.ui_main_menu_logo_size, config.ui_main_menu_logo_size)
	
	# Apply dynamic layout dimensions from ThemeConfig SSOT
	var margin_container = $MarginContainer as MarginContainer
	if margin_container:
		margin_container.add_theme_constant_override("margin_left", int(config.menu_margin_x))
		margin_container.add_theme_constant_override("margin_right", int(config.menu_margin_x))
		margin_container.add_theme_constant_override("margin_top", int(config.menu_margin_y))
		margin_container.add_theme_constant_override("margin_bottom", int(config.menu_margin_y))
		
	if play_btn:
		play_btn.custom_minimum_size.x = config.menu_button_width
		play_btn.custom_minimum_size.y = config.play_button_height
		play_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		play_btn.add_theme_font_size_override("font_size", config.ui_main_menu_primary_button_font_size)
		
	if leader_btn:
		leader_btn.custom_minimum_size.x = config.menu_button_width
		leader_btn.custom_minimum_size.y = config.ui_main_menu_secondary_button_height
		leader_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		leader_btn.add_theme_font_size_override("font_size", config.ui_main_menu_secondary_button_font_size)
		
	if mute_btn:
		mute_btn.custom_minimum_size.x = config.menu_button_width
		mute_btn.custom_minimum_size.y = config.utility_button_height
		mute_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		mute_btn.add_theme_font_size_override("font_size", config.ui_main_menu_secondary_button_font_size)

func _on_play_btn_pressed() -> void:
	if get_node_or_null("/root/SceneRouter"):
		SceneRouter.change_scene("res://Scenes/Main/LevelSelect.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Main/LevelSelect.tscn")

func _on_leaderboard_btn_pressed() -> void:
	var popup_scene = load("res://Scenes/Common/LeaderboardPopup.tscn")
	if popup_scene:
		var inst = popup_scene.instantiate()
		add_child(inst)
		if inst.has_method("apply_generated_ui_theme"):
			inst.apply_generated_ui_theme(ThemeManager.active_theme)

func _on_mute_btn_pressed() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.toggle_master_mute()
		_update_mute_button()

func _update_mute_button() -> void:
	if has_node("/root/AudioManager") and mute_btn:
		var is_muted = AudioManager.is_master_muted()
		mute_btn.text = "VOLUME: MUTED" if is_muted else "VOLUME: ON"
