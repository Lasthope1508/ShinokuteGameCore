class_name ShinokuteSpawnPool
extends Node

signal instance_spawned(instance: Node)
signal instance_returned(instance: Node)

var packed_scene: PackedScene
var parent_node: Node
var active_list: Array[Node] = []
var inactive_list: Array[Node] = []

func _exit_tree() -> void:
	clear_pool()

func configure(scene: PackedScene, parent: Node) -> void:
	packed_scene = scene
	parent_node = parent

func spawn(config_callback: Callable = Callable()) -> Node:
	if packed_scene == null or parent_node == null:
		return null
	var instance: Node
	if inactive_list.is_empty():
		instance = packed_scene.instantiate()
	else:
		instance = inactive_list.pop_back()
	if config_callback.is_valid():
		config_callback.call(instance)
	if instance.get_parent() == null:
		parent_node.add_child(instance)
	if not active_list.has(instance):
		active_list.append(instance)
	instance_spawned.emit(instance)
	return instance

func return_instance(instance: Node) -> int:
	if instance == null or not active_list.has(instance):
		return ERR_DOES_NOT_EXIST
	active_list.erase(instance)
	if instance.get_parent() != null:
		instance.get_parent().remove_child(instance)
	if not inactive_list.has(instance):
		inactive_list.append(instance)
	instance_returned.emit(instance)
	return OK

func clear_pool() -> void:
	for instance in inactive_list:
		if is_instance_valid(instance):
			instance.free()
	inactive_list.clear()

func get_active_count() -> int:
	return active_list.size()

func get_inactive_count() -> int:
	return inactive_list.size()
