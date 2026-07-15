class_name ShinokuteAttackPatternResolver2D
extends RefCounted

func resolve(config: Dictionary) -> Array:
	var count := int(max(0, int(config.get("instances", config.get("count", 1)))))
	if count <= 0:
		return []
	var origin: Vector2 = config.get("origin", Vector2.ZERO)
	var base_direction: Vector2 = Vector2(config.get("direction", Vector2.RIGHT))
	if base_direction.length_squared() <= 0.0001:
		base_direction = Vector2.RIGHT
	base_direction = base_direction.normalized()
	var spawn_offset := float(config.get("spawn_offset", 0.0))
	var vertical_spread := float(config.get("vertical_spread", 0.0))
	var angle_offsets := _angle_offsets(config, count)
	var emissions: Array = []
	for index in range(count):
		var angle_degrees := float(angle_offsets[index])
		var direction := base_direction.rotated(deg_to_rad(angle_degrees)).normalized()
		var lateral := direction.orthogonal()
		var vertical_offset := _vertical_offset(index, count, vertical_spread)
		emissions.append({
			"index": index,
			"angle_degrees": angle_degrees,
			"direction": direction,
			"position": origin + direction * spawn_offset + lateral * vertical_offset
		})
	return emissions

func _angle_offsets(config: Dictionary, count: int) -> Array:
	if config.has("angle_offsets_degrees"):
		var explicit: Array = Array(config.get("angle_offsets_degrees", []))
		if explicit.size() >= count:
			return explicit.slice(0, count)
	var spread := float(config.get("angular_spread", config.get("spread_degrees", 0.0)))
	if count == 1:
		return [0.0]
	var offsets: Array = []
	var step := spread / float(max(1, count - 1))
	var start := -spread * 0.5
	for index in range(count):
		offsets.append(start + step * float(index))
	return offsets

func _vertical_offset(index: int, count: int, vertical_spread: float) -> float:
	if count <= 1 or is_zero_approx(vertical_spread):
		return 0.0
	var step := vertical_spread / float(max(1, count - 1))
	return -vertical_spread * 0.5 + step * float(index)
