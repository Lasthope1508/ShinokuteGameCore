extends Control

@onready var background: ColorRect = $Background
@onready var margin_container: MarginContainer = $MarginContainer
@onready var vbox_container: VBoxContainer = $MarginContainer/VBoxContainer
@onready var studio_name: Label = $MarginContainer/VBoxContainer/StudioName
@onready var presents_label: Label = $MarginContainer/VBoxContainer/PresentsLabel

func _ready() -> void:
	var theme_config: ThemeConfig = null
	if has_node("/root/ThemeManager"):
		theme_config = ThemeManager.active_theme
	if theme_config == null:
		push_error("Splash requires ThemeManager.active_theme for SSOT UI timing and layout")
		return
	_apply_theme(theme_config)

	# Hide elements initially for fade-in animation
	studio_name.modulate.a = 0.0
	presents_label.modulate.a = 0.0
	
	# Play music if available
	if has_node("/root/AudioManager"):
		AudioManager.play_music()

	# Start splash animation sequence
	var tw = create_tween()
	var fade_in_duration := theme_config.ui_splash_fade_in_duration
	var hold_duration := theme_config.ui_splash_hold_duration
	var fade_out_duration := theme_config.ui_splash_fade_out_duration
	tw.tween_property(studio_name, "modulate:a", 1.0, fade_in_duration)
	tw.parallel().tween_property(presents_label, "modulate:a", 1.0, fade_in_duration)
	tw.tween_interval(hold_duration)
	
	# Fade out whole screen
	tw.tween_property(self, "modulate:a", 0.0, fade_out_duration)
	tw.tween_callback(func():
		if get_node_or_null("/root/SceneRouter"):
			# Go to MainMenu through Router to preserve dynamic transitions
			SceneRouter.change_scene("res://Scenes/Main/MainMenu.tscn")
		else:
			get_tree().change_scene_to_file("res://Scenes/Main/MainMenu.tscn")
	)

func _apply_theme(theme_config: ThemeConfig) -> void:
	if background:
		background.color = theme_config.panel_bg_color
	if margin_container:
		margin_container.add_theme_constant_override("margin_left", int(theme_config.menu_margin_x))
		margin_container.add_theme_constant_override("margin_top", int(theme_config.menu_margin_y))
		margin_container.add_theme_constant_override("margin_right", int(theme_config.menu_margin_x))
		margin_container.add_theme_constant_override("margin_bottom", int(theme_config.menu_margin_y))
	if vbox_container:
		vbox_container.add_theme_constant_override("separation", theme_config.ui_splash_gap)
	if studio_name:
		studio_name.add_theme_color_override("font_color", theme_config.accent_color)
		studio_name.add_theme_font_size_override("font_size", theme_config.ui_splash_studio_font_size)
	if presents_label:
		presents_label.add_theme_color_override("font_color", theme_config.alert_color)
		presents_label.add_theme_font_size_override("font_size", theme_config.ui_splash_presents_font_size)
