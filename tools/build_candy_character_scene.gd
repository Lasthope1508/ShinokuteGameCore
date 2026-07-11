extends SceneTree

const PLAYER_GLB := "res://assets/themes/candy_sky_islands/models/character_candy_marshmallow.glb"
const CHARACTER_SCENE := "res://objects/character.tscn"

func _init() -> void:
	var visual_scene: PackedScene = load(PLAYER_GLB)
	if visual_scene == null:
		push_error("Candy player GLB should load: %s" % PLAYER_GLB)
		quit(1)
		return

	var root := Node3D.new()
	root.name = "character"

	var visual := visual_scene.instantiate()
	visual.name = "CandyCharacterVisual"
	root.add_child(visual)
	visual.owner = root

	var animation_player := AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	root.add_child(animation_player)
	animation_player.owner = root

	var library := AnimationLibrary.new()
	library.add_animation("idle", _make_bob_animation(1.2, 0.025, true))
	library.add_animation("walk", _make_bob_animation(0.55, 0.055, true))
	library.add_animation("jump", _make_bob_animation(0.7, 0.14, false))
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
		quit(1)
		return
	print("wrote ", CHARACTER_SCENE)
	quit(0)

func _make_bob_animation(length: float, bob_height: float, loop: bool) -> Animation:
	var animation := Animation.new()
	animation.length = length
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE

	var track := animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(track, NodePath("CandyCharacterVisual"))
	animation.track_insert_key(track, 0.0, Vector3.ZERO)
	animation.track_insert_key(track, length * 0.5, Vector3(0, bob_height, 0))
	animation.track_insert_key(track, length, Vector3.ZERO)

	var scale_track := animation.add_track(Animation.TYPE_SCALE_3D)
	animation.track_set_path(scale_track, NodePath("CandyCharacterVisual"))
	animation.track_insert_key(scale_track, 0.0, Vector3.ONE)
	animation.track_insert_key(scale_track, length * 0.5, Vector3(1.03, 0.97, 1.03))
	animation.track_insert_key(scale_track, length, Vector3.ONE)

	return animation
