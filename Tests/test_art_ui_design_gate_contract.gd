extends SceneTree

const GATE_DOC := "res://docs/art_ui_design_gate.md"
const INVENTORY_DOC := "res://docs/art_ui_asset_inventory_method.md"
const REGISTRY_DOC := "res://docs/core_module_registry.md"
const BOUNDARY_DOC := "res://docs/reskin_core_skin_boundary.md"
const AGENTS_DOC := "res://AGENTS.md"
const VALIDATOR := "res://tools/validate_art_ui_gate.py"
const OVERLAY_PRESENTATION_CORE := "res://addons/shinokute_game_core/ux/overlay_presentation_core.gd"
const TEMPLATE_DIR := "res://docs/templates/art_ui_gate/"

const TEMPLATE_FILES := [
	"GAME_ART_UI.template.md",
	"asset_count_matrix.template.md",
	"asset_coverage_matrix.template.md",
	"ui_composition_contracts.template.md",
	"screenshot_verification_checklist.template.md",
	"art_pipeline_validation_gate.template.md"
]

var _passed := true

func _init() -> void:
	var gate := FileAccess.get_file_as_string(GATE_DOC)
	var inventory := FileAccess.get_file_as_string(INVENTORY_DOC)
	var registry := FileAccess.get_file_as_string(REGISTRY_DOC)
	var boundary := FileAccess.get_file_as_string(BOUNDARY_DOC)
	var agents := FileAccess.get_file_as_string(AGENTS_DOC)
	var validator := FileAccess.get_file_as_string(VALIDATOR)
	var overlay_presentation := FileAccess.get_file_as_string(OVERLAY_PRESENTATION_CORE)

	_assert_true(not gate.is_empty(), "core art/UI design gate doc exists")
	_assert_true(gate.contains("Art Design Approval Gate"), "gate doc defines art design approval gate")
	_assert_true(gate.contains("RUNTIME_FIT_PASS is not final art design approval"), "gate doc separates runtime fit from art design")
	_assert_true(gate.contains("ART_DESIGN_PENDING"), "gate doc includes art design pending state")
	_assert_true(gate.contains("OWNER_APPROVED"), "gate doc includes owner approval state")
	_assert_true(gate.contains("game-owned"), "gate doc keeps assets and art game-owned")
	_assert_true(gate.contains("No fallback"), "gate doc preserves no-fallback policy")
	_assert_true(gate.contains("No legacy service fallback"), "gate doc defines no-fallback boundary")
	_assert_true(gate.contains("manual_placement"), "gate doc requires manual placement editor")
	_assert_true(gate.contains("READY_FOR_OWNER_ADJUSTMENT"), "gate doc defines manual placement ready status")
	_assert_true(gate.contains("OWNER_PLACEMENT_APPROVED"), "gate doc defines manual placement approved status")
	_assert_true(gate.contains("No agent-picked or draft placement may claim `RUNTIME_FIT_PASS`"), "gate doc blocks draft placement runtime fit")
	_assert_true(gate.contains("min_background_size"), "gate doc defines manual placement background quality")
	_assert_true(gate.contains("slot_kind"), "gate doc requires manual placement slot kind")
	_assert_true(gate.contains("sample_text"), "gate doc requires manual placement sample text")
	_assert_true(gate.contains("sample_asset"), "gate doc requires manual placement sample asset for image/icon payloads")
	_assert_true(gate.contains("clean_background_payload_slot_kinds_removed"), "gate doc requires clean background payload removal list")
	_assert_true(gate.contains("clean_background_audit"), "gate doc requires clean background audit proof")
	_assert_true(gate.contains("contains_runtime_text/icon/image/control = false"), "gate doc blocks baked runtime payloads")
	_assert_true(gate.contains("layer_contract"), "gate doc requires manual placement layer contract")
	_assert_true(gate.contains("repeated_region_groups"), "gate doc supports repeated region groups")
	_assert_true(gate.contains("repeated indexed editable regions"), "gate doc rejects repeated indexed editable regions")
	_assert_true(gate.contains("card_1_title"), "gate doc includes repeated-region anti-pattern example")
	_assert_true(gate.contains("Yellow frame coordinates"), "gate doc requires independent yellow frame panel")
	_assert_true(gate.contains("image_quality_profile"), "gate doc defines core image quality profile")
	_assert_true(gate.contains("mobile_high_quality"), "gate doc defines mobile high quality profile")

	_assert_true(not inventory.is_empty(), "core art/UI inventory method exists")
	_assert_true(inventory.contains("runtime surface -> asset family -> semantic key -> state variant -> proof requirement"), "inventory method counts surfaces before folders")
	_assert_true(inventory.contains("owner rect"), "inventory method requires owner rect")
	_assert_true(inventory.contains("text slot"), "inventory method requires text slots")
	_assert_true(inventory.contains("screenshot proof"), "inventory method requires screenshot proof")

	_assert_true(not validator.is_empty(), "core generic art/UI validator exists")
	_assert_true(validator.contains("validate_art_ui_gate"), "validator has stable entry name")
	_assert_true(validator.contains("--game-root"), "validator accepts game root")
	_assert_true(validator.contains("--contract"), "validator accepts game-owned contract")
	_assert_true(validator.contains("ART_DESIGN_PENDING"), "validator checks art design pending")
	_assert_true(validator.contains("RUNTIME_FIT_PASS"), "validator checks runtime fit")
	_assert_true(validator.contains("_require_manual_placement_rules"), "validator checks manual placement")
	_assert_true(validator.contains("_require_manual_background_quality"), "validator checks manual placement background quality")
	_assert_true(validator.contains("slot_kind"), "validator checks manual placement slot kind")
	_assert_true(validator.contains("sample_text"), "validator checks manual placement sample text")
	_assert_true(validator.contains("sample_asset"), "validator checks manual placement sample assets")
	_assert_true(validator.contains("_require_manual_clean_background_audit"), "validator checks clean background audit proof")
	_assert_true(validator.contains("contains_runtime_text"), "validator blocks baked runtime text in placement backgrounds")
	_assert_true(validator.contains("contains_runtime_icon"), "validator blocks baked runtime icons in placement backgrounds")
	_assert_true(validator.contains("contains_runtime_image"), "validator blocks baked runtime images in placement backgrounds")
	_assert_true(validator.contains("contains_runtime_control"), "validator blocks baked runtime controls in placement backgrounds")
	_assert_true(validator.contains("slot_kind == \"shell\""), "validator excludes shell frame from payload removal checks")
	_assert_true(validator.contains("_require_manual_layer_contract"), "validator checks manual placement layer contract")
	_assert_true(validator.contains("clean_background_payload_slot_kinds_removed"), "validator checks clean background payload removals")
	_assert_true(validator.contains("_manual_region_coverage"), "validator accepts derived repeated region coverage")
	_assert_true(validator.contains("_require_repeated_region_group_policy"), "validator rejects repeated indexed editable regions")
	_assert_true(validator.contains("_indexed_region_signature"), "validator detects repeated indexed region signatures")
	_assert_true(validator.contains("drag_once_apply_to_all_instances"), "validator requires drag-once repeated region rule")
	_assert_true(validator.contains("Yellow frame coordinates"), "validator checks manual placement independent layer panels")
	_assert_true(validator.contains("_require_image_quality_profile"), "validator checks image quality profile")
	_assert_true(validator.contains("IMAGE_QUALITY_PROFILES"), "validator owns image quality profiles")
	_assert_true(validator.contains("_require_no_fallback_contract_values"), "validator rejects fallback/default art UI contract keys")
	_assert_true(not validator.contains("LastHope"), "validator must not hardcode First Peace")
	_assert_true(not validator.contains("ArcaneCircuit"), "validator must not hardcode Arcane Circuit")

	_assert_true(not overlay_presentation.contains("fallback_size"), "overlay presentation core does not accept fallback_size config")

	for file_name in TEMPLATE_FILES:
		var template_name := String(file_name)
		var path := TEMPLATE_DIR + template_name
		var text := FileAccess.get_file_as_string(path)
		_assert_true(not text.is_empty(), "template exists: %s" % file_name)
		_assert_true(text.contains("{{GAME_NAME}}"), "template has game placeholder: %s" % template_name)

	_assert_true(registry.contains("ArtUiDesignGate"), "registry lists core art/UI design gate")
	_assert_true(registry.contains("doctrine.art-ui.gate"), "registry includes art/UI gate function tag")
	_assert_true(registry.contains("debug-publish"), "registry tags art/UI gate for debug-publish")
	_assert_true(boundary.contains("Art UI Design Gate"), "reskin boundary requires core art/UI gate")
	_assert_true(boundary.contains("RUNTIME_FIT_PASS is not final art design approval"), "reskin boundary separates runtime fit from art approval")
	_assert_true(agents.contains("docs/art_ui_design_gate.md"), "agent guide requires art/UI gate doc")
	_assert_true(agents.contains("tools/validate_art_ui_gate.py"), "agent guide requires generic art/UI validator")

	_report("test_art_ui_design_gate_contract")

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
