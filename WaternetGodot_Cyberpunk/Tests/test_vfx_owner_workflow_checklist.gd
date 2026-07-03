extends SceneTree

const CHECKLIST_PATH = "res://docs/fake3d_vfx_checklist.md"
const USAGE_PATH = "res://docs/vfx_usage_library.md"

func _init() -> void:
	var passed := true
	var checklist_text := _read_text(CHECKLIST_PATH)
	var usage_text := _read_text(USAGE_PATH)
	var checklist_terms := [
		"Owner Question Gate",
		"visual intent",
		"effect role",
		"trigger rules",
		"layering order",
		"asset source",
		"performance budget",
		"acceptance evidence",
		"SSOT",
		"no fallback",
		"A-Z VFX Workflow"
	]
	var usage_terms := [
		"Owner question gate",
		"Checkpoint A",
		"Checkpoint Z",
		"design owner approval",
		"capture evidence"
	]
	passed = passed and _assert_true(checklist_text != "", "Fake3D VFX checklist should be readable")
	passed = passed and _assert_true(usage_text != "", "VFX usage library should be readable")
	for term in checklist_terms:
		passed = passed and _assert_true(checklist_text.find(term) >= 0, "Checklist should mention %s" % term)
	for term in usage_terms:
		passed = passed and _assert_true(usage_text.find(term) >= 0, "Usage library should mention %s" % term)

	if passed:
		print("test_vfx_owner_workflow_checklist: PASS")
		quit(0)
	else:
		print("test_vfx_owner_workflow_checklist: FAIL")
		quit(1)

func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
