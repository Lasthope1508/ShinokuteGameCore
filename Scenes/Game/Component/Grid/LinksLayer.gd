extends Control

# Custom Control node to draw high-fidelity flowing textured energy links
var grid: Grid
var _time: float = 0.0

# Shader for flowing energy beam with ADD blend mode
var _glow_shader: Shader
var _line_pool: Array[Line2D] = []
var _active_lines_count: int = 0

var _outline_pool: Array[Line2D] = []
var _active_outlines_count: int = 0
const RAINBOW_OUTLINE_SHADER := preload("res://Assets/Shaders/rainbow_outline.gdshader")
var _video_pool: Array[VideoStreamPlayer] = []
var _active_videos_count: int = 0
var _white_texture: Texture2D

# Map elements to Kenney pack textures, scrolling speeds, and widths
var ELEMENT_LINK_CONFIGS = {
	ThemeManager.ElementChainType.FIRE: {
		"texture": preload("res://addons/kenney_particle_pack/trace_07.png"),
		"speed": 2.2,
		"width": 16.0
	},
	ThemeManager.ElementChainType.ICE: {
		"texture": preload("res://addons/kenney_particle_pack/trace_06.png"),
		"speed": 1.5,
		"width": 14.0
	},
	ThemeManager.ElementChainType.EARTH: {
		"texture": preload("res://addons/kenney_particle_pack/trace_03.png"),
		"speed": 1.2,
		"width": 14.0
	},
	ThemeManager.ElementChainType.LIGHTNING: {
		"texture": preload("res://addons/kenney_particle_pack/trace_02.png"),
		"speed": 3.6,
		"width": 18.0
	},
	ThemeManager.ElementChainType.SOUL: {
		"texture": preload("res://addons/kenney_particle_pack/trace_05.png"),
		"speed": 1.6,
		"width": 15.0
	}
}

# Fallback config
const FALLBACK_CONFIG = {
	"texture": preload("res://addons/kenney_particle_pack/trace_01.png"),
	"speed": 1.5,
	"width": 12.0
}

func _ready() -> void:
	grid = get_parent() as Grid
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Compile shared glow shader
	_glow_shader = Shader.new()
	_glow_shader.code = """
	shader_type canvas_item;
	uniform sampler2D line_texture;
	uniform vec4 line_color : source_color = vec4(1.0);
	uniform float speed = 1.5;
	uniform bool is_spritesheet = false;
	uniform float hframes = 6.0;
	uniform float vframes = 4.0;
	uniform float fps = 30.0;
	uniform float time_offset = 0.0;

	void fragment() {
		vec2 uv = UV;
		if (is_spritesheet) {
			float total_frames = hframes * vframes;
			float frame_time = (TIME + time_offset) * fps;
			float frame = mod(floor(frame_time), total_frames);
			
			float col = mod(frame, hframes);
			float row = floor(frame / hframes);
			
			uv.x = (uv.x + col) / hframes;
			uv.y = (uv.y + row) / vframes;
		} else {
			uv.x -= TIME * speed;
		}
		vec4 tex = texture(line_texture, uv);
		COLOR = vec4(line_color.rgb, clamp(tex.a * 5.0, 0.0, 1.0) * line_color.a);
	}
	"""

	
	# Create a dummy white texture to ensure Godot generates valid UVs
	var img = Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_white_texture = ImageTexture.create_from_image(img)
	
	# Pre-populate node pool with 32 lines to prevent runtime allocations
	for i in range(32):
		_create_line_in_pool()

func _create_line_in_pool() -> Line2D:
	var line = Line2D.new()
	line.texture_mode = Line2D.LINE_TEXTURE_TILE
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.visible = false
	
	# Assign custom shader material
	var mat = ShaderMaterial.new()
	mat.shader = _glow_shader
	line.material = mat
	line.z_index = 0
	
	add_child(line)
	_line_pool.append(line)
	return line

func _process(delta: float) -> void:
	_time += delta
	_update_links()

func _update_links() -> void:
	if not grid or grid._cells.is_empty():
		_hide_all_lines()
		return

	# Reset connections on all cells
	for y in range(Grid.SIZE):
		for x in range(Grid.SIZE):
			grid._cells[y][x].reset_connections()
		
	var cell_size: int = grid.cell_size
	var origin: Vector2 = grid._grid_origin
	
	_active_lines_count = 0
	
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
				var cell2 = grid._cells[y][x + 1]
				if not cell2.is_obstacle() and grid._are_cells_same_color(c1, c2):
					var p2 = origin + Vector2((x + 1.5) * cell_size, (y + 0.5) * cell_size)
					var element_type = ThemeManager.get_element_type_for_color(cell1.occupied_color)
					if element_type == ThemeManager.ElementChainType.ICE:
						_draw_flowing_link(p1, p2, cell1.occupied_color)
					cell1.add_connection("right")
					cell2.add_connection("left")
					
			# Check bottom neighbor
			if y + 1 < Grid.SIZE and grid._occupied[y + 1][x]:
				var c2 = Vector2i(x, y + 1)
				var cell2 = grid._cells[y + 1][x]
				if not cell2.is_obstacle() and grid._are_cells_same_color(c1, c2):
					var p2 = origin + Vector2((x + 0.5) * cell_size, (y + 1.5) * cell_size)
					var element_type = ThemeManager.get_element_type_for_color(cell1.occupied_color)
					if element_type == ThemeManager.ElementChainType.ICE:
						_draw_flowing_link(p1, p2, cell1.occupied_color)
					cell1.add_connection("down")
					cell2.add_connection("up")
					
	# Hide unused lines in the pool
	for i in range(_active_lines_count, _line_pool.size()):
		_line_pool[i].visible = false
		
	# Selectively toggle video core players for connected components of the same color
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


func _get_video_player_from_pool() -> VideoStreamPlayer:
	if _active_videos_count < _video_pool.size():
		var player = _video_pool[_active_videos_count]
		_active_videos_count += 1
		player.visible = true
		if not player.is_playing():
			player.play()
		return player
		
	var path = ThemeManager.get_thor_lightning_video_path()
	if ResourceLoader.exists(path):
		var player = VideoStreamPlayer.new()
		player.stream = load(path)
		player.autoplay = true
		player.loop = true
		player.expand = true
		player.volume_db = -80.0
		player.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Set additive blending material
		var canvas_mat = CanvasItemMaterial.new()
		canvas_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		player.material = canvas_mat
		
		add_child(player)
		_video_pool.append(player)
		_active_videos_count += 1
		player.play()
		return player
	return null


func _update_group_outlines() -> void:
	var visited = []
	for y in range(Grid.SIZE):
		var row = []
		for x in range(Grid.SIZE):
			row.append(false)
		visited.append(row)
		
	_active_outlines_count = 0
	_active_videos_count = 0
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
		
	# Hide and stop unused video players in the pool
	for i in range(_active_videos_count, _video_pool.size()):
		_video_pool[i].visible = false
		_video_pool[i].stop()
		



func _draw_flowing_link(from: Vector2, to: Vector2, color: Color) -> void:
	# Fetch or expand pool
	var line: Line2D
	if _active_lines_count < _line_pool.size():
		line = _line_pool[_active_lines_count]
	else:
		line = _create_line_in_pool()
		
	_active_lines_count += 1
	
	# Determine element configuration
	var element_type = ThemeManager.get_element_type_for_color(color)
	var config = ELEMENT_LINK_CONFIGS.get(element_type, FALLBACK_CONFIG)
	
	# Set line points
	line.points = PackedVector2Array([from, to])
	line.texture = config["texture"]
	
	if element_type == ThemeManager.ElementChainType.ICE:
		line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	else:
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
	
	# Animate width slightly to make it pulse
	var pulse = 1.0 + 0.12 * sin(_time * 8.0 + from.x * 0.05)
	line.width = config["width"] * pulse
	
	# Modulate color
	line.default_color = color * 1.4 # Boost brightness for glow shader
	
	# Update shader parameters
	var mat = line.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("line_texture", config["texture"])
		mat.set_shader_parameter("line_color", color * 1.4)
		if element_type == ThemeManager.ElementChainType.ICE:
			mat.set_shader_parameter("is_spritesheet", true)
			mat.set_shader_parameter("hframes", 6.0)
			mat.set_shader_parameter("vframes", 4.0)
			mat.set_shader_parameter("fps", 30.0)
			mat.set_shader_parameter("time_offset", from.x * 0.01 + from.y * 0.07)
		else:
			mat.set_shader_parameter("is_spritesheet", false)
			mat.set_shader_parameter("speed", config["speed"])
		
	line.visible = true

func _hide_all_lines() -> void:
	for line in _line_pool:
		line.visible = false
