extends PanelContainer

const RuntimeThemeConfig := preload("res://Resources/QuantumRuntimeThemeConfig.gd")
const FunctionOverlayGroup := preload("res://addons/shinokute_game_core/ui/function_overlay_group.gd")

@export var bridge_path := NodePath("../../CandyGameCore")
@export var toggle_button_path := NodePath("../SettingsButton")
@export var overlay_group := "hud_function_overlay"
@export var theme_config: RuntimeThemeConfig

@onready var title_label: Label = $Margin/VBox/Header/Title
@onready var close_button: Button = $Margin/VBox/Header/CloseButton
@onready var sfx_button: Button = $Margin/VBox/SfxRow/Margin/Line/Toggle
@onready var bgm_button: Button = $Margin/VBox/BgmRow/Margin/Line/Toggle
@onready var shift_lock_button: Button = $Margin/VBox/ShiftLockRow/Margin/Line/Toggle

var _bridge: Node

func _ready() -> void:
	visible = false
	FunctionOverlayGroup.register_panel(self, overlay_group)
	_bridge = get_node_or_null(bridge_path)
	var toggle_button := get_node_or_null(toggle_button_path)
	if toggle_button is Button:
		FunctionOverlayGroup.disable_gameplay_button_focus(toggle_button)
		toggle_button.pressed.connect(_on_toggle_pressed)
		_apply_hud_button_skin(toggle_button)
	FunctionOverlayGroup.disable_gameplay_button_focus(self)
	close_button.pressed.connect(func(): FunctionOverlayGroup.hide_panel(self))
	sfx_button.pressed.connect(func(): _toggle("sfx_enabled"))
	bgm_button.pressed.connect(func(): _toggle("bgm_enabled"))
	shift_lock_button.pressed.connect(func(): _toggle("shift_lock_enabled"))
	if _bridge != null and _bridge.has_signal("settings_changed"):
		_bridge.settings_changed.connect(func(_key: String, _value): _refresh())
	_apply_function_skin()
	_refresh()

func _on_toggle_pressed() -> void:
	var was_visible := visible
	FunctionOverlayGroup.toggle_panel(self, overlay_group)
	if not was_visible:
		_refresh()

func _toggle(key: String) -> void:
	if _bridge == null:
		return
	if key == "sfx_enabled" and _bridge.has_method("set_sfx_enabled"):
		_bridge.set_sfx_enabled(not _bridge.is_sfx_enabled())
	elif key == "bgm_enabled" and _bridge.has_method("set_bgm_enabled"):
		_bridge.set_bgm_enabled(not _bridge.is_bgm_enabled())
	elif key == "shift_lock_enabled" and _bridge.has_method("set_shift_lock_enabled"):
		_bridge.set_shift_lock_enabled(not _bridge.is_shift_lock_enabled())
	_refresh()
	FunctionOverlayGroup.release_ui_focus(self)

func _refresh() -> void:
	_set_button_state(sfx_button, _is_enabled("sfx_enabled", true))
	_set_button_state(bgm_button, _is_enabled("bgm_enabled", true))
	_set_button_state(shift_lock_button, _is_enabled("shift_lock_enabled", false))

func _is_enabled(key: String, fallback: bool) -> bool:
	if _bridge == null:
		return fallback
	if key == "sfx_enabled" and _bridge.has_method("is_sfx_enabled"):
		return _bridge.is_sfx_enabled()
	if key == "bgm_enabled" and _bridge.has_method("is_bgm_enabled"):
		return _bridge.is_bgm_enabled()
	if key == "shift_lock_enabled" and _bridge.has_method("is_shift_lock_enabled"):
		return _bridge.is_shift_lock_enabled()
	return fallback

func _apply_function_skin() -> void:
	if theme_config == null:
		return
	if ResourceLoader.exists(theme_config.ui_settings_panel_path):
		add_theme_stylebox_override("panel", _texture_style(theme_config.ui_settings_panel_path, theme_config.ui_panel_texture_margins, Vector4(42.0, 42.0, 42.0, 34.0)))
	_apply_button_skin(close_button, false)
	title_label.add_theme_color_override("font_color", theme_config.palette_text)
	title_label.add_theme_font_size_override("font_size", 17)
	for label in [$Margin/VBox/SfxRow/Margin/Line/Name, $Margin/VBox/BgmRow/Margin/Line/Name, $Margin/VBox/ShiftLockRow/Margin/Line/Name]:
		label.add_theme_color_override("font_color", theme_config.palette_text)
		label.add_theme_font_size_override("font_size", 16)
	for row in [$Margin/VBox/SfxRow, $Margin/VBox/BgmRow, $Margin/VBox/ShiftLockRow]:
		if ResourceLoader.exists(theme_config.ui_settings_row_path):
			row.add_theme_stylebox_override("panel", _texture_style(theme_config.ui_settings_row_path, theme_config.ui_row_texture_margins, Vector4(42.0, 8.0, 42.0, 8.0)))

func _set_button_state(button: Button, enabled: bool) -> void:
	if button == null:
		return
	button.text = "ON" if enabled else "OFF"
	_apply_button_skin(button, enabled)

func _apply_button_skin(button: Button, enabled: bool) -> void:
	if theme_config == null or button == null:
		return
	var path := theme_config.ui_settings_toggle_on_path if enabled else theme_config.ui_settings_toggle_off_path
	if button == close_button:
		path = theme_config.ui_leaderboard_close_path
		button.text = ""
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var style := _texture_style(path, theme_config.ui_button_texture_margins, Vector4(24.0, 8.0, 24.0, 8.0))
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", theme_config.palette_text)
	button.add_theme_color_override("font_hover_color", theme_config.palette_text)
	button.add_theme_color_override("font_pressed_color", theme_config.palette_text)
	button.add_theme_font_size_override("font_size", 14)

func _apply_hud_button_skin(button: Button) -> void:
	if theme_config == null or button == null or not ResourceLoader.exists(theme_config.ui_leaderboard_button_path):
		return
	var style := _texture_style(theme_config.ui_leaderboard_button_path, Vector4(26.0, 10.0, 26.0, 10.0), Vector4(30.0, 8.0, 30.0, 8.0))
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", theme_config.palette_text)
	button.add_theme_color_override("font_hover_color", theme_config.palette_text)
	button.add_theme_color_override("font_pressed_color", theme_config.palette_text)
	button.add_theme_font_size_override("font_size", 14)

func _texture_style(path: String, margins: Vector4, content_margins: Vector4) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(path)
	style.texture_margin_left = margins.x
	style.texture_margin_top = margins.y
	style.texture_margin_right = margins.z
	style.texture_margin_bottom = margins.w
	style.content_margin_left = content_margins.x
	style.content_margin_top = content_margins.y
	style.content_margin_right = content_margins.z
	style.content_margin_bottom = content_margins.w
	return style
