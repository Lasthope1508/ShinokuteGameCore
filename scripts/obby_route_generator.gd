class_name CandyObbyRouteGenerator
extends RefCounted

const ShinokuteObbyRouteGenerator3D := preload("res://addons/shinokute_game_core/core/obby_route_generator_3d.gd")
const ROUTE_GENERATOR := ShinokuteObbyRouteGenerator3D.ROUTE_GENERATOR

static func build_stage_segments(profile: Dictionary) -> Array:
	return ShinokuteObbyRouteGenerator3D.build_stage_segments(profile)

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

static func _vector3_from_value(value) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
	return Vector3.ZERO
