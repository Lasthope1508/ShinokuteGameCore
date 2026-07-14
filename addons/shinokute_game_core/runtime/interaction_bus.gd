class_name ShinokuteInteractionBus
extends Node

signal interaction_published(channel: String, payload: Dictionary)

var _subscribers: Dictionary = {}

func subscribe(channel: String, callback: Callable) -> int:
	var key := channel.strip_edges()
	if key.is_empty() or not callback.is_valid():
		return ERR_INVALID_PARAMETER
	if not _subscribers.has(key):
		_subscribers[key] = []
	if not _subscribers[key].has(callback):
		_subscribers[key].append(callback)
	return OK

func unsubscribe(channel: String, callback: Callable) -> void:
	var key := channel.strip_edges()
	if not _subscribers.has(key):
		return
	_subscribers[key].erase(callback)

func publish(channel: String, payload: Dictionary = {}) -> int:
	var key := channel.strip_edges()
	if key.is_empty():
		return ERR_INVALID_PARAMETER
	interaction_published.emit(key, payload)
	var delivered := 0
	for callback in _subscribers.get(key, []):
		if callback.is_valid():
			callback.call(payload)
			delivered += 1
	return delivered
