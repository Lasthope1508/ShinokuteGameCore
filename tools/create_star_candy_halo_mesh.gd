extends SceneTree

const OUT_DIR := "res://assets/themes/candy_sky_islands/meshes"
const OUT_PATH := OUT_DIR + "/star_candy_halo_mesh.tres"
const OUTER_RADIUS := 0.32
const INNER_RADIUS := 0.15
const POINT_COUNT := 5

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var mesh := _build_star_mesh()
	mesh.resource_name = "StarCandyHaloMesh"
	mesh.set_meta("source_asset", "res://assets/themes/candy_sky_islands/models/star_candy_collectible.glb")
	mesh.set_meta("source_method", "tools/create_candy_collectible_glb.py star_points outer=0.32 inner=0.15")
	var err := ResourceSaver.save(mesh, OUT_PATH)
	if err != OK:
		push_error("Failed to save %s: %s" % [OUT_PATH, err])
		quit(1)
		return
	print("wrote %s" % OUT_PATH)
	quit(0)

func _build_star_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	vertices.append(Vector3.ZERO)

	var start_angle := deg_to_rad(90.0)
	for i in range(POINT_COUNT * 2):
		var radius := OUTER_RADIUS if i % 2 == 0 else INNER_RADIUS
		var angle := start_angle + i * PI / POINT_COUNT
		vertices.append(Vector3(cos(angle) * radius, sin(angle) * radius, 0.0))

	for i in range(POINT_COUNT * 2):
		var current := i + 1
		var next := 1 if i == POINT_COUNT * 2 - 1 else current + 1
		indices.append(0)
		indices.append(current)
		indices.append(next)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.resource_name = "Material_StarCandyHaloSurface"
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.949, 0.78, 0.36)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.949, 0.78, 1.0)
	material.emission_energy_multiplier = 0.28
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.billboard_keep_scale = true
	mesh.surface_set_material(0, material)
	return mesh
