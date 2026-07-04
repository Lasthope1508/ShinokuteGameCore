extends SceneTree

func _init() -> void:
	var passed := true
	var export_presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	var theme_manager := FileAccess.get_file_as_string("res://Resources/Globals/ThemeManager.gd")
	var mcp_runtime := FileAccess.get_file_as_string("res://addons/godot_mcp_runtime/mcp_runtime_autoload.gd")
	var mcp_legacy := FileAccess.get_file_as_string("res://Scripts/mcp_interaction_server.gd")
	var firebase_config := FileAccess.get_file_as_string("res://firebase.json")
	passed = passed and _assert_true(not export_presets.is_empty(), "export_presets.cfg should exist")
	for required_text in [
		"custom_features=\"production\"",
		"export_path=\"Export/glyphflow_arrays.html\"",
		"export_path=\"Export/glyphflow_arrays.aab\"",
		"include_filter=\"Resources/levels.json,Assets/Themes/cyberpunk_theme/energy_sheets/manifest.json,Audio/Music/cyberpunk_theme/manifest.json\"",
		"res://Assets/UI/cyberpunk_theme/generated/production/dark/bottom_timer_digits/timer_digits_dark_atlas.png",
		"package/unique_name=\"com.shinokutestudio.glyphflowarrays\"",
		"package/name=\"Glyphflow Arrays\"",
		"keystore/release=\"C:/Users/Admin/.gemini/antigravity/secrets/glyphflow_arrays.keystore\"",
		"keystore/release_user=\"glyphflow_arrays\"",
		"Export/*",
		"Export_clean/*",
		"debug/*",
		"Assets/UI/cyberpunk_theme/source_archive/*",
		"Tests/*",
		"docs/*",
		"*.md",
		"addons/auto_reload/*",
		"addons/godot_mcp_editor/*",
		"Assets/UI/cyberpunk_theme/reference_pack/*",
		"Assets/UI/cyberpunk_theme/component_refs/*",
		"Assets/UI/cyberpunk_theme/generated/style_trial*",
		"Assets/UI/cyberpunk_theme/generated/production/*/*_raw.png",
		"Assets/UI/cyberpunk_theme/generated/production/*/*_alpha.png",
		"Assets/UI/cyberpunk_theme/generated/production/*/*.json",
		"Assets/UI/cyberpunk_theme/generated/production/*/floating_*_pressed_photoroom.png",
		"Assets/UI/cyberpunk_theme/generated/production/*/floating_*_disabled_photoroom.png",
		"Assets/UI/cyberpunk_theme/generated/production/*/floating_*_modal_blocked_photoroom.png",
		"Assets/UI/cyberpunk_theme/generated/production/*/bottom_reserve_layer_photoroom.png",
		"Assets/Sprites/bloxchain_logo*",
		"Assets/Themes/cyberpunk_theme/energy_sheets_ai/*",
		"Assets/Themes/fruit_theme/*",
		"Assets/Themes/chaos/*",
		"Assets/Themes/garden_theme/*",
		"Assets/Themes/wood_theme/*",
		"Resources/Data/Themes/garden_theme.tres",
		"Resources/Data/Themes/wood_theme.tres",
		"Resources/Data/Themes/hacknet_theme.tres",
		"Audio/Music/Gameplay*",
		"Audio/Sfx/default/*",
		"Scenes/Gameplay/DebugGameplay*",
		"test_out*"
	]:
		passed = passed and _assert_true(export_presets.contains(required_text), "Export preset should contain %s" % required_text)
	for required_uid_cache_exclude in [".godot/uid_cache.bin", ".godot/global_script_class_cache.cfg"]:
		passed = passed and _assert_true(export_presets.contains(required_uid_cache_exclude), "Export preset should exclude editor cache %s" % required_uid_cache_exclude)
	for forbidden_pack_path in [
		"res://debug/",
		"backup_cyberpunk_assets_before"
	]:
		passed = passed and _assert_true(not export_presets.contains(forbidden_pack_path), "Export preset should not directly include forbidden pack path %s" % forbidden_pack_path)
	passed = passed and _assert_true(not DirAccess.dir_exists_absolute("res://Assets/Themes/cyberpunk_theme/energy_sheets_ai"), "Forbidden energy_sheets_ai fallback directory should not exist")
	passed = passed and _assert_true(not DirAccess.dir_exists_absolute("res://scratch"), "Scratch/reference workbench directory should not exist in production project")
	passed = passed and _assert_true(not FileAccess.file_exists("res://Audio/Music/Gameplay.ogg"), "Forbidden root BGM fallback file should not exist")
	passed = passed and _assert_true(not DirAccess.dir_exists_absolute("res://Audio/Sfx/default"), "Forbidden default SFX fallback directory should not exist")
	passed = passed and _assert_true(not FileAccess.file_exists("res://test_out.ogg"), "Forbidden root test audio artifact should not exist")
	passed = passed and _assert_true(not FileAccess.file_exists("res://Tests/last_energy_stream_debug.png"), "Forbidden test screenshot artifact should not exist")
	passed = passed and _assert_true(not FileAccess.file_exists("res://Scenes/Gameplay/DebugGameplay.tscn"), "Forbidden debug gameplay scene should not exist in production project")
	passed = passed and _assert_true(not export_presets.contains("export_path=\"Export/blockpuzzle.html\""), "Web export path should not use old blockpuzzle name")
	passed = passed and _assert_true(not export_presets.contains("export_path=\"Export/bloxchain.aab\""), "Android export path should not use old bloxchain name")
	passed = passed and _assert_true(not export_presets.contains("export_filter=\"all_resources\""), "Release exports should not pack all resources")
	for include_line in export_presets.split("\n"):
		if not include_line.begins_with("include_filter="):
			continue
		for broad_include in ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.wav", "*.ogg", "*.tres", "Assets/**"]:
			passed = passed and _assert_true(not include_line.contains(broad_include), "Release include_filter should not use broad marker %s" % broad_include)
	passed = passed and _assert_true(not export_presets.contains("include_filter=\"*.webp,*.png,*.wav,*.tres,*.ogg\""), "Web include filter should not wildcard-pack debug/old texture assets")
	for required_runtime_script in [
		"res://Scripts/connection_solver.gd",
		"res://Scripts/flow_visual_state.gd",
		"res://Scripts/level_data.gd",
		"res://Scripts/level_generator.gd",
		"res://Scripts/bottom_timer_digits.gd",
		"res://Scripts/pipe_grid.gd",
		"res://Scripts/pipe_vfx_layer.gd",
		"res://Scripts/pipe_visual_mapping.gd",
		"res://Scripts/vfx_anchor.gd",
		"res://Scripts/vfx_route.gd",
		"res://Scripts/vfx_transition_state.gd"
	]:
		passed = passed and _assert_true(export_presets.contains("\"%s\"" % required_runtime_script), "Release export_files should include runtime preload script %s" % required_runtime_script)
	passed = passed and _assert_true(not export_presets.contains("package/name=\"BloxChain\""), "Android package label should not use old BloxChain name")
	passed = passed and _assert_true(not export_presets.contains("bloxchain.keystore"), "Android release signing should not use old bloxchain keystore")
	passed = passed and _assert_true(not export_presets.contains("keystore/release_user=\"bloxchain\""), "Android release signing should not use old bloxchain alias")
	for old_theme in ["hacknet_theme", "garden_theme", "wood_theme"]:
		passed = passed and _assert_true(not theme_manager.contains("\"%s\"" % old_theme), "ThemeManager should not register old theme %s in cyber production build" % old_theme)
	passed = passed and _assert_true(theme_manager.contains("\"cyberpunk_theme\": \"res://Resources/Data/Themes/cyberpunk_theme.tres\""), "ThemeManager should register only cyberpunk theme")
	passed = passed and _assert_true(mcp_runtime.contains("OS.has_feature(\"production\")"), "MCP runtime should be disabled in production exports")
	passed = passed and _assert_true(mcp_legacy.contains("OS.has_feature(\"production\")"), "Legacy MCP server should be disabled in production exports")
	for web_runtime_ext in ["**/*.html", "**/*.pck", "**/*.js", "**/*.wasm"]:
		passed = passed and _assert_true(firebase_config.contains("\"source\": \"%s\"" % web_runtime_ext), "Firebase hosting should declare cache headers for %s" % web_runtime_ext)
	passed = passed and _assert_true(firebase_config.contains("\"Cache-Control\""), "Firebase hosting should set Cache-Control for Web runtime files")
	passed = passed and _assert_true(firebase_config.contains("no-cache, no-store, must-revalidate"), "Firebase hosting should not serve stale fixed-name Godot Web runtime files")

	if passed:
		print("test_export_packaging_contract: PASS")
		quit(0)
	else:
		print("test_export_packaging_contract: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
