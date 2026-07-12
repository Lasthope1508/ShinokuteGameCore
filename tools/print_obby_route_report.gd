extends SceneTree

const CONFIG_PATH := "res://Resources/Data/Progression/candy_sky_islands_obby_progression.tres"
const GENERATOR := preload("res://scripts/obby_route_generator.gd")
const PLATFORM_RADIUS_BY_KIND := {
	"small": 1.0,
	"falling": 1.1,
	"medium": 1.5,
	"large": 2.5
}

func _init() -> void:
	var config = load(CONFIG_PATH)
	if config == null:
		push_error("Missing progression config")
		quit(1)
		return
	for level_index in config.level_catalog.size():
		var level = config.level_catalog[level_index]
		var profile: Dictionary = level.difficulty_profile()
		var layout: Dictionary = level.layout_profile
		var route: Array = GENERATOR.build_stage_segments(profile)
		_print_route(level_index + 1, level.level_id, profile, layout, route)
	if config.has_method("get_difficulty_profile_for_level_number"):
		for level_number in [4, 10, 25, 100]:
			var profile: Dictionary = config.get_difficulty_profile_for_level_number(level_number, 3.221)
			var layout: Dictionary = profile.get("layout_profile", {})
			var route: Array = GENERATOR.build_stage_segments(profile)
			_print_route(level_number, String(profile.get("level_id", "")), profile, layout, route)
	quit(0)

func _print_route(level_number: int, level_id: String, profile: Dictionary, layout: Dictionary, route: Array) -> void:
	var z_span := _z_span(route)
	print("ROUTE level=%s id=%s count=%s gap=%.2f width=%.2f z_span=%.2f max_step=%.2f max_height=%.2f delay=%.2f seed=%s" % [
		level_number,
		level_id,
		route.size(),
		float(layout.get("gap_distance", 0.0)),
		float(layout.get("route_width", 0.0)),
		z_span,
		float(layout.get("max_step_distance", 0.0)),
		float(layout.get("max_step_height", 0.0)),
		float(profile.get("falling_platform_trigger_delay", 0.0)),
		str(layout.get("route_seed", ""))
	])
	if route.size() > 32:
		return
	for step in range(1, route.size()):
		var previous: Dictionary = route[step - 1]
		var current: Dictionary = route[step]
		var from_pos := _vector3_from_value(previous.get("position", Vector3.ZERO))
		var to_pos := _vector3_from_value(current.get("position", Vector3.ZERO))
		var horizontal := Vector2(to_pos.x - from_pos.x, to_pos.z - from_pos.z).length()
		var clear_gap: float = maxf(0.0, horizontal - _platform_radius(String(previous.get("platform", "small")), layout) - _platform_radius(String(current.get("platform", "small")), layout))
		var vertical := to_pos.y - from_pos.y
		print("  step=%02d platform=%s role=%s center=%.2f clear_gap=%.2f vertical=%.2f to=%s" % [
			step,
			String(current.get("platform", "")),
			String(current.get("role", "")),
			horizontal,
			clear_gap,
			vertical,
			str(to_pos)
		])

func _vector3_from_value(value) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
	return Vector3.ZERO

func _platform_radius(kind: String, layout: Dictionary) -> float:
	var radii := PLATFORM_RADIUS_BY_KIND.duplicate(true)
	var configured := Dictionary(layout.get("platform_radii", {}))
	for key in configured.keys():
		radii[String(key)] = float(configured[key])
	return float(radii.get(kind, radii["small"]))

func _z_span(route: Array) -> float:
	if route.is_empty():
		return 0.0
	var first_pos := _vector3_from_value(Dictionary(route[0]).get("position", Vector3.ZERO))
	var min_z := first_pos.z
	var max_z := first_pos.z
	for segment in route:
		var position := _vector3_from_value(Dictionary(segment).get("position", Vector3.ZERO))
		min_z = minf(min_z, position.z)
		max_z = maxf(max_z, position.z)
	return max_z - min_z
