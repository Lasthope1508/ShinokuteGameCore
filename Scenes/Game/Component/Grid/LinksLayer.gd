extends Control

# Custom Control node to draw chain link overlays on top of same-color adjacent blocks
var grid: Grid

func _ready() -> void:
	# Find parent Grid node
	grid = get_parent() as Grid
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if not grid or grid._cells.is_empty():
		return
		
	var cell_size: int = grid.cell_size
	var origin: Vector2 = grid._grid_origin
	
	for y in range(Grid.SIZE):
		for x in range(Grid.SIZE):
			if not grid._occupied[y][x]:
				continue
				
			var c1 = Vector2i(x, y)
			var cell1 = grid._cells[y][x]
			if cell1.is_obstacle():
				continue
				
			# Center of c1
			var p1 = origin + Vector2((x + 0.5) * cell_size, (y + 0.5) * cell_size)
			
			# Check right neighbor
			if x + 1 < Grid.SIZE and grid._occupied[y][x + 1]:
				var c2 = Vector2i(x + 1, y)
				if grid._are_cells_same_color(c1, c2):
					var p2 = origin + Vector2((x + 1.5) * cell_size, (y + 0.5) * cell_size)
					_draw_neon_link(p1, p2, cell1.occupied_color)
					
			# Check bottom neighbor
			if y + 1 < Grid.SIZE and grid._occupied[y + 1][x]:
				var c2 = Vector2i(x, y + 1)
				if grid._are_cells_same_color(c1, c2):
					var p2 = origin + Vector2((x + 0.5) * cell_size, (y + 1.5) * cell_size)
					_draw_neon_link(p1, p2, cell1.occupied_color)


# Draws a premium glowing neon line
func _draw_neon_link(from: Vector2, to: Vector2, color: Color) -> void:
	# Glow pass: thick translucent line
	var glow_color = color
	glow_color.a = 0.5
	draw_line(from, to, glow_color, 8.0, true)
	
	# Center pass: thin bright line
	var core_color = Color.WHITE.lerp(color, 0.3)
	draw_line(from, to, core_color, 2.5, true)
