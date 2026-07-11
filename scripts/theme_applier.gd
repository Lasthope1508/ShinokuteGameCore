extends Node

const RuntimeThemeConfig := preload("res://Resources/QuantumRuntimeThemeConfig.gd")

func apply_theme(root: Node, theme: RuntimeThemeConfig) -> void:
	if root == null or theme == null:
		return
	_apply_hud(root, theme)
	_apply_player_materials(root, theme)
	_apply_player_trail(root, theme)
	_apply_world_materials(root, theme)

func _apply_hud(root: Node, theme: RuntimeThemeConfig) -> void:
	var hud := root.get_node_or_null("HUD")
	if hud == null:
		return

	var icon := hud.get_node_or_null("Icon") as TextureRect
	if icon != null and ResourceLoader.exists(theme.hud_coin_icon_path):
		icon.texture = load(theme.hud_coin_icon_path)

	var frame := hud.get_node_or_null("CandyScoreFrame") as TextureRect
	if frame != null:
		if ResourceLoader.exists(theme.hud_score_frame_path):
			frame.texture = load(theme.hud_score_frame_path)
		frame.offset_left = theme.hud_score_frame_rect.position.x
		frame.offset_top = theme.hud_score_frame_rect.position.y
		frame.offset_right = theme.hud_score_frame_rect.end.x
		frame.offset_bottom = theme.hud_score_frame_rect.end.y
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var coins := hud.get_node_or_null("Coins") as Label
	if coins == null:
		return

	coins.offset_left = theme.hud_text_owner_rect.position.x + theme.hud_text_padding.x
	coins.offset_top = theme.hud_text_owner_rect.position.y + theme.hud_text_padding.y
	coins.offset_right = theme.hud_text_owner_rect.end.x - theme.hud_text_padding.z
	coins.offset_bottom = theme.hud_text_owner_rect.end.y - theme.hud_text_padding.w
	coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coins.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coins.add_theme_color_override("font_color", theme.palette_text)
	coins.add_theme_font_size_override("font_size", theme.hud_font_size)
	var label_settings := coins.label_settings.duplicate() as LabelSettings if coins.label_settings != null else LabelSettings.new()
	label_settings.font_color = theme.palette_text
	label_settings.font_size = theme.hud_font_size
	if ResourceLoader.exists(theme.hud_font_path):
		var hud_font := load(theme.hud_font_path)
		coins.add_theme_font_override("font", hud_font)
		label_settings.font = hud_font
	coins.label_settings = label_settings

func _apply_player_materials(root: Node, theme: RuntimeThemeConfig) -> void:
	if not ResourceLoader.exists(theme.player_root_asset_path) and not FileAccess.file_exists(theme.player_root_asset_path):
		push_warning("Approved player root asset is missing: %s" % theme.player_root_asset_path)

	var player := root.get_node_or_null("Player")
	if player == null:
		return

	var character := player.get_node_or_null("Character")
	if character == null:
		return

	_apply_named_mesh_tree_color(character, ["torso"], theme.player_body_material_color)
	_apply_named_mesh_tree_color(character, ["antenna"], theme.player_cap_material_color)
	_apply_named_mesh_tree_color(character, ["arm-left"], theme.player_left_glove_material_color)
	_apply_named_mesh_tree_color(character, ["arm-right"], theme.player_right_glove_material_color)
	_apply_named_mesh_tree_color(character, ["leg-left"], theme.player_left_boot_material_color)
	_apply_named_mesh_tree_color(character, ["leg-right"], theme.player_right_boot_material_color)

func _apply_named_mesh_tree_color(root: Node, names: Array[String], color: Color) -> void:
	for descendant in _collect_mesh_instances(root):
		var mesh := descendant as MeshInstance3D
		if mesh == null:
			continue
		var node_name := String(mesh.name)
		var parent_name := String(mesh.get_parent().name) if mesh.get_parent() != null else ""
		if names.has(node_name) or names.has(parent_name):
			var material := _duplicate_mesh_material(mesh)
			material.albedo_color = color
			material.roughness = 0.82
			material.metallic = 0.0
			mesh.set_surface_override_material(0, material)

func _apply_player_trail(root: Node, theme: RuntimeThemeConfig) -> void:
	var player := root.get_node_or_null("Player")
	if player == null:
		return

	var particles := player.get_node_or_null("ParticlesTrail") as GPUParticles3D
	if particles == null:
		return

	var material := _duplicate_standard_material(particles.material_override)
	material.albedo_color = theme.trail_particle_color
	material.backlight = theme.palette_sky
	particles.material_override = material

func _apply_world_materials(root: Node, theme: RuntimeThemeConfig) -> void:
	var world := root.get_node_or_null("World")
	if world == null:
		return

	for child in world.get_children():
		var child_name := String(child.name)
		if child_name.begins_with("coin"):
			_apply_coin_node(child, theme)
		elif child_name.begins_with("cube"):
			_apply_cloud_node(child, theme)
		elif child_name.begins_with("platform"):
			_apply_platform_node(child, theme)
		elif child_name.begins_with("brick"):
			_apply_obstacle_node(child, theme)
		elif child_name.begins_with("flag"):
			_apply_goal_node(child, theme)

func _apply_coin_node(node: Node, theme: RuntimeThemeConfig) -> void:
	_apply_mesh_tree_color(node, theme.collectible_star_body_color, true, theme.collectible_star_rim_color, ["CandyPickupHalo"])

	var particles := node.get_node_or_null("Particles") as GPUParticles3D
	if particles == null:
		return
	var process_material := particles.process_material as ParticleProcessMaterial
	if process_material != null:
		var themed_process := process_material.duplicate() as ParticleProcessMaterial
		themed_process.color = theme.collectible_star_rim_color
		particles.process_material = themed_process

func _apply_cloud_node(node: Node, theme: RuntimeThemeConfig) -> void:
	for descendant in _collect_mesh_instances(node):
		var mesh := descendant as MeshInstance3D
		if mesh == null:
			continue
		var mesh_name := String(mesh.name)
		var material := _duplicate_mesh_material(mesh)
		if mesh_name == "MintSpark":
			material.albedo_color = theme.palette_accent
			material.emission_enabled = true
			material.emission = theme.palette_accent
			material.emission_energy_multiplier = 0.12
		else:
			material.albedo_color = theme.cloud_material_color
			material.backlight = theme.cloud_shadow_material_color
			material.emission_enabled = true
			material.emission = theme.cloud_shadow_material_color
			material.emission_energy_multiplier = 0.08
		mesh.set_surface_override_material(0, material)

func _apply_platform_node(node: Node, theme: RuntimeThemeConfig) -> void:
	for descendant in _collect_mesh_instances(node):
		var mesh := descendant as MeshInstance3D
		if mesh == null:
			continue
		var mesh_name := String(mesh.name).to_lower()
		var parent_name := String(mesh.get_parent().name).to_lower() if mesh.get_parent() != null else ""
		var material := _duplicate_mesh_material(mesh)
		if mesh_name.contains("mint") or mesh_name.contains("grass"):
			material.albedo_color = theme.palette_accent
		elif mesh_name.contains("cream"):
			material.albedo_color = theme.palette_surface
		elif mesh_name.contains("coral") or mesh_name.contains("cake_top") or mesh_name == "caketop" or mesh_name == "caketopround":
			material.albedo_color = theme.palette_primary
		elif mesh_name.contains("cloud"):
			material.albedo_color = theme.palette_sky
		elif mesh_name.contains("edge") or parent_name.contains("edge"):
			material.albedo_color = theme.platform_edge_material_color
		else:
			material.albedo_color = theme.platform_top_material_color
		material.roughness = 0.86
		material.metallic = 0.0
		mesh.set_surface_override_material(0, material)

func _apply_obstacle_node(node: Node, theme: RuntimeThemeConfig) -> void:
	for descendant in _collect_mesh_instances(node):
		var mesh := descendant as MeshInstance3D
		if mesh == null:
			continue
		var mesh_name := String(mesh.name)
		var material := _duplicate_mesh_material(mesh)
		if mesh_name == "CreamStripe":
			material.albedo_color = theme.palette_surface
		elif mesh_name == "MintChip":
			material.albedo_color = theme.palette_accent
		else:
			material.albedo_color = theme.obstacle_wafer_material_color
		material.roughness = 0.88
		material.metallic = 0.0
		mesh.set_surface_override_material(0, material)

func _apply_goal_node(node: Node, theme: RuntimeThemeConfig) -> void:
	for descendant in _collect_mesh_instances(node):
		var mesh := descendant as MeshInstance3D
		if mesh == null:
			continue
		var mesh_name := String(mesh.name)
		var material := _duplicate_mesh_material(mesh)
		if mesh_name == "MintPole":
			material.albedo_color = theme.palette_accent
		elif mesh_name == "CreamTrim":
			material.albedo_color = theme.palette_surface
		else:
			material.albedo_color = theme.goal_pennant_material_color
		material.roughness = 0.84
		material.metallic = 0.0
		mesh.set_surface_override_material(0, material)

func _apply_mesh_tree_color(node: Node, color: Color, rim_enabled := false, rim_color := Color.WHITE, excluded_names: Array[String] = []) -> void:
	for descendant in _collect_mesh_instances(node):
		var mesh := descendant as MeshInstance3D
		if mesh == null:
			continue
		if excluded_names.has(String(mesh.name)):
			continue
		var material := _duplicate_mesh_material(mesh)
		material.albedo_color = color
		if rim_enabled:
			material.rim_enabled = true
			material.rim = 0.5
			material.rim_tint = 0.8
			material.emission_enabled = true
			material.emission = rim_color
			material.emission_energy_multiplier = 0.12
		mesh.set_surface_override_material(0, material)

func _collect_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		meshes.append(node as MeshInstance3D)
	for child in node.get_children():
		meshes.append_array(_collect_mesh_instances(child))
	return meshes

func _duplicate_mesh_material(mesh: MeshInstance3D) -> StandardMaterial3D:
	var material := mesh.get_surface_override_material(0)
	if material == null and mesh.mesh != null and mesh.mesh.get_surface_count() > 0:
		material = mesh.mesh.surface_get_material(0)
	return _duplicate_standard_material(material)

func _duplicate_standard_material(material: Material) -> StandardMaterial3D:
	if material is StandardMaterial3D:
		return material.duplicate() as StandardMaterial3D
	return StandardMaterial3D.new()
