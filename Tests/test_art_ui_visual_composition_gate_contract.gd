extends SceneTree

const GATE_DOC := "res://docs/art_ui_design_gate.md"
const INVENTORY_DOC := "res://docs/art_ui_asset_inventory_method.md"
const VALIDATOR := "res://tools/validate_art_ui_gate.py"
const TEMPLATE_CONTRACT := "res://docs/templates/art_ui_gate/art_ui_gate_contract.template.json"

var _passed := true

func _init() -> void:
	var gate := FileAccess.get_file_as_string(GATE_DOC)
	var inventory := FileAccess.get_file_as_string(INVENTORY_DOC)
	var validator := FileAccess.get_file_as_string(VALIDATOR)
	var template := FileAccess.get_file_as_string(TEMPLATE_CONTRACT)

	for text in [gate, inventory, validator, template]:
		_assert_true(text.contains("visual_composition_rules"), "visual composition rules are core-standard contract input")
		_assert_true(text.contains("max_surface_viewport_area_ratio"), "surface viewport density is core-standard")
		_assert_true(text.contains("text_safe_zones"), "text safe zones are core-standard")
		_assert_true(text.contains("art_safe_zones"), "art safe zones are core-standard")
		_assert_true(text.contains("ornament_exclusion_zones"), "ornament exclusion zones are core-standard")
		_assert_true(text.contains("slot_rects"), "slot rect validation is core-standard")
		_assert_true(text.contains("safe_padding"), "safe padding is core-standard")
		_assert_true(text.contains("manual_placement"), "manual placement editor gate is core-standard")
		_assert_true(text.contains("rect semantic boundary"), "rect semantic boundary is core-standard")
		_assert_true(text.contains("control_owner_rect"), "control owner rect semantics are core-standard")
		_assert_true(text.contains("visual_shell_rect"), "visual shell rect semantics are core-standard")
		_assert_true(text.contains("coordinate_space"), "coordinate-space declaration is core-standard")
		_assert_true(text.contains("READY_FOR_OWNER_ADJUSTMENT"), "manual placement ready status is core-standard")
		_assert_true(text.contains("OWNER_PLACEMENT_APPROVED"), "manual placement approved status is core-standard")
		_assert_true(text.contains("min_background_size"), "manual placement background quality is core-standard")
		_assert_true(text.contains("image_quality_profile"), "image quality profile is core-standard")
		_assert_true(text.contains("mobile_high_quality"), "mobile high quality profile is core-standard")

	_assert_true(validator.contains("_require_visual_composition_rules"), "validator enforces visual composition rules")
	_assert_true(validator.contains("_require_manual_placement_rules"), "validator enforces manual placement rules")
	_assert_true(validator.contains("_require_manual_background_quality"), "validator enforces manual placement background quality")
	_assert_true(validator.contains("_require_manual_editor_navigation"), "validator enforces manual placement navigation")
	_assert_true(validator.contains("_require_image_quality_profile"), "validator enforces image quality profile")
	_assert_true(validator.contains("visual composition rule missing for runtime-fit screen"), "validator requires rules for every runtime-fit screen")
	_assert_true(validator.contains("manual placement editor missing for runtime-fit screen"), "validator requires manual editor for every runtime-fit screen")
	_assert_true(validator.contains("below min"), "validator blocks low-resolution placement backgrounds")
	_assert_true(validator.contains("text_safe_zones missing matching art_safe_zones rect"), "validator requires each text zone to have matching art-safe zone")
	_assert_true(validator.contains("_rects_overlap"), "validator can block overlapping UI/art zones")
	_assert_true(validator.contains("visual composition rule"), "validator failure names visual composition rules")
	_assert_true(not validator.contains("LastHope"), "visual composition gate stays game-agnostic")
	_assert_true(not validator.contains("ArcaneCircuit"), "visual composition gate stays skin-agnostic")

	_report("test_art_ui_visual_composition_gate_contract")

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
