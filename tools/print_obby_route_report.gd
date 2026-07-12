extends SceneTree

const CONFIG_PATH := "res://Resources/Data/Progression/candy_sky_islands_obby_progression.tres"
const GENERATOR := preload("res://scripts/obby_route_generator.gd")

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
		print("ROUTE level=%s id=%s count=%s max_step=%.2f max_height=%.2f delay=%.2f" % [
			level_index + 1,
			level.level_id,
			route.size(),
			float(layout.get("max_step_distance", 0.0)),
			float(layout.get("max_step_height", 0.0)),
			float(profile.get("falling_platform_trigger_delay", 0.0))
		])
		for step in range(1, route.size()):
			var previous: Dictionary = route[step - 1]
			var current: Dictionary = route[step]
			var from_pos := _vector3_from_value(previous.get("position", Vector3.ZERO))
			var to_pos := _vector3_from_value(current.get("position", Vector3.ZERO))
			var horizontal := Vector2(to_pos.x - from_pos.x, to_pos.z - from_pos.z).length()
			var vertical := to_pos.y - from_pos.y
			print("  step=%02d platform=%s role=%s horizontal=%.2f vertical=%.2f to=%s" % [
				step,
				String(current.get("platform", "")),
				String(current.get("role", "")),
				horizontal,
				vertical,
				str(to_pos)
			])
	quit(0)

func _vector3_from_value(value) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
	return Vector3.ZERO
