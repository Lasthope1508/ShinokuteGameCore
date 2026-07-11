extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"
const OUT_DIR := "res://docs/screenshots"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var passed := true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var packed_scene := load(MAIN_SCENE) as PackedScene
	passed = passed and _assert_true(packed_scene != null, "Main scene should load")
	if packed_scene == null:
		_finish(false)
		return

	var scene := packed_scene.instantiate()
	root.add_child(scene)
	current_scene = scene
	root.size = Vector2i(1280, 720)
	await _settle_frames(12)

	passed = passed and _assert_true(scene.get_node_or_null("Player") != null, "Player should exist")
	passed = passed and _assert_true(scene.get_node_or_null("View/Camera") != null, "Camera should exist")
	passed = passed and _assert_true(scene.get_node_or_null("HUD/Coins") != null, "HUD coins label should exist")
	var desktop_saved: bool = await _save_viewport("candy_sky_islands_desktop_gameplay.png", Rect2i())
	passed = passed and desktop_saved
	var asset_family_saved: bool = await _save_viewport("candy_sky_islands_asset_family_gameplay.png", Rect2i())
	passed = passed and asset_family_saved
	var platform_saved: bool = await _save_viewport("candy_sky_islands_platform_wrapper.png", Rect2i())
	var platform_glb_saved: bool = await _save_viewport("candy_sky_islands_platform_glb_replacement.png", Rect2i())
	passed = passed and platform_saved and platform_glb_saved
	var player_saved: bool = await _save_viewport("candy_sky_islands_player_marshmallow_runner.png", Rect2i(420, 120, 440, 500))
	var player_wrapper_saved: bool = await _save_viewport("candy_sky_islands_player_wrapper.png", Rect2i(420, 120, 440, 500))
	var player_glb_saved: bool = await _save_viewport("candy_sky_islands_player_glb_replacement.png", Rect2i(420, 120, 440, 500))
	passed = passed and player_saved and player_wrapper_saved and player_glb_saved

	var player := scene.get_node_or_null("Player")
	if player != null:
		passed = passed and _assert_true(player.get_node_or_null("Character/CHR077SkeletonMageSlot/CHR077SkeletonMageVisual") != null, "Player should use scaled CHR077 Skeleton Mage GLB visual")
		var player_animation := player.get_node_or_null("Character/AnimationPlayer") as AnimationPlayer
		passed = passed and _assert_true(player_animation != null, "Player should keep Character/AnimationPlayer")
		if player_animation != null:
			for animation_name in ["idle", "walk", "jump"]:
				passed = passed and _assert_true(player_animation.has_animation(animation_name), "Player should keep %s animation" % animation_name)

		var start_position: Vector3 = player.global_position
		Input.action_press("move_right")
		await _settle_physics_frames(20)
		Input.action_release("move_right")
		passed = passed and _assert_true(player.global_position.distance_to(start_position) > 0.01, "Player movement input should move player")
	else:
		passed = false
		push_error("Player movement smoke target should exist")

	var view := scene.get_node_or_null("View")
	if view != null:
		var start_camera_rotation: Vector3 = view.camera_rotation
		Input.action_press("camera_right")
		await _settle_physics_frames(10)
		Input.action_release("camera_right")
		passed = passed and _assert_true(view.camera_rotation != start_camera_rotation, "Camera rotation input should update camera rotation")

		var start_zoom = view.zoom
		Input.action_press("zoom_out")
		await _settle_physics_frames(10)
		Input.action_release("zoom_out")
		passed = passed and _assert_true(view.zoom != start_zoom, "Camera zoom input should update zoom")
	else:
		passed = false
		push_error("View smoke target should exist")

	if player != null and player.has_method("jump"):
		player.jump()
		passed = passed and _assert_true(player.gravity < 0, "Player jump should set upward gravity")
		player.jump()
		passed = passed and _assert_true(not player.jump_double, "Player double jump should consume double-jump state")
	else:
		passed = false
		push_error("Player jump method should exist")

	if player != null and player.has_method("collect_coin"):
		player.collect_coin()
		await _settle_frames(4)
		var coins := scene.get_node_or_null("HUD/Coins") as Label
		passed = passed and _assert_true(coins != null and coins.text == "1", "Coin collection should update HUD")
		var frame := scene.get_node_or_null("HUD/CandyScoreFrame") as TextureRect
		var old_icon := scene.get_node_or_null("HUD/Icon")
		passed = passed and _assert_true(frame != null and frame.texture != null, "HUD score frame should load 9Router-cleaned texture")
		if frame != null:
			passed = passed and _assert_true(frame.expand_mode == TextureRect.EXPAND_IGNORE_SIZE, "HUD score frame should ignore natural texture size")
			passed = passed and _assert_true(frame.size.x <= 360.0 and frame.size.y <= 160.0, "HUD score frame should stay compact")
		passed = passed and _assert_true(old_icon == null, "HUD should not keep legacy icon node")
		var coin_saved: bool = await _save_viewport("candy_sky_islands_coin_pickup.png", Rect2i())
		var hud_saved: bool = await _save_viewport("candy_sky_islands_hud.png", Rect2i(0, 0, 480, 180))
		var asset_family_hud_saved: bool = await _save_viewport("candy_sky_islands_asset_family_hud.png", Rect2i(0, 0, 480, 180))
		var vfx_material_saved: bool = await _save_viewport("candy_sky_islands_vfx_material_cleanup.png", Rect2i())
		passed = passed and coin_saved and hud_saved and asset_family_hud_saved and vfx_material_saved
	else:
		passed = false
		push_error("Player collect_coin method should exist")

	var falling_platform := scene.get_node_or_null("World/platform-falling")
	if falling_platform != null and falling_platform.has_method("_on_body_entered") and player != null:
		falling_platform._on_body_entered(player)
		await _settle_frames(2)
		passed = passed and _assert_true(falling_platform.falling, "Falling platform should enter falling state")
	else:
		passed = false
		push_error("Falling platform smoke target should exist")

	var scene_before_reload := current_scene
	if player != null:
		player.position.y = -11.0
		await _settle_physics_frames(4)
		passed = passed and _assert_true(current_scene != null and current_scene != scene_before_reload and current_scene.get_node_or_null("Player") != null, "Falling below world should reload current scene")
	else:
		passed = false
		push_error("Fall reload smoke target should exist")

	var proof_scene := current_scene
	var proof_player := proof_scene.get_node_or_null("Player") if proof_scene != null else null
	var proof_view := proof_scene.get_node_or_null("View") if proof_scene != null else null
	if proof_player != null and proof_view != null:
		proof_player.global_position = Vector3(-2.0, 3.4, -2.8)
		proof_view.camera_rotation = Vector3(-42, 35, 0)
		proof_view.zoom = 9.0
		await _settle_physics_frames(24)
		var obstacle_goal_saved: bool = await _save_viewport("candy_sky_islands_obstacle_goal_wrapper.png", Rect2i())
		passed = passed and obstacle_goal_saved

		proof_player.global_position = Vector3(-7.0, 2.6, -2.0)
		proof_view.camera_rotation = Vector3(-45, 30, 0)
		proof_view.zoom = 8.0
		await _settle_physics_frames(24)
		var props_background_saved: bool = await _save_viewport("candy_sky_islands_props_background_wrapper.png", Rect2i())
		var props_background_glb_saved: bool = await _save_viewport("candy_sky_islands_props_background_glb_replacement.png", Rect2i())
		passed = passed and props_background_saved and props_background_glb_saved
	else:
		passed = false
		push_error("Obstacle/goal screenshot targets should exist")

	var cleanup_scene := current_scene if current_scene != null else scene
	current_scene = null
	if cleanup_scene != null:
		cleanup_scene.queue_free()
	await _settle_frames(12)
	_finish(passed)

func _settle_frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _settle_physics_frames(count: int) -> void:
	for _i in range(count):
		await physics_frame

func _save_viewport(file_name: String, crop_rect: Rect2i) -> bool:
	await process_frame
	var image := root.get_texture().get_image()
	if crop_rect.size.x > 0 and crop_rect.size.y > 0:
		image = image.get_region(crop_rect)
	var path := "%s/%s" % [OUT_DIR, file_name]
	var error := image.save_png(path)
	if error != OK:
		push_error("Failed to save screenshot: %s" % path)
		return false
	return _assert_nonblank_image(image, file_name)

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

func _collect_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		meshes.append(node as MeshInstance3D)
	for child in node.get_children():
		meshes.append_array(_collect_mesh_instances(child))
	return meshes

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true

func _finish(passed: bool) -> void:
	if passed:
		print("capture_candy_sky_screenshots: PASS")
		quit(0)
	else:
		print("capture_candy_sky_screenshots: FAIL")
		quit(1)
