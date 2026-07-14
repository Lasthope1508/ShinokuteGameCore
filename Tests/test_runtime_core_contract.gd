extends SceneTree

const PauseControllerScript := preload("res://addons/shinokute_game_core/runtime/pause_controller.gd")
const InputBindingManagerScript := preload("res://addons/shinokute_game_core/runtime/input_binding_manager.gd")
const SpawnPoolScript := preload("res://addons/shinokute_game_core/runtime/spawn_pool.gd")
const InteractionBusScript := preload("res://addons/shinokute_game_core/runtime/interaction_bus.gd")
const ScenePreloadCacheScript := preload("res://addons/shinokute_game_core/runtime/scene_preload_cache.gd")
const ResourceRegistryPath := "res://addons/shinokute_game_core/runtime/resource_registry.gd"
const WeightedPickerPath := "res://addons/shinokute_game_core/runtime/weighted_picker.gd"
const DefinitionResolverPath := "res://addons/shinokute_game_core/runtime/definition_resolver.gd"
const RunContextPath := "res://addons/shinokute_game_core/runtime/run_context.gd"
const LimitedCounterPath := "res://addons/shinokute_game_core/runtime/limited_counter.gd"
const InputVectorFilterPath := "res://addons/shinokute_game_core/runtime/input_vector_filter_2d.gd"
const KinematicMotionSolverPath := "res://addons/shinokute_game_core/runtime/kinematic_motion_solver_2d.gd"
const SteeringPath := "res://addons/shinokute_game_core/runtime/steering_2d.gd"

var _passed := true
var _pause_events: Array = []
var _interaction_events: Array = []
var _received_payloads: Array = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_pause_controller()
	_test_input_binding_manager()
	_test_spawn_pool()
	_test_interaction_bus()
	_test_scene_preload_cache()
	_test_resource_registry()
	_test_weighted_picker()
	_test_definition_resolver()
	_test_run_context()
	_test_limited_counter()
	_test_input_vector_filter()
	_test_kinematic_motion_solver()
	_test_steering()
	_report("test_runtime_core_contract")

func _test_pause_controller() -> void:
	var pause = PauseControllerScript.new()
	root.add_child(pause)
	pause.paused_changed.connect(func(value: bool): _pause_events.append(value))
	var gameplay_node := Node.new()
	var menu_node := Node.new()
	root.add_child(gameplay_node)
	root.add_child(menu_node)
	pause.configure_process_sets([gameplay_node], [menu_node], Node.PROCESS_MODE_DISABLED, Node.PROCESS_MODE_ALWAYS)
	pause.set_paused(true)
	_assert_true(pause.is_paused(), "pause state should be true")
	_assert_eq(_pause_events[0], true, "pause signal value")
	_assert_eq(gameplay_node.process_mode, Node.PROCESS_MODE_DISABLED, "gameplay nodes stop during pause")
	_assert_eq(menu_node.process_mode, Node.PROCESS_MODE_ALWAYS, "menu nodes process during pause")
	pause.toggle_paused()
	_assert_true(not pause.is_paused(), "toggle unpauses")
	gameplay_node.free()
	menu_node.free()
	pause.free()

func _test_input_binding_manager() -> void:
	var action := "shinokute_test_jump"
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	var manager = InputBindingManagerScript.new()
	root.add_child(manager)
	manager.configure({action: [{"type": "key", "keycode": KEY_SPACE}]})
	manager.apply_bindings()
	_assert_true(InputMap.has_action(action), "binding manager creates configured action")
	_assert_eq(InputMap.action_get_events(action).size(), 1, "default action has one event")
	var event := InputEventKey.new()
	event.keycode = KEY_J
	manager.rebind_action_to_event(action, event)
	var serialized := manager.serialize_bindings()
	_assert_eq(int(serialized[action][0]["keycode"]), KEY_J, "serialized keycode follows rebind")
	_assert_eq(int(InputMap.action_get_events(action)[0].keycode), KEY_J, "InputMap event follows rebind")
	InputMap.erase_action(action)
	manager.free()

func _test_spawn_pool() -> void:
	var parent := Node.new()
	root.add_child(parent)
	var template := Node.new()
	template.name = "PooledThing"
	var packed := PackedScene.new()
	_assert_eq(packed.pack(template), OK, "packed scene created")
	template.free()
	var pool = SpawnPoolScript.new()
	root.add_child(pool)
	pool.configure(packed, parent)
	var first: Node = pool.spawn()
	_assert_eq(parent.get_child_count(), 1, "spawn adds child")
	pool.return_instance(first)
	_assert_eq(parent.get_child_count(), 0, "return removes child")
	var second: Node = pool.spawn()
	_assert_true(first == second, "pool reuses returned node")
	pool.return_instance(second)
	pool.free()
	parent.free()

func _test_interaction_bus() -> void:
	var bus = InteractionBusScript.new()
	root.add_child(bus)
	bus.interaction_published.connect(func(channel: String, payload: Dictionary): _interaction_events.append({"channel": channel, "payload": payload}))
	bus.subscribe("damage", func(payload: Dictionary): _received_payloads.append(payload))
	bus.publish("damage", {"amount": 3, "source": "test"})
	bus.publish("pickup", {"id": "coin"})
	_assert_eq(_interaction_events.size(), 2, "bus emits all published interactions")
	_assert_eq(_received_payloads.size(), 1, "subscriber receives matching channel only")
	_assert_eq(int(_received_payloads[0]["amount"]), 3, "subscriber payload")
	bus.free()

func _test_scene_preload_cache() -> void:
	var cache = ScenePreloadCacheScript.new()
	root.add_child(cache)
	var path := "res://addons/shinokute_game_core/core/game_core_config.gd"
	_assert_eq(cache.preload_resource(path), OK, "preload existing resource")
	_assert_true(cache.has_resource(path), "cache records loaded resource")
	_assert_true(cache.get_resource(path) != null, "cache returns loaded resource")
	_assert_eq(cache.preload_resource("res://missing/nope.tscn"), ERR_FILE_NOT_FOUND, "missing preload returns error")
	cache.free()

func _test_resource_registry() -> void:
	var registry_script: Script = load(ResourceRegistryPath)
	_assert_true(registry_script != null, "resource registry script loads")
	if registry_script == null:
		return
	var registry = registry_script.new()
	root.add_child(registry)
	registry.configure({
		"ui.logo": {
			"path": "res://addons/shinokute_game_core/core/game_core_config.gd",
			"type": "Script",
			"required": true
		},
		"ui.button": {
			"fallback_key": "ui.logo",
			"type": "Script",
			"required": true
		},
		"future.panel": {
			"path": "",
			"required": false
		}
	})
	_assert_true(registry.has_resource_key("ui.logo"), "registry records semantic key")
	_assert_eq(registry.get_resource_path("ui.logo"), "res://addons/shinokute_game_core/core/game_core_config.gd", "registry returns direct path")
	_assert_eq(registry.get_resource_path("ui.button"), "res://addons/shinokute_game_core/core/game_core_config.gd", "registry resolves fallback key")
	_assert_true(registry.get_resource("ui.logo") != null, "registry loads configured resource")
	_assert_eq(registry.validate().size(), 0, "valid registry passes validation")
	registry.configure({
		"missing.required": {
			"path": "res://missing/nope.tres",
			"type": "Resource",
			"required": true
		}
	})
	_assert_eq(registry.validate().size(), 1, "missing required path is validation error")
	registry.free()

func _test_weighted_picker() -> void:
	var picker_script: Script = load(WeightedPickerPath)
	_assert_true(picker_script != null, "weighted picker script loads")
	if picker_script == null:
		return
	var picker = picker_script.new()
	picker.configure([
		{"id": "drone", "weight": 1},
		{"id": "runner", "weight": 3},
		{"id": "ghost", "weight": 0}
	])
	_assert_eq(picker.entries().size(), 2, "weighted picker ignores non-positive weights")
	_assert_eq(int(picker.total_weight()), 4, "weighted picker sums valid weights")
	_assert_eq(String(picker.pick(0.0).get("id", "")), "drone", "lowest roll picks first item")
	_assert_eq(String(picker.pick(0.99).get("id", "")), "runner", "highest roll picks weighted item")
	_assert_eq(String(picker.pick(0.0, ["drone"]).get("id", "")), "runner", "weighted picker excludes item ids")

func _test_definition_resolver() -> void:
	var resolver_script: Script = load(DefinitionResolverPath)
	_assert_true(resolver_script != null, "definition resolver script loads")
	if resolver_script == null:
		return
	var picker_script: Script = load(WeightedPickerPath)
	var resolver = resolver_script.new()
	resolver.configure([
		{"id": "signal_focus", "target_key": "fire_cooldown", "operation": "multiply", "value": 0.88},
		{"id": "runner_boots", "target_key": "player_speed", "operation": "add", "value": 12.0}
	], [
		{"id": "signal_focus", "weight": 10},
		{"id": "runner_boots", "weight": 6},
		{"id": "missing_upgrade", "weight": 99}
	], picker_script)
	var entries: Array = resolver.resolved_entries()
	_assert_eq(entries.size(), 2, "definition resolver ignores missing pool refs")
	_assert_eq(String(Dictionary(entries[0]).get("target_key", "")), "fire_cooldown", "definition resolver merges definition fields")
	_assert_eq(int(Dictionary(entries[0]).get("weight", 0)), 10, "definition resolver keeps pool weight override")
	_assert_eq(String(resolver.missing_refs()[0]), "missing_upgrade", "definition resolver records missing refs")
	_assert_eq(String(resolver.definition_for_id("runner_boots").get("operation", "")), "add", "definition resolver looks up canonical definition")
	var selected: Array = resolver.pick_unique(2, [0.99, 0.0])
	_assert_eq(selected.size(), 2, "definition resolver picks unique weighted entries")
	if selected.size() == 2:
		_assert_eq(String(Dictionary(selected[0]).get("id", "")), "runner_boots", "definition resolver high roll selects weighted item")
		_assert_eq(String(Dictionary(selected[1]).get("id", "")), "signal_focus", "definition resolver excludes selected entries")

	var duplicate_resolver = resolver_script.new()
	duplicate_resolver.configure([
		{"id": "dupe"},
		{"id": "dupe"}
	], [], picker_script)
	_assert_true(duplicate_resolver.validation_errors().size() >= 1, "definition resolver reports duplicate ids")

func _test_run_context() -> void:
	var run_context_script: Script = load(RunContextPath)
	_assert_true(run_context_script != null, "run context script loads")
	if run_context_script == null:
		return
	var first = run_context_script.new()
	first.configure("run-1", 12345, ["hard", "daily"], {"level_id": "level_01"})
	var second = run_context_script.new()
	second.configure("run-1", 12345, ["daily", "hard"], {"level_id": "level_01"})
	_assert_eq(first.run_id(), "run-1", "run context stores run id")
	_assert_eq(int(first.seed()), 12345, "run context stores seed")
	_assert_true(first.has_modifier("daily"), "run context tracks selected modifier ids")
	_assert_eq(first.roll("upgrade", 0), second.roll("upgrade", 0), "run context deterministic roll is stable")
	_assert_true(first.roll("upgrade", 0) != first.roll("upgrade", 1), "run context roll index changes deterministic value")
	var packed: Dictionary = first.to_dictionary()
	_assert_eq(String(packed.get("level_id", "")), "level_01", "run context carries extra game data without interpreting it")

func _test_limited_counter() -> void:
	var counter_script: Script = load(LimitedCounterPath)
	_assert_true(counter_script != null, "limited counter script loads")
	if counter_script == null:
		return
	var counter = counter_script.new()
	counter.configure([
		{"id": "rare", "max_quantity": 1},
		{"id": "common", "max_quantity": 2},
		{"id": "uncapped", "max_quantity": 0}
	])
	_assert_true(counter.can_consume("rare"), "limited counter allows available id")
	_assert_true(counter.consume("rare"), "limited counter consumes available id")
	_assert_true(not counter.can_consume("rare"), "limited counter blocks capped id")
	var filtered: Array = counter.filter_entries([
		{"id": "rare", "weight": 10},
		{"id": "common", "weight": 1},
		{"id": "uncapped", "weight": 1}
	])
	_assert_eq(filtered.size(), 2, "limited counter filters capped entries")
	_assert_eq(int(counter.count_for_id("rare")), 1, "limited counter reports consumed count")
	_assert_eq(int(counter.limit_for_id("common")), 2, "limited counter reports configured cap")

func _test_input_vector_filter() -> void:
	var filter_script: Script = load(InputVectorFilterPath)
	_assert_true(filter_script != null, "input vector filter script loads")
	if filter_script == null:
		return
	var filter = filter_script.new()
	_assert_eq(filter.filter(Vector2(0.05, 0.0), {"deadzone": 0.1}), Vector2.ZERO, "input filter applies deadzone")
	var diagonal: Vector2 = filter.filter(Vector2(1.0, 1.0), {"deadzone": 0.0, "normalize_diagonal": true})
	_assert_float_eq(diagonal.length(), 1.0, 0.001, "input filter normalizes diagonal movement")
	var curved: Vector2 = filter.filter(Vector2(0.5, 0.0), {"deadzone": 0.0, "analog_curve": 2.0})
	_assert_float_eq(curved.length(), 0.25, 0.001, "input filter applies analog curve")

func _test_kinematic_motion_solver() -> void:
	var solver_script: Script = load(KinematicMotionSolverPath)
	_assert_true(solver_script != null, "kinematic motion solver script loads")
	if solver_script == null:
		return
	var solver = solver_script.new()
	var profile := {
		"max_speed": 100.0,
		"acceleration": 200.0,
		"deceleration": 400.0,
		"turn_acceleration": 300.0
	}
	var accelerated: Vector2 = solver.solve_velocity(Vector2.ZERO, Vector2.RIGHT, 0.25, profile)
	_assert_float_eq(accelerated.x, 50.0, 0.001, "motion solver accelerates toward target speed")
	var capped: Vector2 = solver.solve_velocity(accelerated, Vector2.RIGHT, 1.0, profile)
	_assert_float_eq(capped.x, 100.0, 0.001, "motion solver caps max speed")
	var stopped: Vector2 = solver.solve_velocity(Vector2(100.0, 0.0), Vector2.ZERO, 0.25, profile)
	_assert_float_eq(stopped.length(), 0.0, 0.001, "motion solver decelerates when no input")
	var turned: Vector2 = solver.solve_velocity(Vector2(100.0, 0.0), Vector2.LEFT, 0.25, profile)
	_assert_true(turned.x < 100.0, "motion solver uses turn acceleration against current velocity")

func _test_steering() -> void:
	var steering_script: Script = load(SteeringPath)
	_assert_true(steering_script != null, "steering script loads")
	if steering_script == null:
		return
	var steering = steering_script.new()
	var seek: Vector2 = steering.seek(Vector2.ZERO, Vector2(10.0, 0.0))
	_assert_eq(seek, Vector2.RIGHT, "steering seek points to target")
	var arrive_far: Vector2 = steering.arrive(Vector2.ZERO, Vector2(100.0, 0.0), 32.0)
	_assert_float_eq(arrive_far.length(), 1.0, 0.001, "steering arrive keeps full force far away")
	var arrive_near: Vector2 = steering.arrive(Vector2.ZERO, Vector2(16.0, 0.0), 32.0)
	_assert_float_eq(arrive_near.length(), 0.5, 0.001, "steering arrive slows near target")
	var separation: Vector2 = steering.separation(Vector2.ZERO, [Vector2(4.0, 0.0), Vector2(0.0, 8.0)], 16.0)
	_assert_true(separation.x < 0.0 and separation.y < 0.0, "steering separation pushes away from neighbors")

func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_passed = false
		push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])

func _assert_true(value: bool, label: String) -> void:
	if not value:
		_passed = false
		push_error(label)

func _assert_float_eq(actual: float, expected: float, tolerance: float, label: String) -> void:
	if abs(actual - expected) > tolerance:
		_passed = false
		push_error("%s: expected %s got %s" % [label, str(expected), str(actual)])

func _report(name: String) -> void:
	if _passed:
		print("%s: PASS" % name)
		quit(0)
	else:
		print("%s: FAIL" % name)
		quit(1)
