extends "res://addons/shinokute_game_core/ui/username_prompt_overlay.gd"

const RuntimeThemeConfig := preload("res://Resources/QuantumRuntimeThemeConfig.gd")

@export var theme_config: RuntimeThemeConfig = preload("res://Resources/Data/Themes/candy_sky_islands/theme_runtime_export.tres")

@onready var panel_art: TextureRect = $Panel/PanelArt

var _username_placeholder := "CandyPlayer"

func _ready() -> void:
	super._ready()
	_apply_candy_skin()
	_username_placeholder = name_edit.placeholder_text
	name_edit.caret_blink = true
	name_edit.focus_entered.connect(_on_name_edit_focus_entered)
	name_edit.focus_exited.connect(_on_name_edit_focus_exited)

func _apply_candy_skin() -> void:
	if theme_config == null:
		return
	if ResourceLoader.exists(theme_config.ui_username_panel_path):
		panel_art.texture = load(theme_config.ui_username_panel_path)
	if ResourceLoader.exists(theme_config.ui_username_input_path):
		name_edit.add_theme_stylebox_override("normal", _texture_style(theme_config.ui_username_input_path, Vector4(24.0, 10.0, 24.0, 10.0), Vector4(42.0, 8.0, 42.0, 8.0)))
		name_edit.add_theme_stylebox_override("focus", _texture_style(theme_config.ui_username_input_path, Vector4(24.0, 10.0, 24.0, 10.0), Vector4(42.0, 8.0, 42.0, 8.0)))
		name_edit.add_theme_color_override("font_color", theme_config.palette_text)
		name_edit.add_theme_color_override("font_placeholder_color", theme_config.palette_text.lightened(0.28))
		name_edit.add_theme_font_size_override("font_size", 17)
	if ResourceLoader.exists(theme_config.ui_button_primary_path):
		_apply_button_skin(confirm_button, theme_config.ui_button_primary_path)
	if ResourceLoader.exists(theme_config.ui_button_secondary_path):
		_apply_button_skin(skip_button, theme_config.ui_button_secondary_path)
	for label in [$Panel/Margin/VBox/Title, $Panel/Margin/VBox/Prompt, error_label]:
		label.add_theme_color_override("font_color", theme_config.palette_text)
		label.add_theme_font_size_override("font_size", 17)

func _apply_button_skin(button: Button, path: String) -> void:
	var style := _texture_style(path, Vector4(24.0, 10.0, 24.0, 10.0), Vector4(28.0, 8.0, 28.0, 8.0))
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", theme_config.palette_text)
	button.add_theme_color_override("font_hover_color", theme_config.palette_text)
	button.add_theme_color_override("font_pressed_color", theme_config.palette_text)
	button.add_theme_font_size_override("font_size", 15)

func _texture_style(path: String, margins: Vector4, content_margins := Vector4(-1.0, -1.0, -1.0, -1.0)) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(path)
	style.texture_margin_left = margins.x
	style.texture_margin_top = margins.y
	style.texture_margin_right = margins.z
	style.texture_margin_bottom = margins.w
	if content_margins.x >= 0.0:
		style.content_margin_left = content_margins.x
	if content_margins.y >= 0.0:
		style.content_margin_top = content_margins.y
	if content_margins.z >= 0.0:
		style.content_margin_right = content_margins.z
	if content_margins.w >= 0.0:
		style.content_margin_bottom = content_margins.w
	return style

func _on_name_edit_focus_entered() -> void:
	name_edit.placeholder_text = ""
	name_edit.caret_blink = true

func _on_name_edit_focus_exited() -> void:
	if name_edit.text.strip_edges().is_empty():
		name_edit.placeholder_text = _username_placeholder
