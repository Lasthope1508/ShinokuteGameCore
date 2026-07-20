class_name ShinokuteHealthIndicatorPresenter
extends RefCounted

func ensure_indicator(parent: Node, config: Dictionary = {}) -> Dictionary:
	if parent == null:
		return {}
	var bar_name := String(config.get("bar_name", "HealthBar"))
	var text_name := String(config.get("text_name", "HealthText"))
	var bar := parent.get_node_or_null(bar_name) as ColorRect
	if bar == null:
		bar = ColorRect.new()
		bar.name = bar_name
		bar.position = _vector2(config, "bar_offset", Vector2.ZERO)
		bar.size = _vector2(config, "bar_size", Vector2(24.0, 4.0))
		bar.color = _color(config, "bar_color", Color.WHITE)
		bar.set_meta("full_size", bar.size)
		parent.add_child(bar)
	var text := parent.get_node_or_null(text_name) as Label
	if text == null:
		text = Label.new()
		text.name = text_name
		text.visible = false
		text.position = _vector2(config, "text_offset", Vector2.ZERO)
		var font_size := int(config.get("text_font_size", 0))
		if font_size > 0:
			text.add_theme_font_size_override("font_size", font_size)
		text.add_theme_color_override("font_color", _color(config, "text_color", Color.WHITE))
		parent.add_child(text)
	_apply_parent_scale_compensation(parent, bar, _vector2(config, "bar_offset", Vector2.ZERO), bool(config.get("counter_parent_scale", false)))
	_apply_parent_scale_compensation(parent, text, _vector2(config, "text_offset", Vector2.ZERO), bool(config.get("counter_parent_scale", false)))
	return {"bar": bar, "text": text}

func update_indicator(parent: Node, current_value: int, max_value: int, config: Dictionary = {}) -> void:
	if parent == null:
		return
	ensure_indicator(parent, config)
	var bar := parent.get_node_or_null(String(config.get("bar_name", "HealthBar"))) as ColorRect
	var text := parent.get_node_or_null(String(config.get("text_name", "HealthText"))) as Label
	var current := int(max(0, current_value))
	var maximum := int(max(1, max_value))
	if bar != null:
		var full_size: Vector2 = bar.get_meta("full_size", bar.size)
		bar.size.x = full_size.x * (float(current) / float(maximum))
	if text != null:
		var template := String(config.get("text_format", "%d/%d"))
		text.text = template % [current, maximum]
		text.visible = (not bool(config.get("hide_when_full", false))) or current < maximum
	_apply_parent_scale_compensation(parent, bar, _vector2(config, "bar_offset", Vector2.ZERO), bool(config.get("counter_parent_scale", false)))
	_apply_parent_scale_compensation(parent, text, _vector2(config, "text_offset", Vector2.ZERO), bool(config.get("counter_parent_scale", false)))

func _vector2(config: Dictionary, key: String, missing_value: Vector2) -> Vector2:
	var value = config.get(key, missing_value)
	if value is Vector2:
		return value
	return missing_value

func _color(config: Dictionary, key: String, missing_value: Color) -> Color:
	var value = config.get(key, missing_value)
	if value is Color:
		return value
	return missing_value

func _apply_parent_scale_compensation(parent: Node, node: CanvasItem, offset: Vector2, enabled: bool) -> void:
	if not enabled or parent == null or node == null:
		return
	if not (parent is Node2D):
		return
	var parent_node: Node2D = parent as Node2D
	var parent_scale: Vector2 = parent_node.get_global_transform().get_scale()
	var safe_x: float = 1.0 / maxf(0.001, absf(parent_scale.x))
	var safe_y: float = 1.0 / maxf(0.001, absf(parent_scale.y))
	node.set("position", Vector2(offset.x * safe_x, offset.y * safe_y))
	node.set("scale", Vector2(safe_x, safe_y))
