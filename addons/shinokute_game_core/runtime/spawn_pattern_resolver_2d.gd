class_name ShinokuteSpawnPatternResolver2D
extends RefCounted

func resolve(config: Dictionary) -> Array:
	match String(config.get("pattern", "")):
		"ring":
			return _ring(config)
		"edge":
			return _edge(config)
		"lane":
			return _lane(config)
	return []

func _ring(config: Dictionary) -> Array:
	var points: Array = []
	var center: Vector2 = config.get("center", Vector2.ZERO)
	var radius := float(config.get("radius", 0.0))
	var count := int(max(0, int(config.get("count", 0))))
	if count <= 0:
		return points
	for i in range(count):
		var angle := TAU * float(i) / float(count)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points

func _edge(config: Dictionary) -> Array:
	var points: Array = []
	var rect: Rect2 = config.get("rect", Rect2())
	var side := String(config.get("side", "top"))
	var count := int(max(0, int(config.get("count", 0))))
	if count <= 0:
		return points
	for i in range(count):
		var ratio := 0.5 if count == 1 else float(i) / float(count - 1)
		match side:
			"bottom":
				points.append(Vector2(rect.position.x + rect.size.x * ratio, rect.position.y + rect.size.y))
			"left":
				points.append(Vector2(rect.position.x, rect.position.y + rect.size.y * ratio))
			"right":
				points.append(Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y * ratio))
			_:
				points.append(Vector2(rect.position.x + rect.size.x * ratio, rect.position.y))
	return points

func _lane(config: Dictionary) -> Array:
	var points: Array = []
	var start: Vector2 = config.get("start", Vector2.ZERO)
	var end: Vector2 = config.get("end", start)
	var count := int(max(0, int(config.get("count", 0))))
	if count <= 0:
		return points
	for i in range(count):
		var ratio := 0.0 if count == 1 else float(i) / float(count - 1)
		points.append(start.lerp(end, ratio))
	return points
