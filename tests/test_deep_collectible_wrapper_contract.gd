extends SceneTree

const COIN_SCENE := "res://objects/coin.tscn"
const COIN_SCRIPT := "res://objects/coin.gd"
const THEME_PATH := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"
const DEEP_STAR := "res://assets/themes/candy_sky_islands/deep_star_candy_model_reference.png"
const STAR_GLB := "res://assets/themes/candy_sky_islands/models/star_candy_collectible.glb"

func _init() -> void:
	var passed := true
	passed = _assert_true(ResourceLoader.exists(COIN_SCENE), "Coin scene should load") and passed
	passed = _assert_true(FileAccess.file_exists(DEEP_STAR), "Deep star-candy reference should exist") and passed
	passed = _assert_true(ResourceLoader.exists(STAR_GLB), "Star-candy GLB should exist") and passed
	passed = _assert_file_contains(COIN_SCENE, "[node name=\"coin\" type=\"Area3D\"]", "Collectible root should stay Area3D") and passed
	passed = _assert_file_contains(COIN_SCENE, "path=\"res://objects/coin.gd\"", "Collectible should keep existing behavior script") and passed
	passed = _assert_file_contains(COIN_SCENE, "[node name=\"CollisionShape3D\" type=\"CollisionShape3D\" parent=\".\"]", "Collectible collision should remain") and passed
	passed = _assert_file_contains(COIN_SCENE, "[connection signal=\"body_entered\" from=\".\" to=\".\" method=\"_on_body_entered\"]", "Collectible pickup signal should remain") and passed
	passed = _assert_file_contains(COIN_SCENE, "path=\"res://assets/themes/candy_sky_islands/models/star_candy_collectible.glb\"", "Collectible visual should use Candy star GLB") and passed
	passed = _assert_file_contains(COIN_SCENE, "[node name=\"Mesh\" parent=\".\" instance=", "Collectible visual should keep a child named Mesh for pickup hiding") and passed
	passed = _assert_file_not_contains(COIN_SCENE, "type=\"Sprite3D\"", "Collectible should not keep Sprite3D wrapper after GLB replacement") and passed
	passed = _assert_file_not_contains(COIN_SCENE, "path=\"res://models/coin.glb\"", "Collectible should not keep legacy coin GLB after replacement") and passed
	passed = _assert_file_not_contains(COIN_SCENE, "path=\"res://models/Textures/colormap.png\"", "Collectible should not keep legacy colormap texture after GLB replacement") and passed
	passed = _assert_file_contains(COIN_SCRIPT, "Audio.play_event(\"coin\")", "Collectible should keep SSOT audio event") and passed
	passed = _assert_file_contains(COIN_SCRIPT, "$Mesh.queue_free()", "Collectible should hide visual after pickup") and passed

	var theme := load(THEME_PATH)
	passed = _assert_true(theme != null, "Candy theme should load") and passed
	if theme != null:
		var role = theme.collectible_model_role
		passed = _assert_true(role != null, "collectible_model_role should exist") and passed
		if role != null:
			passed = _assert_true(role.mode == "replacement", "collectible_model_role should be replacement mode") and passed
			passed = _assert_true(role.reference_path == DEEP_STAR, "collectible_model_role should keep accepted deep star reference") and passed
			passed = _assert_true(role.replacement_path == STAR_GLB, "collectible_model_role should point at Candy star GLB") and passed
			passed = _assert_true(role.active_path() == STAR_GLB, "collectible_model_role active_path should use Candy star GLB") and passed

	if passed:
		print("test_deep_collectible_wrapper_contract: PASS")
		quit(0)
	else:
		print("test_deep_collectible_wrapper_contract: FAIL")
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
