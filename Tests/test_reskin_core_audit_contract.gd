extends SceneTree

const AUDIT_CORE := "res://addons/shinokute_game_core/core/reskin_boundary_audit.gd"
const AGENTS_PATH := "res://AGENTS.md"
const DOCTRINE_PATH := "res://docs/reskin_core_skin_boundary.md"
const RUNBOOK_PATH := "res://docs/reskin_runbook.md"
const CHECKLIST_TEMPLATE_PATH := "res://docs/reskin_checklist_template.md"

var _passed := true

func _init() -> void:
	var audit_source := FileAccess.get_file_as_string(AUDIT_CORE)
	var agents := FileAccess.get_file_as_string(AGENTS_PATH)
	var doctrine := FileAccess.get_file_as_string(DOCTRINE_PATH)
	var runbook := FileAccess.get_file_as_string(RUNBOOK_PATH)
	var checklist := FileAccess.get_file_as_string(CHECKLIST_TEMPLATE_PATH)

	_assert_true(ResourceLoader.exists(AUDIT_CORE), "ShinokuteReskinBoundaryAudit should exist in core")
	_assert_true(audit_source.contains("class_name ShinokuteReskinBoundaryAudit"), "audit helper should expose a class_name")
	_assert_true(audit_source.contains("default_forbidden_core_markers"), "audit helper should expose default forbidden markers")
	_assert_true(audit_source.contains("scan_text"), "audit helper should scan text")
	_assert_true(audit_source.contains("scan_file"), "audit helper should scan files")
	_assert_true(audit_source.contains("scan_paths"), "audit helper should scan paths")

	if ResourceLoader.exists(AUDIT_CORE):
		var audit = load(AUDIT_CORE).new()
		var markers: Array = audit.default_forbidden_core_markers()
		for marker in ["CandyGameCore", "candySky", "assets/themes/", "Resources/Data/Themes/", "GameProgressionConfig"]:
			_assert_true(markers.has(marker), "audit marker list should include %s" % marker)
		var hits: Array = audit.scan_text("window.candySkyPointerEvent = 1\nvar p = 'res://assets/themes/candy/x.png'", "sample_core.gd")
		_assert_true(hits.size() >= 2, "audit should catch multiple forbidden markers")
		_assert_true(String(hits[0]).contains("sample_core.gd"), "audit findings should include source label")

	_assert_true(agents.contains("Core Learning Gate"), "agents guide should require Core Learning Gate")
	_assert_true(agents.contains("ShinokuteReskinBoundaryAudit"), "agents guide should require audit helper")
	_assert_true(doctrine.contains("ShinokuteReskinBoundaryAudit"), "doctrine should document audit helper")
	_assert_true(runbook.contains("Core Learning Gate"), "runbook should include Core Learning Gate")
	_assert_true(runbook.contains("Platform Input Matrix"), "runbook should include Platform Input Matrix")
	_assert_true(runbook.contains("Export Audit"), "runbook should include Export Audit")
	_assert_true(checklist.contains("Core Learning Gate"), "checklist should include Core Learning Gate")
	_report("test_reskin_core_audit_contract")

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
