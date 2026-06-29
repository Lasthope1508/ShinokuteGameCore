extends Node2D

const LevelDataScript = preload("res://Scripts/level_data.gd")
const PipeGridScript = preload("res://Scripts/pipe_grid.gd")
const ConnectionSolverScript = preload("res://Scripts/connection_solver.gd")

var level_data: RefCounted
var grid: RefCounted
var solver: RefCounted

var CELL_SIZE := 120.0
var GRID_OFFSET := Vector2(100.0, 200.0)

var is_solved := false

func _ready() -> void:
	# Load levels
	level_data = LevelDataScript.new()
	level_data.load_levels("res://Resources/levels.json")
	
	# Load level 1
	var lvl = level_data.get_level(1)
	grid = PipeGridScript.new()
	grid.initialize(lvl)
	
	solver = ConnectionSolverScript.new()
	is_solved = solver.check_connection(grid)
	
	# Set up viewport resizing/rotation listener
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Initial layout calculation
	_recalculate_layout()

func _recalculate_layout() -> void:
	if grid == null:
		return
		
	# Determine safe area
	var safe_rect: Rect2
	if OS.has_feature("mobile"):
		var safe_screen = DisplayServer.get_display_safe_area()
		var window_size = DisplayServer.window_get_size()
		var viewport_size = get_viewport_rect().size
		var scale_factor = viewport_size / Vector2(window_size)
		safe_rect = Rect2(
			Vector2(safe_screen.position) * scale_factor,
			Vector2(safe_screen.size) * scale_factor
		)
	else:
		safe_rect = get_viewport_rect()
		
	# Responsive scaling calculation
	var padding_x := 40.0
	var max_w = safe_rect.size.x - padding_x
	
	# Leave top margin for notch/header and bottom margin for status/victory circle
	var top_margin := 140.0
	var bottom_margin := 200.0
	var max_h = safe_rect.size.y - safe_rect.position.y - top_margin - bottom_margin
	
	var cell_w = max_w / grid.width
	var cell_h = max_h / grid.height
	CELL_SIZE = min(cell_w, cell_h)
	
	# Calculate centered offset within the safe area
	var grid_w = grid.width * CELL_SIZE
	var grid_h = grid.height * CELL_SIZE
	GRID_OFFSET.x = safe_rect.position.x + (safe_rect.size.x - grid_w) / 2.0
	GRID_OFFSET.y = safe_rect.position.y + top_margin + (max_h - grid_h) / 2.0
	
	queue_redraw()

func _on_viewport_size_changed() -> void:
	_recalculate_layout()

func _draw() -> void:
	if grid == null:
		return
		
	# Draw board cells
	for y in range(grid.height):
		for x in range(grid.width):
			var cell_rect := Rect2(GRID_OFFSET + Vector2(x, y) * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE))
			var cell_color := Color(0.2, 0.2, 0.2)
			
			# Highlight Source (Blue) and Target (Red)
			if Vector2i(x, y) == grid.source_pos:
				cell_color = Color(0.1, 0.3, 0.6)
			elif Vector2i(x, y) == grid.target_pos:
				cell_color = Color(0.6, 0.1, 0.1)
				
			draw_rect(cell_rect, cell_color)
			draw_rect(cell_rect, Color(0.4, 0.4, 0.4), false, 2.0)
			
			# Draw pipe lines inside cell
			var center := GRID_OFFSET + Vector2(x, y) * CELL_SIZE + Vector2(CELL_SIZE/2, CELL_SIZE/2)
			var ports = grid.get_tile_ports(x, y)
			
			# Draw center connection point
			draw_circle(center, CELL_SIZE * 0.07, Color(0.8, 0.8, 0.8))
			
			var line_width := CELL_SIZE * 0.05
			var ext := CELL_SIZE / 2.0
			
			# North port
			if ports[0]:
				draw_line(center, center + Vector2(0, -ext), Color(0.9, 0.9, 0.9), line_width)
			# East port
			if ports[1]:
				draw_line(center, center + Vector2(ext, 0), Color(0.9, 0.9, 0.9), line_width)
			# South port
			if ports[2]:
				draw_line(center, center + Vector2(0, ext), Color(0.9, 0.9, 0.9), line_width)
			# West port
			if ports[3]:
				draw_line(center, center + Vector2(-ext, 0), Color(0.9, 0.9, 0.9), line_width)
				
	# If solved, draw a centered victory checkmark below the grid
	if is_solved:
		var victory_center := Vector2(
			get_viewport_rect().size.x / 2.0,
			GRID_OFFSET.y + (grid.height * CELL_SIZE) + 80.0
		)
		# Ensure it stays within viewport
		if victory_center.y > get_viewport_rect().size.y - 50.0:
			victory_center.y = get_viewport_rect().size.y - 50.0
			
		draw_circle(victory_center, 40.0, Color(0.1, 0.7, 0.1))
		
		# Draw checkmark lines
		var p1 = victory_center + Vector2(-15.0, 0.0)
		var p2 = victory_center + Vector2(-5.0, 10.0)
		var p3 = victory_center + Vector2(18.0, -13.0)
		draw_line(p1, p2, Color.WHITE, 5.0)
		draw_line(p2, p3, Color.WHITE, 5.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = event.position - GRID_OFFSET
		var x = int(mouse_pos.x / CELL_SIZE)
		var y = int(mouse_pos.y / CELL_SIZE)
		
		if x >= 0 and x < grid.width and y >= 0 and y < grid.height:
			# Rotate clicked tile
			grid.rotate_tile(x, y)
			# Re-evaluate connection
			is_solved = solver.check_connection(grid)
			queue_redraw()
