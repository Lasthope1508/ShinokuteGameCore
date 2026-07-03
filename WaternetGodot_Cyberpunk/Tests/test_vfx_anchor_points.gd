extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"
const VfxAnchor = preload("res://Scripts/vfx_anchor.gd")

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var geometry = theme.pipe_l_geometry
	var anchors: Dictionary = VfxAnchor.get_anchor_points(geometry, Vector2(10, 20), 100.0, Vector2i(2, 3))

	passed = passed and _assert_vec2_close(anchors.get("center", Vector2.ZERO), Vector2(260, 370), "center anchor should use grid transform")
	passed = passed and _assert_vec2_close(anchors.get("north", Vector2.ZERO), Vector2(260, 320), "north anchor should use geometry port")
	passed = passed and _assert_vec2_close(anchors.get("east", Vector2.ZERO), Vector2(310, 370), "east anchor should use geometry port")
	passed = passed and _assert_vec2_close(anchors.get("south", Vector2.ZERO), Vector2(260, 420), "south anchor should use geometry port")
	passed = passed and _assert_vec2_close(anchors.get("west", Vector2.ZERO), Vector2(210, 370), "west anchor should use geometry port")
	passed = passed and _assert_vec2_close(anchors.get("energy_center", Vector2.ZERO), Vector2(278.55, 351.45), "energy center should use geometry energy_rect")

	if passed:
		print("test_vfx_anchor_points: PASS")
		quit(0)
	else:
		print("test_vfx_anchor_points: FAIL")
		quit(1)

func _assert_vec2_close(actual: Vector2, expected: Vector2, message: String, epsilon: float = 0.02) -> bool:
	if actual.distance_to(expected) > epsilon:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
