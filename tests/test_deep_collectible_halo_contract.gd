extends SceneTree

const COIN_SCENE := "res://objects/coin.tscn"
const STAR_HALO_MESH := "res://assets/themes/candy_sky_islands/meshes/star_candy_halo_mesh.tres"
const STAR_GLB := "res://assets/themes/candy_sky_islands/models/star_candy_collectible.glb"
const THEME_APPLIER := "res://scripts/theme_applier.gd"
func _init() -> void:
	var passed := true
	passed = _assert_true(ResourceLoader.exists(COIN_SCENE), "Coin scene should load") and passed
	passed = _assert_true(ResourceLoader.exists(STAR_GLB), "Real star collectible GLB should exist") and passed
	passed = _assert_true(ResourceLoader.exists(STAR_HALO_MESH), "Star-shaped halo mesh should exist") and passed

	passed = _assert_file_contains(COIN_SCENE, "path=\"res://assets/themes/candy_sky_islands/meshes/star_candy_halo_mesh.tres\"", "Coin scene should reference star halo mesh") and passed
	passed = _assert_file_contains(COIN_SCENE, "path=\"res://assets/themes/candy_sky_islands/models/star_candy_collectible.glb\"", "Coin scene should keep the real star collectible asset") and passed
	passed = _assert_file_contains(COIN_SCENE, "mesh = ExtResource(\"4_halo\")", "CandyPickupHalo should use star halo mesh resource") and passed
	passed = _assert_file_contains(STAR_HALO_MESH, "resource_name = \"StarCandyHaloMesh\"", "Star halo mesh should be named") and passed
	passed = _assert_file_contains(STAR_HALO_MESH, "\"vertex_count\": 11", "Star halo mesh should be 10 points plus center") and passed
	passed = _assert_file_contains(STAR_HALO_MESH, "metadata/source_asset = \"res://assets/themes/candy_sky_islands/models/star_candy_collectible.glb\"", "Star halo mesh should record real collectible source") and passed
	passed = _assert_file_contains(STAR_HALO_MESH, "star_points outer=0.32 inner=0.15", "Star halo mesh should preserve collectible star proportions") and passed
	passed = _assert_file_contains(THEME_APPLIER, "[\"CandyPickupHalo\"]", "Theme applier should not recolor the halo as coin body mesh") and passed
	var halo_mesh := load(STAR_HALO_MESH) as ArrayMesh
	passed = _assert_true(halo_mesh != null, "Star halo mesh should load as ArrayMesh") and passed
	if halo_mesh != null:
		passed = _assert_true(halo_mesh.get_surface_count() == 1, "Star halo mesh should have one surface") and passed
		passed = _assert_true(halo_mesh.surface_get_material(0) != null, "Star halo mesh surface should own a production material") and passed

	if passed:
		print("test_deep_collectible_halo_contract: PASS")
		quit(0)
	else:
		print("test_deep_collectible_halo_contract: FAIL")
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
