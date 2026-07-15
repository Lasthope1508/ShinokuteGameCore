class_name ShinokuteWorldFeedbackPresenter
extends RefCounted

func spawn_feedback(parent: Node, text: String, world_position: Vector2, config: Dictionary = {}) -> Label:
	if parent == null or text.is_empty():
		return null
	var label := Label.new()
	label.text = text
	label.position = screen_position(world_position, config) + _vector2(config, "offset", Vector2.ZERO)
	label.set_meta("source_position", world_position)
	label.set_meta("source_screen_position", screen_position(world_position, config))
	label.set_meta("ttl_frames", int(max(0, int(config.get("ttl_frames", 0)))))
	var font_size := int(config.get("font_size", 0))
	if font_size > 0:
		label.add_theme_font_size_override("font_size", font_size)
	if config.has("color") and config["color"] is Color:
		label.add_theme_color_override("font_color", config["color"])
	parent.add_child(label)
	return label

func update_feedback(parent: Node, drift_per_frame: float = 0.0) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		var ttl := int(child.get_meta("ttl_frames", 0)) - 1
		child.set_meta("ttl_frames", ttl)
		if child is Control:
			(child as Control).position.y -= drift_per_frame
		if ttl <= 0:
			parent.remove_child(child)
			child.queue_free()

func screen_position(world_position: Vector2, config: Dictionary = {}) -> Vector2:
	var viewport_size := _vector2(config, "viewport_size", Vector2.ZERO)
	var camera_position := _vector2(config, "camera_position", Vector2.ZERO)
	var zoom := _vector2(config, "zoom", Vector2.ONE)
	if viewport_size == Vector2.ZERO:
		return world_position
	return (world_position - camera_position) * zoom + viewport_size * 0.5

func _vector2(config: Dictionary, key: String, fallback: Vector2) -> Vector2:
	var value = config.get(key, fallback)
	if value is Vector2:
		return value
	return fallback
