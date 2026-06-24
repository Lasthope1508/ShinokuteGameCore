## Single Source of Truth (SSOT) registry for all piece shapes in the game.
## Provides weighted random picking.
class_name PieceLibrary extends RefCounted

const SHAPES_REGISTRY: Array[Dictionary] = [
	{
		"name": "mono",
		"display_name": "Mono",
		"cells": [Vector2i(0, 0)],
		"weight": 0.4,
		"tier": 1
	},
	{
		"name": "domino_h",
		"display_name": "Domino H",
		"cells": [Vector2i(0, 0), Vector2i(1, 0)],
		"weight": 1.5,
		"tier": 1
	},
	{
		"name": "domino_v",
		"display_name": "Domino V",
		"cells": [Vector2i(0, 0), Vector2i(0, 1)],
		"weight": 1.5,
		"tier": 1
	},
	{
		"name": "tri_h",
		"display_name": "Tri H",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
		"weight": 1.5,
		"tier": 1
	},
	{
		"name": "tri_v",
		"display_name": "Tri V",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)],
		"weight": 1.5,
		"tier": 1
	},
	{
		"name": "corner_3",
		"display_name": "Corner 3",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
		"weight": 1.4,
		"tier": 1
	},
	{
		"name": "l_shape",
		"display_name": "L",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)],
		"weight": 1.0,
		"tier": 2
	},
	{
		"name": "j_shape",
		"display_name": "J",
		"cells": [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 2)],
		"weight": 1.0,
		"tier": 2
	},
	{
		"name": "t_shape",
		"display_name": "T",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
		"weight": 1.0,
		"tier": 2
	},
	{
		"name": "i_shape_h",
		"display_name": "I-4 H",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
		"weight": 0.8,
		"tier": 3
	},
	{
		"name": "i_shape_v",
		"display_name": "I-4 V",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)],
		"weight": 0.8,
		"tier": 3
	},
	{
		"name": "s_shape",
		"display_name": "S",
		"cells": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
		"weight": 0.9,
		"tier": 2
	},
	{
		"name": "square_2",
		"display_name": "Square 2",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		"weight": 1.2,
		"tier": 2
	},
	{
		"name": "square_3",
		"display_name": "Square 3",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)],
		"weight": 0.5,
		"tier": 4
	},
	{
		"name": "u_shape",
		"display_name": "U Shape",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(2, 1), Vector2i(2, 0)],
		"weight": 0.8,
		"tier": 4
	},
	{
		"name": "t_shape_large",
		"display_name": "Large T",
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)],
		"weight": 0.7,
		"tier": 3
	},
	{
		"name": "l_shape_3x3",
		"display_name": "L 3x3",
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)],
		"weight": 0.7,
		"tier": 3
	},
	{
		"name": "l_shape_inverted_3x3",
		"display_name": "L Inverted 3x3",
		"cells": [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(1, 2), Vector2i(0, 2)],
		"weight": 0.7,
		"tier": 3
	}
]

var _shapes: Array[PieceShape] = []
var _total_weight: float = 0.0


func _init(_pieces_dir: String = "") -> void:
	_shapes.clear()
	_total_weight = 0.0
	
	for data in SHAPES_REGISTRY:
		var shape := PieceShape.new()
		var cells_typed: Array[Vector2i] = []
		for cell in data.cells:
			cells_typed.append(cell)
		shape.cells = cells_typed
		shape.display_name = data.display_name
		shape.weight = data.weight
		shape.tier = data.get("tier", 1)
		_register_shape(shape)


func _register_shape(shape: PieceShape) -> void:
	if shape and shape.cells.size() > 0:
		_shapes.append(shape)
		_total_weight += max(0.0, shape.weight)


func get_all() -> Array[PieceShape]:
	return _shapes.duplicate()


func is_empty() -> bool:
	return _shapes.is_empty()


# Weighted random pick. Falls back to uniform if every weight is 0.
func pick_random() -> PieceShape:
	if _shapes.is_empty():
		return null
	if _total_weight <= 0.0:
		return _shapes.pick_random()
	var roll := randf() * _total_weight
	var acc := 0.0
	for s in _shapes:
		acc += max(0.0, s.weight)
		if roll <= acc:
			return s
	return _shapes.back()


# Weighted random pick restricted to allowed tiers.
func pick_random_from_tiers(allowed_tiers: Array[int]) -> PieceShape:
	var filtered: Array[PieceShape] = []
	var total_w := 0.0
	for s in _shapes:
		if s.tier in allowed_tiers:
			filtered.append(s)
			total_w += max(0.0, s.weight)
	if filtered.is_empty():
		return pick_random()
	var roll := randf() * total_w
	var acc := 0.0
	for s in filtered:
		acc += max(0.0, s.weight)
		if roll <= acc:
			return s
	return filtered.back()
