extends SceneTree

const DOC_PATH := "res://docs/reskin_core_skin_boundary.md"
const RUNBOOK_PATH := "res://docs/reskin_runbook.md"
const CHECKLIST_TEMPLATE_PATH := "res://docs/reskin_checklist_template.md"
const AGENTS_PATH := "res://AGENTS.md"
const README_PATH := "res://README.md"
const ADDON_README_PATH := "res://addons/shinokute_game_core/README.md"

var _passed := true

func _init() -> void:
	var doctrine := FileAccess.get_file_as_string(DOC_PATH)
	var runbook := FileAccess.get_file_as_string(RUNBOOK_PATH)
	var checklist := FileAccess.get_file_as_string(CHECKLIST_TEMPLATE_PATH)
	var agents := FileAccess.get_file_as_string(AGENTS_PATH)
	var readme := FileAccess.get_file_as_string(README_PATH)
	var addon_readme := FileAccess.get_file_as_string(ADDON_README_PATH)

	_assert_true(not doctrine.is_empty(), "reskin doctrine doc should exist")
	_assert_true(doctrine.contains("MUST READ BEFORE RESKIN"), "doctrine should be mandatory")
	_assert_true(doctrine.contains("Core = behavior"), "doctrine should define core boundary")
	_assert_true(doctrine.contains("Game skin ="), "doctrine should define game skin boundary")
	_assert_true(doctrine.contains("Function skin ="), "doctrine should define function skin boundary")
	_assert_true(doctrine.contains("No fallback"), "doctrine should preserve no-fallback rule")
	_assert_true(doctrine.contains("Function Skin Existing Asset Gate"), "doctrine should require existing asset gate")
	_assert_true(doctrine.contains("inventory the existing approved game assets first"), "doctrine should require asset inventory before new frames")
	_assert_true(doctrine.contains("Use an existing asset through the game SSOT"), "doctrine should require existing asset use through SSOT")
	_assert_true(doctrine.contains("role, ratio, crop, padding, and owner rect"), "doctrine should require asset role and geometry fit before reuse")
	_assert_true(doctrine.contains("Do not draw a new procedural frame"), "doctrine should forbid procedural frames when generated assets exist")
	_assert_true(doctrine.contains("Do not reuse multi-panel tray art as a field shell"), "doctrine should forbid uncropped tray art as field shell")
	_assert_true(doctrine.contains("contract test proving the chosen control uses an existing asset key"), "doctrine should require tests for function skin asset keys")
	_assert_true(doctrine.contains("Core owns local best score persistence, pending score persistence, submit retry handoff after username commit, and score comparison by configured sort direction."), "doctrine should make score persistence core-owned")
	_assert_true(doctrine.contains("Core must not auto-create username fallback during score submit."), "doctrine should forbid username fallback submit")
	_assert_true(doctrine.contains("Text Fit And Game Context Gate"), "doctrine should require text fit and game context gate")
	_assert_true(doctrine.contains("text and text-owner regions must fit the game screen, art style, and control role"), "doctrine should bind text to game context")
	_assert_true(not runbook.is_empty(), "reskin runbook should exist")
	_assert_true(runbook.contains("Phase 0: Read And Freeze Scope"), "runbook should start with read/scope phase")
	_assert_true(runbook.contains("Phase 4: Function Skin And Text Fit"), "runbook should include function skin and text fit phase")
	_assert_true(runbook.contains("Do not continue until text fits inside its owner region"), "runbook should block text overflow")
	_assert_true(runbook.contains("Ask whether this still looks like a game screen"), "runbook should force game-context review")
	_assert_true(not checklist.is_empty(), "reskin checklist template should exist")
	_assert_true(checklist.contains("Text Fit And Game Context"), "checklist should include text fit and game context section")
	_assert_true(checklist.contains("All labels fit inside their owner regions"), "checklist should require label fit")
	_assert_true(checklist.contains("Screen still reads as a game screen"), "checklist should require game screen context")
	_assert_true(agents.contains("docs/reskin_runbook.md"), "agents guide should link reskin runbook")
	_assert_true(agents.contains("docs/reskin_checklist_template.md"), "agents guide should link checklist template")
	_assert_true(readme.contains("reskin_core_skin_boundary.md"), "root README should link doctrine")
	_assert_true(readme.contains("reskin_runbook.md"), "root README should link reskin runbook")
	_assert_true(addon_readme.contains("reskin_core_skin_boundary.md"), "addon README should link doctrine")
	_report("test_reskin_boundary_doctrine")

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
