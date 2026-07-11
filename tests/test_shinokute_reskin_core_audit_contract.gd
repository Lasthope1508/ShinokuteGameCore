extends SceneTree

const AUDIT_CORE := "res://addons/shinokute_game_core/core/reskin_boundary_audit.gd"
const RESKIN_DOC := "res://docs/reskin_checklist.md"
const VALIDATION_DOC := "res://docs/validation_runbook.md"
const AGENTS_DOC := "res://AGENTS.md"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	passed = _assert_true(ResourceLoader.exists(AUDIT_CORE), "Shinokute core should expose a reusable reskin boundary audit helper") and passed
	passed = _assert_file_contains(AUDIT_CORE, "class_name ShinokuteReskinBoundaryAudit", "Core audit helper should be globally named") and passed
	passed = _assert_file_contains(AUDIT_CORE, "default_forbidden_core_markers", "Core audit helper should own default forbidden game-leak markers") and passed
	passed = _assert_file_contains(AUDIT_CORE, "scan_text", "Core audit helper should scan text") and passed
	passed = _assert_file_contains(AUDIT_CORE, "scan_file", "Core audit helper should scan files") and passed
	passed = _assert_file_contains(AUDIT_CORE, "scan_paths", "Core audit helper should scan path lists") and passed

	if ResourceLoader.exists(AUDIT_CORE):
		var audit = load(AUDIT_CORE).new()
		var markers: Array = audit.default_forbidden_core_markers()
		for marker in ["CandyGameCore", "candySky", "assets/themes/", "Resources/Data/Themes/", "GameProgressionConfig"]:
			passed = _assert_true(markers.has(marker), "Core audit default markers should include %s" % marker) and passed
		var hits: Array = audit.scan_text("window.candySkyPointerEvent = 1\nvar p = 'res://assets/themes/candy_sky_islands/x.png'", "sample_core.gd")
		passed = _assert_true(hits.size() >= 2, "Core audit should report multiple forbidden markers in one source") and passed
		passed = _assert_true(String(hits[0]).contains("sample_core.gd"), "Core audit findings should include source label") and passed

	passed = _assert_file_contains(RESKIN_DOC, "ShinokuteReskinBoundaryAudit", "Reskin checklist should require the core boundary audit helper") and passed
	passed = _assert_file_contains(RESKIN_DOC, "Core Learning Gate", "Reskin checklist should record what core learned before moving to the next game") and passed
	passed = _assert_file_contains(RESKIN_DOC, "Platform Input Matrix", "Reskin checklist should require cross-platform input parity notes") and passed
	passed = _assert_file_contains(RESKIN_DOC, "Export Audit", "Reskin checklist should require export/PCK stale marker audit") and passed
	passed = _assert_file_contains(VALIDATION_DOC, "Gate Core: Boundary Audit", "Validation runbook should include a core/game boundary audit gate") and passed
	passed = _assert_file_contains(VALIDATION_DOC, "ShinokuteReskinBoundaryAudit", "Validation runbook should call out the core audit helper") and passed
	passed = _assert_file_contains(AGENTS_DOC, "Core learning reset rule", "Agent reset rules should require core learning audit") and passed
	passed = _assert_file_contains(AGENTS_DOC, "test_shinokute_reskin_core_audit_contract.gd", "Agent reset rules should name the reusable audit contract") and passed

	if passed:
		print("test_shinokute_reskin_core_audit_contract: PASS")
		quit(0)
	else:
		print("test_shinokute_reskin_core_audit_contract: FAIL")
		quit(1)

func _assert_file_contains(path: String, needle: String, message: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("%s: missing %s" % [message, path])
		return false
	var text := FileAccess.get_file_as_string(path)
	if not text.contains(needle):
		push_error("%s: missing '%s'" % [message, needle])
		return false
	return true

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true
