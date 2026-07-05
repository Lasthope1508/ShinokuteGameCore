class_name UiTextLayout extends RefCounted

const DEFAULT_TEXT_ROLES := {
	"modal_title": {
		"font_size": 28,
		"min_font_size": 16,
		"horizontal_alignment": "center",
		"vertical_alignment": "center",
		"size_flags_horizontal": "expand_fill",
		"overflow": "ellipsis",
		"fit": "shrink_to_fit",
		"padding_ratio": 0.08,
		"max_lines": 1
	},
	"modal_body_center": {
		"font_size": 18,
		"min_font_size": 12,
		"horizontal_alignment": "center",
		"vertical_alignment": "center",
		"size_flags_horizontal": "expand_fill",
		"overflow": "ellipsis",
		"fit": "shrink_to_fit",
		"padding_ratio": 0.08,
		"max_lines": 2
	},
	"leaderboard_empty_state": {
		"font_size": 18,
		"min_font_size": 12,
		"horizontal_alignment": "center",
		"vertical_alignment": "center",
		"size_flags_horizontal": "expand_fill",
		"overflow": "ellipsis",
		"fit": "shrink_to_fit",
		"padding_ratio": 0.08,
		"max_lines": 1
	},
	"leaderboard_title": {
		"font_size": 24,
		"min_font_size": 16,
		"horizontal_alignment": "center",
		"vertical_alignment": "center",
		"size_flags_horizontal": "expand_fill",
		"overflow": "ellipsis",
		"fit": "shrink_to_fit",
		"padding_ratio": 0.10,
		"max_lines": 1
	},
	"leaderboard_status": {
		"font_size": 15,
		"min_font_size": 11,
		"horizontal_alignment": "center",
		"vertical_alignment": "center",
		"size_flags_horizontal": "expand_fill",
		"overflow": "ellipsis",
		"fit": "shrink_to_fit",
		"padding_ratio": 0.08,
		"max_lines": 1
	},
	"leaderboard_score_row": {
		"font_size": 18,
		"min_font_size": 11,
		"horizontal_alignment": "left",
		"vertical_alignment": "center",
		"size_flags_horizontal": "expand_fill",
		"overflow": "ellipsis",
		"fit": "shrink_to_fit",
		"padding_ratio": 0.05,
		"max_lines": 1
	},
	"modal_action_button": {
		"font_size": 20,
		"min_font_size": 12,
		"horizontal_alignment": "center",
		"vertical_alignment": "center",
		"size_flags_horizontal": "expand_fill",
		"overflow": "ellipsis",
		"fit": "shrink_to_fit",
		"padding_ratio": 0.10,
		"max_lines": 1
	}
}

static func apply_label_role(label: Label, theme: ThemeConfig, role_name: String, owner_size: Vector2 = Vector2.ZERO) -> void:
	if label == null:
		return
	var role := get_text_role(theme, role_name)
	_apply_common_control_role(label, role)
	label.horizontal_alignment = _horizontal_alignment(String(role.get("horizontal_alignment", "left")))
	label.vertical_alignment = _vertical_alignment(String(role.get("vertical_alignment", "center")))
	label.clip_text = true
	label.text_overrun_behavior = _overrun_behavior(String(role.get("overflow", "ellipsis")))
	label.autowrap_mode = _autowrap_mode(String(role.get("overflow", "ellipsis")))
	_apply_label_font_and_color(label, theme, role)
	if String(role.get("fit", "none")) == "shrink_to_fit" and owner_size.x > 0.0 and owner_size.y > 0.0:
		fit_label_font_to_owner(label, theme, role_name, owner_size)

static func fit_label_font_to_owner(label: Label, theme: ThemeConfig, role_name: String, owner_size: Vector2) -> int:
	if label == null:
		return 0
	var role := get_text_role(theme, role_name)
	var max_size := int(role.get("font_size", label.get_theme_font_size("font_size")))
	var min_size := int(role.get("min_font_size", max(8, max_size)))
	var padding_ratio := clampf(float(role.get("padding_ratio", 0.0)), 0.0, 0.45)
	var usable_width: float = max(1.0, owner_size.x * (1.0 - padding_ratio * 2.0))
	var usable_height: float = max(1.0, owner_size.y * (1.0 - padding_ratio * 2.0))
	var max_lines: int = max(1, int(role.get("max_lines", 1)))
	var font: Font = _resolve_font(label, theme, role)
	for size in range(max_size, min_size - 1, -1):
		if _label_text_fits(label.text, font, size, usable_width, usable_height, max_lines):
			label.add_theme_font_size_override("font_size", size)
			return size
	label.add_theme_font_size_override("font_size", min_size)
	return min_size

static func apply_button_role(button: Button, theme: ThemeConfig, role_name: String, owner_size: Vector2 = Vector2.ZERO) -> void:
	if button == null:
		return
	var role := get_text_role(theme, role_name)
	_apply_common_control_role(button, role)
	button.clip_text = true
	button.text_overrun_behavior = _overrun_behavior(String(role.get("overflow", "ellipsis")))
	var max_size := int(role.get("font_size", button.get_theme_font_size("font_size")))
	button.add_theme_font_size_override("font_size", max_size)
	if theme != null and theme.custom_font != null:
		button.add_theme_font_override("font", theme.custom_font)
	if String(role.get("fit", "none")) == "shrink_to_fit" and owner_size.x > 0.0 and owner_size.y > 0.0:
		fit_button_font_to_owner(button, theme, role_name, owner_size)

static func fit_button_font_to_owner(button: Button, theme: ThemeConfig, role_name: String, owner_size: Vector2) -> int:
	if button == null:
		return 0
	var role := get_text_role(theme, role_name)
	var max_size := int(role.get("font_size", button.get_theme_font_size("font_size")))
	var min_size := int(role.get("min_font_size", max(8, max_size)))
	var padding_ratio := clampf(float(role.get("padding_ratio", 0.0)), 0.0, 0.45)
	var usable_width: float = max(1.0, owner_size.x * (1.0 - padding_ratio * 2.0))
	var usable_height: float = max(1.0, owner_size.y * (1.0 - padding_ratio * 2.0))
	var font: Font = button.get_theme_font("font")
	if font == null and theme != null:
		font = theme.custom_font
	for size in range(max_size, min_size - 1, -1):
		if _label_text_fits(button.text, font, size, usable_width, usable_height, 1):
			button.add_theme_font_size_override("font_size", size)
			return size
	button.add_theme_font_size_override("font_size", min_size)
	return min_size

static func get_text_role(theme: ThemeConfig, role_name: String) -> Dictionary:
	var merged := DEFAULT_TEXT_ROLES.duplicate(true)
	if theme != null:
		var theme_roles = theme.get("ui_text_roles")
		if theme_roles is Dictionary:
			for key in theme_roles.keys():
				var base: Dictionary = merged.get(key, {}).duplicate(true)
				var override = theme_roles.get(key)
				if override is Dictionary:
					for override_key in override.keys():
						base[override_key] = override[override_key]
					merged[key] = base
	if merged.has(role_name):
		return Dictionary(merged.get(role_name, {})).duplicate(true)
	return Dictionary(merged.get("modal_body_center", {})).duplicate(true)

static func _apply_common_control_role(control: Control, role: Dictionary) -> void:
	match String(role.get("size_flags_horizontal", "expand_fill")):
		"shrink_center":
			control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		"shrink_end":
			control.size_flags_horizontal = Control.SIZE_SHRINK_END
		"fill":
			control.size_flags_horizontal = Control.SIZE_FILL
		_:
			control.size_flags_horizontal = Control.SIZE_EXPAND_FILL

static func _apply_label_font_and_color(label: Label, theme: ThemeConfig, role: Dictionary) -> void:
	var font := _resolve_font(label, theme, role)
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", int(role.get("font_size", label.get_theme_font_size("font_size"))))
	if role.has("font_color"):
		label.add_theme_color_override("font_color", role.get("font_color"))
	elif theme != null:
		label.add_theme_color_override("font_color", theme.text_color)
	if role.has("outline_color"):
		label.add_theme_color_override("font_outline_color", role.get("outline_color"))
	if role.has("outline_size"):
		label.add_theme_constant_override("outline_size", int(role.get("outline_size")))

static func _resolve_font(label: Label, theme: ThemeConfig, role: Dictionary) -> Font:
	var font_path := String(role.get("font_path", ""))
	if not font_path.is_empty() and ResourceLoader.exists(font_path):
		var loaded_font := load(font_path) as Font
		if loaded_font != null:
			return loaded_font
	if theme != null and theme.custom_font != null:
		return theme.custom_font
	if label != null:
		return label.get_theme_font("font")
	return null

static func _label_text_fits(text: String, font: Font, font_size: int, usable_width: float, usable_height: float, max_lines: int) -> bool:
	var lines := text.split("\n")
	if lines.size() > max_lines:
		return false
	var line_height := float(font_size) * 1.18
	if line_height * float(max(1, lines.size())) > usable_height:
		return false
	if font == null:
		return true
	for raw_line in lines:
		if font.get_string_size(String(raw_line), HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > usable_width:
			return false
	return true

static func _horizontal_alignment(value: String) -> HorizontalAlignment:
	match value:
		"center":
			return HORIZONTAL_ALIGNMENT_CENTER
		"right":
			return HORIZONTAL_ALIGNMENT_RIGHT
		_:
			return HORIZONTAL_ALIGNMENT_LEFT

static func _vertical_alignment(value: String) -> VerticalAlignment:
	match value:
		"top":
			return VERTICAL_ALIGNMENT_TOP
		"bottom":
			return VERTICAL_ALIGNMENT_BOTTOM
		_:
			return VERTICAL_ALIGNMENT_CENTER

static func _overrun_behavior(value: String) -> TextServer.OverrunBehavior:
	match value:
		"clip":
			return TextServer.OVERRUN_NO_TRIMMING
		_:
			return TextServer.OVERRUN_TRIM_ELLIPSIS

static func _autowrap_mode(value: String) -> TextServer.AutowrapMode:
	match value:
		"wrap":
			return TextServer.AUTOWRAP_WORD_SMART
		_:
			return TextServer.AUTOWRAP_OFF
