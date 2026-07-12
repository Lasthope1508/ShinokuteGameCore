extends SceneTree

const MODEL_PATH := "res://assets/themes/candy_sky_islands/source/model_candidates/character_shinokute_human.glb"

func _init():
	var scene = load(MODEL_PATH)
	if scene == null:
		push_error("Could not load %s" % MODEL_PATH)
		quit(1)
		return
	var root = scene.instantiate()
	get_root().add_child(root)
	_print_tree(root, "")
	var aabb = _combined_aabb(root)
	print("MODEL_AABB ", aabb.size)
	quit(0)

func _print_tree(node, indent):
	print("%s%s:%s" % [indent, node.name, node.get_class()])
	for child in node.get_children():
		_print_tree(child, indent + "  ")

func _combined_aabb(node):
	var has_aabb = false
	var result = AABB()
	for child in node.get_children():
		var child_aabb = _combined_aabb(child)
		if child_aabb.size != Vector3.ZERO:
			if has_aabb:
				result = result.merge(child_aabb)
			else:
				result = child_aabb
				has_aabb = true
	if node is MeshInstance3D and node.mesh != null:
		var mesh_aabb = node.mesh.get_aabb()
		mesh_aabb.position = node.global_transform * mesh_aabb.position
		if has_aabb:
			result = result.merge(mesh_aabb)
		else:
			result = mesh_aabb
			has_aabb = true
	return result
