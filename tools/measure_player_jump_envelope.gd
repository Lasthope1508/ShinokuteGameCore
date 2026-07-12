extends SceneTree

const PLAYER_SCENE := "res://objects/player.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_disable_test_audio_events()
	var world := Node3D.new()
	world.name = "JumpEnvelopeWorld"
	root.add_child(world)

	var floor := StaticBody3D.new()
	floor.name = "FlatFloor"
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 0.1, 200)
	floor_shape.shape = box
	floor.add_child(floor_shape)
	floor.position.y = -0.05
	world.add_child(floor)

	var view := Node3D.new()
	view.name = "View"
	view.rotation.y = PI / 2.0
	world.add_child(view)

	var player := (load(PLAYER_SCENE) as PackedScene).instantiate()
	player.name = "Player"
	player.view = view
	player.position = Vector3(0, 1.2, 0)
	world.add_child(player)

	for _i in range(60):
		await physics_frame
		if player.is_on_floor():
			break

	Input.action_press("move_forward")
	for _i in range(30):
		await physics_frame
	var takeoff_x: float = player.global_position.x
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")

	for _i in range(16):
		await physics_frame
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")

	var airborne_seen := false
	var landing_x: float = player.global_position.x
	for _i in range(240):
		await physics_frame
		if not player.is_on_floor():
			airborne_seen = true
		elif airborne_seen:
			landing_x = player.global_position.x
			break
	Input.action_release("move_forward")

	var measured_distance := absf(landing_x - takeoff_x)
	print("PLAYER_JUMP_ENVELOPE takeoff_x=%.3f landing_x=%.3f measured_max_horizontal=%.3f" % [takeoff_x, landing_x, measured_distance])
	world.queue_free()
	await process_frame
	quit(0)

func _disable_test_audio_events() -> void:
	var audio := root.get_node_or_null("Audio")
	if audio != null and audio.has_method("set_sfx_enabled"):
		audio.set_sfx_enabled(false)
