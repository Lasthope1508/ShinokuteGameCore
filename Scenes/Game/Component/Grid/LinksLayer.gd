extends Control

# Custom Control node to draw high-fidelity flowing textured energy links
var grid: Grid
var _time: float = 0.0

# Shader for flowing energy beam with ADD blend mode
var _glow_shader: Shader
var _line_pool: Array[Line2D] = []
var _active_lines_count: int = 0

# Map elements to Kenney pack textures, scrolling speeds, and widths
const ELEMENT_LINK_CONFIGS = {
	ThemeManager.ElementChainType.FIRE: {
		"texture": preload("res://addons/kenney_particle_pack/trace_07.png"),
		"speed": 2.2,
		"width": 16.0
	},
	ThemeManager.ElementChainType.ICE: {
		"texture": preload("res://addons/kenney_particle_pack/trace_04.png"),
		"speed": 0.8,
		"width": 12.0
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
	render_mode blend_add;
	uniform float speed = 1.5;
	void fragment() {
		vec2 uv = UV;
		// Scroll texture along the X coordinate (length of Line2D)
		uv.x -= TIME * speed;
		vec4 tex = texture(TEXTURE, uv);
		COLOR = tex * COLOR;
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
				if grid._are_cells_same_color(c1, c2):
					var p2 = origin + Vector2((x + 1.5) * cell_size, (y + 0.5) * cell_size)
					_draw_flowing_link(p1, p2, cell1.occupied_color)
					
			# Check bottom neighbor
			if y + 1 < Grid.SIZE and grid._occupied[y + 1][x]:
				var c2 = Vector2i(x, y + 1)
				if grid._are_cells_same_color(c1, c2):
					var p2 = origin + Vector2((x + 0.5) * cell_size, (y + 1.5) * cell_size)
					_draw_flowing_link(p1, p2, cell1.occupied_color)
					
	# Hide unused lines in the pool
	for i in range(_active_lines_count, _line_pool.size()):
		_line_pool[i].visible = false

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
	
	# Animate width slightly to make it pulse
	var pulse = 1.0 + 0.12 * sin(_time * 8.0 + from.x * 0.05)
	line.width = config["width"] * pulse
	
	# Modulate color
	line.default_color = color * 1.4 # Boost brightness for glow shader
	
	# Update shader parameters
	var mat = line.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("speed", config["speed"])
		
	line.visible = true

func _hide_all_lines() -> void:
	for line in _line_pool:
		line.visible = false
