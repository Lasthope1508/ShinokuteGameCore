## Single Source of Truth (SSOT) registry for all piece shapes in the game.
## Provides weighted random picking.
class_name PieceLibrary extends RefCounted

# Tuning constants for the Smart Block Spawner algorithm
const DANGER_OCCUPANCY_THRESHOLD: float = 0.55 # Grid is >55% full (45+ cells)
const TIER_1_DANGER_BOOST: float = 1.5
const TIER_3_DANGER_NERF: float = 0.5
const TIER_4_DANGER_NERF: float = 0.2

const GAP_1_BOOST: float = 12.0 # Boost 1x1 block when a line is 1 cell away from clear
const GAP_2_BOOST: float = 8.0  # Boost 2x1 block when a line is 2 cells away from clear
const GAP_3_BOOST: float = 5.0  # Boost 3-cell blocks when a line is 3 cells away from clear

const STREAK_CLEAR_BOOST: float = 2.0 # Boost weight of any block that can immediately cause a clear if streak > 0

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


# Smart / Adaptive spawner that analyzes the grid layout and current streak.
# Adjusts weights dynamically to give smaller blocks during danger, matching block
# sizes when rows/columns are close to clearing, and boosting blocks that keep
# the current clear streak alive.
func pick_smart_piece(allowed_tiers: Array[int], occupancy: Array, turns_without_clear: int) -> PieceShape:
	if _shapes.is_empty():
		return null
		
	# 1. Calculate occupancy stats
	var occupied_cells := 0
	for y in range(9):
		for x in range(9):
			if occupancy[y][x]:
				occupied_cells += 1
				
	var occupancy_ratio := occupied_cells / 81.0
	var is_in_danger := occupancy_ratio > DANGER_OCCUPANCY_THRESHOLD
	
	# Determine AI Director Pacing State
	var relief_mode := (turns_without_clear >= 3 and occupancy_ratio > 0.45)
	var melody_mode := (GameState.current_streak > 0 and not relief_mode)
	var challenge_mode := (occupancy_ratio < 0.30 and not relief_mode and not melody_mode)
	
	# 2. Check row / column gap sizes
	var row_empty_counts = []
	row_empty_counts.resize(9)
	var col_empty_counts = []
	col_empty_counts.resize(9)
	
	for y in range(9):
		var row_occ := 0
		for x in range(9):
			if occupancy[y][x]:
				row_occ += 1
		row_empty_counts[y] = 9 - row_occ
		
	for x in range(9):
		var col_occ := 0
		for y in range(9):
			if occupancy[y][x]:
				col_occ += 1
		col_empty_counts[x] = 9 - col_occ
			
	var has_gap_1 := false
	var has_gap_2 := false
	var has_gap_3 := false
	
	for count in row_empty_counts:
		if count == 1: has_gap_1 = true
		elif count == 2: has_gap_2 = true
		elif count == 3: has_gap_3 = true
		
	for count in col_empty_counts:
		if count == 1: has_gap_1 = true
		elif count == 2: has_gap_2 = true
		elif count == 3: has_gap_3 = true
		
	# 3. Dynamic weight calculation
	var filtered: Array[PieceShape] = []
	var temp_weights: Array[float] = []
	var total_temp_w := 0.0
	
	for s in _shapes:
		if not s.tier in allowed_tiers:
			continue
			
		var w: float = s.weight
		
		# Base danger scaling
		if is_in_danger:
			if s.tier == 1:
				w *= TIER_1_DANGER_BOOST
			elif s.tier == 3:
				w *= TIER_3_DANGER_NERF
			elif s.tier == 4:
				w *= TIER_4_DANGER_NERF
				
		var can_clear := _can_shape_cause_clear(s, occupancy)
		
		# Apply Pacing Mode tweaks
		if relief_mode:
			# Relief Mode: boost savior blocks massively, remove tier 3/4 pieces entirely
			if can_clear:
				w *= 20.0
			elif s.tier >= 3:
				w = 0.0
		elif melody_mode:
			# Melody Mode: support active clear streak/combos
			if can_clear:
				w *= 3.0
		elif challenge_mode:
			# Challenge Mode: safe board, standard distribution
			pass
			
		# Gap-matching boosts (skip in relief mode to prevent cluttering weights)
		if not relief_mode:
			var shape_size := s.cells.size()
			if has_gap_1 and shape_size == 1:
				w *= GAP_1_BOOST
			if has_gap_2 and shape_size == 2:
				w *= GAP_2_BOOST
			if has_gap_3 and shape_size == 3:
				w *= GAP_3_BOOST
				
		filtered.append(s)
		temp_weights.append(w)
		total_temp_w += w
		
	# Fallback if no matching pieces or total weight is zero
	if filtered.is_empty():
		return pick_random_from_tiers(allowed_tiers)
	if total_temp_w <= 0.0:
		return filtered.pick_random()
		
	var roll := randf() * total_temp_w
	var acc := 0.0
	for idx in range(filtered.size()):
		acc += temp_weights[idx]
		if roll <= acc:
			return filtered[idx]
			
	return filtered.back()


# Checks if placing a shape anywhere on the current grid would complete a row or column.
func _can_shape_cause_clear(shape: PieceShape, occupancy: Array) -> bool:
	for y in range(9):
		for x in range(9):
			if _can_fit_at_matrix(occupancy, shape, Vector2i(x, y)):
				if _placement_causes_clear(occupancy, shape, Vector2i(x, y)):
					return true
	return false


# Helper to check if a shape fits at a specific coordinate in the occupancy matrix.
func _can_fit_at_matrix(occupancy: Array, shape: PieceShape, origin: Vector2i) -> bool:
	for cell in shape.cells:
		var target := origin + cell
		if target.x < 0 or target.x >= 9 or target.y < 0 or target.y >= 9:
			return false
		if occupancy[target.y][target.x]:
			return false
	return true


# Helper to check if placing a shape at origin completes any row or column.
func _placement_causes_clear(occupancy: Array, shape: PieceShape, origin: Vector2i) -> bool:
	var placed_cells = []
	for cell in shape.cells:
		placed_cells.append(origin + cell)
		
	for pc in placed_cells:
		# Check row pc.y
		var row_complete := true
		for x in range(9):
			if x != pc.x and not occupancy[pc.y][x]:
				row_complete = false
				break
		if row_complete:
			return true
			
		# Check column pc.x
		var col_complete := true
		for y in range(9):
			if y != pc.y and not occupancy[y][pc.x]:
				col_complete = false
				break
		if col_complete:
			return true
			
	return false
