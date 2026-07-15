class_name ShinokuteMapLayoutGenerator2D
extends RefCounted

func build_layout(config: Dictionary = {}) -> Dictionary:
	var rooms := _normalize_rooms(Array(config.get("rooms", [])), config)
	var corridors: Array = []
	var layout := {
		"rooms": rooms,
		"corridors": corridors,
		"floor_cells": []
	}
	var floor_index := {}
	for room in rooms:
		_add_room_cells(floor_index, Dictionary(room))
	if String(config.get("connect", "sequence")) == "sequence":
		for i in range(max(0, rooms.size() - 1)):
			var corridor := _connect_rooms(Dictionary(rooms[i]), Dictionary(rooms[i + 1]), String(config.get("corridor_axis", "x_first")))
			corridors.append(corridor)
			_add_cells(floor_index, Array(corridor.get("cells", [])))
	layout["corridors"] = corridors
	layout["floor_cells"] = floor_index.keys()
	return layout

func _normalize_rooms(room_entries: Array, config: Dictionary) -> Array:
	var rooms: Array = []
	var width: int = int(config.get("width", 0))
	var height: int = int(config.get("height", 0))
	for index in range(room_entries.size()):
		var entry = room_entries[index]
		if not (entry is Dictionary):
			continue
		var room := Dictionary(entry).duplicate(true)
		var requested_size: Vector2i = Vector2i(room.get("size", Vector2i.ONE))
		var size: Vector2i = Vector2i(max(1, requested_size.x), max(1, requested_size.y))
		var position: Vector2i = _clamp_position(Vector2i(room.get("position", Vector2i.ZERO)), size, width, height)
		room["id"] = String(room.get("id", "room_%d" % index))
		room["position"] = position
		room["size"] = size
		room["center"] = position + Vector2i(int(size.x / 2), int(size.y / 2))
		rooms.append(room)
	return rooms

func _clamp_position(position: Vector2i, size: Vector2i, width: int, height: int) -> Vector2i:
	var max_x: int = width - max(1, size.x)
	var max_y: int = height - max(1, size.y)
	if width <= 0:
		max_x = position.x
	if height <= 0:
		max_y = position.y
	return Vector2i(int(clamp(position.x, 0, max_x)), int(clamp(position.y, 0, max_y)))

func _connect_rooms(a: Dictionary, b: Dictionary, axis: String) -> Dictionary:
	var start := Vector2i(a.get("center", Vector2i.ZERO))
	var end := Vector2i(b.get("center", Vector2i.ZERO))
	var cells: Array = [start]
	var cursor := start
	if axis == "y_first":
		cursor = _walk_axis(cursor, Vector2i(cursor.x, end.y), cells, true)
		cursor = _walk_axis(cursor, end, cells, false)
	else:
		cursor = _walk_axis(cursor, Vector2i(end.x, cursor.y), cells, false)
		cursor = _walk_axis(cursor, end, cells, true)
	return {
		"from": String(a.get("id", "")),
		"to": String(b.get("id", "")),
		"cells": cells.duplicate(true)
	}

func _walk_axis(from_cell: Vector2i, to_cell: Vector2i, cells: Array, vertical: bool) -> Vector2i:
	var cursor := from_cell
	if vertical:
		var step_y := 1 if to_cell.y >= cursor.y else -1
		while cursor.y != to_cell.y:
			cursor.y += step_y
			cells.append(cursor)
	else:
		var step_x := 1 if to_cell.x >= cursor.x else -1
		while cursor.x != to_cell.x:
			cursor.x += step_x
			cells.append(cursor)
	return cursor

func _add_room_cells(index: Dictionary, room: Dictionary) -> void:
	var position := Vector2i(room.get("position", Vector2i.ZERO))
	var size := Vector2i(room.get("size", Vector2i.ONE))
	for y in range(position.y, position.y + size.y):
		for x in range(position.x, position.x + size.x):
			index[Vector2i(x, y)] = true

func _add_cells(index: Dictionary, cells: Array) -> void:
	for cell in cells:
		index[Vector2i(cell)] = true
