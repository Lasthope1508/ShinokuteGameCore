extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const VfxAnchor = preload("res://Scripts/vfx_anchor.gd")
const VfxRoute = preload("res://Scripts/vfx_route.gd")

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var geometry = theme.get_asset_geometry("T")
	var anchors: Dictionary = VfxAnchor.get_anchor_points(geometry, Vector2(10, 20), 100.0, Vector2i(0, 0))

	passed = passed and _assert_true(anchors.has("route_junction"), "Anchors should expose route junction")
	passed = passed and _assert_vec2_close(anchors.get("route_junction", Vector2.ZERO), Vector2(60, 70), "T route junction should sit at tile center")
	passed = passed and _assert_true(anchors.get("route_junction", Vector2.ZERO).distance_to(anchors.get("energy_center", Vector2.ZERO)) > 1.0, "Route junction should be independent from shifted energy center")

	var straight: Array = VfxRoute.get_route_points(geometry, 3, 1, anchors)
	passed = passed and _assert_equal(straight.size(), 2, "T opposite ports should route straight without far junction")
	if straight.size() == 2:
		passed = passed and _assert_vec2_close(straight[0], anchors["west"], "Straight route should start at input port")
		passed = passed and _assert_vec2_close(straight[1], anchors["east"], "Straight route should end at output port")

	var branch: Array = VfxRoute.get_route_points(geometry, 3, 0, anchors)
	passed = passed and _assert_equal(branch.size(), 3, "T branch route should pass through junction")
	if branch.size() == 3:
		passed = passed and _assert_vec2_close(branch[1], anchors["route_junction"], "T branch should use route junction")

	var source_route: Array = VfxRoute.get_route_points(theme.get_asset_geometry("source"), -1, 1, VfxAnchor.get_anchor_points(theme.get_asset_geometry("source"), Vector2(10, 20), 100.0, Vector2i(0, 0)))
	passed = passed and _assert_equal(source_route.size(), 2, "Source route should use junction to output port")

	if passed:
		print("test_vfx_route_points: PASS")
		quit(0)
	else:
		print("test_vfx_route_points: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true

func _assert_vec2_close(actual: Vector2, expected: Vector2, message: String, epsilon: float = 0.02) -> bool:
	if actual.distance_to(expected) > epsilon:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
