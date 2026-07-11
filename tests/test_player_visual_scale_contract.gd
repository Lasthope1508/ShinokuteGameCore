extends SceneTree

const CHARACTER_SCENE := "res://objects/character.tscn"
const PLAYER_SCENE := "res://objects/player.tscn"
const SSOT := "res://docs/default_skin_size_ssot.md"
const MIN_HEIGHT := 1.10
const TARGET_HEIGHT := 1.30
const MAX_HEIGHT := 1.35

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true

	var character_packed := load(CHARACTER_SCENE) as PackedScene
	passed = _assert_true(character_packed != null, "Character scene should load") and passed
	if character_packed == null:
		_finish(false)
		return

	var character := character_packed.instantiate() as Node3D
	passed = _assert_true(character != null, "Character scene should instantiate as Node3D") and passed
	if character == null:
		_finish(false)
		return

	var slot := character.get_node_or_null("CHR077SkeletonMageSlot") as Node3D
	passed = _assert_true(slot != null, "CHR077 scale slot should exist") and passed
	if slot != null:
		passed = _assert_true(is_equal_approx(slot.scale.x, 0.5), "CHR077 scale slot x should be 0.5") and passed
		passed = _assert_true(is_equal_approx(slot.scale.y, 0.5), "CHR077 scale slot y should be 0.5") and passed
		passed = _assert_true(is_equal_approx(slot.scale.z, 0.5), "CHR077 scale slot z should be 0.5") and passed

	var visual_aabb := _collect_aabb(character, Transform3D.IDENTITY)
	var visual_height := visual_aabb.size.y
	passed = _assert_true(visual_height >= MIN_HEIGHT and visual_height <= MAX_HEIGHT, "player.model visual height %.3f should stay within %.2f..%.2f u" % [visual_height, MIN_HEIGHT, MAX_HEIGHT]) and passed
	passed = _assert_true(absf(visual_height - TARGET_HEIGHT) <= 0.06, "player.model visual height %.3f should stay near target %.2f u" % [visual_height, TARGET_HEIGHT]) and passed

	var player_packed := load(PLAYER_SCENE) as PackedScene
	passed = _assert_true(player_packed != null, "Player scene should load") and passed
	if player_packed != null:
		var player := player_packed.instantiate()
		var collider := player.get_node_or_null("Collider") as CollisionShape3D
		passed = _assert_true(collider != null, "Player collider should exist") and passed
		if collider != null:
			var capsule := collider.shape as CapsuleShape3D
			passed = _assert_true(capsule != null, "Player collider should remain CapsuleShape3D") and passed
			if capsule != null:
				passed = _assert_true(is_equal_approx(capsule.radius, 0.3), "Player collider radius should remain 0.3") and passed
				passed = _assert_true(is_equal_approx(capsule.height, 1.0), "Player collider height should remain 1.0") and passed
		player.free()

	character.free()

	passed = _assert_file_contains(SSOT, "player.visual_target_height = 1.30 u", "SSOT should define player visual target height") and passed
	passed = _assert_file_contains(SSOT, "player.visual_allowed_height = 1.10..1.35 u", "SSOT should define player visual allowed range") and passed
	passed = _assert_file_contains(SSOT, "player.visual_scale_policy", "SSOT should define player visual scale policy") and passed

	_finish(passed)

func _collect_aabb(node: Node3D, parent_transform: Transform3D) -> AABB:
	var found := false
	var combined := AABB()
	var world_transform := parent_transform * node.transform
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			combined = _transformed_aabb(world_transform, mesh_instance.mesh.get_aabb())
			found = true
	for child in node.get_children():
		if child is Node3D:
			var child_aabb := _collect_aabb(child as Node3D, world_transform)
			if child_aabb.size != Vector3.ZERO:
				if found:
					combined = combined.merge(child_aabb)
				else:
					combined = child_aabb
					found = true
	return combined if found else AABB()

func _transformed_aabb(transform: Transform3D, aabb: AABB) -> AABB:
	var points := [
		aabb.position,
		aabb.position + Vector3(aabb.size.x, 0, 0),
		aabb.position + Vector3(0, aabb.size.y, 0),
		aabb.position + Vector3(0, 0, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0),
		aabb.position + Vector3(aabb.size.x, 0, aabb.size.z),
		aabb.position + Vector3(0, aabb.size.y, aabb.size.z),
		aabb.position + aabb.size
	]
	var result := AABB(transform * points[0], Vector3.ZERO)
	for index in range(1, points.size()):
		result = result.expand(transform * points[index])
	return result

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

func _finish(passed: bool) -> void:
	if passed:
		print("test_player_visual_scale_contract: PASS")
		quit(0)
	else:
		print("test_player_visual_scale_contract: FAIL")
		quit(1)
