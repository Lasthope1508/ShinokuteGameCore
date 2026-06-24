## 9x9 puzzle grid composed of 81 Cells and 9 decorative Quadrants. Children
## are spawned in code from Cell.tscn / Quadrant.tscn so the user can restyle
## the single component without touching 90 nodes by hand. All placement /
## clear / preview logic lives here.
class_name Grid extends Control

const SIZE: int = 9
const QUADRANT_SIZE: int = 3

const CELL_SCENE := preload("res://Scenes/Game/Component/Grid/Cell.tscn")
const QUADRANT_SCENE := preload("res://Scenes/Game/Component/Grid/Quadrant.tscn")

signal placement_committed(filled_cells: Array[Vector2i])
signal clears_completed

@export var cell_size: int = 64
@export var theme_config: ThemeConfig

@onready var quadrants_layer: Control = $QuadrantsLayer
@onready var cells_layer: Control = $CellsLayer
@onready var popups_layer: Control = $PopupsLayer

var _cells: Array = []          # 9x9 of Cell, indexed [y][x]
var _quadrants: Array = []      # 3x3 of Quadrant
var _occupied: Array = []       # 9x9 of bool, mirrors _cells.occupied
var _last_clear_cells: Array[Vector2i] = []
# Pixel offset of cell (0,0) inside cells_layer; updated by _layout_grid().
var _grid_origin: Vector2 = Vector2.ZERO


func _ready() -> void:
	_build_grid()
	resized.connect(_layout_grid)
	call_deferred("_layout_grid")
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_update_theme()


func _update_theme() -> void:
	theme_config = ThemeManager.get_active_theme()
	
	var playboard = get_node_or_null("Playboard")
	if playboard:
		playboard.texture = preload("res://Assets/Sprites/playboard.png")
		playboard.visible = true

	if _quadrants.size() > 0:
		for qy in QUADRANT_SIZE:
			for qx in QUADRANT_SIZE:
				var q: Quadrant = _quadrants[qy][qx]
				var is_light: bool = (qx + qy) % 2 == 0
				if theme_config:
					q.modulate = theme_config.quadrant_light_tint if is_light else theme_config.quadrant_dark_tint


func _on_theme_changed(_name: String, _config: ThemeConfig) -> void:
	_update_theme()



# --- Public API -----------------------------------------------------------

# True if every cell required by the shape at origin is in-bounds and empty.
func can_place(shape: PieceShape, origin: Vector2i) -> bool:
	if shape == null or shape.cells.is_empty():
		return false
	for offset in shape.cells:
		var p := origin + offset
		if not _in_bounds(p) or _occupied[p.y][p.x]:
			return false
	return true


# Places the shape at origin and returns the number of filled cells.
func place(shape: PieceShape, origin: Vector2i, color: Color) -> int:
	var placed: Array[Vector2i] = []
	for offset in shape.cells:
		var p: Vector2i = origin + offset
		_cells[p.y][p.x].fill(color)
		_occupied[p.y][p.x] = true
		placed.append(p)
	placement_committed.emit(placed)
	return placed.size()


# Returns {rows, cols, quadrants, cells} for the full lines/quadrants now occupied.
func compute_clears() -> Dictionary:
	var rows: Array[int] = []
	var cols: Array[int] = []
	var quadrants: Array[Vector2i] = []
	var cells_to_clear: Dictionary = {}

	for y in SIZE:
		var full := true
		for x in SIZE:
			if not _occupied[y][x]:
				full = false
				break
		if full:
			rows.append(y)
			for x in SIZE:
				cells_to_clear[Vector2i(x, y)] = true

	for x in SIZE:
		var full := true
		for y in SIZE:
			if not _occupied[y][x]:
				full = false
				break
		if full:
			cols.append(x)
			for y in SIZE:
				cells_to_clear[Vector2i(x, y)] = true

	for qy in QUADRANT_SIZE:
		for qx in QUADRANT_SIZE:
			if _is_quadrant_full(qx, qy):
				quadrants.append(Vector2i(qx, qy))
				for dy in QUADRANT_SIZE:
					for dx in QUADRANT_SIZE:
						cells_to_clear[Vector2i(qx * QUADRANT_SIZE + dx, qy * QUADRANT_SIZE + dy)] = true

	var cell_array: Array[Vector2i] = []
	for k in cells_to_clear.keys():
		cell_array.append(k)
	_last_clear_cells = cell_array

	return {
		"rows": rows,
		"cols": cols,
		"quadrants": quadrants,
		"cells": cell_array,
	}


# Animates the removal of `cells`. Awaits a single fixed timer (not per-tween
# `finished` signals, which Safari iOS can drop and hang the whole pipeline).
func clear_cells(cells: Array[Vector2i]) -> void:
	if cells.is_empty():
		clears_completed.emit()
		return
	# Lift the clearing cells so their bump renders above surviving blocks.
	# Cell.clear_with_animation resets z_index when the tween ends.
	for c in cells:
		_cells[c.y][c.x].z_index = 10

	var max_stagger: float = 0.0
	for c in cells:
		var delay: float = (c.x + c.y) * 0.030
		if delay > max_stagger:
			max_stagger = delay
		_occupied[c.y][c.x] = false
		_cells[c.y][c.x].clear_with_animation(delay)

	# Total = longest stagger + bump (0.18) + shrink (0.22) + safety margin.
	var total_duration: float = max_stagger + 0.18 + 0.22 + 0.05
	await get_tree().create_timer(total_duration).timeout
	clears_completed.emit()


# Renders the translucent ghost of the dragged piece. Invalid → no preview.
func project_preview(shape: PieceShape, origin: Vector2i, piece_color: Color) -> void:
	clear_preview()
	if not can_place(shape, origin):
		return
	for offset in shape.cells:
		var p: Vector2i = origin + offset
		_cells[p.y][p.x].show_preview(piece_color)
	# Hint at lines/quadrants this placement would clear.
	_highlight_potential_clears(shape, origin)


func clear_preview() -> void:
	for row in _cells:
		for c: Cell in row:
			c.clear_preview()
			c.clear_clear_hint()
			c.stop_pulse()


# Deep copy of the occupancy matrix for GridSolver, avoiding aliasing.
func snapshot_occupancy() -> Array:
	var out: Array = []
	for y in SIZE:
		out.append((_occupied[y] as Array).duplicate())
	return out


# Global pointer pos → cell coord, or Vector2i(-1, -1) if outside the grid.
func global_to_cell(global_pos: Vector2) -> Vector2i:
	var local := cells_layer.get_global_transform().affine_inverse() * global_pos
	local -= _grid_origin
	if local.x < 0 or local.y < 0 \
		or local.x >= SIZE * cell_size or local.y >= SIZE * cell_size:
		return Vector2i(-1, -1)
	return Vector2i(int(local.x / cell_size), int(local.y / cell_size))


func cell_to_global(cell: Vector2i) -> Vector2:
	return cells_layer.get_global_transform() * (
		_grid_origin + Vector2(cell.x * cell_size, cell.y * cell_size)
	)


# Geometric center of a (possibly fractional) cell coord, in global coords.
func cell_center_to_global(cell: Vector2) -> Vector2:
	return cells_layer.get_global_transform() * (
		_grid_origin + Vector2((cell.x + 0.5) * cell_size, (cell.y + 0.5) * cell_size)
	)


func get_popups_layer() -> Control:
	return popups_layer


# --- Save / load helpers --------------------------------------------------

# Serializable list of occupied cells: [{"x", "y", "color": "#rrggbbaa"}].
func snapshot_grid_state() -> Array:
	var out: Array = []
	for y in SIZE:
		for x in SIZE:
			if _occupied[y][x]:
				out.append({
					"x": x,
					"y": y,
					"color": (_cells[y][x] as Cell).occupied_color.to_html(),
				})
	return out


# Rebuilds the grid from a snapshot_grid_state() result. Wipes existing state.
func restore_grid_state(state: Array) -> void:
	reset()
	for entry in state:
		var x: int = int(entry.get("x", -1))
		var y: int = int(entry.get("y", -1))
		var color: Color = Color(str(entry.get("color", "#ffffffff")))
		_fill_single(x, y, color)


func _fill_single(x: int, y: int, color: Color) -> void:
	if not _in_bounds(Vector2i(x, y)):
		return
	if _occupied[y][x]:
		return
	(_cells[y][x] as Cell).fill(color)
	_occupied[y][x] = true


func reset() -> void:
	for y in SIZE:
		for x in SIZE:
			_occupied[y][x] = false
			var c: Cell = _cells[y][x]
			c.occupied = false
			c.block.visible = false
			c.clear_preview()
			c.clear_clear_hint()


func get_cell_color(cell: Vector2i) -> Color:
	if _in_bounds(cell):
		return (_cells[cell.y][cell.x] as Cell).occupied_color
	return Color.WHITE


# --- Internal helpers -----------------------------------------------------


func _build_grid() -> void:
	_cells.clear()
	_quadrants.clear()
	_occupied.clear()

	# Quadrants (decorative, behind cells).
	for qy in QUADRANT_SIZE:
		var row: Array = []
		for qx in QUADRANT_SIZE:
			var q: Quadrant = QUADRANT_SCENE.instantiate()
			q.position = Vector2(qx * QUADRANT_SIZE * cell_size, qy * QUADRANT_SIZE * cell_size)
			q.custom_minimum_size = Vector2(QUADRANT_SIZE * cell_size, QUADRANT_SIZE * cell_size)
			q.size = q.custom_minimum_size
			# Add to tree first so @onready (background) resolves.
			quadrants_layer.add_child(q)
			# Per-quadrant checkerboard tint + texture swap.
			var is_light: bool = (qx + qy) % 2 == 0
			if theme_config:
				q.modulate = theme_config.quadrant_light_tint if is_light else theme_config.quadrant_dark_tint
			if is_light:
				q.background.texture = preload("res://Assets/Sprites/quadrant_bg_light.png")
			else:
				q.background.texture = preload("res://Assets/Sprites/quadrant_bg_dark.png")
			row.append(q)
		_quadrants.append(row)

	# Cells.
	for y in SIZE:
		var cell_row: Array = []
		var occ_row: Array = []
		for x in SIZE:
			var c: Cell = CELL_SCENE.instantiate()
			c.position = Vector2(x * cell_size, y * cell_size)
			c.custom_minimum_size = Vector2(cell_size, cell_size)
			c.size = c.custom_minimum_size
			cells_layer.add_child(c)
			cell_row.append(c)
			occ_row.append(false)
		_cells.append(cell_row)
		_occupied.append(occ_row)


# Recomputes cell_size to fit the Control and repositions every cell/quadrant.
# Called on _ready and on every `resized` event.
func _layout_grid() -> void:
	if _cells.is_empty():
		return
	var avail: float = min(size.x, size.y)
	if avail <= 0.0:
		return
	cell_size = int(floor(avail / SIZE))
	var quad_px: int = cell_size * QUADRANT_SIZE
	var grid_px: float = cell_size * SIZE
	_grid_origin = Vector2(
		floor((size.x - grid_px) * 0.5),
		floor((size.y - grid_px) * 0.5),
	)

	var playboard = get_node_or_null("Playboard")
	if playboard:
		playboard.anchor_left = 0.0
		playboard.anchor_top = 0.0
		playboard.anchor_right = 0.0
		playboard.anchor_bottom = 0.0
		playboard.offset_left = 0.0
		playboard.offset_top = 0.0
		playboard.offset_right = 0.0
		playboard.offset_bottom = 0.0
		
		var scale_factor: float = theme_config.playboard_scale if theme_config else 1.0
		var pb_size: float = grid_px * scale_factor
		var offset: float = (pb_size - grid_px) * 0.5
		playboard.position = _grid_origin - Vector2(offset, offset)
		playboard.size = Vector2(pb_size, pb_size)

	for qy in QUADRANT_SIZE:
		for qx in QUADRANT_SIZE:
			var q: Quadrant = _quadrants[qy][qx]
			q.position = _grid_origin + Vector2(qx * quad_px, qy * quad_px)
			q.custom_minimum_size = Vector2(quad_px, quad_px)
			q.size = q.custom_minimum_size

	for y in SIZE:
		for x in SIZE:
			var c: Cell = _cells[y][x]
			c.position = _grid_origin + Vector2(x * cell_size, y * cell_size)
			c.custom_minimum_size = Vector2(cell_size, cell_size)
			c.size = c.custom_minimum_size


func _in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < SIZE and p.y >= 0 and p.y < SIZE


func _is_quadrant_full(qx: int, qy: int) -> bool:
	for dy in QUADRANT_SIZE:
		for dx in QUADRANT_SIZE:
			if not _occupied[qy * QUADRANT_SIZE + dy][qx * QUADRANT_SIZE + dx]:
				return false
	return true


# Highlights cells that would be cleared on drop. Works on hypothetical
# occupancy = current ∪ shape cells.
func _highlight_potential_clears(shape: PieceShape, origin: Vector2i) -> void:
	var hypothetical: Array = []
	for y in SIZE:
		hypothetical.append((_occupied[y] as Array).duplicate())
	for offset in shape.cells:
		var p: Vector2i = origin + offset
		hypothetical[p.y][p.x] = true

	var color := theme_config.preview_clear_highlight if theme_config else Color(1, 0.95, 0.4, 0.55)

	for y in SIZE:
		var full := true
		for x in SIZE:
			if not hypothetical[y][x]:
				full = false
				break
		if full:
			for x in SIZE:
				_apply_clear_feedback(_cells[y][x], color)

	for x in SIZE:
		var full := true
		for y in SIZE:
			if not hypothetical[y][x]:
				full = false
				break
		if full:
			for y in SIZE:
				_apply_clear_feedback(_cells[y][x], color)

	for qy in QUADRANT_SIZE:
		for qx in QUADRANT_SIZE:
			var full := true
			for dy in QUADRANT_SIZE:
				for dx in QUADRANT_SIZE:
					if not hypothetical[qy * QUADRANT_SIZE + dy][qx * QUADRANT_SIZE + dx]:
						full = false
						break
				if not full:
					break
			if full:
				for dy in QUADRANT_SIZE:
					for dx in QUADRANT_SIZE:
						_apply_clear_feedback(_cells[qy * QUADRANT_SIZE + dy][qx * QUADRANT_SIZE + dx], color)


# Filled cells pulse (shader flash); empty cells get the static overlay.
func _apply_clear_feedback(c: Cell, color: Color) -> void:
	if c.occupied:
		c.start_pulse()
	else:
		c.show_clear_hint(color)
