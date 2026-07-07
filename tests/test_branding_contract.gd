extends SceneTree

const THEME_PATH := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"
const MANIFEST := "res://docs/asset_manifest.md"
const CHECKLIST := "res://docs/reskin_checklist.md"
const STATE := "res://docs/reskin_state.md"
const PROJECT := "res://project.godot"

func _init() -> void:
	var passed := true
	var theme := load(THEME_PATH)
	passed = passed and _assert_true(theme != null, "Candy theme should load")
	if theme != null:
		passed = passed and _assert_equal(theme.get("branding_icon_source_path"), "res://assets/themes/candy_sky_islands/branding/app_icon_source.png", "Branding icon source path should be explicit")
		passed = passed and _assert_equal(theme.get("branding_splash_path"), "res://assets/themes/candy_sky_islands/branding/splash_candy_sky_islands.png", "Branding splash path should be explicit")
		passed = passed and _assert_equal(theme.get("branding_logo_path"), "res://assets/themes/candy_sky_islands/branding/logo_candy_sky_islands.png", "Branding logo path should be explicit")
		passed = passed and _assert_equal(theme.get("branding_display_name"), "Candy Sky Islands", "Branding display name should match exact logo text")
	passed = passed and _assert_file_contains(MANIFEST, "app.icon", "Manifest should include app icon row")
	passed = passed and _assert_file_contains(MANIFEST, "app.splash", "Manifest should include splash row")
	passed = passed and _assert_file_contains(MANIFEST, "app.logo.main", "Manifest should include logo row")
	passed = passed and _assert_file_contains(CHECKLIST, "### Checkpoint 4: Branding", "Checklist should include branding checkpoint")
	passed = passed and _assert_file_contains(STATE, "Branding", "State should mention branding gate")
	passed = passed and _assert_file_contains(PROJECT, "config/icon=\"res://icon.png\"", "Project should keep root icon setting")
	passed = passed and _assert_file_contains(PROJECT, "boot_splash/image=\"res://splash-screen.png\"", "Project should keep root splash setting")
	if passed:
		print("test_branding_contract: PASS")
		quit(0)
	else:
		print("test_branding_contract: FAIL")
		quit(1)

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true

func _assert_file_contains(path: String, needle: String, message: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("%s: missing %s" % [message, path])
		return false
	var text := FileAccess.get_file_as_string(path)
	if not text.contains(needle):
		push_error("%s: missing '%s'" % [message, needle])
		return false
	return true
