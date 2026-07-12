extends SceneTree

const CONFIG_PATH := "res://Resources/Data/Progression/candy_sky_islands_obby_progression.tres"
const GENERATOR_PATH := "res://scripts/obby_route_generator.gd"
const MAIN_SCENE := "res://scenes/main.tscn"
const ALLOWED_ROUTE_STEP := 3.221

var _passed := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var config = load(CONFIG_PATH)
	var generator_script = load(GENERATOR_PATH)
	_assert_true(config != null, "Candy progression config should load")
	_assert_true(generator_script != null, "Candy route generator should load")
	if config == null or generator_script == null:
		_finish()
		return

	_assert_true(config.has_method("get_difficulty_profile_for_level_number"), "Core catalog should expose dynamic level profile lookup")
	if not config.has_method("get_difficulty_profile_for_level_number"):
		_finish()
		return

	var level_4: Dictionary = config.get_difficulty_profile_for_level_number(4, ALLOWED_ROUTE_STEP)
	var level_10: Dictionary = config.get_difficulty_profile_for_level_number(10, ALLOWED_ROUTE_STEP)
	var level_25: Dictionary = config.get_difficulty_profile_for_level_number(25, ALLOWED_ROUTE_STEP)
	var level_100: Dictionary = config.get_difficulty_profile_for_level_number(100, ALLOWED_ROUTE_STEP)
	var level_25_again: Dictionary = config.get_difficulty_profile_for_level_number(25, ALLOWED_ROUTE_STEP)

	_validate_profile(level_4, 4)
	_validate_profile(level_10, 10)
	_validate_profile(level_25, 25)
	_validate_profile(level_100, 100)
	_assert_eq(str(level_25), str(level_25_again), "Dynamic profile should be deterministic for the same level")
	_assert_progression_increases(level_4, level_10, level_25, level_100)
	_assert_routes_are_fair_and_deterministic(generator_script, level_4, level_25, level_100)
	await _assert_level_hud_exists()
	_finish()

func _validate_profile(profile: Dictionary, level_number: int) -> void:
	_assert_eq(int(profile.get("level_number", 0)), level_number, "Profile should record visible level number")
	_assert_true(String(profile.get("display_name", "")).contains(str(level_number)), "Display name should include visible level number")
	_assert_true(String(profile.get("level_id", "")).contains(str(level_number).pad_zeros(3)), "Dynamic level id should include zero-padded level number")
	var layout := Dictionary(profile.get("layout_profile", {}))
	var curve := Dictionary(profile.get("difficulty_curve", {}))
	_assert_true(not layout.is_empty(), "Profile level %s should include layout_profile" % level_number)
	_assert_true(not curve.is_empty(), "Profile level %s should include difficulty_curve" % level_number)
	_assert_true(float(layout.get("gap_distance", 999.0)) <= ALLOWED_ROUTE_STEP, "Level %s gap_distance should stay inside measured jump cap" % level_number)
	_assert_true(int(layout.get("platform_count", 0)) >= 2, "Level %s platform_count should be playable" % level_number)
	_assert_true(Dictionary(layout.get("platform_radii", {})).has("small"), "Level %s should own platform radii in SSOT" % level_number)
	_assert_true(Dictionary(layout.get("route_shape", {})).has("width_overshoot_factor"), "Level %s should own route shape tuning in SSOT" % level_number)
	_assert_true(Array(layout.get("platform_mix", [])).size() > 0, "Level %s should own platform mix in SSOT" % level_number)

func _assert_progression_increases(level_4: Dictionary, level_10: Dictionary, level_25: Dictionary, level_100: Dictionary) -> void:
	var l4 := Dictionary(level_4.get("layout_profile", {}))
	var l10 := Dictionary(level_10.get("layout_profile", {}))
	var l25 := Dictionary(level_25.get("layout_profile", {}))
	var l100 := Dictionary(level_100.get("layout_profile", {}))
	_assert_true(float(l10.get("route_length", 0.0)) > float(l4.get("route_length", 0.0)), "route_length should increase after onboarding")
	_assert_true(float(l25.get("route_length", 0.0)) > float(l10.get("route_length", 0.0)), "route_length should continue increasing")
	_assert_true(float(l100.get("route_length", 0.0)) > float(l25.get("route_length", 0.0)), "route_length should scale deep levels")
	_assert_true(int(l100.get("platform_count", 0)) > int(l4.get("platform_count", 0)), "platform_count should increase for long routes")
	_assert_true(float(l100.get("route_width", 0.0)) > float(l4.get("route_width", 0.0)), "route_width should increase for 3D difficulty")
	_assert_true(float(l100.get("turn_cycles", 0.0)) > float(l4.get("turn_cycles", 0.0)), "turn_cycles should increase route complexity")
	_assert_true(int(l100.get("hazard_count", 0)) > int(l4.get("hazard_count", 0)), "hazard_count should increase")

func _assert_routes_are_fair_and_deterministic(generator_script: Script, level_4: Dictionary, level_25: Dictionary, level_100: Dictionary) -> void:
	for profile in [level_4, level_25, level_100]:
		var first: Array = generator_script.build_stage_segments(profile)
		var second: Array = generator_script.build_stage_segments(profile)
		_assert_eq(str(first), str(second), "Generated route should be deterministic for level %s" % int(profile.get("level_number", 0)))
		_validate_route(profile, first)

func _validate_route(profile: Dictionary, route: Array) -> void:
	var layout := Dictionary(profile.get("layout_profile", {}))
	_assert_eq(route.size(), int(layout.get("platform_count", 0)), "Route platform count should match dynamic layout")
	var min_z := 0.0
	var max_z := 0.0
	var has_descent := false
	var previous_y := 0.0
	for index in route.size():
		var segment := Dictionary(route[index])
		var position := _vector3_from_value(segment.get("position", Vector3.ZERO))
		min_z = minf(min_z, position.z)
		max_z = maxf(max_z, position.z)
		if index > 0 and position.y < previous_y:
			has_descent = true
		previous_y = position.y
	_assert_true(max_z - min_z >= float(layout.get("route_width", 0.0)) - 0.05, "Dynamic route level %s width %.2f should use configured 3D route_width %.2f" % [int(profile.get("level_number", 0)), max_z - min_z, float(layout.get("route_width", 0.0))])
	var goal_pos := _vector3_from_value(Dictionary(route[route.size() - 1]).get("position", Vector3.ZERO))
	_assert_true(absf(goal_pos.y - float(layout.get("verticality", 0.0))) <= 0.01, "Dynamic route goal height should reach configured verticality")
	if float(layout.get("descent_ratio", 0.0)) > 0.0:
		_assert_true(has_descent, "Dynamic route should include fair descent segments when descent_ratio is configured")

func _assert_level_hud_exists() -> void:
	var scene := load(MAIN_SCENE) as PackedScene
	_assert_true(scene != null, "Main scene should load")
	if scene == null:
		return
	var instance := scene.instantiate()
	_disable_audio_autoplay(instance)
	root.add_child(instance)
	await process_frame
	var level_label := instance.get_node_or_null("HUD/Level") as Label
	_assert_true(level_label != null, "HUD should include a visible level label")
	if level_label != null:
		_assert_eq(level_label.text, "LEVEL 1", "HUD level label should show initial level number")
	var progression := instance.get_node_or_null("GameProgression")
	_assert_true(progression != null, "Main scene should include GameProgression")
	if progression != null and level_label != null:
		progression._start_level(1)
		await process_frame
		_assert_eq(level_label.text, "LEVEL 2", "HUD level label should update when level 2 starts")
		progression._start_level(24)
		await process_frame
		_assert_eq(level_label.text, "LEVEL 25", "HUD level label should show dynamic level numbers")
	_stop_audio_streams(instance)
	root.remove_child(instance)
	instance.free()
	await process_frame

func _disable_audio_autoplay(node: Node) -> void:
	if node is AudioStreamPlayer:
		var player := node as AudioStreamPlayer
		player.autoplay = false
		player.stop()
		player.stream = null
	for child in node.get_children():
		_disable_audio_autoplay(child)

func _stop_audio_streams(node: Node) -> void:
	if node is AudioStreamPlayer:
		var player := node as AudioStreamPlayer
		player.stop()
		player.stream = null
	for child in node.get_children():
		_stop_audio_streams(child)

func _vector3_from_value(value) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
	return Vector3.ZERO

func _assert_true(value: bool, message: String) -> void:
	if not value:
		_passed = false
		push_error(message)

func _assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		_passed = false
		push_error("%s: expected %s got %s" % [message, str(expected), str(actual)])

func _finish() -> void:
	if _passed:
		print("test_dynamic_obby_progression_contract: PASS")
		quit(0)
	else:
		print("test_dynamic_obby_progression_contract: FAIL")
		quit(1)
