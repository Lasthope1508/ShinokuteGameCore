extends PanelContainer

const RuntimeThemeConfig := preload("res://Resources/QuantumRuntimeThemeConfig.gd")
const FunctionOverlayGroup := preload("res://addons/shinokute_game_core/ui/function_overlay_group.gd")

@export var bridge_path := NodePath("../../CandyGameCore")
@export var toggle_button_path := NodePath("../LeaderboardButton")
@export var default_tab := "world"
@export var overlay_group := "hud_function_overlay"
@export var theme_config: RuntimeThemeConfig

@onready var title_label: Label = $Margin/VBox/Header/Title
@onready var close_button: Button = $Margin/VBox/Header/CloseButton
@onready var world_button: Button = $Margin/VBox/Tabs/WorldButton
@onready var country_button: Button = $Margin/VBox/Tabs/CountryButton
@onready var rows: VBoxContainer = $Margin/VBox/Rows
@onready var status_label: Label = $Margin/VBox/StatusLabel

var _bridge: Node
var _active_tab := "world"

func _ready() -> void:
	visible = false
	FunctionOverlayGroup.register_panel(self, overlay_group)
	_active_tab = default_tab
	_bridge = get_node_or_null(bridge_path)
	var toggle_button := get_node_or_null(toggle_button_path)
	if toggle_button is Button:
		FunctionOverlayGroup.disable_gameplay_button_focus(toggle_button)
		toggle_button.pressed.connect(_on_toggle_pressed)
		_apply_button_skin(toggle_button, "leaderboard")
	FunctionOverlayGroup.disable_gameplay_button_focus(self)
	close_button.pressed.connect(func(): FunctionOverlayGroup.hide_panel(self))
	world_button.pressed.connect(func(): show_leaderboard("world"))
	country_button.pressed.connect(func(): show_leaderboard("country"))
	if _bridge != null and _bridge.has_signal("leaderboard_loaded"):
		_bridge.leaderboard_loaded.connect(_on_leaderboard_loaded)
	_apply_function_skin()

func show_leaderboard(tab: String = default_tab) -> void:
	_active_tab = tab
	FunctionOverlayGroup.show_panel(self, overlay_group)
	_set_status("Loading...")
	_clear_rows()
	if _bridge == null:
		_set_status("Leaderboard unavailable")
		return
	if _bridge.has_method("fetch_leaderboard"):
		var err: int = _bridge.fetch_leaderboard(tab)
		if err != OK:
			_set_status("Leaderboard unavailable")

func _on_toggle_pressed() -> void:
	if visible:
		FunctionOverlayGroup.hide_panel(self)
	else:
		show_leaderboard(_active_tab)

func _on_leaderboard_loaded(tab: String, scores: Array, _mode: String) -> void:
	if tab != _active_tab:
		return
	_clear_rows()
	if scores.is_empty():
		_set_status("No scores yet")
		return
	_set_status("")
	for index in min(scores.size(), 10):
		_add_score_row(index + 1, scores[index])

func _add_score_row(rank: int, score_data: Dictionary) -> void:
	var row_panel := PanelContainer.new()
	row_panel.name = "Row%02d" % rank
	row_panel.custom_minimum_size = Vector2(0.0, 48.0)
	if theme_config != null and ResourceLoader.exists(theme_config.ui_leaderboard_row_path):
		row_panel.add_theme_stylebox_override("panel", _texture_style(theme_config.ui_leaderboard_row_path, Vector4(22.0, 10.0, 22.0, 10.0), Vector4(42.0, 8.0, 42.0, 8.0)))

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 58)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_bottom", 7)
	row_panel.add_child(margin)

	var row := Label.new()
	row.name = "Text"
	var username := String(score_data.get("username", "Anonymous"))
	var score := int(score_data.get("score", 0))
	var label := String(score_data.get("score_label", "level"))
	row.text = "%02d  %s  %s %s" % [rank, username, label, score]
	row.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_color_override("font_color", _text_color())
	row.add_theme_font_size_override("font_size", 16)
	margin.add_child(row)
	rows.add_child(row_panel)

func _clear_rows() -> void:
	for child in rows.get_children():
		child.queue_free()

func _set_status(message: String) -> void:
	status_label.text = message
	status_label.visible = not message.is_empty()
	title_label.text = "LEADERBOARD"

func _apply_function_skin() -> void:
	if theme_config == null:
		return
	if ResourceLoader.exists(theme_config.ui_leaderboard_panel_path):
		add_theme_stylebox_override("panel", _texture_style(theme_config.ui_leaderboard_panel_path, theme_config.ui_panel_texture_margins, Vector4(54.0, 54.0, 46.0, 34.0)))
	_apply_button_skin(close_button, "close")
	_apply_button_skin(world_button, "tab")
	_apply_button_skin(country_button, "tab")
	for label in [title_label, status_label]:
		label.add_theme_color_override("font_color", theme_config.palette_text)
		label.add_theme_font_size_override("font_size", 17)

func _apply_button_skin(button: Button, role: String) -> void:
	if theme_config == null or button == null:
		return
	var texture_path := ""
	var margins := theme_config.ui_button_texture_margins
	if role == "leaderboard":
		texture_path = theme_config.ui_leaderboard_button_path
		margins = Vector4(26.0, 10.0, 26.0, 10.0)
	elif role == "close":
		texture_path = theme_config.ui_leaderboard_close_path
		button.text = ""
	elif role == "tab":
		texture_path = theme_config.ui_leaderboard_tab_path
		margins = Vector4(24.0, 10.0, 24.0, 10.0)
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		return
	var style := _texture_style(texture_path, margins, _content_margins_for_role(role))
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", theme_config.palette_text)
	button.add_theme_color_override("font_hover_color", theme_config.palette_text)
	button.add_theme_color_override("font_pressed_color", theme_config.palette_text)
	button.add_theme_font_size_override("font_size", 14 if role == "leaderboard" else 13)

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

func _content_margins_for_role(role: String) -> Vector4:
	if role == "leaderboard":
		return Vector4(30.0, 8.0, 30.0, 8.0)
	if role == "tab":
		return Vector4(28.0, 8.0, 28.0, 8.0)
	if role == "close":
		return Vector4(24.0, 24.0, 24.0, 24.0)
	return Vector4(28.0, 8.0, 28.0, 8.0)

func _text_color() -> Color:
	if theme_config != null:
		return theme_config.palette_text
	return Color("#273043")
