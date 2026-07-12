extends Node3D

const CandyObbyRouteGenerator := preload("res://scripts/obby_route_generator.gd")

@export var small_platform_scene: PackedScene
@export var medium_platform_scene: PackedScene
@export var large_platform_scene: PackedScene
@export var falling_platform_scene: PackedScene
@export var goal_scene: PackedScene
@export var coin_scene: PackedScene
@export var prop_scenes: Dictionary = {}
@export var generated_root_name := "GeneratedStage"
@export var preserve_non_generated_children := true

var _generated_root: Node3D

func apply_difficulty_profile(profile: Dictionary) -> void:
	_clear_generated_stage()
	_generated_root = Node3D.new()
	_generated_root.name = generated_root_name
	add_child(_generated_root)
	var segments: Array = CandyObbyRouteGenerator.build_stage_segments(profile)
	for index in segments.size():
		var segment: Dictionary = segments[index]
		_spawn_segment(segment, index, profile)
	var environment_segments: Array = CandyObbyRouteGenerator.build_environment_segments(profile, segments)
	for index in environment_segments.size():
		var segment: Dictionary = environment_segments[index]
		_spawn_environment_segment(segment, index)

func _clear_generated_stage() -> void:
	var old := get_node_or_null(generated_root_name)
	if old != null:
		old.queue_free()
		remove_child(old)
	if not preserve_non_generated_children:
		for child in get_children():
			child.queue_free()

func _spawn_segment(segment: Dictionary, index: int, profile: Dictionary) -> void:
	var role := String(segment.get("role", "platform"))
	var platform_kind := String(segment.get("platform", "small"))
	var position := _vector3_from_value(segment.get("position", Vector3.ZERO))
	var rotation_degrees_y := float(segment.get("rotation_y", 0.0))
	var node := _instantiate_scene(_platform_scene_for_kind(platform_kind))
	if node != null:
		_configure_spawned_node(node, "%03d_%s_%s" % [index, role, platform_kind], position, rotation_degrees_y, segment)
		if node.has_method("apply_difficulty_profile"):
			node.apply_difficulty_profile(profile)
	if bool(segment.get("coin", false)):
		_spawn_coin("%03d_coin" % index, position + _vector3_from_value(segment.get("coin_offset", Vector3(0, 1.15, 0))))
	for coin_index in Array(segment.get("coin_offsets", [])).size():
		var offsets: Array = segment.get("coin_offsets", [])
		_spawn_coin("%03d_coin_%02d" % [index, coin_index], position + _vector3_from_value(offsets[coin_index]))
	if role == "goal":
		var goal := _instantiate_scene(goal_scene)
		if goal != null:
			var goal_position := position + _vector3_from_value(segment.get("goal_offset", Vector3(0, 1.15, 0)))
			_configure_spawned_node(goal, "%03d_goal" % index, goal_position, rotation_degrees_y, segment)

func _spawn_environment_segment(segment: Dictionary, index: int) -> void:
	var kind := String(segment.get("kind", ""))
	var node := _instantiate_scene(prop_scenes.get(kind))
	if node == null:
		return
	var position := _vector3_from_value(segment.get("position", Vector3.ZERO))
	var rotation_degrees_y := float(segment.get("rotation_y", 0.0))
	_configure_spawned_node(node, "%03d_env_%s" % [index, kind], position, rotation_degrees_y, segment)

func _spawn_coin(node_name: String, position: Vector3) -> void:
	var coin := _instantiate_scene(coin_scene)
	if coin == null:
		return
	coin.name = node_name
	coin.position = position
	_generated_root.add_child(coin)

func _configure_spawned_node(node: Node3D, node_name: String, position: Vector3, rotation_degrees_y: float, segment: Dictionary) -> void:
	node.name = node_name
	node.position = position
	node.rotation_degrees.y = rotation_degrees_y
	if segment.has("scale"):
		node.scale = _vector3_from_value(segment["scale"])
	_generated_root.add_child(node)

func _platform_scene_for_kind(kind: String) -> PackedScene:
	match kind:
		"none":
			return null
		"medium":
			return medium_platform_scene
		"large":
			return large_platform_scene
		"falling":
			return falling_platform_scene
		_:
			return small_platform_scene

func _instantiate_scene(scene: PackedScene) -> Node3D:
	if scene == null:
		return null
	var node := scene.instantiate()
	if node is Node3D:
		return node
	node.queue_free()
	return null

func _vector3_from_value(value) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	if value is Dictionary:
		return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
	return Vector3.ZERO
