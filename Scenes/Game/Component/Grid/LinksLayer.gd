extends Control

# Custom Control node to draw high-fidelity flowing textured energy links
var grid: Grid
var _outline_pool: Array[Line2D] = []
var _active_outlines_count: int = 0
const RAINBOW_OUTLINE_SHADER := preload("res://Assets/Shaders/rainbow_outline.gdshader")
var _white_texture: Texture2D

func _ready() -> void:
	grid = get_parent() as Grid
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Create a dummy white texture to ensure Godot generates valid UVs
	var img = Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_white_texture = ImageTexture.create_from_image(img)

func _process(_delta: float) -> void:
	if not grid or grid._cells.is_empty():
		return
	_update_group_outlines()

func _create_outline_in_pool() -> Line2D:
	var line = Line2D.new()
	line.name = "RainbowOutline"
	
	var mat := ShaderMaterial.new()
	mat.shader = RAINBOW_OUTLINE_SHADER
	mat.set_shader_parameter("speed", 0.2)
	mat.set_shader_parameter("frequency", 1.0)
	mat.set_shader_parameter("glow_power", 2.0)
	line.material = mat
	
	line.texture = _white_texture
	line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.width = 3.0
	line.visible = false
	
	add_child(line)
	_outline_pool.append(line)
	return line

func _trace_boundary(cells: Array) -> PackedVector2Array:
	if cells.is_empty():
		return PackedVector2Array()
		
	var cell_set = {}
	for pos in cells:
		cell_set[Vector2i(pos.x, pos.y)] = true
		
	var start_to_end = {}
	for c in cells:
		var tl = Vector2(c.x, c.y)
		var tr = Vector2(c.x + 1, c.y)
		var br = Vector2(c.x + 1, c.y + 1)
		var bl = Vector2(c.x, c.y + 1)
		
		if not Vector2i(c.x, c.y - 1) in cell_set:
			start_to_end[tl] = tr
		if not Vector2i(c.x + 1, c.y) in cell_set:
			start_to_end[tr] = br
		if not Vector2i(c.x, c.y + 1) in cell_set:
			start_to_end[br] = bl
		if not Vector2i(c.x - 1, c.y) in cell_set:
			start_to_end[bl] = tl
			
	if start_to_end.is_empty():
		return PackedVector2Array()
		
	var start_cell = cells[0]
	for c in cells:
		if c.y < start_cell.y or (c.y == start_cell.y and c.x < start_cell.x):
			start_cell = c
	var start_vertex = Vector2(start_cell.x, start_cell.y)
	
	var path = PackedVector2Array()
	var curr = start_vertex
	
	for i in range(start_to_end.size() + 2):
		path.append(curr)
		if not start_to_end.has(curr):
			break
		var next_vertex = start_to_end[curr]
		if next_vertex == start_vertex:
			path.append(next_vertex)
			break
		curr = next_vertex
		
	return path

func _update_group_outlines() -> void:
	var visited = []
	for y in range(Grid.SIZE):
		var row = []
		for x in range(Grid.SIZE):
			row.append(false)
		visited.append(row)
		
	_active_outlines_count = 0
	var cell_size: int = grid.cell_size
	
	var components_to_process := []
	
	for y in range(Grid.SIZE):
		for x in range(Grid.SIZE):
			if visited[y][x]:
				continue
			var cell = grid._cells[y][x]
			if not grid._occupied[y][x] or cell.is_obstacle():
				continue
				
			# Group connected cells of the same color via BFS
			var component = []
			var queue = [Vector2i(x, y)]
			visited[y][x] = true
			
			while queue.size() > 0:
				var curr = queue.pop_front()
				component.append(curr)
				
				var dirs = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
				for d in dirs:
					var n = curr + d
					if n.x >= 0 and n.x < Grid.SIZE and n.y >= 0 and n.y < Grid.SIZE:
						if not visited[n.y][n.x]:
							var n_cell = grid._cells[n.y][n.x]
							if grid._occupied[n.y][n.x] and not n_cell.is_obstacle():
								if grid._are_cells_same_color(curr, n):
									visited[n.y][n.x] = true
									queue.append(n)
			
			components_to_process.append({
				"component": component,
				"color": cell.occupied_color
			})
			
	for comp_data in components_to_process:
		var component = comp_data["component"]
		var color = comp_data["color"]
		
		# Draw 7-color running outline only if >= 8
		if component.size() < 8:
			continue
			
		var path_vertices = _trace_boundary(component)
		if not path_vertices.is_empty():
			var line: Line2D
			if _active_outlines_count < _outline_pool.size():
				line = _outline_pool[_active_outlines_count]
			else:
				line = _create_outline_in_pool()
				
			_active_outlines_count += 1
			line.visible = true
			
			var pixel_points = PackedVector2Array()
			for v in path_vertices:
				pixel_points.append(grid._grid_origin + v * cell_size)
				
			line.points = pixel_points
			
			# Configure shader uniforms: just slowly running rainbow aura (using white texture for UVs)
			var mat = line.material as ShaderMaterial
			line.texture = _white_texture
			if mat:
				mat.set_shader_parameter("use_lightning", false)
				mat.set_shader_parameter("use_rainbow", true)
				mat.set_shader_parameter("block_color", Color.WHITE)
				
			# Render outline on top of everything
			move_child(line, get_child_count() - 1)
				
	# Hide unused outlines in the pool
	for i in range(_active_outlines_count, _outline_pool.size()):
		_outline_pool[i].visible = false
