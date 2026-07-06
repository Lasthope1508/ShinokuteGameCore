extends Panel

const UiTextLayout = preload("res://Scripts/ui_text_layout.gd")

signal dismissed

@onready var margin_container: MarginContainer = $MarginContainer
@onready var vbox_container: VBoxContainer = $MarginContainer/VBoxContainer
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var scroll_container: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer
@onready var score_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ScoreList
@onready var close_btn: Button = $CloseBtn

func _ready() -> void:
	if has_node("/root/ThemeManager"):
		apply_generated_ui_theme(ThemeManager.active_theme)
	if has_node("/root/GameCoreManager"):
		if not GameCoreManager.leaderboard_loaded.is_connected(_on_leaderboard_loaded):
			GameCoreManager.leaderboard_loaded.connect(_on_leaderboard_loaded)
		status_label.text = "LOADING LEADERBOARD..."
		var err := GameCoreManager.fetch_leaderboard("world", "classic")
		if err != OK:
			status_label.text = "LEADERBOARD NOT AVAILABLE"
	else:
		status_label.text = "LEADERBOARD NOT AVAILABLE"

func _on_leaderboard_loaded(tab: String, scores: Array, mode: String) -> void:
	status_label.text = "WORLD LEADERBOARD"
	for child in score_list.get_children():
		child.queue_free()
	if scores.is_empty():
		_add_score_row("No scores submitted yet.", "leaderboard_empty_state")
		return
	var rank := 1
	for item in scores:
		var player_name := String(item.get("username", "Anonymous"))
		var val := int(item.get("score", 0))
		var label := String(item.get("score_label", "moves")).to_upper()
		_add_score_row("%02d  %s  %d %s" % [rank, player_name, val, label], "leaderboard_score_row")
		rank += 1

func _add_score_row(text: String, text_role: String) -> void:
	var row := Label.new()
	row.text = text
	var theme_config: ThemeConfig = null
	if has_node("/root/ThemeManager"):
		theme_config = ThemeManager.active_theme
	UiTextLayout.apply_label_role(row, theme_config, text_role, _get_score_list_owner_size())
	score_list.add_child(row)

func _on_close_btn_pressed() -> void:
	dismissed.emit()
	queue_free()

func apply_generated_ui_theme(theme_config: ThemeConfig) -> void:
	if theme_config == null:
		return
	add_theme_stylebox_override("panel", _make_transparent_control_style())
	if margin_container:
		margin_container.add_theme_constant_override("margin_left", theme_config.ui_leaderboard_popup_content_margin_x)
		margin_container.add_theme_constant_override("margin_top", theme_config.ui_leaderboard_popup_content_margin_top)
		margin_container.add_theme_constant_override("margin_right", theme_config.ui_leaderboard_popup_content_margin_x)
		margin_container.add_theme_constant_override("margin_bottom", theme_config.ui_leaderboard_popup_content_margin_bottom)
	if vbox_container:
		vbox_container.add_theme_constant_override("separation", theme_config.ui_modal_content_gap)
	if scroll_container:
		scroll_container.clip_contents = true
		scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	if title_label:
		UiTextLayout.apply_label_role(title_label, theme_config, "leaderboard_title", _get_title_owner_size(theme_config))
	if score_list:
		score_list.clip_contents = true
		score_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		score_list.add_theme_constant_override("separation", theme_config.ui_leaderboard_popup_list_gap)
	if status_label:
		UiTextLayout.apply_label_role(status_label, theme_config, "leaderboard_status", _get_status_owner_size(theme_config))
	var texture := theme_config.get_ui_generated_asset_texture(String(theme_config.ui_generated_asset_mode), "modal_frame")
	if texture != null:
		var frame := _ensure_generated_modal_frame()
		frame.texture = _get_generated_ui_region_texture(theme_config, "modal_frame", texture)
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		frame.visible = true
	if close_btn:
		var close_padding := theme_config.ui_modal_close_button_padding
		close_btn.custom_minimum_size = Vector2(theme_config.ui_modal_close_button_size, theme_config.ui_modal_close_button_size)
		close_btn.anchor_left = 1.0
		close_btn.anchor_right = 1.0
		close_btn.anchor_top = 0.0
		close_btn.anchor_bottom = 0.0
		close_btn.offset_left = -theme_config.ui_modal_close_button_size - close_padding
		close_btn.offset_top = close_padding
		close_btn.offset_right = -close_padding
		close_btn.offset_bottom = close_padding + theme_config.ui_modal_close_button_size
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			close_btn.add_theme_stylebox_override(state, _make_transparent_control_style())

func _ensure_generated_modal_frame() -> TextureRect:
	var existing := get_node_or_null("GeneratedModalFrame")
	if existing is TextureRect:
		return existing as TextureRect
	var frame := TextureRect.new()
	frame.name = "GeneratedModalFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.anchor_left = 0.0
	frame.anchor_top = 0.0
	frame.anchor_right = 1.0
	frame.anchor_bottom = 1.0
	frame.offset_left = 0.0
	frame.offset_top = 0.0
	frame.offset_right = 0.0
	frame.offset_bottom = 0.0
	frame.z_index = -10
	add_child(frame)
	move_child(frame, 0)
	return frame

func _get_generated_ui_region_texture(theme_config: ThemeConfig, asset_key: String, texture: Texture2D) -> Texture2D:
	var geometry := theme_config.get_ui_generated_asset_geometry(asset_key)
	var bboxes: Dictionary = geometry.get("alpha_bbox", {})
	var bbox = bboxes.get(String(theme_config.ui_generated_asset_mode), null)
	if not (bbox is Vector4):
		return texture
	var rect := Rect2(Vector2(bbox.x, bbox.y), Vector2(bbox.z, bbox.w))
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = rect
	return atlas

func _make_transparent_control_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	style.shadow_color = Color.TRANSPARENT
	style.shadow_size = 0
	style.shadow_offset = Vector2.ZERO
	return style

func _get_score_list_owner_size() -> Vector2:
	if score_list != null and score_list.size.x > 0.0 and score_list.size.y > 0.0:
		return score_list.size
	if scroll_container != null and scroll_container.size.x > 0.0 and scroll_container.size.y > 0.0:
		return scroll_container.size
	if vbox_container != null and vbox_container.size.x > 0.0:
		return Vector2(vbox_container.size.x, max(1.0, float(get_theme_font_size("font_size")) * 1.4))
	return Vector2.ZERO

func _get_title_owner_size(theme_config: ThemeConfig) -> Vector2:
	var owner_width := 0.0
	if margin_container != null and margin_container.size.x > 0.0:
		owner_width = margin_container.size.x - float(theme_config.ui_leaderboard_popup_content_margin_x * 2)
	elif size.x > 0.0:
		owner_width = size.x - float(theme_config.ui_leaderboard_popup_content_margin_x * 2)
	return Vector2(max(1.0, owner_width), max(1.0, float(theme_config.ui_leaderboard_popup_title_font_size) * 1.45))

func _get_status_owner_size(theme_config: ThemeConfig) -> Vector2:
	var title_owner := _get_title_owner_size(theme_config)
	return Vector2(title_owner.x, max(1.0, float(theme_config.ui_leaderboard_popup_status_font_size) * 1.45))
