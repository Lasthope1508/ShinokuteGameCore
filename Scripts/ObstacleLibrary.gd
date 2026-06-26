## Single Source of Truth (SSOT) registry for custom obstacle shapes.
class_name ObstacleLibrary extends RefCounted

const SHAPES: Array[Dictionary] = [
	{
		"name": "demo_2x2",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
	},
	{
		"name": "cross",
		"cells": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]
	},
	{
		"name": "hollow_square",
		"cells": [
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
			Vector2i(0, 1),                 Vector2i(2, 1),
			Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)
		]
	},
	{
		"name": "u_shape",
		"cells": [
			Vector2i(0, 0),                 Vector2i(2, 0),
			Vector2i(0, 1),                 Vector2i(2, 1),
			Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)
		]
	},
	{
		"name": "diagonal",
		"cells": [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2), Vector2i(3, 3)]
	},
	{
		"name": "h_shape",
		"cells": [
			Vector2i(0, 0),                 Vector2i(2, 0),
			Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
			Vector2i(0, 2),                 Vector2i(2, 2)
		]
	}
]

static func get_random_shape() -> Array[Vector2i]:
	var entry = SHAPES.pick_random()
	var cells: Array[Vector2i] = []
	for cell in entry.cells:
		cells.append(cell)
	return cells

static func get_shape_by_name(name: String) -> Array[Vector2i]:
	for s in SHAPES:
		if s.name == name:
			var cells: Array[Vector2i] = []
			for cell in s.cells:
				cells.append(cell)
			return cells
	return []


static func get_shape_by_tier(tier: int) -> Array[Vector2i]:
	var clamped_tier = clamp(tier, 0, 3)
	var candidates: Array[Dictionary] = []
	match clamped_tier:
		0:
			for s in SHAPES:
				if s.cells.size() == 4:
					candidates.append(s)
		1:
			for s in SHAPES:
				if s.cells.size() == 5:
					candidates.append(s)
		2:
			for s in SHAPES:
				if s.cells.size() == 7:
					candidates.append(s)
		3:
			for s in SHAPES:
				if s.cells.size() == 8:
					candidates.append(s)
					
	if candidates.is_empty():
		return get_random_shape()
		
	var entry = candidates.pick_random()
	var cells: Array[Vector2i] = []
	for cell in entry.cells:
		cells.append(cell)
	return cells

