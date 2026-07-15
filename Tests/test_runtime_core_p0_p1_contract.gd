extends SceneTree

const ActionEffectReportPath := "res://addons/shinokute_game_core/runtime/action_effect_report.gd"
const ContentTableValidatorPath := "res://addons/shinokute_game_core/runtime/content_table_validator.gd"
const RequirementResolverPath := "res://addons/shinokute_game_core/runtime/requirement_resolver.gd"
const ModifierStackPath := "res://addons/shinokute_game_core/runtime/modifier_stack.gd"
const ModalLifecyclePath := "res://addons/shinokute_game_core/runtime/modal_lifecycle.gd"
const RuntimeDebugSnapshotPath := "res://addons/shinokute_game_core/runtime/runtime_debug_snapshot.gd"
const RunRewardPickerPath := "res://addons/shinokute_game_core/runtime/run_reward_picker.gd"
const EventTimelinePath := "res://addons/shinokute_game_core/runtime/event_timeline.gd"
const SpawnPatternResolverPath := "res://addons/shinokute_game_core/runtime/spawn_pattern_resolver_2d.gd"
const PickupAttractorPath := "res://addons/shinokute_game_core/runtime/pickup_attractor_2d.gd"
const TelemetryEventSchemaPath := "res://addons/shinokute_game_core/runtime/telemetry_event_schema.gd"
const WeightedPickerPath := "res://addons/shinokute_game_core/runtime/weighted_picker.gd"
const BudgetResolverPath := "res://addons/shinokute_game_core/runtime/budget_resolver.gd"
const ProjectileBlueprintComposerPath := "res://addons/shinokute_game_core/runtime/projectile_blueprint_composer_2d.gd"
const AttackPatternResolverPath := "res://addons/shinokute_game_core/runtime/attack_pattern_resolver_2d.gd"
const SpatialHashPath := "res://addons/shinokute_game_core/runtime/spatial_hash_2d.gd"
const DropTableResolverPath := "res://addons/shinokute_game_core/runtime/drop_table_resolver.gd"
const SpawnTelegraphLifecyclePath := "res://addons/shinokute_game_core/runtime/spawn_telegraph_lifecycle.gd"
const NumericEffectResolverPath := "res://addons/shinokute_game_core/runtime/numeric_effect_resolver.gd"
const StatusEffectRuntimePath := "res://addons/shinokute_game_core/runtime/status_effect_runtime.gd"
const SpawnScheduleResolverPath := "res://addons/shinokute_game_core/runtime/spawn_schedule_resolver.gd"
const RuntimeLedgerPath := "res://addons/shinokute_game_core/runtime/runtime_ledger.gd"
const InventoryContainerPath := "res://addons/shinokute_game_core/runtime/inventory_container.gd"
const RngStreamPath := "res://addons/shinokute_game_core/runtime/rng_stream.gd"
const TargetingQueryPath := "res://addons/shinokute_game_core/runtime/targeting_query_2d.gd"
const ProjectileHitBudgetPath := "res://addons/shinokute_game_core/runtime/projectile_hit_budget.gd"
const ProjectileTravelPath := "res://addons/shinokute_game_core/runtime/projectile_travel_runtime_2d.gd"
const AttackCadencePath := "res://addons/shinokute_game_core/runtime/attack_cadence.gd"
const PublishAuditPath := "res://addons/shinokute_game_core/runtime/publish_audit.gd"

var _passed := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_p0_action_report()
	_test_p0_content_validator()
	_test_p0_requirement_resolver()
	_test_p0_modifier_stack()
	_test_p0_modal_lifecycle()
	_test_p0_debug_snapshot()
	_test_p1_reward_picker()
	_test_p1_event_timeline()
	_test_p1_spawn_patterns()
	_test_p1_pickup_attractor()
	_test_p1_telemetry_schema()
	_test_p1_projectile_blueprint_composer()
	_test_p1_attack_pattern_resolver()
	_test_p1_spatial_hash()
	_test_p1_targeting_query()
	_test_p0_projectile_hit_budget()
	_test_p0_projectile_travel_runtime()
	_test_p1_attack_cadence()
	_test_p1_publish_audit()
	_test_p1_drop_table_resolver()
	_test_p1_spawn_telegraph_lifecycle()
	_test_p1_numeric_effect_resolver()
	_test_p1_status_effect_runtime()
	_test_p0_spawn_schedule_resolver()
	_test_p0_rng_stream()
	_test_p1_runtime_ledger()
	_test_p2_inventory_container()
	_report("test_runtime_core_p0_p1_contract")

func _test_p0_action_report() -> void:
	var script: Script = load(ActionEffectReportPath)
	_assert_true(script != null, "action effect report script loads")
	if script == null:
		return
	var report = script.new()
	report.accept({"actor_id": "player"})
	report.add_effect("damage", {"target_id": "enemy_1", "amount": 3})
	report.add_event("hit", {"target_id": "enemy_1"})
	var packed: Dictionary = report.to_dictionary()
	_assert_true(bool(packed.get("accepted", false)), "action report records accepted state")
	_assert_eq(String(packed.get("block_reason", "")), "", "accepted action has no block reason")
	_assert_eq(String(Dictionary(Array(packed.get("effects", []))[0]).get("type", "")), "damage", "action report stores typed effects")
	_assert_eq(String(Dictionary(Array(packed.get("events", []))[0]).get("name", "")), "hit", "action report stores typed events")
	report.block("cooldown", {"remaining": 0.2})
	packed = report.to_dictionary()
	_assert_true(not bool(packed.get("accepted", true)), "blocked action clears accepted state")
	_assert_eq(String(packed.get("block_reason", "")), "cooldown", "blocked action records reason")

func _test_p0_content_validator() -> void:
	var script: Script = load(ContentTableValidatorPath)
	_assert_true(script != null, "content table validator script loads")
	if script == null:
		return
	var validator = script.new()
	var result: Dictionary = validator.validate_table([
		{"id": "bolt", "damage": 2, "projectile_id": "projectile_bolt"},
		{"id": "bolt", "damage": "bad", "projectile_id": "missing_projectile"},
		{"damage": 1}
	], {
		"id_key": "id",
		"required": ["id", "damage"],
		"types": {"id": TYPE_STRING, "damage": TYPE_INT, "projectile_id": TYPE_STRING},
		"refs": [{"field": "projectile_id", "allowed": ["projectile_bolt"]}]
	})
	var errors: Array = Array(result.get("errors", []))
	_assert_true(errors.size() >= 4, "content validator reports duplicate, missing id, bad type, and missing ref")
	_assert_true(_has_error_code(errors, "duplicate_id"), "content validator reports duplicate id")
	_assert_true(_has_error_code(errors, "missing_required"), "content validator reports missing required field")
	_assert_true(_has_error_code(errors, "type_mismatch"), "content validator reports type mismatch")
	_assert_true(_has_error_code(errors, "missing_ref"), "content validator reports missing reference")

func _test_p0_requirement_resolver() -> void:
	var script: Script = load(RequirementResolverPath)
	_assert_true(script != null, "requirement resolver script loads")
	if script == null:
		return
	var resolver = script.new()
	var context := {
		"flags": {"level_3": true},
		"counts": {"currency": {"gem": 10}},
		"tags": ["fire", "projectile"]
	}
	var requirement := {
		"all": [
			{"flag": "level_3"},
			{"count_group": "currency", "key": "gem", "min": 5},
			{"any": [{"tag": "ice"}, {"tag": "fire"}]}
		]
	}
	_assert_true(resolver.is_met(requirement, context), "requirement resolver passes nested all/any requirement")
	var blocked := {"all": [{"flag": "level_3"}, {"count_group": "currency", "key": "gem", "min": 50}]}
	_assert_true(not resolver.is_met(blocked, context), "requirement resolver blocks unmet count")
	_assert_eq(String(Dictionary(resolver.missing_requirements(blocked, context)[0]).get("key", "")), "gem", "requirement resolver reports missing key")

func _test_p0_modifier_stack() -> void:
	var script: Script = load(ModifierStackPath)
	_assert_true(script != null, "modifier stack script loads")
	if script == null:
		return
	var stack = script.new()
	stack.add_modifier({"source": "upgrade_damage", "target_key": "damage", "operation": "add", "value": 2})
	stack.add_modifier({"source": "buff_damage", "target_key": "damage", "operation": "multiply", "value": 1.5})
	stack.add_modifier({"source": "short_focus", "target_key": "cooldown", "operation": "set", "value": 1.8, "duration": 1.0})
	var resolved: Dictionary = stack.resolve({"damage": 10, "cooldown": 2.5})
	_assert_float_eq(float(resolved.get("damage", 0.0)), 18.0, 0.001, "modifier stack applies add then multiply")
	_assert_float_eq(float(resolved.get("cooldown", 0.0)), 1.8, 0.001, "modifier stack applies set")
	stack.tick(1.0)
	resolved = stack.resolve({"damage": 10, "cooldown": 2.5})
	_assert_float_eq(float(resolved.get("cooldown", 0.0)), 2.5, 0.001, "modifier stack expires timed modifier")
	stack.remove_source("upgrade_damage")
	resolved = stack.resolve({"damage": 10})
	_assert_float_eq(float(resolved.get("damage", 0.0)), 15.0, 0.001, "modifier stack removes modifiers by source")

func _test_p0_modal_lifecycle() -> void:
	var script: Script = load(ModalLifecyclePath)
	_assert_true(script != null, "modal lifecycle script loads")
	if script == null:
		return
	var lifecycle = script.new()
	lifecycle.configure({
		"upgrade": {"blocking": true},
		"result": {"blocking": true, "supersedes": ["upgrade"]},
		"settings": {"blocking": false}
	})
	var upgrade_result: Dictionary = lifecycle.request("upgrade", {"wave": 2})
	_assert_eq(String(upgrade_result.get("status", "")), "shown", "modal lifecycle shows first modal")
	_assert_eq(lifecycle.active_key(), "upgrade", "modal lifecycle records active modal")
	var result_request: Dictionary = lifecycle.request("result", {"outcome": "defeated"})
	_assert_eq(String(result_request.get("status", "")), "shown", "result modal shows")
	_assert_true(Array(result_request.get("closed", [])).has("upgrade"), "result supersedes upgrade")
	_assert_eq(lifecycle.active_key(), "result", "modal lifecycle makes result active")
	var blocked_upgrade: Dictionary = lifecycle.request("upgrade", {"wave": 3})
	_assert_eq(String(blocked_upgrade.get("status", "")), "blocked", "blocking result blocks later upgrade modal")
	_assert_eq(lifecycle.active_key(), "result", "blocked modal does not replace result")
	lifecycle.close("result")
	_assert_eq(lifecycle.active_key(), "", "modal lifecycle closes active modal")

func _test_p0_debug_snapshot() -> void:
	var script: Script = load(RuntimeDebugSnapshotPath)
	_assert_true(script != null, "runtime debug snapshot script loads")
	if script == null:
		return
	var snapshotter = script.new()
	var parent := Node.new()
	parent.name = "SnapshotParent"
	var child := Node.new()
	child.name = "ChildA"
	parent.add_child(child)
	root.add_child(parent)
	var snapshot: Dictionary = snapshotter.build_snapshot({
		"run": {"level_id": "level_03"},
		"modal": {"active": "result"},
		"nodes": snapshotter.node_names(parent)
	})
	_assert_eq(String(Dictionary(snapshot.get("run", {})).get("level_id", "")), "level_03", "debug snapshot keeps run section")
	_assert_true(Array(snapshot.get("nodes", [])).has("ChildA"), "debug snapshot lists node names")
	parent.free()

func _test_p1_reward_picker() -> void:
	var script: Script = load(RunRewardPickerPath)
	var picker_script: Script = load(WeightedPickerPath)
	_assert_true(script != null, "run reward picker script loads")
	if script == null or picker_script == null:
		return
	var picker = script.new()
	picker.configure([
		{"id": "common", "weight": 10, "max_quantity": 0},
		{"id": "rare", "weight": 5, "max_quantity": 1, "requirements": {"flag": "rare_unlocked"}},
		{"id": "banished", "weight": 100, "max_quantity": 0}
	], picker_script)
	var first: Array = picker.pick_options(2, {"flags": {"rare_unlocked": true}}, {"banished": ["banished"], "counts": {"rare": 1}}, [0.99, 0.0])
	_assert_eq(first.size(), 1, "reward picker filters capped and banished rewards")
	if first.size() == 1:
		_assert_eq(String(Dictionary(first[0]).get("id", "")), "common", "reward picker keeps eligible common reward")
	var second: Array = picker.pick_options(2, {"flags": {"rare_unlocked": true}}, {"banished": ["banished"], "counts": {}}, [0.99, 0.0])
	_assert_eq(second.size(), 2, "reward picker returns unique eligible rewards")
	if second.size() == 2:
		_assert_eq(String(Dictionary(second[0]).get("id", "")), "rare", "reward picker uses weight roll")

func _test_p1_event_timeline() -> void:
	var script: Script = load(EventTimelinePath)
	_assert_true(script != null, "event timeline script loads")
	if script == null:
		return
	var timeline = script.new()
	timeline.configure([
		{"id": "spawn", "time": 1.0, "payload": {"batch": 3}},
		{"id": "elite", "time": 2.0}
	])
	var due: Array = timeline.advance(1.5)
	_assert_eq(due.size(), 1, "timeline emits first due event")
	_assert_eq(String(Dictionary(due[0]).get("id", "")), "spawn", "timeline returns event id")
	due = timeline.advance(0.6)
	_assert_eq(String(Dictionary(due[0]).get("id", "")), "elite", "timeline emits later event")
	timeline.reset()
	_assert_eq(timeline.elapsed(), 0.0, "timeline resets elapsed time")

func _test_p1_spawn_patterns() -> void:
	var script: Script = load(SpawnPatternResolverPath)
	_assert_true(script != null, "spawn pattern resolver script loads")
	if script == null:
		return
	var resolver = script.new()
	var ring: Array = resolver.resolve({"pattern": "ring", "center": Vector2.ZERO, "radius": 10.0, "count": 4})
	_assert_eq(ring.size(), 4, "spawn pattern ring returns count")
	_assert_float_eq((ring[0] as Vector2).length(), 10.0, 0.001, "spawn pattern ring uses radius")
	var edge: Array = resolver.resolve({"pattern": "edge", "rect": Rect2(Vector2.ZERO, Vector2(100.0, 50.0)), "side": "top", "count": 3})
	_assert_eq(edge[1], Vector2(50.0, 0.0), "spawn pattern edge spaces along side")
	var lane: Array = resolver.resolve({"pattern": "lane", "start": Vector2.ZERO, "end": Vector2(10.0, 0.0), "count": 3})
	_assert_eq(lane[2], Vector2(10.0, 0.0), "spawn pattern lane includes end")

func _test_p1_pickup_attractor() -> void:
	var script: Script = load(PickupAttractorPath)
	_assert_true(script != null, "pickup attractor script loads")
	if script == null:
		return
	var attractor = script.new()
	var result: Dictionary = attractor.step(Vector2.ZERO, Vector2(10.0, 0.0), 4.0, 1.0, 1.0)
	_assert_eq(Vector2(result.get("position", Vector2.ZERO)), Vector2(4.0, 0.0), "pickup attractor moves toward target")
	_assert_true(not bool(result.get("collected", false)), "pickup attractor does not collect too early")
	result = attractor.step(Vector2(9.5, 0.0), Vector2(10.0, 0.0), 4.0, 1.0, 1.0)
	_assert_true(bool(result.get("collected", false)), "pickup attractor collects inside radius")

func _test_p1_telemetry_schema() -> void:
	var script: Script = load(TelemetryEventSchemaPath)
	_assert_true(script != null, "telemetry event schema script loads")
	if script == null:
		return
	var schema = script.new()
	schema.configure({
		"upgrade_picked": {"required": ["id", "level"], "types": {"id": TYPE_STRING, "level": TYPE_INT}},
		"run_end": {"required": ["outcome"], "types": {"outcome": TYPE_STRING, "score": TYPE_INT}}
	})
	var ok: Dictionary = schema.validate("upgrade_picked", {"id": "pierce", "level": 2})
	_assert_eq(Array(ok.get("errors", [])).size(), 0, "telemetry schema accepts valid event")
	var bad: Dictionary = schema.validate("upgrade_picked", {"id": 7})
	_assert_true(_has_error_code(Array(bad.get("errors", [])), "missing_required"), "telemetry schema reports missing field")
	_assert_true(_has_error_code(Array(bad.get("errors", [])), "type_mismatch"), "telemetry schema reports bad type")
	var normalized: Dictionary = schema.normalize("run_end", {"outcome": "lost", "score": 10, "extra": true})
	_assert_true(not normalized.has("extra"), "telemetry schema drops undeclared keys")

func _test_p1_projectile_blueprint_composer() -> void:
	var script: Script = load(ProjectileBlueprintComposerPath)
	_assert_true(script != null, "projectile blueprint composer script loads")
	if script == null:
		return
	var composer = script.new()
	var base := {
		"id": "pulse_orb",
		"damage": 2,
		"pierce": 0,
		"instances": 1,
		"angular_spread": 0.0,
		"hit_radius": 40
	}
	var modifiers := [
		{"target_key": "pierce", "operation": "add", "value": 1},
		{"target_key": "instances", "operation": "max", "value": 3},
		{"target_key": "angular_spread", "operation": "set_if_greater", "value": 24.0}
	]
	var composed: Dictionary = composer.compose(base, modifiers)
	_assert_eq(String(composed.get("id", "")), "pulse_orb", "projectile composer keeps game-owned blueprint id")
	_assert_eq(int(composed.get("pierce", 0)), 1, "projectile composer applies pierce as generic numeric key")
	_assert_eq(int(composed.get("instances", 0)), 3, "projectile composer applies instances as generic numeric key")
	_assert_float_eq(float(composed.get("angular_spread", 0.0)), 24.0, 0.001, "projectile composer applies spread as generic numeric key")
	_assert_eq(int(composed.get("hit_radius", 0)), 40, "projectile composer preserves untouched game-owned keys")
	var reordered: Dictionary = composer.compose(base, [
		modifiers[2],
		modifiers[0],
		modifiers[1]
	])
	_assert_eq(reordered, composed, "projectile composer gives same result for independent modifier order")

func _test_p1_attack_pattern_resolver() -> void:
	var script: Script = load(AttackPatternResolverPath)
	_assert_true(script != null, "attack pattern resolver script loads")
	if script == null:
		return
	var resolver = script.new()
	var emissions: Array = resolver.resolve({
		"origin": Vector2(10.0, 5.0),
		"direction": Vector2.RIGHT,
		"instances": 3,
		"angular_spread": 20.0,
		"spawn_offset": 12.0
	})
	_assert_eq(emissions.size(), 3, "attack pattern resolver emits requested instances")
	if emissions.size() == 3:
		var middle := Dictionary(emissions[1])
		_assert_true(Vector2(middle.get("direction", Vector2.ZERO)).distance_to(Vector2.RIGHT) <= 0.001, "attack pattern middle lane keeps base direction")
		_assert_true(Vector2(middle.get("position", Vector2.ZERO)).distance_to(Vector2(22.0, 5.0)) <= 0.001, "attack pattern applies spawn offset")
		_assert_float_eq(float(Dictionary(emissions[0]).get("angle_degrees", 0.0)), -10.0, 0.001, "attack pattern left lane uses half spread")
		_assert_float_eq(float(Dictionary(emissions[2]).get("angle_degrees", 0.0)), 10.0, 0.001, "attack pattern right lane uses half spread")

func _test_p1_spatial_hash() -> void:
	var script: Script = load(SpatialHashPath)
	_assert_true(script != null, "spatial hash script loads")
	if script == null:
		return
	var index = script.new()
	index.configure(64.0)
	index.upsert("near_a", Vector2(10.0, 0.0), 4.0, {"kind": "enemy"})
	index.upsert("near_b", Vector2(32.0, 32.0), 4.0, {"kind": "enemy"})
	index.upsert("far", Vector2(120.0, 0.0), 4.0, {"kind": "enemy"})
	var nearby: Array = index.query_radius(Vector2.ZERO, 50.0)
	_assert_true(_entry_ids(nearby).has("near_a"), "spatial hash finds nearby entry")
	_assert_true(_entry_ids(nearby).has("near_b"), "spatial hash finds diagonal nearby entry")
	_assert_true(not _entry_ids(nearby).has("far"), "spatial hash excludes far entry")
	index.upsert("near_a", Vector2(200.0, 0.0), 4.0)
	index.remove("near_b")
	nearby = index.query_radius(Vector2.ZERO, 50.0)
	_assert_true(not _entry_ids(nearby).has("near_a"), "spatial hash updates moved entry")
	_assert_true(not _entry_ids(nearby).has("near_b"), "spatial hash removes entry")

func _test_p1_targeting_query() -> void:
	var script: Script = load(TargetingQueryPath)
	_assert_true(script != null, "targeting query script loads")
	if script == null:
		return
	var query = script.new()
	var candidates := [
		{"id": "behind", "position": Vector2(-30.0, 0.0), "radius": 4.0},
		{"id": "near", "position": Vector2(20.0, 0.0), "radius": 4.0},
		{"id": "far", "position": Vector2(80.0, 0.0), "radius": 4.0},
		{"id": "upper", "position": Vector2(40.0, 20.0), "radius": 6.0}
	]
	var nearest: Dictionary = query.nearest(Vector2.ZERO, candidates, {"max_distance": 100.0})
	_assert_eq(String(nearest.get("id", "")), "near", "targeting query selects nearest candidate")
	var in_radius: Array = query.within_radius(Vector2.ZERO, candidates, 45.0)
	_assert_true(_entry_ids(in_radius).has("near"), "targeting radius includes near candidate")
	_assert_true(_entry_ids(in_radius).has("upper"), "targeting radius includes radius-overlap candidate")
	_assert_true(not _entry_ids(in_radius).has("far"), "targeting radius excludes far candidate")
	var in_cone: Array = query.within_cone(Vector2.ZERO, Vector2.RIGHT, candidates, {"range": 90.0, "angle_degrees": 40.0})
	_assert_true(_entry_ids(in_cone).has("near"), "targeting cone includes forward candidate")
	_assert_true(not _entry_ids(in_cone).has("behind"), "targeting cone excludes behind candidate")
	var segment_hits: Array = query.segment_hits(Vector2.ZERO, Vector2(100.0, 0.0), candidates, {"hit_radius": 2.0})
	_assert_eq(_entry_ids(segment_hits), ["near", "far"], "targeting segment returns pierce hits in travel order")

func _test_p0_projectile_hit_budget() -> void:
	var script: Script = load(ProjectileHitBudgetPath)
	_assert_true(script != null, "projectile hit budget script loads")
	if script == null:
		return
	var budget = script.new()
	budget.configure({"default_max_hits": 1, "allow_rehit": false, "rehit_cooldown": 0.25})
	var registered: Dictionary = budget.register_projectile("bolt", {"max_hits": 2})
	_assert_eq(String(registered.get("projectile_id", "")), "bolt", "projectile hit budget registers projectile id")
	_assert_eq(int(registered.get("remaining_hits", 0)), 2, "projectile hit budget uses caller-owned max hit count")
	var first: Dictionary = budget.record_hit("bolt", "enemy_a")
	_assert_true(bool(first.get("accepted", false)), "projectile hit budget accepts first target hit")
	_assert_eq(int(first.get("remaining_hits", -1)), 1, "projectile hit budget consumes one hit")
	var duplicate: Dictionary = budget.record_hit("bolt", "enemy_a")
	_assert_true(not bool(duplicate.get("accepted", true)), "projectile hit budget blocks duplicate hit when rehit disabled")
	_assert_eq(String(duplicate.get("reason", "")), "duplicate_target", "projectile hit budget reports duplicate target")
	var second: Dictionary = budget.record_hit("bolt", "enemy_b")
	_assert_true(bool(second.get("accepted", false)), "projectile hit budget accepts second distinct target")
	_assert_true(bool(second.get("expired", false)), "projectile hit budget expires when hit count reaches zero")
	_assert_eq(String(second.get("expire_reason", "")), "hit_budget_depleted", "projectile hit budget reports hit budget expiry")

	var rehit = script.new()
	rehit.configure({"default_max_hits": 3, "allow_rehit": true, "rehit_cooldown": 0.5})
	rehit.register_projectile("orb")
	_assert_true(bool(rehit.record_hit("orb", "enemy_a").get("accepted", false)), "projectile hit budget accepts initial rehit target")
	var too_soon: Dictionary = rehit.record_hit("orb", "enemy_a")
	_assert_true(not bool(too_soon.get("accepted", true)), "projectile hit budget blocks rehit during cooldown")
	_assert_eq(String(too_soon.get("reason", "")), "rehit_cooldown", "projectile hit budget reports rehit cooldown")
	rehit.advance(0.5)
	var after_cooldown: Dictionary = rehit.record_hit("orb", "enemy_a")
	_assert_true(bool(after_cooldown.get("accepted", false)), "projectile hit budget accepts rehit after cooldown")
	var snapshot: Dictionary = rehit.snapshot()
	rehit.record_hit("orb", "enemy_b")
	rehit.restore(snapshot)
	_assert_eq(int(Dictionary(rehit.projectile_state("orb")).get("remaining_hits", 0)), 1, "projectile hit budget restores remaining hits")
	_assert_true(Array(Dictionary(rehit.projectile_state("orb")).get("hit_ids", [])).has("enemy_a"), "projectile hit budget restores hit ids")

func _test_p0_projectile_travel_runtime() -> void:
	var script: Script = load(ProjectileTravelPath)
	_assert_true(script != null, "projectile travel runtime script loads")
	if script == null:
		return
	var travel = script.new()
	travel.configure({"default_speed": 100.0, "default_range": 150.0, "default_lifetime": 2.0})
	var state: Dictionary = travel.initial_state({"position": Vector2.ZERO, "direction": Vector2.RIGHT})
	var first: Dictionary = travel.step(state, 0.5)
	_assert_eq(Vector2(first.get("position", Vector2.ZERO)), Vector2(50.0, 0.0), "projectile travel advances position by speed and delta")
	_assert_float_eq(float(first.get("distance", 0.0)), 50.0, 0.001, "projectile travel tracks traveled distance")
	_assert_true(not bool(first.get("expired", true)), "projectile travel does not expire before range or lifetime")
	var second: Dictionary = travel.step(first, 1.0)
	_assert_true(bool(second.get("expired", false)), "projectile travel expires at configured range")
	_assert_eq(String(second.get("expire_reason", "")), "range", "projectile travel reports range expiry")
	var timed: Dictionary = travel.initial_state({"position": Vector2.ZERO, "direction": Vector2.RIGHT, "speed": 10.0, "lifetime": 0.25, "range": 1000.0})
	var timed_result: Dictionary = travel.step(timed, 0.3)
	_assert_true(bool(timed_result.get("expired", false)), "projectile travel expires by lifetime")
	_assert_eq(String(timed_result.get("expire_reason", "")), "lifetime", "projectile travel reports lifetime expiry")
	var steering: Dictionary = travel.initial_state({"position": Vector2.ZERO, "direction": Vector2.RIGHT, "speed": 0.0, "range": 1000.0})
	var steered: Dictionary = travel.step(steering, 0.5, {"target_position": Vector2(0.0, 100.0), "angular_speed_degrees": 90.0})
	var steered_direction := Vector2(steered.get("direction", Vector2.ZERO))
	_assert_true(steered_direction.distance_to(Vector2.RIGHT.rotated(deg_to_rad(45.0))) <= 0.001, "projectile travel turns toward target with angular limit")
	var snapshot: Dictionary = travel.snapshot(steered)
	var restored: Dictionary = travel.restore(snapshot)
	_assert_eq(restored, snapshot, "projectile travel restores snapshot dictionary")

func _test_p1_attack_cadence() -> void:
	var script: Script = load(AttackCadencePath)
	_assert_true(script != null, "attack cadence script loads")
	if script == null:
		return
	var cadence = script.new()
	cadence.configure({"cooldown": 0.5, "anticipate": 0.1, "duration": 0.2, "recovery": 0.3})
	var state: Dictionary = cadence.initial_state()
	var requested: Dictionary = cadence.request(state)
	_assert_eq(String(requested.get("status", "")), "accepted", "attack cadence accepts ready attack")
	_assert_eq(String(Dictionary(requested.get("state", {})).get("phase", "")), "anticipate", "attack cadence enters anticipate phase")
	var blocked: Dictionary = cadence.request(Dictionary(requested.get("state", {})))
	_assert_eq(String(blocked.get("status", "")), "blocked", "attack cadence blocks request while active")
	_assert_eq(String(blocked.get("reason", "")), "phase_active", "attack cadence reports active phase block")
	var duration: Dictionary = cadence.advance(Dictionary(requested.get("state", {})), 0.1)
	_assert_eq(String(duration.get("phase", "")), "duration", "attack cadence advances to duration phase")
	_assert_true(Array(duration.get("events", [])).has("execute"), "attack cadence emits execute event")
	var recovery: Dictionary = cadence.advance(duration, 0.2)
	_assert_eq(String(recovery.get("phase", "")), "recovery", "attack cadence advances to recovery phase")
	var ready: Dictionary = cadence.advance(recovery, 0.3)
	_assert_eq(String(ready.get("phase", "")), "ready", "attack cadence returns to ready after recovery")
	var cooling: Dictionary = cadence.request(ready)
	var cooldown_state: Dictionary = cadence.advance(Dictionary(cooling.get("state", {})), 0.6)
	_assert_true(cadence.can_request(cooldown_state), "attack cadence can request after cooldown window")
	var snapshot: Dictionary = cadence.snapshot(cooldown_state)
	_assert_eq(cadence.restore(snapshot), snapshot, "attack cadence restores snapshot dictionary")

func _test_p1_publish_audit() -> void:
	var script: Script = load(PublishAuditPath)
	_assert_true(script != null, "publish audit script loads")
	if script == null:
		return
	var audit = script.new()
	var manifest: Dictionary = audit.validate_manifest([
		{"path": "res://Audio/Music/theme.ogg", "role": "music", "required": true},
		{"role": "missing_path"},
		{"path": "res://debug/raw.psd", "role": "source"}
	])
	var errors: Array = Array(manifest.get("errors", []))
	_assert_true(_has_error_code(errors, "missing_required"), "publish audit reports missing manifest fields")
	_assert_true(_has_error_code(errors, "forbidden_marker"), "publish audit reports forbidden marker in manifest path")
	var marker_report: Dictionary = audit.scan_forbidden_markers([
		"res://Scenes/Game.tscn",
		"res://docs/reference/raw_mockup.png",
		"res://Assets/runtime/player.png"
	], ["raw", "reference"])
	_assert_eq(Array(marker_report.get("matches", [])).size(), 1, "publish audit scans forbidden markers")
	var presets: Dictionary = audit.audit_export_presets_text("[preset.0]\nname=\"Web\"\nplatform=\"Web\"\n[preset.1]\nname=\"Android\"\nplatform=\"Android\"", ["Web", "Android", "Windows Desktop"])
	_assert_true(Array(presets.get("missing_presets", [])).has("Windows Desktop"), "publish audit reports missing export preset")
	var headers: Dictionary = audit.audit_hosting_headers({"Cross-Origin-Opener-Policy": "same-origin"}, ["Cross-Origin-Opener-Policy", "Cross-Origin-Embedder-Policy"])
	_assert_true(Array(headers.get("missing_headers", [])).has("Cross-Origin-Embedder-Policy"), "publish audit reports missing hosting header")

func _test_p1_drop_table_resolver() -> void:
	var script: Script = load(DropTableResolverPath)
	_assert_true(script != null, "drop table resolver script loads")
	if script == null:
		return
	var resolver = script.new()
	resolver.configure(RequirementResolverPath)
	var drops: Array = resolver.resolve([
		{"id": "coin", "chance": 1.0, "quantity": 3},
		{"id": "repair", "chance": 0.25, "quantity": 1},
		{"id": "rare_core", "chance": 1.0, "quantity": 1, "requirements": {"flag": "rare_unlocked"}}
	], {"flags": {"rare_unlocked": true}}, [0.0, 0.9, 0.0])
	var ids := _entry_ids(drops)
	_assert_true(ids.has("coin"), "drop table keeps guaranteed drop")
	_assert_true(not ids.has("repair"), "drop table blocks failed chance")
	_assert_true(ids.has("rare_core"), "drop table accepts met requirement")
	_assert_eq(int(Dictionary(drops[0]).get("quantity", 0)), 3, "drop table preserves quantity")

func _test_p1_spawn_telegraph_lifecycle() -> void:
	var script: Script = load(SpawnTelegraphLifecyclePath)
	_assert_true(script != null, "spawn telegraph lifecycle script loads")
	if script == null:
		return
	var lifecycle = script.new()
	lifecycle.request({"id": "spawn_a", "delay": 0.5, "payload": {"enemy_id": "runner"}})
	_assert_eq(lifecycle.pending_count(), 1, "spawn telegraph records pending request")
	_assert_eq(lifecycle.advance(0.25).size(), 0, "spawn telegraph waits until delay")
	var ready: Array = lifecycle.advance(0.25)
	_assert_eq(ready.size(), 1, "spawn telegraph emits ready request after delay")
	if ready.size() == 1:
		_assert_eq(String(Dictionary(ready[0]).get("id", "")), "spawn_a", "spawn telegraph keeps request id")
		_assert_eq(String(Dictionary(Dictionary(ready[0]).get("payload", {})).get("enemy_id", "")), "runner", "spawn telegraph keeps game-owned payload")
	_assert_eq(lifecycle.pending_count(), 0, "spawn telegraph removes emitted request")

func _test_p1_numeric_effect_resolver() -> void:
	var script: Script = load(NumericEffectResolverPath)
	_assert_true(script != null, "numeric effect resolver script loads")
	if script == null:
		return
	var resolver = script.new()
	var result: Dictionary = resolver.resolve({
		"amount": 10,
		"add": 2,
		"multiplier": 1.5,
		"resistance": 0.25,
		"min": 1,
		"round": "ceil",
		"crit_chance": 0.5,
		"crit_multiplier": 2.0,
		"roll": 0.25,
		"tags": ["projectile"]
	})
	_assert_eq(int(result.get("amount", 0)), 27, "numeric effect resolver applies add, multiplier, resistance, crit, and round")
	_assert_true(bool(result.get("critical", false)), "numeric effect resolver reports critical roll")
	_assert_true(Array(result.get("tags", [])).has("projectile"), "numeric effect resolver preserves caller-owned tags")
	var blocked: Dictionary = resolver.resolve({"amount": 10, "resistance": 2.0, "min": 0, "round": "floor"})
	_assert_eq(int(blocked.get("amount", -1)), 0, "numeric effect resolver clamps fully resisted effect")

func _test_p1_status_effect_runtime() -> void:
	var script: Script = load(StatusEffectRuntimePath)
	_assert_true(script != null, "status effect runtime script loads")
	if script == null:
		return
	var runtime = script.new()
	runtime.add_effect({"id": "slow", "duration": 1.0, "tick_interval": 0.5, "max_stacks": 2, "payload": {"amount": 0.25}})
	runtime.add_effect({"id": "slow", "duration": 1.0, "tick_interval": 0.5, "max_stacks": 2, "payload": {"amount": 0.25}})
	runtime.add_effect({"id": "slow", "duration": 1.0, "tick_interval": 0.5, "max_stacks": 2, "payload": {"amount": 0.25}})
	_assert_eq(int(Dictionary(runtime.active_effect("slow")).get("stacks", 0)), 2, "status runtime caps stacks")
	var first_events: Array = runtime.advance(0.5)
	_assert_true(_has_event(first_events, "tick", "slow"), "status runtime emits tick event")
	var second_events: Array = runtime.advance(0.5)
	_assert_true(_has_event(second_events, "expired", "slow"), "status runtime emits expired event")
	_assert_true(Dictionary(runtime.active_effect("slow")).is_empty(), "status runtime removes expired effect")

func _test_p0_spawn_schedule_resolver() -> void:
	var script: Script = load(SpawnScheduleResolverPath)
	var picker_script: Script = load(WeightedPickerPath)
	var budget_script: Script = load(BudgetResolverPath)
	_assert_true(script != null, "spawn schedule resolver script loads")
	if script == null or picker_script == null or budget_script == null:
		return
	var resolver = script.new()
	resolver.configure([
		{
			"wave": 1,
			"spawn_batch": 2,
			"spawn_interval_ms": 1000,
			"spawn_pattern": {"pattern": "edge", "side": "top"},
			"spawn_telegraph_ms": 300,
			"entry_weights": [{"id": "drone", "weight": 1}, {"id": "sentinel", "weight": 9}]
		},
		{
			"wave": 3,
			"spawn_batch": 4,
			"spawn_interval_ms": 750,
			"spawn_pattern": {"pattern": "ring"},
			"spawn_telegraph_ms": 500,
			"entry_weights": [{"id": "drone", "weight": 1}, {"id": "sentinel", "weight": 99}],
			"role_limits": [{"role": "shooter", "max_alive": 1}]
		}
	], {
		"stage_key": "wave",
		"weight_entries_key": "entry_weights",
		"weighted_picker_script": picker_script,
		"budget_resolver_script": budget_script,
		"budget_sources": [{"source_key": "role_limits", "group": "role", "key_field": "role", "max_field": "max_alive"}]
	})
	_assert_eq(int(resolver.value_for_stage(2, "spawn_batch", -1)), 2, "spawn schedule uses latest entry at or before stage")
	_assert_eq(int(resolver.value_for_stage(3, "spawn_interval_ms", -1)), 750, "spawn schedule reads stage scalar")
	_assert_eq(int(resolver.value_for_stage(3, "spawn_telegraph_ms", -1)), 500, "spawn schedule reads telegraph scalar")
	_assert_eq(String(resolver.pattern_for_stage(3).get("pattern", "")), "ring", "spawn schedule reads pattern dictionary")
	var selected: Dictionary = resolver.select_entry_for_stage(
		3,
		[
			{"id": "drone", "role": "chaser"},
			{"id": "sentinel", "role": "shooter"}
		],
		{"id": "fallback"},
		0.99,
		{"roles": {"shooter": 1}},
		[{"group": "role", "entry_key": "role", "count_group": "roles"}]
	)
	_assert_eq(String(selected.get("id", "")), "drone", "spawn schedule applies generic budget limits before weighted pick")
	var uncapped: Dictionary = resolver.select_entry_for_stage(
		3,
		[
			{"id": "drone", "role": "chaser"},
			{"id": "sentinel", "role": "shooter"}
		],
		{"id": "fallback"},
		0.99,
		{},
		[{"group": "role", "entry_key": "role", "count_group": "roles"}]
	)
	_assert_eq(String(uncapped.get("id", "")), "sentinel", "spawn schedule weighted pick uses caller-owned candidate ids")

func _test_p0_rng_stream() -> void:
	var script: Script = load(RngStreamPath)
	_assert_true(script != null, "rng stream script loads")
	if script == null:
		return
	var first = script.new()
	first.configure(12345)
	var first_rolls := [
		first.next_float("spawn"),
		first.next_int("drop", 10),
		first.next_range_float("spread", -1.0, 1.0)
	]
	var snapshot: Dictionary = first.snapshot()
	var after_snapshot: int = int(first.next_int("spawn", 1000))
	first.restore(snapshot)
	_assert_eq(first.next_int("spawn", 1000), after_snapshot, "rng stream restores deterministic state")
	var second = script.new()
	second.configure(12345)
	var second_rolls := [
		second.next_float("spawn"),
		second.next_int("drop", 10),
		second.next_range_float("spread", -1.0, 1.0)
	]
	_assert_eq(first_rolls, second_rolls, "rng stream repeats sequence for same seed and stream names")
	var different = script.new()
	different.configure(54321)
	_assert_true(different.next_float("spawn") != first_rolls[0], "rng stream changes sequence for different seed")

func _test_p1_runtime_ledger() -> void:
	var script: Script = load(RuntimeLedgerPath)
	_assert_true(script != null, "runtime ledger script loads")
	if script == null:
		return
	var ledger = script.new()
	ledger.configure([
		{"id": "integrity", "min": 0, "max": 10, "default": 5},
		{"id": "signal", "min": 0, "default": 0}
	])
	_assert_eq(int(ledger.value("integrity")), 5, "ledger reads default value")
	var add_report: Dictionary = ledger.add("integrity", 8, "repair")
	_assert_eq(int(add_report.get("previous", -1)), 5, "ledger report records previous value")
	_assert_eq(int(add_report.get("current", -1)), 10, "ledger clamps add to max")
	_assert_true(bool(add_report.get("clamped", false)), "ledger report records clamp")
	ledger.add("signal", 3, "pickup")
	_assert_eq(int(ledger.value("signal")), 3, "ledger adds uncapped value")
	var snapshot: Dictionary = ledger.snapshot()
	ledger.set_value("signal", 99, "debug")
	ledger.restore(snapshot)
	_assert_eq(int(ledger.value("signal")), 3, "ledger restores snapshot")
	_assert_eq(ledger.events().size(), 3, "ledger records changed events")

func _test_p2_inventory_container() -> void:
	var script: Script = load(InventoryContainerPath)
	_assert_true(script != null, "inventory container script loads")
	if script == null:
		return
	var inventory = script.new()
	inventory.configure({"capacity": 2, "default_max_stack": 5})
	var first: Dictionary = inventory.add_item({"id": "shard", "quantity": 3, "max_stack": 5})
	_assert_true(bool(first.get("accepted", false)), "inventory accepts first stack")
	var second: Dictionary = inventory.add_item({"id": "shard", "quantity": 4, "max_stack": 5})
	_assert_eq(int(second.get("accepted_quantity", 0)), 4, "inventory fills existing stack and creates overflow stack")
	_assert_eq(int(inventory.quantity("shard")), 7, "inventory reports total quantity across stacks")
	var blocked: Dictionary = inventory.add_item({"id": "core", "quantity": 1, "max_stack": 1})
	_assert_true(not bool(blocked.get("accepted", true)), "inventory blocks item when capacity is full")
	_assert_eq(int(blocked.get("rejected_quantity", 0)), 1, "inventory reports rejected quantity")
	var removed: Dictionary = inventory.remove_item("shard", 6)
	_assert_eq(int(removed.get("removed_quantity", 0)), 6, "inventory removes quantity across stacks")
	_assert_eq(int(inventory.quantity("shard")), 1, "inventory keeps remaining quantity")
	var snapshot: Array = inventory.snapshot()
	inventory.clear()
	inventory.restore(snapshot)
	_assert_eq(int(inventory.quantity("shard")), 1, "inventory restores snapshot")

func _has_event(events: Array, event_type: String, id: String) -> bool:
	for item in events:
		if item is Dictionary:
			var entry := Dictionary(item)
			if String(entry.get("type", "")) == event_type and String(entry.get("id", "")) == id:
				return true
	return false

func _entry_ids(entries: Array) -> Array:
	var ids: Array = []
	for item in entries:
		if item is Dictionary:
			ids.append(String(Dictionary(item).get("id", "")))
	return ids

func _has_error_code(errors: Array, code: String) -> bool:
	for item in errors:
		if item is Dictionary and String(Dictionary(item).get("code", "")) == code:
			return true
	return false

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
