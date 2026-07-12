extends SceneTree

const CONFIG_PATH := "res://Resources/Data/Progression/candy_sky_islands_obby_progression.tres"
const GENERATOR_PATH := "res://scripts/obby_route_generator.gd"
const PLAYER_SCENE := "res://objects/player.tscn"
const JUMP_DISTANCE_SAFETY_FACTOR := 0.80
const PLATFORM_RADIUS_BY_KIND := {
	"small": 1.0,
	"falling": 1.1,
	"medium": 1.5,
	"large": 2.5
}

var _passed := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var config = load(CONFIG_PATH)
	_assert_true(config != null, "Progression config should load")
	_assert_true(ResourceLoader.exists(GENERATOR_PATH), "Candy route generator should exist")
	var generator_script = load(GENERATOR_PATH) if ResourceLoader.exists(GENERATOR_PATH) else null
	_assert_true(generator_script != null, "Candy route generator script should load")
	var measured_jump_distance := await _measure_player_double_jump_distance()
	var allowed_step_distance := measured_jump_distance * JUMP_DISTANCE_SAFETY_FACTOR
	_assert_true(measured_jump_distance > 0.0, "Player measured max jump distance should be greater than zero")
	print("CANDY_SOLVABILITY_JUMP measured_max_horizontal=%.3f allowed_route_step=%.3f safety_factor=%.2f" % [measured_jump_distance, allowed_step_distance, JUMP_DISTANCE_SAFETY_FACTOR])
	if config != null and generator_script != null:
		for index in config.level_catalog.size():
			_validate_level(config.level_catalog[index], generator_script, index, allowed_step_distance)
	if _passed:
		print("test_obby_route_solvability_contract: PASS")
		quit(0)
	else:
		print("test_obby_route_solvability_contract: FAIL")
		quit(1)

func _measure_player_double_jump_distance() -> float:
	_disable_test_audio_events()
	var world := Node3D.new()
	world.name = "JumpEnvelopeWorld"
	root.add_child(world)

	var floor := StaticBody3D.new()
	floor.name = "FlatFloor"
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 0.1, 200)
	floor_shape.shape = box
	floor.add_child(floor_shape)
	floor.position.y = -0.05
	world.add_child(floor)

	var view := Node3D.new()
	view.name = "View"
	view.rotation.y = PI / 2.0
	world.add_child(view)

	var player_scene := load(PLAYER_SCENE) as PackedScene
	_assert_true(player_scene != null, "Player scene should load for jump measurement")
	if player_scene == null:
		_cleanup_world(world)
		return 0.0
	var player = player_scene.instantiate()
	player.name = "Player"
	player.view = view
	player.position = Vector3(0, 1.2, 0)
	_release_audio_streams(player)
	world.add_child(player)

	for _i in range(60):
		await physics_frame
		if player.is_on_floor():
			break

	Input.action_press("move_forward")
	for _i in range(30):
		await physics_frame
	var takeoff_x: float = player.global_position.x
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")

	for _i in range(16):
		await physics_frame
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")

	var airborne_seen := false
	var landing_x: float = player.global_position.x
	for _i in range(240):
		await physics_frame
		if not player.is_on_floor():
			airborne_seen = true
		elif airborne_seen:
			landing_x = player.global_position.x
			break
	Input.action_release("move_forward")

	var measured_distance := absf(landing_x - takeoff_x)
	_cleanup_world(world)
	await process_frame
	return measured_distance

func _disable_test_audio_events() -> void:
	var audio := root.get_node_or_null("Audio")
	if audio != null and audio.has_method("set_sfx_enabled"):
		audio.set_sfx_enabled(false)

func _cleanup_world(world: Node) -> void:
	_release_audio_streams(world)
	if world.get_parent() != null:
		world.get_parent().remove_child(world)
	world.free()

func _release_audio_streams(node: Node) -> void:
	if node is AudioStreamPlayer:
		node.stop()
		node.stream = null
	for child in node.get_children():
		_release_audio_streams(child)

func _validate_level(level: Resource, generator_script: Script, index: int, allowed_step_distance: float) -> void:
	_assert_true(level != null, "Level %s should exist" % index)
	if level == null:
		return
	var layout: Dictionary = level.layout_profile
	_assert_true(String(layout.get("route_generator", "")) == "candy_curve_v1", "Level %s should use generated Candy route" % index)
	_assert_true(level.stage_segments.size() <= 2, "Level %s should keep only start/goal anchors, not fixed terrain" % index)
	var profile: Dictionary = level.difficulty_profile()
	var route: Array = generator_script.build_stage_segments(profile)
	_assert_eq(route.size(), int(layout.get("platform_count", 0)), "Level %s generated platform count should match layout_profile" % index)
	_assert_true(route.size() >= 2, "Level %s generated route should include start and goal" % index)
	if route.size() < 2:
		return
	_assert_eq(String(route[0].get("role", "")), "start", "Level %s first segment should be start" % index)
	_assert_eq(String(route[route.size() - 1].get("role", "")), "goal", "Level %s final segment should be goal" % index)
	var route_length := float(layout.get("route_length", 0.0))
	var start_pos := _vector3_from_value(route[0].get("position", Vector3.ZERO))
	var goal_pos := _vector3_from_value(route[route.size() - 1].get("position", Vector3.ZERO))
	var generated_span := Vector2(goal_pos.x - start_pos.x, goal_pos.z - start_pos.z).length()
	_assert_true(generated_span > 0.0, "Level %s generated start-to-goal span should be positive" % index)
	var max_step := float(layout.get("max_step_distance", allowed_step_distance))
	var step_limit := minf(allowed_step_distance, max_step)
	var max_height := float(layout.get("max_step_height", 0.55))
	var gap_distance := float(layout.get("gap_distance", 0.0))
	var route_width := float(layout.get("route_width", 0.0))
	var hazard_count := 0
	var cumulative_clear_gap := 0.0
	var min_z := start_pos.z
	var max_z := start_pos.z
	for segment_index in range(1, route.size()):
		var previous: Dictionary = route[segment_index - 1]
		var current: Dictionary = route[segment_index]
		var previous_pos := _vector3_from_value(previous.get("position", Vector3.ZERO))
		var current_pos := _vector3_from_value(current.get("position", Vector3.ZERO))
		var horizontal := Vector2(current_pos.x - previous_pos.x, current_pos.z - previous_pos.z).length()
		var vertical := absf(current_pos.y - previous_pos.y)
		var previous_radius := _platform_radius(String(previous.get("platform", "small")))
		var current_radius := _platform_radius(String(current.get("platform", "small")))
		var clear_gap: float = maxf(0.0, horizontal - previous_radius - current_radius)
		cumulative_clear_gap += clear_gap
		min_z = minf(min_z, current_pos.z)
		max_z = maxf(max_z, current_pos.z)
		_assert_true(clear_gap >= gap_distance - 0.05, "Level %s step %s clear landing gap %.2f should use layout gap_distance %.2f instead of crowding platform centers" % [index, segment_index, clear_gap, gap_distance])
		_assert_true(clear_gap <= step_limit + 0.01, "Level %s step %s clear landing gap %.2f should be <= min(measured jump cap %.2f, max_step_distance %.2f)" % [index, segment_index, clear_gap, allowed_step_distance, max_step])
		_assert_true(vertical <= max_height + 0.01, "Level %s step %s vertical %.2f should be <= %.2f" % [index, segment_index, vertical, max_height])
		if String(current.get("platform", "")) == "falling":
			hazard_count += 1
			_assert_true(segment_index < route.size() - 1, "Level %s falling hazard should not be final goal step" % index)
	var lateral_span := max_z - min_z
	_assert_true(cumulative_clear_gap >= route_length - 0.05, "Level %s cumulative clear route %.2f should honor route_length %.2f" % [index, cumulative_clear_gap, route_length])
	_assert_true(lateral_span >= route_width - 0.05, "Level %s lateral route width %.2f should honor route_width %.2f so 3D obby is not a one-axis line" % [index, lateral_span, route_width])
	var expected_hazards := int(layout.get("hazard_count", 0))
	_assert_eq(hazard_count, expected_hazards, "Level %s generated hazard count should match layout_profile" % index)
	var trigger_delay := float(profile.get("falling_platform_trigger_delay", 0.0))
	_assert_true(trigger_delay >= 0.20, "Level %s falling platforms need at least 0.20s delay for jump recovery" % index)

func _platform_radius(kind: String) -> float:
	return float(PLATFORM_RADIUS_BY_KIND.get(kind, PLATFORM_RADIUS_BY_KIND["small"]))

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
