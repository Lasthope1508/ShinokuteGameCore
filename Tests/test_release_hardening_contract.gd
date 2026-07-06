extends SceneTree

const EXPORT_PRESETS_PATH := "res://export_presets.cfg"
const PROJECT_PATH := "res://project.godot"
const MCP_SCRIPT_PATH := "res://Scripts/mcp_interaction_server.gd"
const MANIFEST_PATH := "res://docs/runtime_asset_manifest.json"

func _init() -> void:
	var passed := true
	var export_presets := FileAccess.get_file_as_string(EXPORT_PRESETS_PATH)
	var project := FileAccess.get_file_as_string(PROJECT_PATH)
	var mcp_script := FileAccess.get_file_as_string(MCP_SCRIPT_PATH)
	var manifest := FileAccess.get_file_as_string(MANIFEST_PATH)
	var manifest_data = JSON.parse_string(manifest)

	passed = passed and _assert_true(not export_presets.contains("keystore/release_password=\"dQ"), "Release keystore password must not be committed")
	passed = passed and _assert_true(export_presets.contains("keystore/release_password=\"\""), "Release keystore password should be blank in source")
	passed = passed and _assert_true(not export_presets.contains("res://Scripts/mcp_interaction_server.gd"), "MCP interaction server must not ship in selected resources")
	passed = passed and _assert_true(not project.contains("McpInteractionServer=\"*res://Scripts/mcp_interaction_server.gd\""), "MCP interaction server must not be an always-on autoload")
	passed = passed and _assert_true(manifest_data is Dictionary, "Runtime manifest should parse")
	if manifest_data is Dictionary:
		passed = passed and _assert_true(not _manifest_runtime_assets_contain(manifest_data, MCP_SCRIPT_PATH), "MCP interaction server must not be listed as runtime manifest asset")
		passed = passed and _assert_true(_manifest_forbids_path(manifest_data, MCP_SCRIPT_PATH), "MCP interaction server should be documented as non-runtime forbidden policy")
	passed = passed and _assert_true(not mcp_script.is_empty(), "MCP source can stay in repo for local tooling")

	if passed:
		print("test_release_hardening_contract: PASS")
		quit(0)
	else:
		print("test_release_hardening_contract: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		return false
	return true

func _manifest_runtime_assets_contain(manifest_data: Dictionary, path: String) -> bool:
	for item in manifest_data.get("runtime_assets", []):
		if item is Dictionary and item.get("path", "") == path:
			return true
	return false

func _manifest_forbids_path(manifest_data: Dictionary, path: String) -> bool:
	for item in manifest_data.get("non_runtime_policies", []):
		if item is Dictionary and item.get("path", "") == path and item.get("export_policy", "") == "forbidden":
			return true
	return false
