class_name ShinokuteTargetingQuery2D
extends RefCounted

func nearest(origin: Vector2, candidates: Array, options: Dictionary = {}) -> Dictionary:
	var max_distance := float(options.get("max_distance", INF))
	var best: Dictionary = {}
	var best_distance := INF
	for item in candidates:
		if not (item is Dictionary):
			continue
		var candidate := Dictionary(item)
		var position := Vector2(candidate.get("position", origin))
		var distance := origin.distance_to(position)
		if distance > max_distance:
			continue
		if distance < best_distance:
			best_distance = distance
			best = candidate.duplicate(true)
			best["distance"] = distance
	return best

func within_radius(origin: Vector2, candidates: Array, radius: float, options: Dictionary = {}) -> Array:
	var include_candidate_radius := bool(options.get("include_candidate_radius", true))
	var results: Array = []
	for item in candidates:
		if not (item is Dictionary):
			continue
		var candidate := Dictionary(item)
		var position := Vector2(candidate.get("position", origin))
		var candidate_radius := float(candidate.get("radius", 0.0)) if include_candidate_radius else 0.0
		var distance := origin.distance_to(position)
		if distance <= radius + candidate_radius:
			var packed := candidate.duplicate(true)
			packed["distance"] = distance
			results.append(packed)
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("distance", 0.0)) < float(b.get("distance", 0.0))
	)
	return results

func within_cone(origin: Vector2, direction: Vector2, candidates: Array, options: Dictionary = {}) -> Array:
	var range := float(options.get("range", INF))
	var angle_degrees := float(options.get("angle_degrees", 360.0))
	var base_direction := direction.normalized()
	if base_direction == Vector2.ZERO:
		base_direction = Vector2.RIGHT
	var half_angle := deg_to_rad(angle_degrees * 0.5)
	var results: Array = []
	for item in candidates:
		if not (item is Dictionary):
			continue
		var candidate := Dictionary(item)
		var position := Vector2(candidate.get("position", origin))
		var offset := position - origin
		var distance := offset.length()
		if distance > range or distance <= 0.0:
			continue
		var angle := abs(base_direction.angle_to(offset.normalized()))
		if angle <= half_angle:
			var packed := candidate.duplicate(true)
			packed["distance"] = distance
			packed["angle"] = rad_to_deg(angle)
			results.append(packed)
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("distance", 0.0)) < float(b.get("distance", 0.0))
	)
	return results

func segment_hits(start: Vector2, end: Vector2, candidates: Array, options: Dictionary = {}) -> Array:
	var hit_radius := float(options.get("hit_radius", 0.0))
	var include_candidate_radius := bool(options.get("include_candidate_radius", true))
	var segment := end - start
	var length_squared := segment.length_squared()
	var results: Array = []
	if length_squared <= 0.0:
		return results
	for item in candidates:
		if not (item is Dictionary):
			continue
		var candidate := Dictionary(item)
		var position := Vector2(candidate.get("position", start))
		var projection := clamp((position - start).dot(segment) / length_squared, 0.0, 1.0)
		var closest: Vector2 = start + segment * projection
		var distance_to_segment := position.distance_to(closest)
		var candidate_radius := float(candidate.get("radius", 0.0)) if include_candidate_radius else 0.0
		if distance_to_segment <= hit_radius + candidate_radius:
			var packed := candidate.duplicate(true)
			packed["segment_t"] = projection
			packed["segment_distance"] = distance_to_segment
			packed["travel_distance"] = start.distance_to(closest)
			results.append(packed)
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("segment_t", 0.0)) < float(b.get("segment_t", 0.0))
	)
	return results
