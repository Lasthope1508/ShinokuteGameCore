extends SceneTree

const CHECKLIST := "res://docs/reskin_checklist.md"
const STATE := "res://docs/reskin_state.md"
const MANIFEST := "res://docs/asset_manifest.md"
const SSOT := "res://docs/default_skin_size_ssot.md"
const THEME_CONFIG_SCRIPT := "res://Resources/QuantumThemeConfig.gd"
const HALO_PROOF := "res://docs/screenshots/candy_sky_islands_star_halo_closeup.png"

func _init() -> void:
	var passed := true
	passed = _assert_file_contains(STATE, "Player full GLB replacement validation passed", "State should record player GLB validation") and passed
	passed = _assert_file_contains(STATE, "CHR077 Skeleton Mage player replacement validation passed", "State should record CHR077 player validation") and passed
	passed = _assert_file_contains(CHECKLIST, "Player full GLB replacement applied and validated", "Checklist should record player GLB validation") and passed
	passed = _assert_file_contains(MANIFEST, "character_chr077_skeleton_mage.glb", "Manifest should point at CHR077 Skeleton Mage player GLB") and passed
	passed = _assert_file_contains(SSOT, "player.model", "SSOT should cover player model") and passed
	passed = _assert_file_contains(SSOT, "glb_replacement_done", "SSOT should mark GLB replacements done") and passed
	passed = _assert_file_contains(MANIFEST, "star_candy_halo_mesh.tres", "Manifest should record star halo mesh") and passed
	passed = _assert_true(FileAccess.file_exists(HALO_PROOF), "Star halo close-up proof should exist") and passed
	passed = _assert_file_contains(THEME_CONFIG_SCRIPT, "hud_coin_icon_path := \"res://assets/themes/candy_sky_islands/star_collectible.png\"", "Theme defaults should use Candy HUD star") and passed
	passed = _assert_file_contains(THEME_CONFIG_SCRIPT, "skybox_path := \"res://assets/themes/candy_sky_islands/sky_panel_islands.png\"", "Theme defaults should use Candy skybox") and passed
	passed = _assert_file_contains(THEME_CONFIG_SCRIPT, "bgm_track_path := \"res://sounds/candy_sky_islands/bgm_candy_island_main.ogg\"", "Theme defaults should include Candy BGM route") and passed
	passed = _assert_file_contains(THEME_CONFIG_SCRIPT, "\"break\": \"res://sounds/candy_sky_islands/sfx_break.ogg\"", "Theme defaults should include Candy break SFX route") and passed
	passed = _assert_file_contains(THEME_CONFIG_SCRIPT, "\"fall\": \"res://sounds/candy_sky_islands/sfx_fall.ogg\"", "Theme defaults should include Candy fall SFX route") and passed

	passed = _assert_file_not_contains(CHECKLIST, "Deeper GLB replacement for player is not complete", "Checklist should not keep stale player pending gap") and passed
	passed = _assert_file_not_contains(CHECKLIST, "Player uses a local wrapper over the legacy rig/model, not a full model replacement", "Checklist should not say player wrapper remains after GLB replacement") and passed
	passed = _assert_file_not_contains(STATE, "Deep Reskin plan written on 2026-07-07; implementation validation not run yet.", "State should not keep stale unvalidated deep plan note") and passed
	passed = _assert_file_not_contains(THEME_CONFIG_SCRIPT, "hud_coin_icon_path := \"res://sprites/coin.png\"", "Theme defaults should not fall back to old HUD coin") and passed
	passed = _assert_file_not_contains(THEME_CONFIG_SCRIPT, "skybox_path := \"res://sprites/skybox.png\"", "Theme defaults should not fall back to old skybox") and passed

	passed = _assert_file_contains(CHECKLIST, "Candy Island BGM/SFX replacement applied", "Checklist should record Candy Island audio replacement") and passed
	passed = _assert_file_contains(STATE, "Candy Island BGM/SFX replacement applied", "State should record Candy Island audio replacement") and passed

	if passed:
		print("test_reskin_final_audit_contract: PASS")
		quit(0)
	else:
		print("test_reskin_final_audit_contract: FAIL")
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

func _assert_file_not_contains(path: String, needle: String, message: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("%s: missing %s" % [message, path])
		return false
	var text := FileAccess.get_file_as_string(path)
	if text.contains(needle):
		push_error("%s: unexpected '%s'" % [message, needle])
		return false
	return true

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true
