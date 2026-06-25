extends Control

# Custom Control node to draw high-fidelity flowing textured energy links
var grid: Grid
var _time: float = 0.0

# Shader for flowing energy beam with ADD blend mode
var _glow_shader: Shader
var _line_pool: Array[Line2D] = []
var _active_lines_count: int = 0

var _video_pool: Array[Control] = []
var _active_videos_count: int = 0
const TINT_SHADER := preload("res://Assets/Shaders/video_tint.gdshader")

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
	_update_video_cores()


func _create_video_container_in_pool() -> Control:
	var container = Control.new()
	container.name = "VideoMaskContainer"
	container.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var player = VideoStreamPlayer.new()
	player.autoplay = true
	player.loop = true
	player.expand = true
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player.volume_db = -80.0
	
	var mat := ShaderMaterial.new()
	mat.shader = TINT_SHADER
	player.material = mat
	
	container.add_child(player)
	container.draw.connect(_on_grid_video_mask_draw.bind(container))
	
	add_child(container)
	_video_pool.append(container)
	return container


func _on_grid_video_mask_draw(container: Control) -> void:
	if not container.has_meta("mask_cells"):
		return
	var mask_cells = container.get_meta("mask_cells")
	var min_x = container.get_meta("min_x")
	var min_y = container.get_meta("min_y")
	var c_size = container.get_meta("cell_size")
	for cell in mask_cells:
		var local_x = (cell.x - min_x) * c_size
		var local_y = (cell.y - min_y) * c_size
		container.draw_rect(Rect2(local_x, local_y, c_size, c_size), Color.WHITE)


func _update_video_cores() -> void:
	var visited = []
	for y in range(Grid.SIZE):
		var row = []
		for x in range(Grid.SIZE):
			row.append(false)
		visited.append(row)
		
	_active_videos_count = 0
	
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
									
			# Determine video stream path for this component's color
			var color = cell.occupied_color
			var element_type = ThemeManager.get_element_type_for_color(color)
			var video_path := ThemeManager.get_element_video_path(element_type)
				
			if video_path == "":
				continue
				
			# Find bounding box
			var min_x = component[0].x
			var max_x = component[0].x
			var min_y = component[0].y
			var max_y = component[0].y
			for pos in component:
				min_x = min(min_x, pos.x)
				max_x = max(max_x, pos.x)
				min_y = min(min_y, pos.y)
				max_y = max(max_y, pos.y)
				
			_show_video_core(video_path, color, component, min_x, min_y, max_x, max_y)
			
	# Hide unused video players in the pool
	for i in range(_active_videos_count, _video_pool.size()):
		var container = _video_pool[i]
		if container.visible:
			container.visible = false
			var player = container.get_child(0) as VideoStreamPlayer
			player.stop()


func _show_video_core(video_path: String, color: Color, component_cells: Array, min_x: int, min_y: int, max_x: int, max_y: int) -> void:
	var container: Control
	if _active_videos_count < _video_pool.size():
		container = _video_pool[_active_videos_count]
	else:
		container = _create_video_container_in_pool()
		
	_active_videos_count += 1
	container.visible = true
	
	var player: VideoStreamPlayer = container.get_child(0) as VideoStreamPlayer
	
	var current_stream_path = ""
	if player.stream:
		current_stream_path = player.stream.resource_path
		
	if current_stream_path != video_path:
		player.stream = load(video_path)
		player.play()
	elif not player.is_playing():
		player.play()
		
	var cell_size: int = grid.cell_size
	var W = max_x - min_x + 1
	var H = max_y - min_y + 1
	
	container.position = grid._grid_origin + Vector2(min_x, min_y) * cell_size
	container.size = Vector2(W * cell_size, H * cell_size)
	
	player.position = Vector2.ZERO
	player.size = container.size
	player.material.set_shader_parameter("target_color", color)
	
	container.set_meta("mask_cells", component_cells)
	container.set_meta("min_x", min_x)
	container.set_meta("min_y", min_y)
	container.set_meta("cell_size", cell_size)
	container.queue_redraw()


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
