extends SceneTree

const VisibilityFieldPath := "res://addons/shinokute_game_core/runtime/visibility_field_2d.gd"
const MapLayoutGeneratorPath := "res://addons/shinokute_game_core/runtime/map_layout_generator_2d.gd"

var _passed := true

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_visibility_field()
	_test_map_layout_generator()
	_report("test_visibility_map_layout_core_contract")

func _test_visibility_field() -> void:
	var script: Script = load(VisibilityFieldPath)
	_assert_true(script != null, "visibility field script loads")
	if script == null:
		return
	var visibility = script.new()
	var config := {
		"width": 7,
		"height": 5,
		"radius": 5,
		"opaque": [Vector2i(3, 2)]
	}
	var visible: Dictionary = visibility.compute_visible(Vector2i(1, 2), config)
	_assert_true(bool(visible.get(Vector2i(1, 2), false)), "visibility includes origin")
	_assert_true(bool(visible.get(Vector2i(2, 2), false)), "visibility includes cell before opaque blocker")
	_assert_true(bool(visible.get(Vector2i(3, 2), false)), "visibility includes opaque blocker cell")
	_assert_true(not bool(visible.get(Vector2i(4, 2), false)), "visibility excludes cell behind opaque blocker")
	var seen: Dictionary = visibility.update_seen({Vector2i(6, 4): true}, visible)
	_assert_true(bool(seen.get(Vector2i(6, 4), false)), "seen update preserves previous seen cells")
	_assert_true(bool(seen.get(Vector2i(2, 2), false)), "seen update stores visible cells")
	var report: Dictionary = visibility.query_cell(Vector2i(6, 4), visible, seen)
	_assert_eq(bool(report.get("visible", true)), false, "visibility query reports not currently visible")
	_assert_eq(bool(report.get("seen", false)), true, "visibility query reports previously seen")
	_assert_eq(String(report.get("state", "")), "seen", "visibility query separates seen from visible")

func _test_map_layout_generator() -> void:
	var script: Script = load(MapLayoutGeneratorPath)
	_assert_true(script != null, "map layout generator script loads")
	if script == null:
		return
	var generator = script.new()
	var layout: Dictionary = generator.build_layout({
		"width": 20,
		"height": 12,
		"rooms": [
			{"id": "start", "position": Vector2i(1, 1), "size": Vector2i(4, 4)},
			{"id": "exit", "position": Vector2i(12, 6), "size": Vector2i(5, 4)}
		],
		"connect": "sequence"
	})
	var rooms: Array = Array(layout.get("rooms", []))
	_assert_eq(rooms.size(), 2, "map layout preserves normalized room count")
	_assert_eq(Vector2i(Dictionary(rooms[0]).get("center", Vector2i.ZERO)), Vector2i(3, 3), "map layout computes first room center")
	_assert_eq(Vector2i(Dictionary(rooms[1]).get("center", Vector2i.ZERO)), Vector2i(14, 8), "map layout computes second room center")
	var corridors: Array = Array(layout.get("corridors", []))
	_assert_eq(corridors.size(), 1, "map layout builds sequence corridor")
	var corridor := Dictionary(corridors[0])
	var cells: Array = Array(corridor.get("cells", []))
	_assert_true(cells.has(Vector2i(3, 3)), "map corridor includes source center")
	_assert_true(cells.has(Vector2i(14, 8)), "map corridor includes target center")
	_assert_true(Array(layout.get("floor_cells", [])).has(Vector2i(1, 1)), "map layout emits room floor cells")
	_assert_true(Array(layout.get("floor_cells", [])).has(Vector2i(14, 8)), "map layout emits corridor floor cells")
	_assert_eq(String(corridor.get("from", "")), "start", "map corridor keeps caller-owned source id")
	_assert_eq(String(corridor.get("to", "")), "exit", "map corridor keeps caller-owned target id")

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
