## Overlay shown on first launch to ask the user for a username.
## Supports skip (assigns default Player_XXXX) and confirm with validation.
extends "res://Scenes/Common/ElasticOverlay.gd"

signal username_set(username: String)

@onready var line_edit: LineEdit = $Panel/Margin/VBox/LineEdit
@onready var error_label: Label = $Panel/Margin/VBox/ErrorLabel
@onready var skip_button: Button = $Panel/Margin/VBox/Buttons/SkipButton
@onready var confirm_button: Button = $Panel/Margin/VBox/Buttons/ConfirmButton


func _ready() -> void:
	super()
	skip_button.pressed.connect(_on_skip_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	line_edit.text_submitted.connect(func(_new_text): _on_confirm_pressed())
	line_edit.focus_entered.connect(_on_line_edit_focus_entered)
	
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_update_theme_styles()


func _on_line_edit_focus_entered() -> void:
	if OS.has_feature("web"):
		line_edit.release_focus()
		var js_bridge = Engine.get_singleton("JavaScriptBridge")
		if js_bridge:
			var current_val = line_edit.text.replace("'", "\\'")
			var js_prompt = js_bridge.eval("prompt('Enter your name (3-15 characters):', '" + current_val + "')")
			if js_prompt != null:
				var typed_name = str(js_prompt).strip_edges()
				if typed_name != "":
					line_edit.text = typed_name
					_on_confirm_pressed()



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
	var title = $Panel/Margin/VBox/Title
	var subtitle = $Panel/Margin/VBox/Subtitle
	title.add_theme_color_override("font_color", active_theme.accent_color)
	title.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.8))
	title.add_theme_constant_override("outline_size", 10)
	
	subtitle.add_theme_color_override("font_color", active_theme.text_color)
	error_label.add_theme_color_override("font_color", Color("#FF5555"))
	
	# Style buttons
	for btn in [skip_button, confirm_button]:
		btn.add_theme_color_override("font_color", active_theme.text_color)
		btn.add_theme_color_override("font_hover_color", active_theme.accent_color)


func _on_theme_changed(_name: String, _config: ThemeConfig) -> void:
	_update_theme_styles()


func _on_skip_pressed() -> void:
	AudioManager.play_sfx("button")
	var default_username = "Player_%s" % SaveManager.get_device_uuid().substr(0, 5)
	SaveManager.set_username(default_username)
	
	# Trigger score submission for high score if already achieved
	var best = SaveManager.get_best_score()
	if best > 0:
		SaveManager.set_last_submitted_score(0, "classic")
		LeaderboardManager.submit_score(best)
		
	username_set.emit(default_username)
	await close()
	queue_free()



func _on_confirm_pressed() -> void:
	var text = line_edit.text.strip_edges()
	if text == "":
		error_label.text = "Username cannot be empty!"
		error_label.visible = true
		AudioManager.play_sfx("timeout") # using timeout sfx for error feedback
		return
		
	if text.length() < 3:
		error_label.text = "Username must be at least 3 characters!"
		error_label.visible = true
		AudioManager.play_sfx("timeout")
		return
		
	if text.length() > 15:
		error_label.text = "Username cannot exceed 15 characters!"
		error_label.visible = true
		AudioManager.play_sfx("timeout")
		return
		
	AudioManager.play_sfx("button")
	SaveManager.set_username(text)
	
	# Trigger score submission for high score if already achieved
	var best = SaveManager.get_best_score()
	if best > 0:
		SaveManager.set_last_submitted_score(0, "classic")
		LeaderboardManager.submit_score(best)
		
	username_set.emit(text)
	await close()
	queue_free()

