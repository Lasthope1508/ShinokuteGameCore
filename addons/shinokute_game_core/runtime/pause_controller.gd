class_name ShinokutePauseController
extends Node

signal paused_changed(is_paused: bool)

var _is_paused := false
var _paused_nodes: Array[Node] = []
var _unpaused_nodes: Array[Node] = []
var _paused_state: Node.ProcessMode = Node.PROCESS_MODE_DISABLED
var _not_paused_state: Node.ProcessMode = Node.PROCESS_MODE_INHERIT

func configure_process_sets(
	paused_nodes: Array,
	unpaused_nodes: Array,
	paused_state: Node.ProcessMode = Node.PROCESS_MODE_DISABLED,
	not_paused_state: Node.ProcessMode = Node.PROCESS_MODE_INHERIT
) -> void:
	_paused_nodes = _filter_nodes(paused_nodes)
	_unpaused_nodes = _filter_nodes(unpaused_nodes)
	_paused_state = paused_state
	_not_paused_state = not_paused_state
	_apply_process_modes()

func set_paused(value: bool) -> void:
	if _is_paused == value:
		_apply_process_modes()
		return
	_is_paused = value
	_apply_process_modes()
	paused_changed.emit(_is_paused)

func toggle_paused() -> void:
	set_paused(not _is_paused)

func is_paused() -> bool:
	return _is_paused

func _apply_process_modes() -> void:
	for node in _paused_nodes:
		if is_instance_valid(node):
			node.process_mode = _paused_state if _is_paused else _not_paused_state
	for node in _unpaused_nodes:
		if is_instance_valid(node):
			node.process_mode = _not_paused_state if _is_paused else _paused_state

func _filter_nodes(values: Array) -> Array[Node]:
	var nodes: Array[Node] = []
	for value in values:
		if value is Node:
			nodes.append(value)
	return nodes
