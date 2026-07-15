extends SceneTree

const ContentPackPath := "res://addons/shinokute_game_core/runtime/content_pack.gd"
const RequirementResolverPath := "res://addons/shinokute_game_core/runtime/requirement_resolver.gd"

var _passed := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_content_pack_resolves_inheritance_refs_and_queries()
	_test_content_pack_reports_invalid_data()
	_report("test_content_pack_core_contract")

func _test_content_pack_resolves_inheritance_refs_and_queries() -> void:
	var script: Script = load(ContentPackPath)
	_assert_true(script != null, "content pack script loads")
	if script == null:
		return
	var pack = script.new()
	pack.configure(_valid_pack(), {"requirement_resolver_script": load(RequirementResolverPath)})
	_assert_true(pack.is_valid(), "valid content pack has no errors")
	_assert_eq(pack.pack_id(), "test_pack", "pack stores id")
	_assert_eq(pack.version(), "1.0.0", "pack stores version")
	_assert_eq(pack.dependencies(), ["base_pack"], "pack stores dependencies")

	var bolt: Dictionary = pack.entry("projectiles", "pierce_bolt")
	_assert_eq(int(bolt.get("speed", 0)), 320, "copy_from inherits base speed")
	_assert_eq(int(bolt.get("damage", 0)), 3, "child overrides inherited damage")
	_assert_true(Array(bolt.get("tags", [])).has("projectile"), "copy_from keeps base tag")
	_assert_true(Array(bolt.get("tags", [])).has("piercing"), "copy_from keeps child tag")
	_assert_true(not pack.entry("projectiles", "projectile_base").is_empty(), "direct lookup can fetch abstract entry")

	var projectiles: Array = pack.entries("projectiles")
	_assert_eq(projectiles.size(), 1, "normal table reads hide abstract entries")
	_assert_eq(String(Dictionary(projectiles[0]).get("id", "")), "pierce_bolt", "normal table reads keep concrete entry")

	var options: Array = pack.query("upgrades", {
		"tags": ["projectile"],
		"context": {"flags": {"wave_2": true}}
	})
	_assert_eq(options.size(), 1, "query filters by tag and requirements")
	_assert_eq(String(Dictionary(options[0]).get("id", "")), "pierce_tuning", "query returns eligible id")

	var pool_items: Array = pack.resolve_group("groups", "starter_pool")
	_assert_eq(pool_items.size(), 1, "group resolver returns concrete refs")
	_assert_eq(String(Dictionary(pool_items[0]).get("id", "")), "pierce_bolt", "group resolver follows table/id ref")
	_assert_eq(int(Dictionary(pool_items[0]).get("weight", 0)), 7, "group resolver keeps group item metadata")

func _test_content_pack_reports_invalid_data() -> void:
	var script: Script = load(ContentPackPath)
	_assert_true(script != null, "content pack script loads for invalid pack")
	if script == null:
		return
	var pack = script.new()
	pack.configure(_invalid_pack(), {"requirement_resolver_script": load(RequirementResolverPath)})
	var errors: Array = pack.errors()
	_assert_true(not pack.is_valid(), "invalid content pack reports invalid state")
	_assert_true(_has_error_code(errors, "duplicate_id"), "content pack reports duplicate ids")
	_assert_true(_has_error_code(errors, "missing_ref"), "content pack reports missing cross-table refs")
	_assert_true(_has_error_code(errors, "copy_from_missing"), "content pack reports missing inheritance parent")

func _valid_pack() -> Dictionary:
	return {
		"id": "test_pack",
		"version": "1.0.0",
		"dependencies": ["base_pack"],
		"tables": {
			"projectiles": [
				{"id": "projectile_base", "abstract": true, "type": "bullet", "speed": 320, "damage": 1, "tags": ["projectile"]},
				{"id": "pierce_bolt", "copy_from": "projectile_base", "damage": 3, "pierce": 1, "tags": ["piercing"]}
			],
			"upgrades": [
				{"id": "pierce_tuning", "type": "upgrade", "projectile_id": "pierce_bolt", "tags": ["projectile"], "requirements": {"flag": "wave_2"}},
				{"id": "locked_arc", "type": "upgrade", "projectile_id": "pierce_bolt", "tags": ["projectile"], "requirements": {"flag": "wave_5"}}
			],
			"groups": [
				{"id": "starter_pool", "items": [{"ref": "projectiles/pierce_bolt", "weight": 7}]}
			]
		},
		"schemas": {
			"projectiles": {"required": ["id"], "types": {"id": TYPE_STRING, "speed": TYPE_INT, "damage": TYPE_INT}},
			"upgrades": {"required": ["id", "projectile_id"], "refs": [{"field": "projectile_id", "table": "projectiles"}]},
			"groups": {"required": ["id"]}
		}
	}

func _invalid_pack() -> Dictionary:
	return {
		"id": "bad_pack",
		"version": "1.0.0",
		"tables": {
			"projectiles": [
				{"id": "bolt"},
				{"id": "bolt"},
				{"id": "orphan_child", "copy_from": "missing_base"}
			],
			"upgrades": [
				{"id": "bad_upgrade", "projectile_id": "missing_projectile"}
			]
		},
		"schemas": {
			"projectiles": {"required": ["id"]},
			"upgrades": {"required": ["id", "projectile_id"], "refs": [{"field": "projectile_id", "table": "projectiles"}]}
		}
	}

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

func _report(name: String) -> void:
	if _passed:
		print("%s: PASS" % name)
		quit(0)
	else:
		print("%s: FAIL" % name)
		quit(1)
