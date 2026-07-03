extends SceneTree

const USAGE_PATH = "res://docs/vfx_usage_library.md"

func _init() -> void:
	var passed := true
	var required_terms := [
		"60 FPS",
		"static_energy_overlay",
		"contact_spark",
		"directional_trail",
		"source_emission",
		"target_pulse",
		"target_core_blink",
		"idle_hum",
		"energy_stream",
		"path_wave",
		"lightning_arc",
		"rotation_spark",
		"disconnect_decay",
		"error_spark",
		"win_burst",
		"Trigger:",
		"Data source:",
		"Renderer:",
		"SSOT:",
		"Budget:",
		"Integration:"
	]
	passed = passed and _assert_true(FileAccess.file_exists(USAGE_PATH), "VFX usage library should exist")
	var text := ""
	if FileAccess.file_exists(USAGE_PATH):
		var file := FileAccess.open(USAGE_PATH, FileAccess.READ)
		text = file.get_as_text() if file != null else ""
	for term in required_terms:
		passed = passed and _assert_true(text.find(term) >= 0, "Usage library should mention %s" % term)

	if passed:
		print("test_vfx_usage_library: PASS")
		quit(0)
	else:
		print("test_vfx_usage_library: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
