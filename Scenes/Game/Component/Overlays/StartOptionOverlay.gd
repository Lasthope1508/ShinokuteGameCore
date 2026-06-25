## Overlay popup allowing the player to choose between Classic or Chaos start mode.
extends "res://Scenes/Common/ElasticOverlay.gd"

signal mode_selected(mode: String)

@onready var classic_button: Button = $Panel/Margin/VBox/Buttons/ClassicButton
@onready var chaos_button: Button = $Panel/Margin/VBox/Buttons/ChaosButton
@onready var title: Label = $Panel/Margin/VBox/Title
@onready var subtitle: Label = $Panel/Margin/VBox/Subtitle


func _ready() -> void:
	super()
	classic_button.pressed.connect(_on_classic_pressed)
	chaos_button.pressed.connect(_on_chaos_pressed)
	
	# Set button text dynamically based on the constants
	chaos_button.text = "Chaos Start (%d Obstacles)" % Grid.CHAOS_START_BLOCKS
	
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_update_theme_styles()


func _update_theme_styles() -> void:
	var active_theme = ThemeManager.get_active_theme()
	if not active_theme:
		return
		
	# Style panel container
	var panel_style = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if not panel_style:
		panel_style = StyleBoxFlat.new()
		panel.add_theme_stylebox_override("panel", panel_style)
		
	panel_style.bg_color = active_theme.panel_bg_color
	panel_style.border_color = active_theme.panel_border_color
	var border_w = active_theme.popup_border_width
	panel_style.border_width_left = border_w
	panel_style.border_width_right = border_w
	panel_style.border_width_top = border_w
	panel_style.border_width_bottom = border_w
	panel_style.set_corner_radius_all(active_theme.popup_corner_radius)
	
	# Style labels
	title.add_theme_color_override("font_color", active_theme.accent_color)
	title.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.8))
	title.add_theme_constant_override("outline_size", 10)
	
	subtitle.add_theme_color_override("font_color", active_theme.text_color)
	
	# Style buttons
	for btn in [classic_button, chaos_button]:
		btn.add_theme_color_override("font_color", active_theme.text_color)
		btn.add_theme_color_override("font_hover_color", active_theme.accent_color)


func _on_theme_changed(_name: String, _config: ThemeConfig) -> void:
	_update_theme_styles()


func _on_classic_pressed() -> void:
	AudioManager.play_sfx("button")
	mode_selected.emit("classic")
	await close()
	queue_free()


func _on_chaos_pressed() -> void:
	AudioManager.play_sfx("button")
	mode_selected.emit("chaos")
	await close()
	queue_free()
