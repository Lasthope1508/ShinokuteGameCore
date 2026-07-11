extends Node

signal level_started(level_index: int, level: Resource)
signal level_completed(level_index: int, level: Resource)
signal level_failed(level_index: int, level: Resource)

@export var progression_config: ShinokuteProgressionCatalog
@export var player_path := NodePath("../Player")
@export var world_path := NodePath("../World")
@export var hud_path := NodePath("../HUD")

static var session_level_index := 0

var current_level: Resource
var _transition_in_progress := false
var _player_spawn_transform := Transform3D.IDENTITY
var _has_player_spawn_transform := false

func _ready() -> void:
	if progression_config == null:
		push_warning("GameProgression missing progression_config")
		return
	var errors := progression_config.validate()
	for error in errors:
		push_error(error)
	if not errors.is_empty():
		return
	_capture_player_spawn_transform()
	_start_level(session_level_index)

func _start_level(level_index: int) -> void:
	current_level = progression_config.get_level(level_index)
	if current_level == null:
		push_error("Missing progression level at index %s" % level_index)
		return
	var profile: Dictionary = current_level.difficulty_profile()
	_apply_profile_to_player(profile)
	_apply_profile_to_world(profile)
	_connect_goal_nodes()
	_connect_player_failure()
	_reset_player_for_level()
	_notify_hud(level_index, current_level)
	level_started.emit(level_index, current_level)
	_transition_in_progress = false

func _capture_player_spawn_transform() -> void:
	var player := get_node_or_null(player_path) as Node3D
	if player == null:
		return
	_player_spawn_transform = player.global_transform
	_has_player_spawn_transform = true

func _apply_profile_to_player(profile: Dictionary) -> void:
	var player := get_node_or_null(player_path)
	if player == null:
		return
	if player.has_method("apply_progression_profile"):
		player.apply_progression_profile(profile)
	if player.has_signal("fell_out_of_bounds"):
		var callable := Callable(self, "_on_player_fell_out_of_bounds")
		if not player.is_connected("fell_out_of_bounds", callable):
			player.connect("fell_out_of_bounds", callable)
	if "fall_policy" in player:
		player.fall_policy = "emit_only"

func _reset_player_for_level() -> void:
	if not _has_player_spawn_transform:
		_capture_player_spawn_transform()
	var player := get_node_or_null(player_path)
	if player != null and player.has_method("reset_for_level"):
		player.reset_for_level(_player_spawn_transform)

func _apply_profile_to_world(profile: Dictionary) -> void:
	var world := get_node_or_null(world_path)
	if world == null:
		return
	_apply_profile_recursive(world, profile)

func _apply_profile_recursive(node: Node, profile: Dictionary) -> void:
	if node.has_method("apply_difficulty_profile"):
		node.apply_difficulty_profile(profile)
	for child in node.get_children():
		_apply_profile_recursive(child, profile)

func _connect_goal_nodes() -> void:
	var world := get_node_or_null(world_path)
	if world == null:
		return
	_connect_goal_recursive(world)

func _connect_goal_recursive(node: Node) -> void:
	if node.has_signal("goal_reached"):
		var callable := Callable(self, "_on_goal_reached")
		if not node.is_connected("goal_reached", callable):
			node.connect("goal_reached", callable)
	for child in node.get_children():
		_connect_goal_recursive(child)

func _connect_player_failure() -> void:
	var player := get_node_or_null(player_path)
	if player == null or not player.has_signal("fell_out_of_bounds"):
		return
	var callable := Callable(self, "_on_player_fell_out_of_bounds")
	if not player.is_connected("fell_out_of_bounds", callable):
		player.connect("fell_out_of_bounds", callable)

func _notify_hud(level_index: int, level: Resource) -> void:
	var hud := get_node_or_null(hud_path)
	if hud != null and hud.has_method("_on_level_started"):
		hud._on_level_started(level_index, level.display_name, level.difficulty_tier)

func _on_goal_reached(body: Node) -> void:
	if _transition_in_progress:
		return
	var player := get_node_or_null(player_path)
	if player != null and body != player:
		return
	if current_level == null:
		return
	var coins := 0
	if player != null and "coins" in player:
		coins = int(player.coins)
	var condition: Dictionary = current_level.completion_condition
	var coin_quota := int(condition.get("coin_quota", 0))
	if coins < coin_quota:
		return
	level_completed.emit(session_level_index, current_level)
	session_level_index = progression_config.get_next_level_index(session_level_index)
	_request_next_level_start()

func _on_player_fell_out_of_bounds() -> void:
	if _transition_in_progress:
		return
	if current_level != null:
		level_failed.emit(session_level_index, current_level)
	_request_current_level_restart()

func _request_current_level_restart() -> void:
	if _transition_in_progress:
		return
	_transition_in_progress = true
	call_deferred("_restart_current_level")

func _request_next_level_start() -> void:
	if _transition_in_progress:
		return
	_transition_in_progress = true
	call_deferred("_start_next_level")

func _restart_current_level() -> void:
	_start_level(session_level_index)

func _start_next_level() -> void:
	_start_level(session_level_index)
