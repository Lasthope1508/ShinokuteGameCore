extends SceneTree

const COIN_SCENE := "res://objects/coin.tscn"
const OUT_PATH := "res://docs/screenshots/candy_sky_islands_star_halo_closeup.png"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/screenshots"))
	root.size = Vector2i(768, 768)

	var coin_scene := load(COIN_SCENE) as PackedScene
	if coin_scene == null:
		push_error("Coin scene should load")
		quit(1)
		return

	var node := Node3D.new()
	root.add_child(node)

	var coin := coin_scene.instantiate() as Node3D
	node.add_child(coin)
	coin.position = Vector3.ZERO

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 2.0
	node.add_child(light)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 0.5, 2.2)
	camera.fov = 22
	node.add_child(camera)
	camera.look_at(Vector3(0, 0.5, 0), Vector3.UP)
	camera.current = true

	await _settle_frames(18)
	var image := root.get_texture().get_image()
	var err := image.save_png(OUT_PATH)
	if err != OK:
		push_error("Failed to save %s" % OUT_PATH)
		quit(1)
		return
	print("wrote %s" % OUT_PATH)
	quit(0)

func _settle_frames(count: int) -> void:
	for _i in range(count):
		await process_frame
