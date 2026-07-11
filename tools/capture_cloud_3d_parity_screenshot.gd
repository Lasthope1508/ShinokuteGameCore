extends SceneTree

const CLOUD_SCENE := "res://objects/cloud.tscn"
const OUT_PATH := "res://docs/screenshots/candy_sky_islands_cloud_3d_parity.png"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	root.size = Vector2i(960, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/screenshots"))

	var world := Node3D.new()
	root.add_child(world)

	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#79C7F2")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#FFF2C7")
	env.ambient_light_energy = 0.6
	environment.environment = env
	world.add_child(environment)

	var light := DirectionalLight3D.new()
	light.light_energy = 1.4
	light.rotation_degrees = Vector3(-45, 35, 0)
	world.add_child(light)

	var packed := load(CLOUD_SCENE) as PackedScene
	passed = passed and _assert_true(packed != null, "Cloud scene should load")
	if packed != null:
		var cloud := packed.instantiate() as Node3D
		passed = passed and _assert_true(cloud != null, "Cloud scene should instantiate")
		if cloud != null:
			world.add_child(cloud)
			cloud.position = Vector3(0, -0.45, 0)
			cloud.rotation_degrees = Vector3(0, -22, 0)
			cloud.scale = Vector3(1.35, 1.35, 1.35)
			passed = passed and _assert_true(cloud.get_node_or_null("CloudModel") != null, "CloudModel should exist")

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 0.75, 4.2)
	camera.fov = 43.0
	camera.current = true
	world.add_child(camera)
	camera.look_at(Vector3(0, 0.15, 0), Vector3.UP)

	await _settle_frames(16)
	var image := root.get_texture().get_image()
	passed = passed and _assert_nonblank_image(image, "cloud 3D parity")
	var error := image.save_png(OUT_PATH)
	passed = passed and _assert_true(error == OK, "Cloud 3D parity screenshot should save")
	world.queue_free()
	await _settle_frames(4)
	if passed:
		print("capture_cloud_3d_parity_screenshot: PASS")
		quit(0)
	else:
		print("capture_cloud_3d_parity_screenshot: FAIL")
		quit(1)

func _settle_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _assert_nonblank_image(image: Image, label: String) -> bool:
	var width := image.get_width()
	var height := image.get_height()
	if width <= 0 or height <= 0:
		push_error("%s screenshot has invalid size" % label)
		return false
	var first := image.get_pixel(0, 0)
	for y in range(0, height, max(1, height / 12)):
		for x in range(0, width, max(1, width / 12)):
			if image.get_pixel(x, y) != first:
				return true
	push_error("%s screenshot appears blank" % label)
	return false

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true
