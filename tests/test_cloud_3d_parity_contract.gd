extends SceneTree

const CLOUD_SCENE := "res://objects/cloud.tscn"
const CLOUD_GLB := "res://assets/themes/candy_sky_islands/models/cloud_candy_volume.glb"
const CLOUD_REFERENCE := "res://assets/themes/candy_sky_islands/cloud_large.png"
const THEME_PATH := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"
const SSOT := "res://docs/default_skin_size_ssot.md"
const MANIFEST := "res://docs/asset_manifest.md"
const STATE := "res://docs/reskin_state.md"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	passed = _assert_true(FileAccess.file_exists(CLOUD_REFERENCE), "Approved Photoroom cloud reference should exist") and passed
	passed = _assert_true(ResourceLoader.exists(CLOUD_GLB), "Reference-derived volumetric cloud GLB should exist") and passed
	passed = _assert_file_contains(CLOUD_SCENE, "path=\"res://assets/themes/candy_sky_islands/models/cloud_candy_volume.glb\"", "Cloud scene should reference volumetric Candy cloud GLB") and passed
	passed = _assert_file_contains(CLOUD_SCENE, "[node name=\"CloudModel\" parent=\".\" instance=", "Cloud scene should instance the volumetric cloud model as CloudModel") and passed
	passed = _assert_file_contains(CLOUD_SCENE, "path=\"res://objects/cloud.gd\"", "Cloud root should keep movement script") and passed
	passed = _assert_file_not_contains(CLOUD_SCENE, "type=\"Sprite3D\"", "Cloud production visual must not be a flat Sprite3D") and passed
	passed = _assert_file_not_contains(CLOUD_SCENE, "path=\"res://assets/themes/candy_sky_islands/models/cloud_candy.glb\"", "Cloud scene must not use rejected primitive dummy GLB") and passed
	passed = _assert_file_not_contains(CLOUD_SCENE, "path=\"res://models/cloud.glb\"", "Cloud scene must not keep legacy cloud GLB visual") and passed

	if ResourceLoader.exists(CLOUD_SCENE):
		var scene := load(CLOUD_SCENE) as PackedScene
		passed = _assert_true(scene != null, "Cloud scene should load") and passed
		if scene != null:
			var root := scene.instantiate()
			passed = _assert_true(root != null and root.name == "cube", "Cloud root should remain named cube") and passed
			if root != null:
				passed = _assert_true(root.get_script() != null, "Cloud root should keep cloud.gd script") and passed
				var aabb := _combined_mesh_aabb(root)
				passed = _assert_true(aabb.size.x >= 1.0, "Cloud model should preserve readable width, got %.3f" % aabb.size.x) and passed
				passed = _assert_true(aabb.size.y >= 0.45, "Cloud model should preserve visible height, got %.3f" % aabb.size.y) and passed
				passed = _assert_true(aabb.size.z >= 0.35, "Cloud model should have real 3D depth, got %.3f" % aabb.size.z) and passed
				root.free()

	var theme := load(THEME_PATH)
	passed = _assert_true(theme != null, "Candy theme should load") and passed
	if theme != null:
		var role = theme.prop_cloud_role
		passed = _assert_true(role != null, "prop_cloud_role should exist") and passed
		if role != null:
			passed = _assert_true(role.mode == "replacement", "prop_cloud_role should stay in replacement mode") and passed
			passed = _assert_true(role.reference_path == CLOUD_REFERENCE, "prop_cloud_role should keep approved Photoroom reference") and passed
			passed = _assert_true(role.notes.contains("reference-derived volumetric"), "prop_cloud_role should record reference-derived volumetric method") and passed
			passed = _assert_true(not role.notes.contains("Sprite3D"), "prop_cloud_role notes should not describe flat Sprite3D production") and passed

	passed = _assert_file_contains(SSOT, "prop.cloud", "SSOT should keep prop.cloud row") and passed
	passed = _assert_file_contains(SSOT, "glb_replacement_done", "SSOT should mark cloud as full GLB replacement after parity fix") and passed
	passed = _assert_file_contains(MANIFEST, "cloud_candy_volume.glb", "Manifest should record volumetric cloud GLB") and passed
	passed = _assert_file_contains(STATE, "Cloud 3D parity replacement applied", "State should record cloud 3D parity completion") and passed

	if passed:
		print("test_cloud_3d_parity_contract: PASS")
		quit(0)
	else:
		print("test_cloud_3d_parity_contract: FAIL")
		quit(1)

func _combined_mesh_aabb(root: Node) -> AABB:
	var found := false
	var combined := AABB()
	for item in _walk_3d(root, Transform3D.IDENTITY):
		var node := item["node"] as Node
		var transform := item["transform"] as Transform3D
		if node is MeshInstance3D and node.mesh != null:
			var mesh_instance := node as MeshInstance3D
			var local_aabb := mesh_instance.mesh.get_aabb()
			var world_aabb := _transform_aabb(transform, local_aabb)
			if not found:
				combined = world_aabb
				found = true
			else:
				combined = combined.merge(world_aabb)
	return combined

func _walk_3d(root: Node, parent_transform: Transform3D) -> Array[Dictionary]:
	var current_transform := parent_transform
	if root is Node3D:
		current_transform = parent_transform * (root as Node3D).transform
	var result: Array[Dictionary] = [{"node": root, "transform": current_transform}]
	for child in root.get_children():
		result.append_array(_walk_3d(child, current_transform))
	return result

func _transform_aabb(transform: Transform3D, aabb: AABB) -> AABB:
	var points := [
		aabb.position,
		aabb.position + Vector3(aabb.size.x, 0, 0),
		aabb.position + Vector3(0, aabb.size.y, 0),
		aabb.position + Vector3(0, 0, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0),
		aabb.position + Vector3(aabb.size.x, 0, aabb.size.z),
		aabb.position + Vector3(0, aabb.size.y, aabb.size.z),
		aabb.position + aabb.size,
	]
	var transformed := AABB(transform * points[0], Vector3.ZERO)
	for i in range(1, points.size()):
		transformed = transformed.expand(transform * points[i])
	return transformed

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
