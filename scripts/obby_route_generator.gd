class_name CandyObbyRouteGenerator
extends RefCounted

const ROUTE_GENERATOR := "candy_curve_v1"
const PLATFORM_RADIUS_BY_KIND := {
	"small": 1.0,
	"falling": 1.1,
	"medium": 1.5,
	"large": 2.5
}

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
	var gap_distance: float = minf(max_step, maxf(0.5, float(layout.get("gap_distance", max_step * 0.8))))
	var route_width: float = maxf(0.0, float(layout.get("route_width", float(layout.get("lateral_amplitude", 1.0)) * 3.0)))
	var turn_cycles: float = maxf(0.5, float(layout.get("turn_cycles", 1.0 + float(hazard_count) * 0.25)))
	var seed: int = int(layout.get("route_seed", 1001))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var rise_per_step: float = min(max_height, verticality / float(max(1, count - 1)))
	var route: Array = []
	var hazard_indices: Dictionary = _hazard_indices(count, hazard_count)
	var previous_position := Vector3.ZERO
	var previous_platform := "large"
	for index in count:
		var t: float = float(index) / float(maxi(1, count - 1))
		var role := "platform"
		var platform := "small"
		if index == 0:
			role = "start"
			platform = "large"
		elif index == count - 1:
			role = "goal"
			platform = "large"
		elif hazard_indices.has(index):
			role = "hazard"
			platform = "falling"
		elif index % 3 == 0:
			platform = "medium"
		var position := Vector3.ZERO
		if index == 0:
			position = Vector3.ZERO
		else:
			position = _next_position(
				previous_position,
				previous_platform,
				platform,
				gap_distance,
				route_width,
				turn_cycles,
				t,
				rise_per_step,
				verticality,
				index,
				count,
				rng
			)
		var segment := {
			"role": role,
			"platform": platform,
			"position": position,
			"rotation_y": rng.randf_range(-12.0, 12.0)
		}
		if role != "start":
			segment["coin"] = true
		if role == "goal":
			segment["goal_offset"] = Vector3(0, 1.2, 0)
		route.append(segment)
		previous_position = position
		previous_platform = platform
	return route

static func _next_position(
	previous_position: Vector3,
	previous_platform: String,
	current_platform: String,
	gap_distance: float,
	route_width: float,
	turn_cycles: float,
	t: float,
	rise_per_step: float,
	verticality: float,
	index: int,
	count: int,
	rng: RandomNumberGenerator
) -> Vector3:
	var previous_radius := _platform_radius(previous_platform)
	var current_radius := _platform_radius(current_platform)
	var center_distance := previous_radius + current_radius + gap_distance
	var target_half_width := route_width * 0.55
	var desired_z := sin(t * TAU * turn_cycles) * target_half_width
	if index > 1 and index < count - 1:
		desired_z += rng.randf_range(-0.18, 0.18)
	var max_lateral_delta := center_distance * 0.72
	var next_z := clampf(desired_z, previous_position.z - max_lateral_delta, previous_position.z + max_lateral_delta)
	var dz := next_z - previous_position.z
	var dx := -sqrt(maxf(0.01, center_distance * center_distance - dz * dz))
	var next_y := verticality if index == count - 1 else minf(verticality, rise_per_step * float(index))
	return Vector3(previous_position.x + dx, next_y, next_z)

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

static func _platform_radius(kind: String) -> float:
	return float(PLATFORM_RADIUS_BY_KIND.get(kind, PLATFORM_RADIUS_BY_KIND["small"]))

static func _vector3_from_value(value) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
	return Vector3.ZERO
