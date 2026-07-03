extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)

	passed = passed and _assert_true(_has_property(theme, "energy_sheet_manifest_path"), "Theme should own energy sheet manifest path")
	passed = passed and _assert_true(theme.has_method("validate_energy_sheet_manifest"), "Theme should validate energy sheet manifest")

	if theme.has_method("validate_energy_sheet_manifest"):
		var errors: Array = theme.validate_energy_sheet_manifest()
		passed = passed and _assert_equal(errors.size(), 0, "Cyber energy sheet manifest should validate cleanly")
		var broken_theme = theme.duplicate(true)
		broken_theme.energy_sheet_manifest_path = "res://Assets/Themes/cyberpunk_theme/energy_sheets/missing_manifest.json"
		errors = broken_theme.validate_energy_sheet_manifest()
		passed = passed and _assert_true(errors.size() > 0, "Missing energy manifest should fail validation")

	if passed:
		print("test_energy_sheet_manifest_contract: PASS")
		quit(0)
	else:
		print("test_energy_sheet_manifest_contract: FAIL")
		quit(1)

func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if property.get("name", "") == property_name:
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
