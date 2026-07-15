class_name ShinokuteEventTimeline
extends RefCounted

var _events: Array = []
var _elapsed := 0.0
var _cursor := 0

func configure(events: Array) -> void:
	_events = []
	for item in events:
		if item is Dictionary:
			_events.append(Dictionary(item).duplicate(true))
	_sort_events()
	reset()

func advance(delta: float) -> Array:
	_elapsed += max(0.0, delta)
	var due: Array = []
	while _cursor < _events.size() and float(Dictionary(_events[_cursor]).get("time", 0.0)) <= _elapsed:
		due.append(Dictionary(_events[_cursor]).duplicate(true))
		_cursor += 1
	return due

func reset() -> void:
	_elapsed = 0.0
	_cursor = 0

func elapsed() -> float:
	return _elapsed

func _sort_events() -> void:
	for i in range(1, _events.size()):
		var current = _events[i]
		var j := i - 1
		while j >= 0 and float(Dictionary(_events[j]).get("time", 0.0)) > float(Dictionary(current).get("time", 0.0)):
			_events[j + 1] = _events[j]
			j -= 1
		_events[j + 1] = current
