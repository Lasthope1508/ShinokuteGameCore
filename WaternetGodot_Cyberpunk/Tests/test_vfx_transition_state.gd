extends SceneTree

const VfxTransitionStateScript = preload("res://Scripts/vfx_transition_state.gd")

func _init() -> void:
	var passed := true
	var previous := {
		Vector2i(0, 0): {"cell_pos": Vector2i(0, 0), "input_dir": -1, "output_dirs": [1], "age": 0.5},
		Vector2i(1, 0): {"cell_pos": Vector2i(1, 0), "input_dir": 3, "output_dirs": [1], "age": 0.4},
		Vector2i(2, 0): {"cell_pos": Vector2i(2, 0), "input_dir": 3, "output_dirs": [], "age": 0.3}
	}
	var current := {
		Vector2i(0, 0): {"cell_pos": Vector2i(0, 0), "input_dir": -1, "output_dirs": [2], "age": 0.0},
		Vector2i(0, 1): {"cell_pos": Vector2i(0, 1), "input_dir": 0, "output_dirs": [], "age": 0.0}
	}
	var transition: Dictionary = VfxTransitionStateScript.build(previous, current, Vector2i(0, 0), 9.5)

	passed = passed and _assert_equal(transition.get("changed_cell"), Vector2i(0, 0), "Changed cell should be stored")
	passed = passed and _assert_equal(transition.get("event_time"), 9.5, "Event time should be stored")
	passed = passed and _assert_true(transition.get("entered_cells", []).has(Vector2i(0, 1)), "Entered cells should include new powered cell")
	passed = passed and _assert_true(transition.get("lost_cells", []).has(Vector2i(1, 0)), "Lost cells should include removed powered cell")
	passed = passed and _assert_true(transition.get("lost_cells", []).has(Vector2i(2, 0)), "Lost cells should include old target")
	passed = passed and _assert_true(_has_contact(transition.get("entered_contacts", []), Vector2i(0, 0), 2, Vector2i(0, 1)), "Entered contacts should include source south")
	passed = passed and _assert_true(_has_contact(transition.get("lost_contacts", []), Vector2i(0, 0), 1, Vector2i(1, 0)), "Lost contacts should include broken east")
	passed = passed and _assert_true(_has_contact(transition.get("lost_contacts", []), Vector2i(1, 0), 1, Vector2i(2, 0)), "Lost contacts should include broken middle east")

	if passed:
		print("test_vfx_transition_state: PASS")
		quit(0)
	else:
		print("test_vfx_transition_state: FAIL")
		quit(1)

func _has_contact(contacts: Array, cell_pos: Vector2i, direction: int, neighbor_pos: Vector2i) -> bool:
	for contact in contacts:
		if contact.get("cell_pos") == cell_pos and int(contact.get("direction", -1)) == direction and contact.get("neighbor_pos") == neighbor_pos:
			return true
	return false

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
