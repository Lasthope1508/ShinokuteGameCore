extends SceneTree

const LEVEL_GENERATOR_PATH = "res://Scripts/level_generator.gd"

func _init() -> void:
	var passed := true
	var generator = load(LEVEL_GENERATOR_PATH)

	var grid_signatures := {}

	for i in range(24):
		var level = generator.generate_level(7, true)
		passed = passed and _assert_equal(level.get("width"), 7, "Level 7 should keep difficulty width")
		passed = passed and _assert_equal(level.get("height"), 7, "Level 7 should keep difficulty height")

		var source: Dictionary = level.get("source", {})
		var target: Dictionary = level.get("target", {})
		passed = passed and _assert_equal(Vector2i(source.get("x", -1), source.get("y", -1)), Vector2i(0, 0), "Source should stay fixed at top-left")
		passed = passed and _assert_equal(Vector2i(target.get("x", -1), target.get("y", -1)), Vector2i(6, 6), "Target should stay fixed at bottom-right")
		grid_signatures[_grid_signature(level.get("grid", []))] = true

	passed = passed and _assert_true(
		grid_signatures.size() > 1,
		"Randomized generation should produce varied pipe layouts"
	)

	if passed:
		print("test_level_randomization: PASS")
		quit(0)
	else:
		print("test_level_randomization: FAIL")
		quit(1)

func _grid_signature(grid: Array) -> String:
	var parts := []
	for cell in grid:
		parts.append("%s:%s:%s" % [
			str(cell.get("type", "")),
			str(cell.get("rotation", "")),
			str(cell.get("ports", []))
		])
	return "|".join(parts)

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
