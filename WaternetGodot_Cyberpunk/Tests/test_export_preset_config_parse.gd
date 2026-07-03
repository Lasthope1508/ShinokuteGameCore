extends SceneTree

func _init() -> void:
	var config := ConfigFile.new()
	var err := config.load("res://export_presets.cfg")
	var passed := true
	passed = passed and _assert_equal(err, OK, "export_presets.cfg should parse as ConfigFile")
	passed = passed and _assert_true(config.has_section("preset.0"), "preset.0 should exist")
	passed = passed and _assert_true(config.has_section("preset.1"), "preset.1 should exist")
	passed = passed and _assert_equal(str(config.get_value("preset.0", "name", "")), "Web", "preset.0 should be Web")
	passed = passed and _assert_equal(str(config.get_value("preset.1", "name", "")), "Android", "preset.1 should be Android")
	if config.has_section("preset.0"):
		passed = passed and _assert_true(config.get_value("preset.0", "export_files", PackedStringArray()).size() > 0, "Web export_files should not be empty")
	if config.has_section("preset.1"):
		passed = passed and _assert_true(config.get_value("preset.1", "export_files", PackedStringArray()).size() > 0, "Android export_files should not be empty")

	if passed:
		print("test_export_preset_config_parse: PASS")
		quit(0)
	else:
		print("test_export_preset_config_parse: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s got %s" % [message, str(expected), str(actual)])
		return false
	return true
