extends Control

# Custom Control node to draw chain link overlays on top of same-color adjacent blocks
var grid: Grid
var _time: float = 0.0

func _ready() -> void:
	# Find parent Grid node
	grid = get_parent() as Grid
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


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
					_draw_element_link(p1, p2, cell1.occupied_color)
					
			# Check bottom neighbor
			if y + 1 < Grid.SIZE and grid._occupied[y + 1][x]:
				var c2 = Vector2i(x, y + 1)
				if grid._are_cells_same_color(c1, c2):
					var p2 = origin + Vector2((x + 0.5) * cell_size, (y + 1.5) * cell_size)
					_draw_element_link(p1, p2, cell1.occupied_color)


func _draw_element_link(from: Vector2, to: Vector2, color: Color) -> void:
	var element_type = ThemeManager.get_element_type_for_color(color)
	match element_type:
		ThemeManager.ElementChainType.FIRE:
			_draw_fire_link(from, to, color)
		ThemeManager.ElementChainType.ICE:
			_draw_ice_link(from, to, color)
		ThemeManager.ElementChainType.EARTH:
			_draw_earth_link(from, to, color)
		ThemeManager.ElementChainType.LIGHTNING:
			_draw_lightning_link(from, to, color)
		ThemeManager.ElementChainType.SOUL:
			_draw_soul_link(from, to, color)
		_:
			_draw_neon_link(from, to, color)


# --- Element Specific Drawing Methods ---

func _draw_fire_link(from: Vector2, to: Vector2, color: Color) -> void:
	var dir = (to - from).normalized()
	var perp = Vector2(-dir.y, dir.x)
	var segments := 6
	
	var glow_color = color
	glow_color.a = 0.4 + 0.12 * sin(_time * 12.0)
	
	var points = PackedVector2Array()
	for i in range(segments + 1):
		var t = float(i) / segments
		var p = from.lerp(to, t)
		if i > 0 and i < segments:
			var wave = sin(_time * 15.0 + t * 10.0) * 1.8
			p += perp * wave
		points.append(p)
		
	draw_polyline(points, glow_color, 8.0, true)
	
	var core_color = Color.WHITE.lerp(color, 0.4)
	draw_polyline(points, core_color, 2.5, true)


func _draw_ice_link(from: Vector2, to: Vector2, color: Color) -> void:
	var dir = (to - from).normalized()
	var perp = Vector2(-dir.y, dir.x)
	var offset = perp * 3.0
	
	# Translucent glow behind the whole link
	var glow = color
	glow.a = 0.3
	draw_line(from, to, glow, 10.0, true)
	
	# Draw two parallel thin frosty lines
	var frost_color = Color.WHITE.lerp(color, 0.5)
	draw_line(from + offset, to + offset, frost_color, 1.5, true)
	draw_line(from - offset, to - offset, frost_color, 1.5, true)


func _draw_earth_link(from: Vector2, to: Vector2, color: Color) -> void:
	var dir = (to - from).normalized()
	var perp = Vector2(-dir.y, dir.x)
	var segments := 10
	
	var points = PackedVector2Array()
	for i in range(segments + 1):
		var t = float(i) / segments
		var p = from.lerp(to, t)
		var wave = sin(t * PI) * 3.5 * sin(_time * 5.0 + t * 4.0)
		p += perp * wave
		points.append(p)
		
	var glow_color = color
	glow_color.a = 0.4
	draw_polyline(points, glow_color, 6.0, true)
	
	var core_color = Color.WHITE.lerp(color, 0.25)
	draw_polyline(points, core_color, 2.0, true)


func _draw_lightning_link(from: Vector2, to: Vector2, color: Color) -> void:
	var dir = (to - from).normalized()
	var perp = Vector2(-dir.y, dir.x)
	var segments := 5
	
	var points = PackedVector2Array()
	points.append(from)
	
	var seed_val = int(_time * 24.0)
	for i in range(1, segments):
		var t = float(i) / segments
		var p = from.lerp(to, t)
		var offset_amount = sin(seed_val * 0.73 + i * 2.37) * 4.2
		p += perp * offset_amount
		points.append(p)
	points.append(to)
	
	var glow = color
	glow.a = 0.65
	draw_polyline(points, glow, 6.5, true)
	draw_polyline(points, Color.WHITE, 1.8, true)


func _draw_soul_link(from: Vector2, to: Vector2, color: Color) -> void:
	var dist = from.distance_to(to)
	var dir = (to - from).normalized()
	
	var base_color = color
	base_color.a = 0.25
	draw_line(from, to, base_color, 3.0, true)
	
	var glow_color = color
	glow_color.a = 0.65
	
	var speed = 40.0
	var dot_spacing = 16.0
	var start_offset = fmod(_time * speed, dot_spacing)
	
	var curr_dist = start_offset
	while curr_dist < dist:
		var dot_pos = from + dir * curr_dist
		draw_circle(dot_pos, 2.0, Color.WHITE)
		draw_circle(dot_pos, 4.5, glow_color)
		curr_dist += dot_spacing


# Draws a premium glowing neon line (Fallback)
func _draw_neon_link(from: Vector2, to: Vector2, color: Color) -> void:
	var glow_color = color
	glow_color.a = 0.5
	draw_line(from, to, glow_color, 8.0, true)
	
	var core_color = Color.WHITE.lerp(color, 0.3)
	draw_line(from, to, core_color, 2.5, true)

