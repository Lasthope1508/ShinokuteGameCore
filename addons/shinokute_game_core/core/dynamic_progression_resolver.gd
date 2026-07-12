class_name ShinokuteDynamicProgressionResolver
extends RefCounted

static func build_level(catalog, level_number: int, measured_jump_cap: float = 0.0) -> Resource:
	var profile := resolve_profile(catalog, level_number, measured_jump_cap)
	var level := ShinokuteProgressionLevel.new()
	level.level_id = String(profile.get("level_id", ""))
	level.display_name = String(profile.get("display_name", ""))
	level.difficulty_tier = int(profile.get("difficulty_tier", level_number))
	level.completion_condition = Dictionary(profile.get("completion_condition", {})).duplicate(true)
	level.failure_policy = Dictionary(profile.get("failure_policy", {})).duplicate(true)
	level.layout_profile = Dictionary(profile.get("layout_profile", {})).duplicate(true)
	level.stage_segments = Array(profile.get("stage_segments", [])).duplicate(true)
	level.environment_segments = Array(profile.get("environment_segments", [])).duplicate(true)
	level.difficulty_curve = Dictionary(profile.get("difficulty_curve", {})).duplicate(true)
	level.next_level_id = String(profile.get("next_level_id", ""))
	return level

static func resolve_profile(catalog, level_number: int, measured_jump_cap: float = 0.0) -> Dictionary:
	var dynamic: Dictionary = catalog.dynamic_progression_profile
	var authored_count: int = catalog.level_catalog.size()
	var template_index := clampi(int(dynamic.get("template_level_index", authored_count - 1)), 0, maxi(0, authored_count - 1))
	var template: Resource = catalog.get_authored_level(template_index)
	var profile: Dictionary = catalog.get_authored_difficulty_profile(template_index) if template != null else {}
	var start_level := maxi(1, int(dynamic.get("start_level_number", authored_count + 1)))
	var n := max(0, level_number - start_level)

	profile["level_number"] = level_number
	profile["level_id"] = _format_string(String(dynamic.get("level_id_format", "level_%03d")), level_number)
	profile["display_name"] = _format_string(String(dynamic.get("display_name_format", "Level %d")), level_number)
	profile["difficulty_tier"] = level_number
	profile["next_level_id"] = ""

	var layout := Dictionary(profile.get("layout_profile", {})).duplicate(true)
	var difficulty := Dictionary(profile.get("difficulty_curve", {})).duplicate(true)
	_apply_curves(layout, Dictionary(dynamic.get("layout_curves", {})), n, measured_jump_cap)
	_apply_curves(difficulty, Dictionary(dynamic.get("difficulty_curves", {})), n, measured_jump_cap)
	for key in ["layout_defaults", "route_shape", "platform_radii"]:
		if dynamic.has(key):
			var value = dynamic[key]
			if value is Dictionary:
				if key == "layout_defaults":
					_merge_missing(layout, Dictionary(value))
				else:
					layout[key] = Dictionary(value).duplicate(true)
	if dynamic.has("platform_mix"):
		layout["platform_mix"] = Array(dynamic.get("platform_mix", [])).duplicate(true)
	if dynamic.has("route_shape"):
		layout["route_shape"] = Dictionary(dynamic.get("route_shape", {})).duplicate(true)
	if dynamic.has("platform_radii"):
		layout["platform_radii"] = Dictionary(dynamic.get("platform_radii", {})).duplicate(true)

	var seed_base := int(dynamic.get("seed_base", 9000))
	var seed_stride := int(dynamic.get("seed_stride", 97))
	layout["route_seed"] = seed_base + level_number * seed_stride
	layout["route_generator"] = String(layout.get("route_generator", dynamic.get("route_generator", "shinokute_3d_obby_curve_v1")))
	layout["hazard_count"] = clampi(int(layout.get("hazard_count", 0)), 0, max(0, int(layout.get("platform_count", 2)) - 3))
	profile["layout_profile"] = layout
	profile["difficulty_curve"] = difficulty
	for key in difficulty.keys():
		profile[key] = difficulty[key]
	return profile

static func _apply_curves(target: Dictionary, curves: Dictionary, n: int, measured_jump_cap: float) -> void:
	for key in curves.keys():
		target[key] = _evaluate_curve(Dictionary(curves[key]), n, measured_jump_cap, String(key))

static func _evaluate_curve(spec: Dictionary, n: int, measured_jump_cap: float, key: String):
	var mode := String(spec.get("mode", "linear")).to_lower()
	var base := float(spec.get("base", 0.0))
	var per_level := float(spec.get("per_level", 0.0))
	var value := base
	if mode == "sqrt":
		value = base + per_level * sqrt(float(n))
	elif mode == "log":
		value = base + per_level * log(float(n) + 1.0)
	elif mode == "density":
		value = base
	else:
		value = base + per_level * float(n)
	if spec.has("add"):
		value += float(spec.get("add", 0.0))
	if spec.has("min"):
		value = maxf(value, float(spec.get("min", value)))
	if spec.has("max"):
		value = minf(value, float(spec.get("max", value)))
	if bool(spec.get("max_from_jump_cap", false)) and measured_jump_cap > 0.0:
		value = minf(value, measured_jump_cap - float(spec.get("jump_cap_margin", 0.0)))
	if key == "gap_distance" and measured_jump_cap > 0.0:
		value = minf(value, measured_jump_cap)
	var round_mode := String(spec.get("round", "")).to_lower()
	if round_mode == "ceil":
		return int(ceili(value))
	if round_mode == "floor":
		return int(floori(value))
	if round_mode == "round":
		return int(roundi(value))
	if round_mode == "int":
		return int(value)
	return value

static func _merge_missing(target: Dictionary, defaults: Dictionary) -> void:
	for key in defaults.keys():
		if not target.has(key):
			var value = defaults[key]
			target[key] = value.duplicate(true) if value is Dictionary or value is Array else value

static func _format_string(format: String, level_number: int) -> String:
	if format.contains("%03d"):
		return format % level_number
	if format.contains("%d"):
		return format % level_number
	if format.contains("%s"):
		return format % str(level_number)
	return "%s %s" % [format, level_number]
