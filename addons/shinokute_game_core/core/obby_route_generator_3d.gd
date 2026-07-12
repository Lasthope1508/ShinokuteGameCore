class_name ShinokuteObbyRouteGenerator3D
extends RefCounted

const ROUTE_GENERATOR := "shinokute_3d_obby_curve_v1"
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
	var hazard_count: int = clampi(int(layout.get("hazard_count", 0)), 0, max(0, count - 3))
	var route_length: float = float(layout.get("route_length", 12.0))
	var max_step: float = maxf(1.0, float(layout.get("max_step_distance", 3.6)))
	var max_height: float = maxf(0.1, float(layout.get("max_step_height", 0.55)))
	var verticality: float = maxf(0.0, float(layout.get("verticality", 0.0)))
	var minimum_gap_from_route_length := route_length / float(maxi(1, count - 1))
	var requested_gap := maxf(float(layout.get("gap_distance", max_step * 0.8)), minimum_gap_from_route_length)
	var gap_distance: float = minf(max_step, maxf(0.5, requested_gap))
	var route_width: float = maxf(0.0, float(layout.get("route_width", float(layout.get("lateral_amplitude", 1.0)) * 3.0)))
	var turn_cycles: float = maxf(0.5, float(layout.get("turn_cycles", 1.0 + float(hazard_count) * 0.25)))
	var platform_radii := _platform_radii(layout)
	var route_shape := Dictionary(layout.get("route_shape", {}))
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
		else:
			platform = _platform_for_index(index, layout, rng)
		var position := Vector3.ZERO
		if index == 0:
			position = Vector3.ZERO
		else:
			position = _next_position(
				previous_position,
				previous_platform,
				platform,
				platform_radii,
				route_shape,
				layout,
				gap_distance,
				route_width,
				turn_cycles,
				t,
				rise_per_step,
				max_height,
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
	platform_radii: Dictionary,
	route_shape: Dictionary,
	layout: Dictionary,
	gap_distance: float,
	route_width: float,
	turn_cycles: float,
	t: float,
	rise_per_step: float,
	max_height: float,
	verticality: float,
	index: int,
	count: int,
	rng: RandomNumberGenerator
) -> Vector3:
	var previous_radius := _platform_radius(previous_platform, platform_radii)
	var current_radius := _platform_radius(current_platform, platform_radii)
	var center_distance := previous_radius + current_radius + gap_distance
	var target_half_width := route_width * float(route_shape.get("width_overshoot_factor", 0.55))
	var desired_z := sin(t * TAU * turn_cycles) * target_half_width
	var position_jitter := float(route_shape.get("position_jitter", 0.18))
	if index > 1 and index < count - 1:
		desired_z += rng.randf_range(-position_jitter, position_jitter)
	var max_lateral_delta := center_distance * float(route_shape.get("max_lateral_step_ratio", 0.72))
	var next_z := clampf(desired_z, previous_position.z - max_lateral_delta, previous_position.z + max_lateral_delta)
	var dz := next_z - previous_position.z
	var dx := -sqrt(maxf(0.01, center_distance * center_distance - dz * dz))
	var next_y := _next_height(previous_position.y, layout, t, rise_per_step, max_height, verticality, index, count)
	return Vector3(previous_position.x + dx, next_y, next_z)

static func _next_height(
	previous_y: float,
	layout: Dictionary,
	t: float,
	rise_per_step: float,
	max_height: float,
	verticality: float,
	index: int,
	count: int
) -> float:
	var desired_y := verticality if index == count - 1 else minf(verticality, rise_per_step * float(index))
	var wave_amplitude := float(layout.get("height_wave_amplitude", 0.0))
	var wave_cycles := maxf(0.0, float(layout.get("height_wave_cycles", 0.0)))
	if index > 0 and index < count - 1 and wave_amplitude > 0.0 and wave_cycles > 0.0:
		desired_y += sin(t * TAU * wave_cycles) * wave_amplitude
	var descent_ratio := maxf(0.0, float(layout.get("descent_ratio", 0.0)))
	if descent_ratio > 0.0 and index > 2 and index < count - 2:
		var descent_interval := maxi(4, roundi(1.0 / descent_ratio))
		if index % descent_interval == 0:
			desired_y = previous_y - max_height * 0.75
	desired_y = clampf(desired_y, 0.0, verticality)
	var remaining_after := maxi(0, count - 1 - index)
	var minimum_to_reach_goal := verticality - max_height * float(remaining_after)
	desired_y = maxf(desired_y, minimum_to_reach_goal)
	return clampf(desired_y, previous_y - max_height, previous_y + max_height)

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

static func _platform_for_index(index: int, layout: Dictionary, rng: RandomNumberGenerator) -> String:
	var route_shape := Dictionary(layout.get("route_shape", {}))
	var recovery_interval := int(route_shape.get("recovery_interval", 0))
	if recovery_interval > 0 and index % recovery_interval == 0:
		return "medium"
	var mix := Array(layout.get("platform_mix", []))
	if mix.is_empty():
		return "medium" if index % 3 == 0 else "small"
	var total_weight := 0.0
	for entry in mix:
		total_weight += maxf(0.0, float(Dictionary(entry).get("weight", 0.0)))
	if total_weight <= 0.0:
		return "small"
	var pick := rng.randf_range(0.0, total_weight)
	var cursor := 0.0
	for entry in mix:
		var item := Dictionary(entry)
		cursor += maxf(0.0, float(item.get("weight", 0.0)))
		if pick <= cursor:
			return String(item.get("platform", "small"))
	return String(Dictionary(mix.back()).get("platform", "small"))

static func _platform_radii(layout: Dictionary) -> Dictionary:
	var radii := PLATFORM_RADIUS_BY_KIND.duplicate(true)
	var configured := Dictionary(layout.get("platform_radii", {}))
	for key in configured.keys():
		radii[String(key)] = float(configured[key])
	return radii

static func _platform_radius(kind: String, platform_radii: Dictionary) -> float:
	return float(platform_radii.get(kind, platform_radii.get("small", PLATFORM_RADIUS_BY_KIND["small"])))
