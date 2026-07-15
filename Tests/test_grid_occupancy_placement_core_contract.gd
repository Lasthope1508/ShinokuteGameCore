extends SceneTree

const GridOccupancyPath := "res://addons/shinokute_game_core/runtime/grid_occupancy_2d.gd"
const GridPlacementPath := "res://addons/shinokute_game_core/runtime/grid_placement_query_2d.gd"

var _passed := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_grid_occupancy()
	_test_grid_placement_query()
	_report("test_grid_occupancy_placement_core_contract")

func _test_grid_occupancy() -> void:
	var script: Script = load(GridOccupancyPath)
	_assert_true(script != null, "grid occupancy script loads")
	if script == null:
		return
	var occupancy = script.new()
	occupancy.configure({
		"width": 5,
		"height": 5,
		"blocked": [Vector2i(4, 4)]
	})
	var hero_report: Dictionary = occupancy.place({
		"id": "hero",
		"cell": Vector2i(1, 1),
		"layer": "actor",
		"blocks": true,
		"tags": ["player"]
	})
	_assert_eq(String(hero_report.get("status", "")), "placed", "occupancy places blocking actor")
	occupancy.place({"id": "coin", "cell": Vector2i(1, 1), "layer": "pickup", "blocks": false})
	_assert_eq(occupancy.entries_at(Vector2i(1, 1)).size(), 2, "occupancy allows non-blocking stack")
	_assert_true(occupancy.is_occupied(Vector2i(1, 1), {"blocking_only": true}), "occupancy detects blocking entries")
	var blocked_report: Dictionary = occupancy.place({"id": "enemy", "cell": Vector2i(1, 1), "layer": "actor", "blocks": true})
	_assert_eq(String(blocked_report.get("status", "")), "blocked", "occupancy blocks second blocking actor")
	_assert_eq(String(blocked_report.get("reason", "")), "occupied", "occupancy reports occupied reason")
	var move_report: Dictionary = occupancy.move("hero", Vector2i(2, 1))
	_assert_eq(String(move_report.get("status", "")), "moved", "occupancy moves actor")
	_assert_eq(String(Dictionary(occupancy.entry("hero")).get("id", "")), "hero", "occupancy looks up entry by id")
	_assert_true(not occupancy.is_occupied(Vector2i(1, 1), {"blocking_only": true}), "occupancy clears old blocking cell")
	var wall_report: Dictionary = occupancy.move("hero", Vector2i(4, 4))
	_assert_eq(String(wall_report.get("status", "")), "blocked", "occupancy blocks terrain move")
	_assert_eq(String(wall_report.get("reason", "")), "blocked_cell", "occupancy reports blocked cell reason")
	var snapshot: Dictionary = occupancy.snapshot()
	var restored = script.new()
	restored.restore(snapshot)
	_assert_eq(String(Dictionary(restored.entry("hero")).get("id", "")), "hero", "occupancy restores entries")

func _test_grid_placement_query() -> void:
	var script: Script = load(GridPlacementPath)
	_assert_true(script != null, "grid placement script loads")
	if script == null:
		return
	var occupancy_script: Script = load(GridOccupancyPath)
	_assert_true(occupancy_script != null, "grid occupancy script loads for placement")
	if occupancy_script == null:
		return
	var occupancy = occupancy_script.new()
	occupancy.configure({
		"width": 5,
		"height": 5,
		"blocked": [Vector2i(2, 1)]
	})
	occupancy.place({"id": "hero", "cell": Vector2i(1, 1), "blocks": true})
	occupancy.place({"id": "coin", "cell": Vector2i(1, 2), "blocks": false})
	var query = script.new()
	var cells: Array = query.sorted_candidates(Vector2i(1, 1), {
		"width": 5,
		"height": 5,
		"radius": 2,
		"blocked": [Vector2i(2, 1)],
		"occupancy": occupancy
	})
	_assert_true(cells.has(Vector2i(1, 2)), "placement keeps non-blocking occupied cell candidate")
	_assert_true(not cells.has(Vector2i(1, 1)), "placement excludes blocking occupied origin")
	_assert_true(not cells.has(Vector2i(2, 1)), "placement excludes blocked terrain")
	var first: Dictionary = query.first_available(Vector2i(1, 1), {
		"width": 5,
		"height": 5,
		"radius": 2,
		"blocked": [Vector2i(2, 1)],
		"occupancy": occupancy
	})
	_assert_eq(String(first.get("status", "")), "found", "placement finds first available cell")
	_assert_eq(Vector2i(first.get("cell", Vector2i.ZERO)), Vector2i(1, 2), "placement uses stable nearest order")

func _assert_true(value: bool, label: String) -> void:
	if not value:
		_passed = false
		push_error("FAIL: %s" % label)

func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_passed = false
		push_error("FAIL: %s expected=%s actual=%s" % [label, str(expected), str(actual)])

func _report(label: String) -> void:
	if _passed:
		print("%s: PASS" % label)
		quit(0)
	else:
		print("%s: FAIL" % label)
		quit(1)
