class_name ShinokuteProjectileTravelRuntime2D
extends RefCounted

var _defaults: Dictionary = {}

func configure(defaults: Dictionary = {}) -> void:
	_defaults = defaults.duplicate(true)

func initial_state(config: Dictionary = {}) -> Dictionary:
	var merged := _merged_config(config)
	var direction := Vector2(merged.get("direction", Vector2.RIGHT)).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	return {
		"position": Vector2(merged.get("position", Vector2.ZERO)),
		"direction": direction,
		"speed": float(merged.get("speed", merged.get("default_speed", 0.0))),
		"distance": float(merged.get("distance", 0.0)),
		"elapsed": float(merged.get("elapsed", 0.0)),
		"range": float(merged.get("range", merged.get("default_range", 0.0))),
		"lifetime": float(merged.get("lifetime", merged.get("default_lifetime", 0.0))),
		"expired": bool(merged.get("expired", false)),
		"expire_reason": String(merged.get("expire_reason", ""))
	}

func step(state: Dictionary, delta: float, config: Dictionary = {}) -> Dictionary:
	var merged := _merged_config(config)
	var next := state.duplicate(true)
	if bool(next.get("expired", false)):
		return next
	var position := Vector2(next.get("position", Vector2.ZERO))
	var direction := Vector2(next.get("direction", Vector2.RIGHT)).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	direction = _steered_direction(position, direction, delta, merged)
	var speed := float(merged.get("speed", next.get("speed", _defaults.get("default_speed", 0.0))))
	var travel_delta: Vector2 = direction * speed * max(0.0, delta)
	position += travel_delta
	var distance: float = float(next.get("distance", 0.0)) + travel_delta.length()
	var elapsed: float = float(next.get("elapsed", 0.0)) + max(0.0, delta)
	next["position"] = position
	next["direction"] = direction
	next["speed"] = speed
	next["distance"] = distance
	next["elapsed"] = elapsed
	next["range"] = float(merged.get("range", next.get("range", _defaults.get("default_range", 0.0))))
	next["lifetime"] = float(merged.get("lifetime", next.get("lifetime", _defaults.get("default_lifetime", 0.0))))
	next["expired"] = false
	next["expire_reason"] = ""
	if float(next.get("range", 0.0)) > 0.0 and distance >= float(next.get("range", 0.0)):
		next["expired"] = true
		next["expire_reason"] = "range"
	elif float(next.get("lifetime", 0.0)) > 0.0 and elapsed >= float(next.get("lifetime", 0.0)):
		next["expired"] = true
		next["expire_reason"] = "lifetime"
	return next

func snapshot(state: Dictionary) -> Dictionary:
	return state.duplicate(true)

func restore(snapshot: Dictionary) -> Dictionary:
	return snapshot.duplicate(true)

func _merged_config(config: Dictionary) -> Dictionary:
	var merged := _defaults.duplicate(true)
	for key in config.keys():
		merged[key] = config[key]
	return merged

func _steered_direction(position: Vector2, direction: Vector2, delta: float, config: Dictionary) -> Vector2:
	if not config.has("target_position"):
		return direction
	var target_direction := (Vector2(config.get("target_position", position)) - position).normalized()
	if target_direction == Vector2.ZERO:
		return direction
	var angular_speed := float(config.get("angular_speed_degrees", 0.0))
	if angular_speed <= 0.0:
		return target_direction
	var max_angle: float = deg_to_rad(angular_speed) * max(0.0, delta)
	var angle := clampf(direction.angle_to(target_direction), -max_angle, max_angle)
	return direction.rotated(angle).normalized()
