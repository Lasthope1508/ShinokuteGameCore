extends SceneTree

const GridPathQueryPath := "res://addons/shinokute_game_core/runtime/grid_path_query_2d.gd"
const AreaFieldRuntimePath := "res://addons/shinokute_game_core/runtime/area_field_runtime_2d.gd"
const WeightedPickerPath := "res://addons/shinokute_game_core/runtime/weighted_picker.gd"

var _passed := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_grid_path_query()
	_test_area_field_runtime()
	_test_weighted_picker_stable_order()
	_report("test_grid_area_core_contract")

func _test_grid_path_query() -> void:
	var script: Script = load(GridPathQueryPath)
	_assert_true(script != null, "grid path query script loads")
	if script == null:
		return
	var query = script.new()
	var config := {
		"width": 5,
		"height": 5,
		"blocked": [Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)]
	}
	var neighbors: Array = query.neighbors(Vector2i(1, 1), config)
	_assert_true(neighbors.has(Vector2i(1, 0)), "grid query returns orthogonal neighbor")
	_assert_true(not neighbors.has(Vector2i(2, 1)), "grid query excludes blocked neighbor")
	var path: Array = query.shortest_path(Vector2i(0, 2), Vector2i(4, 2), config)
	_assert_true(path.size() > 0, "grid query finds path around wall")
	_assert_eq(path[0], Vector2i(0, 2), "grid path includes start")
	_assert_eq(path[path.size() - 1], Vector2i(4, 2), "grid path includes target")
	_assert_true(not path.has(Vector2i(2, 2)), "grid path avoids blocked cells")
	var distances: Dictionary = query.distance_field(Vector2i(0, 0), config, 3)
	_assert_eq(int(distances.get(Vector2i(1, 0), -1)), 1, "grid distance field stores distance")
	_assert_true(not distances.has(Vector2i(4, 4)), "grid distance field respects max distance")
	var ray: Array = query.ray_cells(Vector2i(0, 0), Vector2i(4, 4), config)
	_assert_eq(ray[0], Vector2i(0, 0), "grid ray includes start")
	_assert_eq(ray[ray.size() - 1], Vector2i(4, 4), "grid ray includes end")
	_assert_true(ray.has(Vector2i(2, 2)), "grid ray follows diagonal cells")

func _test_area_field_runtime() -> void:
	var script: Script = load(AreaFieldRuntimePath)
	_assert_true(script != null, "area field runtime script loads")
	if script == null:
		return
	var runtime = script.new()
	runtime.configure({"cell_size": 1.0})
	runtime.add_field({
		"id": "smoke_zone",
		"field_type": "smoke",
		"position": Vector2(2.0, 2.0),
		"radius": 1.5,
		"intensity": 3.0,
		"duration": 2.0,
		"tick_interval": 1.0,
		"tags": ["opaque"],
		"source": "test"
	})
	var inside: Array = runtime.query_point(Vector2(2.5, 2.0))
	_assert_eq(inside.size(), 1, "area field query finds containing field")
	_assert_eq(String(Dictionary(inside[0]).get("field_type", "")), "smoke", "area field preserves caller-owned type")
	var first_events: Array = runtime.advance(1.0)
	_assert_true(_has_field_event(first_events, "tick", "smoke_zone"), "area field emits tick event")
	var second_events: Array = runtime.advance(1.0)
	_assert_true(_has_field_event(second_events, "expired", "smoke_zone"), "area field emits expired event")
	_assert_eq(runtime.active_fields().size(), 0, "area field removes expired field")

func _test_weighted_picker_stable_order() -> void:
	var script: Script = load(WeightedPickerPath)
	_assert_true(script != null, "weighted picker script loads")
	if script == null:
		return
	var picker = script.new()
	picker.configure([
		{"id": "zeta", "weight": 1},
		{"id": "alpha", "weight": 1},
		{"id": "middle", "weight": 1}
	], "id", "weight", {"stable_sort": true})
	_assert_eq(_entry_ids(picker.entries()), ["alpha", "middle", "zeta"], "weighted picker can sort entries stably by id")
	_assert_eq(String(picker.pick(0.0).get("id", "")), "alpha", "stable weighted picker first roll uses sorted order")

func _entry_ids(entries: Array) -> Array:
	var ids: Array = []
	for item in entries:
		if item is Dictionary:
			ids.append(String(Dictionary(item).get("id", "")))
	return ids

func _has_field_event(events: Array, event_type: String, id: String) -> bool:
	for item in events:
		if item is Dictionary:
			var entry := Dictionary(item)
			if String(entry.get("type", "")) == event_type and String(entry.get("id", "")) == id:
				return true
	return false

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
