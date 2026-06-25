## 9x9 puzzle grid composed of 81 Cells and 9 decorative Quadrants. Children
## are spawned in code from Cell.tscn / Quadrant.tscn so the user can restyle
## the single component without touching 90 nodes by hand. All placement /
## clear / preview logic lives here.
class_name Grid extends Control

const SIZE: int = 9
const QUADRANT_SIZE: int = 3

const CHAOS_START_BLOCKS = 20
const CHAOS_OBSTACLE_COLOR = Color(0.4, 0.4, 0.4, 1.0)

const CELL_SCENE := preload("res://Scenes/Game/Component/Grid/Cell.tscn")
const QUADRANT_SCENE := preload("res://Scenes/Game/Component/Grid/Quadrant.tscn")

signal placement_committed(filled_cells: Array[Vector2i])
signal clears_completed

@export var cell_size: int = 64
@export var theme_config: ThemeConfig

@onready var quadrants_layer: Control = $QuadrantsLayer
@onready var cells_layer: Control = $CellsLayer
@onready var links_layer: Control = $LinksLayer
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
	cells_layer.z_index = 10
	links_layer.z_index = 9



func _update_theme() -> void:
	theme_config = ThemeManager.get_active_theme()
	
	var playboard = get_node_or_null("Playboard")
	if playboard:
		playboard.texture = preload("res://Assets/Sprites/playboard.png")
		
		# Create shader material to clean out solid background of playboard.png
		var mat = ShaderMaterial.new()
		mat.shader = preload("res://Assets/Shaders/playboard_clean.gdshader")
		
		# Modulate the grid lines to theme accent color (neon cyan)
		var line_col = theme_config.accent_color if theme_config else Color(0.0, 0.96, 0.83)
		mat.set_shader_parameter("line_color", line_col)
		mat.set_shader_parameter("threshold", 0.6)
		
		# Set playboard background color and opacity similar to piece slots (~0.47 opacity modulated by 0.9 mod)
		var bg_col = theme_config.panel_bg_color if theme_config else Color(0.08, 0.06, 0.15, 1.0)
		bg_col.a = 0.52 # Set alpha so that final opacity after modulate is ~0.47
		mat.set_shader_parameter("bg_color", bg_col)
		
		playboard.material = mat
		playboard.modulate = Color(1, 1, 1, 0.9) # High opacity to make lines stand out!
		playboard.visible = true

	if _quadrants.size() > 0:
		for qy in QUADRANT_SIZE:
			for qx in QUADRANT_SIZE:
				var q: Quadrant = _quadrants[qy][qx]
				q.modulate = Color(1, 1, 1, 0)


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
	if links_layer:
		links_layer.queue_redraw()
	return placed.size()


# Returns {rows, cols, quadrants, cells} for the full lines/quadrants now occupied.
func compute_clears(placed_color: Color = Color.TRANSPARENT) -> Dictionary:
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

	# BFS Cascade Propagation for linked same-color blocks
	var queue: Array[Vector2i] = []
	var visited: Dictionary = {}
	
	# Mark all line clearing cells as visited so they are cleared.
	for cell in cells_to_clear.keys():
		visited[cell] = true
		
	# Only start the BFS cascade from cells in the cleared lines that match the placed_color.
	# If placed_color is TRANSPARENT (fallback), we trigger cascade for all cleared cells.
	for cell in cells_to_clear.keys():
		var cell_color = _cells[cell.y][cell.x].occupied_color
		var matches_placed_color = (
			placed_color == Color.TRANSPARENT or 
			(abs(cell_color.r - placed_color.r) < 0.02 and 
			 abs(cell_color.g - placed_color.g) < 0.02 and 
			 abs(cell_color.b - placed_color.b) < 0.02)
		)
		if matches_placed_color:
			queue.append(cell)

	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not queue.is_empty():
		var curr: Vector2i = queue.pop_front()
		for d: Vector2i in dirs:
			var nbr: Vector2i = curr + d
			if _in_bounds(nbr) and _occupied[nbr.y][nbr.x]:
				if not nbr in visited:
					if _are_cells_same_color(curr, nbr):
						visited[nbr] = true
						queue.append(nbr)

	var cell_array: Array[Vector2i] = []
	for k in visited.keys():
		cell_array.append(k)
	_last_clear_cells = cell_array

	return {
		"rows": rows,
		"cols": cols,
		"quadrants": quadrants,
		"cells": cell_array,
	}


# Helper to check if two adjacent cells have the same color (and are not obstacles)
func _are_cells_same_color(c1: Vector2i, c2: Vector2i) -> bool:
	var cell1: Cell = _cells[c1.y][c1.x]
	var cell2: Cell = _cells[c2.y][c2.x]
	if cell1.is_obstacle() or cell2.is_obstacle():
		return false
	var col1 := cell1.occupied_color
	var col2 := cell2.occupied_color
	return abs(col1.r - col2.r) < 0.02 and abs(col1.g - col2.g) < 0.02 and abs(col1.b - col2.b) < 0.02


# Animates the removal of `cells`. Awaits a single fixed timer (not per-tween
# `finished` signals, which Safari iOS can drop and hang the whole pipeline).
func clear_cells(cells: Array[Vector2i]) -> void:
	if cells.is_empty():
		clears_completed.emit()
		return

	# Identify cleared rows, cols, and quadrants from the cell array
	var rows: Array[int] = []
	var cols: Array[int] = []
	var quadrants: Array[Vector2i] = []
	
	for y in range(SIZE):
		var row_cleared := true
		for x in range(SIZE):
			if not Vector2i(x, y) in cells:
				row_cleared = false
				break
		if row_cleared:
			rows.append(y)
			
	for x in range(SIZE):
		var col_cleared := true
		for y in range(SIZE):
			if not Vector2i(x, y) in cells:
				col_cleared = false
				break
		if col_cleared:
			cols.append(x)
			


	# Compute propagation wave centers
	var centers: Array[Vector2] = []
	var intersected_rows: Dictionary = {}
	var intersected_cols: Dictionary = {}
	
	for r in rows:
		for col in cols:
			centers.append(Vector2(col, r))
			intersected_rows[r] = true
			intersected_cols[col] = true
			
	for r in rows:
		if not r in intersected_rows:
			centers.append(Vector2(4, r))
			
	for col in cols:
		if not col in intersected_cols:
			centers.append(Vector2(col, 4))
			
	for q in quadrants:
		centers.append(Vector2(q.x * 3 + 1, q.y * 3 + 1))
		
	if centers.is_empty():
		var centroid := Vector2.ZERO
		for c in cells:
			centroid += Vector2(c.x, c.y)
		centroid /= float(cells.size())
		centers.append(centroid)

	for c in cells:
		_cells[c.y][c.x].z_index = 10

	var max_stagger: float = 0.0
	for c in cells:
		var min_dist := 999.0
		for center in centers:
			var d = Vector2(c.x, c.y).distance_to(center)
			if d < min_dist:
				min_dist = d
		var delay: float = min_dist * 0.12
		if delay > max_stagger:
			max_stagger = delay
		_occupied[c.y][c.x] = false
		_cells[c.y][c.x].clear_with_animation(delay)

	if links_layer:
		links_layer.queue_redraw()

	# Total = longest stagger + bump (0.12) + shake (0.12) + dissolve (0.35) + safety
	var total_duration: float = max_stagger + 0.65
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
	_highlight_potential_clears(shape, origin, piece_color)


func clear_preview() -> void:
	for row in _cells:
		for c: Cell in row:
			c.clear_preview()
			c.clear_clear_hint()
			c.stop_pulse()
			c.clear_clear_aura()


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
			c.reset_cell()


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
			q.modulate = Color(1, 1, 1, 0)
			var is_light: bool = (qx + qy) % 2 == 0
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
			c.cell_x = x
			c.cell_y = y
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
# Highlights cells that would be cleared on drop. Works on hypothetical
# occupancy = current ∪ shape cells.
func _highlight_potential_clears(shape: PieceShape, origin: Vector2i, piece_color: Color) -> void:
	var hypothetical: Array = []
	for y in SIZE:
		hypothetical.append((_occupied[y] as Array).duplicate())
	for offset in shape.cells:
		var p: Vector2i = origin + offset
		hypothetical[p.y][p.x] = true

	for y in SIZE:
		var full := true
		for x in SIZE:
			if not hypothetical[y][x]:
				full = false
				break
		if full:
			for x in SIZE:
				_cells[y][x].show_clear_aura(piece_color)

	for x in SIZE:
		var full := true
		for y in SIZE:
			if not hypothetical[y][x]:
				full = false
				break
		if full:
			for y in SIZE:
				_cells[y][x].show_clear_aura(piece_color)




# Generates random start blocks (Chaos Start) avoiding instant clears.
func generate_random_start_blocks(count: int = CHAOS_START_BLOCKS) -> void:
	var occupied_positions: Array[Vector2i] = []
	var all_positions: Array[Vector2i] = []
	for y in range(SIZE):
		for x in range(SIZE):
			all_positions.append(Vector2i(x, y))
	all_positions.shuffle()
	
	var spawned = 0
	for pos in all_positions:
		if spawned >= count:
			break
		if _would_cause_instant_clear(pos, occupied_positions):
			continue
		occupied_positions.append(pos)
		spawned += 1
		
	for pos in occupied_positions:
		_fill_single(pos.x, pos.y, CHAOS_OBSTACLE_COLOR)


# Limits pre-filled blocks per row, column, and quadrant to prevent easy clears and make obstacles challenging.
func _would_cause_instant_clear(pos: Vector2i, current_occupied: Array[Vector2i]) -> bool:
	var row_count = 0
	for p in current_occupied:
		if p.y == pos.y:
			row_count += 1
	if row_count >= 3:
		return true
		
	var col_count = 0
	for p in current_occupied:
		if p.x == pos.x:
			col_count += 1
	if col_count >= 3:
		return true
		
	var qx = pos.x / 3
	var qy = pos.y / 3
	var quad_count = 0
	for p in current_occupied:
		if p.x / 3 == qx and p.y / 3 == qy:
			quad_count += 1
	if quad_count >= 3:
		return true
		
	return false


func get_occupied_cell_count() -> int:
	var count = 0
	for y in range(SIZE):
		for x in range(SIZE):
			if _occupied[y][x]:
				count += 1
	return count

