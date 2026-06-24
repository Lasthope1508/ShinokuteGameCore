## Bottom tray with three PieceSlot children. Auto-refills when all three slots
## empty, and exposes helpers for game-over detection and the ADReward effect
## (replace remaining pieces with single blocks).
class_name PieceTray extends Control

signal piece_picked(piece: Piece)
signal tray_refilled

@export var theme_config: ThemeConfig

# Needed so spawned pieces can do global → cell conversions during drag.
var grid: Grid
var drag_layer: Control

@onready var slot1: PieceSlot = $HBox/PieceSlot1
@onready var slot2: PieceSlot = $HBox/PieceSlot2
@onready var slot3: PieceSlot = $HBox/PieceSlot3

var _slots: Array[PieceSlot] = []
var _library: PieceLibrary


func _ready() -> void:
	_slots = [slot1, slot2, slot3]
	_library = PieceLibrary.new()
	for s in _slots:
		s.piece_picked.connect(_on_slot_piece_picked)
		
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_update_layout_padding()


func _on_theme_changed(_name: String, _config: ThemeConfig) -> void:
	_update_layout_padding()


func _update_layout_padding() -> void:
	var active_theme = ThemeManager.get_active_theme()
	var bottom_margin = 60.0
	if active_theme and "tray_bottom_margin" in active_theme:
		bottom_margin = active_theme.tray_bottom_margin
	add_theme_constant_override("margin_bottom", bottom_margin)


# Wires dependencies; must be called before refill() / fill_with_single_blocks().
func setup(p_grid: Grid, p_drag_layer: Control) -> void:
	grid = p_grid
	drag_layer = p_drag_layer


# Populates all three slots with new random pieces, staggered with a small bump.
# Re-rolls the triplet up to MAX_REROLLS times as long as no shape fits the
# current grid, so the player is never handed a fully unusable refill — within
# the assist budget. Past the cap, the first draw is accepted and game-over
# proceeds normally, keeping the difficulty curve intact.
const MAX_REROLLS: int = 30

func refill() -> void:
	if _library == null or _library.is_empty():
		push_warning("PieceTray.refill: piece library is empty, refill skipped")
		return
	var occupancy: Array = grid.snapshot_occupancy() if grid else []
	var shapes: Array[PieceShape] = []
	var colors: Array[Color] = []
	var rerolls: int = 0
	var consumed_assist: bool = false
	while true:
		shapes.clear()
		colors.clear()
		for i in _slots.size():
			var allowed_tiers = _get_slot_allowed_tiers(i, GameState.current_score)
			shapes.append(_library.pick_random_from_tiers(allowed_tiers))
			colors.append(_random_color())
		if grid == null or _any_shape_playable(shapes, occupancy):
			break
		if GameState.assists_used >= GameState.MAX_ASSISTS:
			break
		# One assist charged per refill attempt (not per reroll).
		if not consumed_assist:
			GameState.assists_used += 1
			consumed_assist = true
		rerolls += 1
		if rerolls >= MAX_REROLLS:
			break

	var delay: float = 0.0
	for i in _slots.size():
		if shapes[i] == null:
			continue
		_slots[i].populate(shapes[i], colors[i], grid, drag_layer, delay)
		delay += 0.10
	tray_refilled.emit()


func _any_shape_playable(shapes: Array[PieceShape], occupancy: Array) -> bool:
	for s in shapes:
		if GridSolver.can_shape_fit(occupancy, s):
			return true
	return false


# Regenerates only EMPTY slots, leaving any held piece untouched. Re-rolls
# until at least one shape across the fixed + fresh set is playable. Returns
# true if any slot was repopulated.
func regenerate_empty_slots() -> bool:
	if grid == null:
		return false
	var empty_slots: Array[PieceSlot] = []
	var fixed_shapes: Array[PieceShape] = []
	for s in _slots:
		if s.is_empty():
			empty_slots.append(s)
			continue
		var p := s.peek()
		if p and p.shape:
			fixed_shapes.append(p.shape)
	if empty_slots.is_empty():
		return false

	var occupancy: Array = grid.snapshot_occupancy()
	var picked: Array[PieceShape] = []
	var colors: Array[Color] = []
	var rerolls: int = 0
	var consumed_assist: bool = false
	while true:
		picked.clear()
		colors.clear()
		for i in empty_slots.size():
			var slot_node = empty_slots[i]
			var slot_idx = _slots.find(slot_node)
			var allowed_tiers = _get_slot_allowed_tiers(slot_idx, GameState.current_score)
			picked.append(_library.pick_random_from_tiers(allowed_tiers))
			colors.append(_random_color())
		# Need >=1 placeable across fixed_shapes + picked.
		if _shapes_union_has_playable(fixed_shapes, picked, occupancy):
			break
		if GameState.assists_used >= GameState.MAX_ASSISTS:
			break
		if not consumed_assist:
			GameState.assists_used += 1
			consumed_assist = true
		rerolls += 1
		if rerolls >= MAX_REROLLS:
			break

	var delay: float = 0.0
	for i in empty_slots.size():
		empty_slots[i].populate(picked[i], colors[i], grid, drag_layer, delay)
		delay += 0.10
	tray_refilled.emit()
	return true


# True if any shape across both arrays fits the snapshot.
func _shapes_union_has_playable(fixed: Array[PieceShape], fresh: Array[PieceShape], occupancy: Array) -> bool:
	for s in fixed:
		if GridSolver.can_shape_fit(occupancy, s):
			return true
	for s in fresh:
		if GridSolver.can_shape_fit(occupancy, s):
			return true
	return false


func find_slot(piece: Piece) -> PieceSlot:
	for s in _slots:
		if s.peek() == piece:
			return s
	return null


func is_fully_empty() -> bool:
	for s in _slots:
		if not s.is_empty():
			return false
	return true


# All shapes still in the tray. Used by the game-over solver.
func remaining_shapes() -> Array[PieceShape]:
	var out: Array[PieceShape] = []
	for s in _slots:
		var p := s.peek()
		if p and p.shape:
			out.append(p.shape)
	return out


# Toggles each non-empty slot's enabled state based on whether its shape
# still fits the grid. Empty slots are left alone.
func update_availability() -> void:
	if grid == null:
		return
	var occupancy: Array = grid.snapshot_occupancy()
	for s in _slots:
		var p := s.peek()
		if p == null or p.shape == null:
			continue
		s.set_enabled(GridSolver.can_shape_fit(occupancy, p.shape))


# True if at least one slot has a still-placeable piece. Empty slots count
# as potentially playable so we don't game-over during a refill animation.
func has_any_enabled() -> bool:
	var any_piece := false
	for s in _slots:
		if s.is_empty():
			continue
		any_piece = true
		if s.is_enabled():
			return true
	return not any_piece


# True if at least one slot holds a dimmed (unplayable) piece.
func has_blocked_slots() -> bool:
	for s in _slots:
		if not s.is_empty() and not s.is_enabled():
			return true
	return false


func has_empty_slots() -> bool:
	for s in _slots:
		if s.is_empty():
			return true
	return false


# --- Save / load helpers --------------------------------------------------

# One entry per slot: null, or {"cells": [{x, y}], "color": "#rrggbbaa"}.
# Self-contained — no dependency on external .tres paths.
func snapshot_state() -> Array:
	var out: Array = []
	for s in _slots:
		var p := s.peek()
		if p == null or p.shape == null:
			out.append(null)
			continue
		var cell_dicts: Array = []
		for c in p.shape.cells:
			cell_dicts.append({"x": int(c.x), "y": int(c.y)})
		out.append({
			"cells": cell_dicts,
			"color": p.color.to_html(),
		})
	return out


# Rebuilds slots from a snapshot_state() result. Skips the spawn-bump
# (passes spawn_delay = -1.0) since the run is being restored.
func restore_state(state: Array) -> void:
	if grid == null:
		return
	for i in min(state.size(), _slots.size()):
		var entry = state[i]
		var s: PieceSlot = _slots[i]
		if entry == null:
			s.clear()
			continue
		var cells_array: Array[Vector2i] = []
		for c in entry.get("cells", []):
			cells_array.append(Vector2i(int(c.get("x", 0)), int(c.get("y", 0))))
		var shape := PieceShape.new()
		shape.cells = cells_array
		shape.display_name = "restored"
		shape.weight = 0.0
		var color := Color(str(entry.get("color", "#ffffffff")))
		s.populate(shape, color, grid, drag_layer, -1.0)


# ADReward effect: every remaining piece becomes a same-color single block,
# guaranteeing at least one playable move. Reuses the staggered pop-in.
func fill_with_single_blocks() -> void:
	var single_block := _build_single_block_shape()
	var delay: float = 0.0
	for s in _slots:
		var existing := s.peek()
		var color: Color = existing.color if existing else _random_color()
		s.populate(single_block, color, grid, drag_layer, delay)
		delay += 0.10


func _build_single_block_shape() -> PieceShape:
	var shape := PieceShape.new()
	shape.cells = [Vector2i.ZERO]
	shape.display_name = "single"
	shape.weight = 0.0
	return shape


func _random_color() -> Color:
	return ThemeManager.get_random_piece_color_for_score(GameState.current_score)


# Helper to determine allowed tiers for a given slot index based on current score
func _get_slot_allowed_tiers(slot_idx: int, score: int) -> Array[int]:
	if score < 500:
		# Early game: all slots are Tier 1 (Easy)
		return [1]
	elif score < 1200:
		# Mid game
		match slot_idx:
			0: return [1]
			1: return [1, 2]
			2: return [2]
	elif score < 2500:
		# Late game
		match slot_idx:
			0: return [1, 2]
			1: return [2, 3]
			2: return [3]
	else:
		# End game (2500+ score)
		match slot_idx:
			0: return [1, 2]
			1: return [2, 3]
			2: return [3, 4]
	return [1]


func _on_slot_piece_picked(_slot: PieceSlot, piece: Piece) -> void:
	piece_picked.emit(piece)


# --- Tutorial helpers ---------------------------------------------------

# Locks every slot except `keep_index`. Pass -1 to unlock all.
func lock_all_except(keep_index: int) -> void:
	for i in _slots.size():
		_slots[i].set_locked(i != keep_index)


# Undoes lock_all_except().
func unlock_all() -> void:
	for s in _slots:
		s.set_locked(false)


func get_slot(index: int) -> PieceSlot:
	if index < 0 or index >= _slots.size():
		return null
	return _slots[index]


# Manually populates a slot with a hand-built shape, bypassing the random
# library and auto-refill rules.
func populate_slot_manual(index: int, shape: PieceShape, color: Color) -> void:
	if grid == null or index < 0 or index >= _slots.size():
		return
	_slots[index].populate(shape, color, grid, drag_layer, 0.0)


# Forces every piece to its final visible state — safety net against the
# HTML5 quirk where the spawn-bump tween is occasionally dropped.
func force_show_pieces() -> void:
	for s in _slots:
		var p := s.peek()
		if p == null or not is_instance_valid(p):
			continue
		p.modulate.a = 1.0
		p.scale = Vector2.ONE
