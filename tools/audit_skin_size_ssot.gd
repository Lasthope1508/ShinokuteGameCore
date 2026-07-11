extends SceneTree

const ROLES := [
	{"key": "app.icon", "default": "res://icon.png", "new": "res://icon.png", "kind": "image"},
	{"key": "app.splash", "default": "res://splash-screen.png", "new": "res://splash-screen.png", "kind": "image"},
	{"key": "env.skybox", "default": "res://sprites/skybox.png", "new": "res://assets/themes/candy_sky_islands/sky_panel_islands.png", "kind": "image"},
	{"key": "hud.coin.icon", "default": "res://sprites/coin.png", "new": "res://assets/themes/candy_sky_islands/star_collectible.png", "kind": "image"},
	{"key": "hud.score.frame", "default": "res://sprites/coin.png", "new": "res://assets/themes/candy_sky_islands/hud_score_frame_clean_9router.png", "kind": "image"},
	{"key": "player.shadow", "default": "res://sprites/blob_shadow.png", "new": "res://assets/themes/candy_sky_islands/player_shadow_soft.png", "kind": "image"},
	{"key": "player.trail.dust", "default": "res://meshes/dust.res", "new": "res://objects/player.tscn", "kind": "3d"},
	{"key": "collectible.coin.particle", "default": "res://sprites/particle.png", "new": "res://objects/coin.tscn", "kind": "mixed"},
	{"key": "material.colormap", "default": "res://models/Textures/colormap.png", "new": "", "kind": "image"},
	{"key": "player.model", "default": "res://models/character.glb", "new": "res://objects/player.tscn", "kind": "3d"},
	{"key": "collectible.coin.model", "default": "res://models/coin.glb", "new": "res://objects/coin.tscn", "kind": "3d"},
	{"key": "platform.small", "default": "res://models/platform.glb", "new": "res://objects/platform.tscn", "kind": "3d"},
	{"key": "platform.medium", "default": "res://models/platform-medium.glb", "new": "res://objects/platform_medium.tscn", "kind": "3d"},
	{"key": "platform.falling", "default": "res://models/platform-falling.glb", "new": "res://objects/platform_falling.tscn", "kind": "3d"},
	{"key": "platform.round.large", "default": "res://models/platform-grass-large-round.glb", "new": "res://objects/platform_grass_large_round.tscn", "kind": "3d"},
	{"key": "platform.large.unused_candidate", "default": "res://models/platform-large.glb", "new": "", "kind": "3d"},
	{"key": "block.coin.unused_candidate", "default": "res://models/block-coin.glb", "new": "", "kind": "3d"},
	{"key": "obstacle.brick", "default": "res://models/brick.glb", "new": "res://objects/brick.tscn", "kind": "3d"},
	{"key": "obstacle.brick.particle", "default": "res://meshes/brick.res", "new": "res://objects/brick.tscn", "kind": "3d"},
	{"key": "goal.flag", "default": "res://models/flag.glb", "new": "res://objects/goal_flag.tscn", "kind": "3d"},
	{"key": "prop.cloud", "default": "res://models/cloud.glb", "new": "res://objects/cloud.tscn", "kind": "3d"},
	{"key": "prop.grass", "default": "res://models/grass.glb", "new": "res://objects/platform_grass_large_round.tscn", "kind": "mixed"},
	{"key": "prop.grass.small", "default": "res://models/grass-small.glb", "new": "res://objects/platform_grass_large_round.tscn", "kind": "mixed"},
	{"key": "audio.jump", "default": "res://sounds/jump.ogg", "new": "", "kind": "audio"},
	{"key": "audio.land", "default": "res://sounds/land.ogg", "new": "", "kind": "audio"},
	{"key": "audio.coin", "default": "res://sounds/coin.ogg", "new": "", "kind": "audio"},
	{"key": "audio.walking", "default": "res://sounds/walking.ogg", "new": "", "kind": "audio"},
	{"key": "audio.break", "default": "res://sounds/break.ogg", "new": "", "kind": "audio"},
	{"key": "audio.fall", "default": "res://sounds/fall.ogg", "new": "", "kind": "audio"}
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for role in ROLES:
		var default_size := _measure(role.default, role.kind)
		var new_size := _measure(role.new, role.kind)
		print("%s|%s|%s|%s|%s|%s" % [role.key, role.kind, role.default, default_size, role.new, new_size])
	quit(0)

func _measure(path: String, kind: String) -> String:
	if path.strip_edges().is_empty():
		return "N/A"
	if kind == "image":
		return _measure_image(path)
	if kind == "3d":
		return _measure_3d(path)
	if kind == "mixed":
		return _measure_mixed(path)
	if kind == "audio":
		return "routed; duration not design-size"
	return "unknown"

func _measure_mixed(path: String) -> String:
	var image_size := _measure_image(path)
	if image_size != "missing":
		return image_size
	return _measure_3d(path)

func _measure_image(path: String) -> String:
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error != OK:
		return "missing"
	return "%dx%d px" % [image.get_width(), image.get_height()]

func _measure_3d(path: String) -> String:
	var resource := load(path)
	if resource == null:
		return "missing"
	var node: Node3D = null
	if resource is PackedScene:
		node = (resource as PackedScene).instantiate() as Node3D
	elif resource is Mesh:
		node = MeshInstance3D.new()
		(node as MeshInstance3D).mesh = resource
	if node == null:
		return "unsupported"
	var aabb := _collect_aabb(node, Transform3D.IDENTITY)
	node.free()
	if aabb.size == Vector3.ZERO:
		return "no mesh"
	return "%.3fx%.3fx%.3f u" % [aabb.size.x, aabb.size.y, aabb.size.z]

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
