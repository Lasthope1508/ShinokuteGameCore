extends Control

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $MarginContainer/VBoxContainer/SubtitleLabel
@onready var theme_btn: Button = $MarginContainer/VBoxContainer/HBoxTheme/ThemeBtn
@onready var mute_btn: Button = $MarginContainer/VBoxContainer/HBoxVolume/MuteBtn

func _ready() -> void:
	# Register theme change signal
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_on_theme_changed(ThemeManager.active_theme_name, ThemeManager.active_theme)
	
	# Load volume states
	_update_mute_button()
	
	if has_node("/root/AudioManager"):
		AudioManager.play_music()

func _on_theme_changed(name: String, config: ThemeConfig) -> void:
	if title_label:
		title_label.text = config.theme_title
		title_label.add_theme_color_override("font_color", config.text_color)
	if subtitle_label:
		subtitle_label.text = config.theme_subtitle
		subtitle_label.add_theme_color_override("font_color", config.accent_color)
		
	# Redraw background ColorRect
	$Background.color = config.panel_bg_color
	
	# Apply dynamic layout dimensions from ThemeConfig SSOT
	var margin_container = $MarginContainer as MarginContainer
	if margin_container:
		margin_container.add_theme_constant_override("margin_left", int(config.menu_margin_x))
		margin_container.add_theme_constant_override("margin_right", int(config.menu_margin_x))
		margin_container.add_theme_constant_override("margin_top", int(config.menu_margin_y))
		margin_container.add_theme_constant_override("margin_bottom", int(config.menu_margin_y))
		
	var play_btn = $MarginContainer/VBoxContainer/PlayBtn as Button
	if play_btn:
		play_btn.custom_minimum_size.x = config.menu_button_width
		play_btn.custom_minimum_size.y = config.play_button_height
		play_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
	var leader_btn = $MarginContainer/VBoxContainer/LeaderboardBtn as Button
	if leader_btn:
		leader_btn.custom_minimum_size.x = config.menu_button_width
		leader_btn.custom_minimum_size.y = config.play_button_height - 10.0
		leader_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
	if theme_btn:
		theme_btn.custom_minimum_size.x = config.menu_button_width
		theme_btn.custom_minimum_size.y = config.utility_button_height
		theme_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
	if mute_btn:
		mute_btn.custom_minimum_size.x = config.menu_button_width
		mute_btn.custom_minimum_size.y = config.utility_button_height
		mute_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

func _on_play_btn_pressed() -> void:
	if get_node_or_null("/root/SceneRouter"):
		SceneRouter.change_scene("res://Scenes/Main/LevelSelect.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Main/LevelSelect.tscn")

func _on_leaderboard_btn_pressed() -> void:
	# Spawn Profile/Leaderboard popup
	var popup_scene = load("res://Scenes/Common/ProfilePopup.tscn")
	if popup_scene:
		var inst = popup_scene.instantiate()
		add_child(inst)

func _on_theme_btn_pressed() -> void:
	if ThemeManager.active_theme_name == "hacknet_theme":
		ThemeManager.load_theme("wood_theme")
	elif ThemeManager.active_theme_name == "wood_theme":
		ThemeManager.load_theme("garden_theme")
	else:
		ThemeManager.load_theme("hacknet_theme")

func _on_mute_btn_pressed() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.toggle_master_mute()
		_update_mute_button()

func _update_mute_button() -> void:
	if has_node("/root/AudioManager") and mute_btn:
		var is_muted = AudioManager.is_master_muted()
		mute_btn.text = "VOLUME: MUTED" if is_muted else "VOLUME: ON"

