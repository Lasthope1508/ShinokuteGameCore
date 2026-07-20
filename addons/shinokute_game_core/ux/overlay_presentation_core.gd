class_name ShinokuteOverlayPresentationCore
extends RefCounted

func resolve_panel(config: Dictionary = {}) -> Dictionary:
	var viewport_size: Vector2 = _vector2(config.get("viewport_size", Vector2.ZERO), Vector2.ZERO)
	var viewport_margin: float = max(0.0, float(config.get("viewport_margin", 0.0)))
	var desired_size: Vector2 = _owner_size(config.get("owner_rect", null), _vector2(config.get("missing_owner_size", viewport_size), viewport_size))
	var min_size: Vector2 = _vector2(config.get("min_size", Vector2.ONE), Vector2.ONE)
	var max_size: Vector2 = _vector2(config.get("max_size", viewport_size), viewport_size)
	if viewport_size != Vector2.ZERO:
		max_size = Vector2(
			min(max_size.x, max(1.0, viewport_size.x - viewport_margin * 2.0)),
			min(max_size.y, max(1.0, viewport_size.y - viewport_margin * 2.0))
		)
	var size: Vector2 = Vector2(
		clamp(desired_size.x, min_size.x, max_size.x),
		clamp(desired_size.y, min_size.y, max_size.y)
	)
	var position: Vector2 = Vector2.ZERO
	if viewport_size != Vector2.ZERO:
		position = (viewport_size - size) * 0.5
	var rect: Rect2 = Rect2(position, size)
	return {
		"rect": rect,
		"size": size,
		"position": position,
		"offsets": Vector4(-size.x * 0.5, -size.y * 0.5, size.x * 0.5, size.y * 0.5),
		"anchors": Vector4(0.5, 0.5, 0.5, 0.5),
		"clamped": size.distance_to(desired_size) > 0.001
	}

func resolve_content(config: Dictionary = {}) -> Dictionary:
	var panel_rect: Rect2 = _rect2(config.get("panel_rect", Rect2()))
	var margin: Vector4 = _vector4(config.get("content_margin", Vector4.ZERO), Vector4.ZERO)
	var left: float = max(0.0, margin.x)
	var top: float = max(0.0, margin.y)
	var right: float = max(0.0, margin.z)
	var bottom: float = max(0.0, margin.w)
	var size: Vector2 = Vector2(
		max(1.0, panel_rect.size.x - left - right),
		max(1.0, panel_rect.size.y - top - bottom)
	)
	var rect: Rect2 = Rect2(panel_rect.position + Vector2(left, top), size)
	return {
		"rect": rect,
		"size": size,
		"offsets": Vector4(left, top, -right, -bottom),
		"margin": Vector4(left, top, right, bottom)
	}

func resolve_vertical_slots(config: Dictionary = {}) -> Dictionary:
	var content_rect: Rect2 = _rect2(config.get("content_rect", Rect2()))
	var count: int = max(0, int(config.get("count", 0)))
	var spacing: float = max(0.0, float(config.get("spacing", 0.0)))
	var desired_size: Vector2 = _owner_size(config.get("item_owner_rect", null), content_rect.size)
	var fit_height: bool = bool(config.get("fit_height", true))
	var item_width: float = min(desired_size.x, content_rect.size.x)
	var item_height: float = desired_size.y
	var available_height: float = max(1.0, content_rect.size.y - spacing * max(0, count - 1))
	if count > 0 and fit_height:
		item_height = min(item_height, available_height / float(count))
	item_height = max(1.0, item_height)
	var item_size: Vector2 = Vector2(max(1.0, item_width), item_height)
	var slots: Array = []
	for index in range(count):
		var x: float = content_rect.position.x + (content_rect.size.x - item_size.x) * 0.5
		var y: float = content_rect.position.y + float(index) * (item_size.y + spacing)
		slots.append(Rect2(Vector2(x, y), item_size))
	return {
		"slots": slots,
		"item_size": item_size,
		"spacing": spacing,
		"clamped": item_size.distance_to(desired_size) > 0.001
	}

func resolve_horizontal_slots(config: Dictionary = {}) -> Dictionary:
	var content_rect: Rect2 = _rect2(config.get("content_rect", Rect2()))
	var count: int = max(0, int(config.get("count", 0)))
	var spacing: float = max(0.0, float(config.get("spacing", 0.0)))
	var desired_size: Vector2 = _owner_size(config.get("item_owner_rect", null), content_rect.size)
	var fit_width: bool = bool(config.get("fit_width", true))
	var item_width: float = desired_size.x
	var item_height: float = min(desired_size.y, content_rect.size.y)
	var available_width: float = max(1.0, content_rect.size.x - spacing * max(0, count - 1))
	if count > 0 and fit_width:
		item_width = min(item_width, available_width / float(count))
	item_width = max(1.0, item_width)
	var item_size: Vector2 = Vector2(item_width, max(1.0, item_height))
	var slots: Array = []
	var total_width: float = item_size.x * float(count) + spacing * float(max(0, count - 1))
	var start_x: float = content_rect.position.x + max(0.0, (content_rect.size.x - total_width) * 0.5)
	for index in range(count):
		var x: float = start_x + float(index) * (item_size.x + spacing)
		var y: float = content_rect.position.y + (content_rect.size.y - item_size.y) * 0.5
		slots.append(Rect2(Vector2(x, y), item_size))
	return {
		"slots": slots,
		"item_size": item_size,
		"spacing": spacing,
		"clamped": item_size.distance_to(desired_size) > 0.001
	}

func resolve_motion(config: Dictionary = {}) -> Dictionary:
	var duration: float = max(0.0, float(config.get("duration", 0.0)))
	var elapsed: float = max(0.0, float(config.get("elapsed", 0.0)))
	var progress: float = 1.0
	if duration > 0.0:
		progress = clamp(elapsed / duration, 0.0, 1.0)
	var from_alpha: float = float(config.get("from_alpha", 1.0))
	var to_alpha: float = float(config.get("to_alpha", 1.0))
	var from_scale: float = float(config.get("from_scale", 1.0))
	var to_scale: float = float(config.get("to_scale", 1.0))
	return {
		"phase": String(config.get("phase", "")),
		"progress": progress,
		"alpha": lerp(from_alpha, to_alpha, progress),
		"scale": lerp(from_scale, to_scale, progress),
		"done": progress >= 1.0
	}

func _owner_size(value, missing_value: Vector2 = Vector2.ONE) -> Vector2:
	if value is Vector4:
		return Vector2(max(1.0, value.z), max(1.0, value.w))
	if value is Rect2:
		return Vector2(max(1.0, value.size.x), max(1.0, value.size.y))
	if value is Vector2:
		return Vector2(max(1.0, value.x), max(1.0, value.y))
	return Vector2(max(1.0, missing_value.x), max(1.0, missing_value.y))

func _vector2(value, missing_value: Vector2) -> Vector2:
	if value is Vector2:
		return value
	return missing_value

func _vector4(value, missing_value: Vector4) -> Vector4:
	if value is Vector4:
		return value
	return missing_value

func _rect2(value) -> Rect2:
	if value is Rect2:
		return value
	return Rect2()
