class_name CandyObbyRouteGenerator
extends RefCounted

const ROUTE_GENERATOR := "candy_curve_v1"

static func build_stage_segments(profile: Dictionary) -> Array:
	var layout: Dictionary = profile.get("layout_profile", {})
	if String(layout.get("route_generator", "")) != ROUTE_GENERATOR:
		return Array(profile.get("stage_segments", [])).duplicate(true)
	var count: int = max(2, int(layout.get("platform_count", 2)))
	var hazard_count: int = clamp(int(layout.get("hazard_count", 0)), 0, max(0, count - 3))
	var route_length: float = float(layout.get("route_length", 12.0))
	var max_step: float = maxf(1.0, float(layout.get("max_step_distance", 3.6)))
	var max_height: float = maxf(0.1, float(layout.get("max_step_height", 0.55)))
	var verticality: float = maxf(0.0, float(layout.get("verticality", 0.0)))
	var seed: int = int(layout.get("route_seed", 1001))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var step_length: float = route_length / float(maxi(1, count - 1))
	var rise_per_step: float = min(max_height, verticality / float(max(1, count - 1)))
	var route: Array = []
	var hazard_indices: Dictionary = _hazard_indices(count, hazard_count)
	for index in count:
		var t: float = float(index) / float(maxi(1, count - 1))
		var x: float = -step_length * float(index)
		var z: float = sin(t * TAU * 1.25 + float(seed % 29) * 0.11) * float(layout.get("lateral_amplitude", 1.15))
		z += rng.randf_range(-0.12, 0.12)
		var y: float = minf(verticality, rise_per_step * float(index))
		var role := "platform"
		var platform := "small"
		if index == 0:
			role = "start"
			platform = "large"
			z = 0.0
			y = 0.0
		elif index == count - 1:
			role = "goal"
			platform = "large"
			z = 0.0
			y = verticality
		elif hazard_indices.has(index):
			role = "hazard"
			platform = "falling"
		elif index % 3 == 0:
			platform = "medium"
		var segment := {
			"role": role,
			"platform": platform,
			"position": Vector3(x, y, z),
			"rotation_y": rng.randf_range(-12.0, 12.0)
		}
		if role != "start":
			segment["coin"] = true
		if role == "goal":
			segment["goal_offset"] = Vector3(0, 1.2, 0)
		route.append(segment)
	return route

static func build_environment_segments(profile: Dictionary, route: Array) -> Array:
	var layout: Dictionary = profile.get("layout_profile", {})
	if String(layout.get("route_generator", "")) != ROUTE_GENERATOR:
		return Array(profile.get("environment_segments", [])).duplicate(true)
	var result: Array = []
	for index in route.size():
		var segment: Dictionary = route[index]
		var position := _vector3_from_value(segment.get("position", Vector3.ZERO))
		if index % 3 == 1:
			result.append({
				"kind": "cloud",
				"role": "decor",
				"position": position + Vector3(1.5, 1.25, -3.4),
				"scale": Vector3.ONE * (1.05 + 0.08 * float(index % 4))
			})
		if String(segment.get("platform", "")) == "falling":
			result.append({
				"kind": "brick",
				"role": "terrain",
				"position": position + Vector3(0.0, 0.95, 0.85),
				"rotation_y": float(segment.get("rotation_y", 0.0)) + 18.0
			})
	return result

static func _hazard_indices(count: int, hazard_count: int) -> Dictionary:
	var indices: Dictionary = {}
	if hazard_count <= 0:
		return indices
	var usable_start: int = 2
	var usable_end: int = maxi(usable_start, count - 2)
	for hazard in hazard_count:
		var t: float = float(hazard + 1) / float(hazard_count + 1)
		var index: int = clampi(roundi(lerp(float(usable_start), float(usable_end), t)), usable_start, usable_end)
		while indices.has(index) and index < usable_end:
			index += 1
		if not indices.has(index):
			indices[index] = true
	return indices

static func _vector3_from_value(value) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
	return Vector3.ZERO
