extends SceneTree

const PLAYER_GLB := "res://assets/themes/candy_sky_islands/source/model_candidates/character_shinokute_human.glb"
const CHARACTER_SCENE := "res://objects/character.tscn"
const VISUAL := "ShinokuteCharacterVisual"
const MODEL_SCALE := 0.68

func _init() -> void:
	var visual_scene: PackedScene = load(PLAYER_GLB)
	if visual_scene == null:
		push_error("Shinokute player GLB should load: %s" % PLAYER_GLB)
		quit(1)
		return

	var root := Node3D.new()
	root.name = "character"

	var visual := visual_scene.instantiate()
	visual.name = VISUAL
	root.add_child(visual)
	visual.owner = root

	var animation_player := AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	root.add_child(animation_player)
	animation_player.owner = root

	var library := AnimationLibrary.new()
	library.add_animation("idle", _make_idle_animation())
	library.add_animation("walk", _make_walk_animation())
	library.add_animation("run", _make_run_animation())
	library.add_animation("jump", _make_jump_animation())
	animation_player.add_animation_library("", library)
	animation_player.autoplay = "idle"

	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	if pack_error != OK:
		push_error("Failed to pack character scene: %s" % pack_error)
		quit(1)
		return
	var save_error := ResourceSaver.save(packed, CHARACTER_SCENE)
	if save_error != OK:
		push_error("Failed to save character scene: %s" % save_error)
		root.free()
		quit(1)
		return
	print("wrote ", CHARACTER_SCENE)
	root.free()
	quit(0)

func _make_idle_animation() -> Animation:
	var animation := Animation.new()
	animation.length = 1.0
	animation.step = 1.0 / 60.0
	animation.loop_mode = Animation.LOOP_LINEAR
	_add_position_track(animation, VISUAL, [
		[0.0, Vector3.ZERO],
		[0.25, Vector3(0.0, 0.018, 0.0)],
		[0.50, Vector3(0.0, 0.030, 0.0)],
		[0.75, Vector3(0.0, 0.014, 0.0)],
		[1.0, Vector3.ZERO],
	])
	_add_scale_track(animation, VISUAL, [
		[0.0, Vector3.ONE],
		[0.5, Vector3(1.015, 0.988, 1.015)],
		[1.0, Vector3.ONE],
	])
	_add_scale_track(animation, "%s/root/idle_sign_aura_ring" % VISUAL, [
		[0.0, Vector3(0.55, 0.55, 0.55)],
		[0.5, Vector3(1.15, 1.15, 1.15)],
		[1.0, Vector3(0.55, 0.55, 0.55)],
	])
	return animation

func _make_walk_animation() -> Animation:
	var animation := Animation.new()
	animation.length = 0.5
	animation.step = 1.0 / 60.0
	animation.loop_mode = Animation.LOOP_LINEAR
	_add_position_track(animation, VISUAL, [
		[0.0, Vector3.ZERO],
		[0.125, Vector3(0.0, 0.045, 0.0)],
		[0.25, Vector3.ZERO],
		[0.375, Vector3(0.0, 0.045, 0.0)],
		[0.5, Vector3.ZERO],
	])
	_add_scale_track(animation, VISUAL, [
		[0.0, Vector3.ONE],
		[0.25, Vector3(1.025, 0.98, 1.025)],
		[0.5, Vector3.ONE],
	])
	return animation

func _make_run_animation() -> Animation:
	var animation := Animation.new()
	animation.length = 0.35
	animation.step = 1.0 / 60.0
	animation.loop_mode = Animation.LOOP_LINEAR
	_add_position_track(animation, VISUAL, [
		[0.0, Vector3.ZERO],
		[0.0875, Vector3(0.0, 0.065, 0.0)],
		[0.175, Vector3.ZERO],
		[0.2625, Vector3(0.0, 0.065, 0.0)],
		[0.35, Vector3.ZERO],
	])
	_add_scale_track(animation, VISUAL, [
		[0.0, Vector3(1.035, 0.975, 1.035)],
		[0.175, Vector3(0.99, 1.025, 0.99)],
		[0.35, Vector3(1.035, 0.975, 1.035)],
	])
	return animation

func _make_jump_animation() -> Animation:
	var animation := Animation.new()
	animation.length = 0.7
	animation.step = 1.0 / 60.0
	animation.loop_mode = Animation.LOOP_NONE
	_add_position_track(animation, VISUAL, [
		[0.0, Vector3.ZERO],
		[0.18, Vector3(0.0, 0.10, 0.0)],
		[0.35, Vector3(0.0, 0.16, 0.0)],
		[0.7, Vector3.ZERO],
	])
	_add_scale_track(animation, VISUAL, [
		[0.0, Vector3(1.03, 0.97, 1.03)],
		[0.22, Vector3(0.98, 1.04, 0.98)],
		[0.7, Vector3.ONE],
	])
	return animation

func _add_position_track(animation: Animation, path: String, keys: Array) -> void:
	var track := animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(track, NodePath(path))
	for item in keys:
		animation.track_insert_key(track, item[0], item[1])

func _add_scale_track(animation: Animation, path: String, keys: Array) -> void:
	var track := animation.add_track(Animation.TYPE_SCALE_3D)
	animation.track_set_path(track, NodePath(path))
	for item in keys:
		animation.track_insert_key(track, item[0], item[1])

func _p(x: float, y: float, z: float) -> Vector3:
	return Vector3(x, y, z) * MODEL_SCALE
