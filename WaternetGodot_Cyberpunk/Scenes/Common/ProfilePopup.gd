extends Panel

const GAME_CORE_CONFIG_PATH := "res://Resources/Data/glyphflow_game_core_config.tres"

@onready var username_edit: LineEdit = $MarginContainer/VBoxContainer/HBoxEdit/UsernameEdit
@onready var margin_container: MarginContainer = $MarginContainer
@onready var vbox_container: VBoxContainer = $MarginContainer/VBoxContainer
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var edit_hbox: HBoxContainer = $MarginContainer/VBoxContainer/HBoxEdit
@onready var save_btn: Button = $MarginContainer/VBoxContainer/HBoxEdit/SaveBtn
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var close_btn: Button = $CloseBtn

var _core_config: Resource

func _ready() -> void:
	_core_config = load(GAME_CORE_CONFIG_PATH)
	if has_node("/root/ThemeManager"):
		apply_generated_ui_theme(ThemeManager.active_theme)
	if has_node("/root/SaveManager"):
		username_edit.text = SaveManager.get_username()
	status_label.text = "ENTER PLAYER NAME"

func _on_save_btn_pressed() -> void:
	var new_name := username_edit.text.strip_edges()
	var errors := _validate_username(new_name)
	if not errors.is_empty():
		status_label.text = String(errors[0]).to_upper()
		return
	if has_node("/root/SaveManager"):
		SaveManager.set_username(new_name)
	status_label.text = "PROFILE SAVED"

func _validate_username(username: String) -> Array:
	if _core_config != null and _core_config.has_method("validate_username"):
		return _core_config.validate_username(username)
	if username.strip_edges().is_empty():
		return ["Username cannot be empty."]
	return []

func _on_close_btn_pressed() -> void:
	queue_free()

func apply_generated_ui_theme(theme_config: ThemeConfig) -> void:
	if theme_config == null:
		return
	add_theme_stylebox_override("panel", _make_transparent_control_style())
	if margin_container:
		margin_container.add_theme_constant_override("margin_left", theme_config.ui_profile_popup_content_margin_x)
		margin_container.add_theme_constant_override("margin_top", theme_config.ui_profile_popup_content_margin_top)
		margin_container.add_theme_constant_override("margin_right", theme_config.ui_profile_popup_content_margin_x)
		margin_container.add_theme_constant_override("margin_bottom", theme_config.ui_profile_popup_content_margin_bottom)
	if vbox_container:
		vbox_container.add_theme_constant_override("separation", theme_config.ui_modal_content_gap)
	if title_label:
		title_label.add_theme_font_size_override("font_size", theme_config.ui_profile_popup_title_font_size)
		title_label.add_theme_color_override("font_color", theme_config.text_color)
	if edit_hbox:
		edit_hbox.add_theme_constant_override("separation", theme_config.ui_profile_popup_field_gap)
	if save_btn:
		save_btn.custom_minimum_size.x = theme_config.ui_profile_popup_save_button_width
	if status_label:
		status_label.add_theme_font_size_override("font_size", theme_config.ui_profile_popup_score_font_size)
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
