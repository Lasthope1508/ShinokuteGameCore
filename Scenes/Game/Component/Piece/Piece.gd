## Draggable piece composed of N Block children laid out by a PieceShape.
## Handles its own input (mouse + touch via Godot's synthesized events).
## Contract: tray_slot owns the piece while idle; during drag the piece
## reparents to drag_layer and emits drop_requested(self, target_origin)
## so Game can commit the placement or bounce back.
class_name Piece extends Control

const BLOCK_SCENE := preload("res://Scenes/Game/Component/Piece/Block.tscn")

signal drag_started(piece: Piece)
signal drag_moved(piece: Piece, hovered_cell: Vector2i)
signal drop_requested(piece: Piece, target_origin: Vector2i)

@export var idle_block_size: int = 36   # size while sitting in a slot
@export var drag_block_size: int = 64   # size while being dragged
# Visual lift applied during drag so the piece sits above the finger.
@export var drag_lift: float = -120.0
@export var lift_duration: float = 0.18
# Higher = piece catches up to the cursor faster during the lift.
@export var lift_follow_rate: float = 18.0

var shape: PieceShape
var color: Color = Color.WHITE
var grid: Grid
var drag_layer: Control

var _is_dragging: bool = false
var _is_lifting: bool = false       # true while the pickup tween is running
var _lift_tween: Tween
var _drag_offset: Vector2 = Vector2.ZERO
var _origin_parent: Control
var _origin_position: Vector2 = Vector2.ZERO
var _last_mouse_global: Vector2 = Vector2.ZERO  # keeps lift smoothing aware of cursor moves
var _drag_start_time: float = 0.0
var _drag_start_pos: Vector2 = Vector2.ZERO
var _glow_shader: Shader

var video_player: VideoStreamPlayer = null
var _current_video_path := ""


func _ready() -> void:
	ThemeManager.theme_changed.connect(_on_theme_changed)


func _on_theme_changed(_name: String, _config: ThemeConfig) -> void:
	for child in get_children():
		if child is Block:
			child.set_color(color)


# Builds the visual blocks and tints them. Idle block size doubles as the
# hit-test cell size.
func setup(p_shape: PieceShape, p_color: Color) -> void:
	shape = p_shape.duplicate() if p_shape else null
	color = p_color
	_clear_blocks()
	if shape == null:
		return
	for offset in shape.get_normalized_cells():
		var b: Block = BLOCK_SCENE.instantiate()
		# Add to tree FIRST so size/position settings are honored by the
		# layout system. HTML5 occasionally kept the .tscn-defined
		# custom_minimum_size of 64 instead of 36, causing overlaps.
		add_child(b)
		b.custom_minimum_size = Vector2(idle_block_size, idle_block_size)
		b.size = Vector2(idle_block_size, idle_block_size)
		b.position = Vector2(offset.x * idle_block_size, offset.y * idle_block_size)
		b.set_color(color)
	var bbox: Vector2i = shape.get_size()
	custom_minimum_size = Vector2(bbox.x * idle_block_size, bbox.y * idle_block_size)
	size = custom_minimum_size
	_update_block_connections()



func _input(event: InputEvent) -> void:
	if not _is_dragging:
		return
	if event is InputEventMouseMotion:
		_update_drag((event as InputEventMouseMotion).global_position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_end_drag(mb.global_position)
			get_viewport().set_input_as_handled()


# --- Public ---------------------------------------------------------------

# Force-cancels the drag and bounces the piece back, regardless of state.
# Used by Game when a picked piece can't be placed anywhere on the grid.
func cancel_drag() -> void:
	_is_dragging = false
	_is_lifting = false
	set_process(false)
	if _lift_tween and _lift_tween.is_valid():
		_lift_tween.kill()
	bounce_back()


# Returns the piece to its origin slot after an invalid drop.
func bounce_back() -> void:
	_end_drag_visuals()
	if _origin_parent:
		_reparent_to(_origin_parent)
		var tw := create_tween()
		tw.tween_property(self, "position", _origin_position, 0.2) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func consume() -> void:
	queue_free()


# --- Drag pipeline --------------------------------------------------------

# Entry point used by PieceSlot when the user presses inside the slot rect.
func begin_drag(global_pos: Vector2) -> void:
	_begin_drag(global_pos)


func _begin_drag(global_pos: Vector2) -> void:
	if drag_layer == null:
		# Drag still works without a layer but the piece may be clipped.
		push_warning("Piece: drag_layer not set; piece may be clipped")
	_is_dragging = true
	_drag_start_time = Time.get_ticks_msec() / 1000.0
	_drag_start_pos = global_pos
	_origin_parent = get_parent() as Control
	_origin_position = position

	# Sync drag size with the grid's current cell_size.
	if grid and grid.cell_size > 0:
		drag_block_size = grid.cell_size

	# Memorize the slot's global pos before reparenting — this anchors the lift.
	var slot_global_pos: Vector2 = global_position

	if drag_layer:
		_reparent_to(drag_layer)

	# Switch to drag-time block size and recompute offset. The piece stays
	# visually at the slot via a smaller starting scale, then tweens up.
	_apply_block_size(drag_block_size)
	
	var active_theme = ThemeManager.get_active_theme()
	var lift_offset = drag_lift
	if active_theme and "drag_lift_offset" in active_theme:
		lift_offset = active_theme.drag_lift_offset
	_drag_offset = (size * 0.5) - Vector2(0.0, lift_offset)

	var start_scale: float = float(idle_block_size) / float(drag_block_size)

	scale = Vector2(start_scale, start_scale)
	# Compensate so the visual stays anchored to the slot.
	global_position = slot_global_pos - (size * (1.0 - start_scale) * 0.5)

	_last_mouse_global = global_pos
	_is_lifting = true

	# Only scale is tweened; position smoothing happens in _process so the
	# piece keeps tracking the cursor while it grows.
	if _lift_tween and _lift_tween.is_valid():
		_lift_tween.kill()
	_lift_tween = create_tween()
	_lift_tween.tween_property(self, "scale", Vector2.ONE, lift_duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_lift_tween.tween_callback(_on_lift_finished)

	set_process(true)
	AudioManager.play_sfx("pick")
	drag_started.emit(self)


# Damped follow during pickup. Inactive otherwise.
func _process(delta: float) -> void:
	if not _is_dragging or not _is_lifting:
		return
	var target: Vector2 = _last_mouse_global - _drag_offset
	# Frame-rate-independent damped lerp.
	var t: float = 1.0 - exp(-lift_follow_rate * delta)
	global_position = global_position.lerp(target, t)
	_emit_hovered_cell()


# Snap to the latest cursor pos so residual lag from the lift is wiped.
func _on_lift_finished() -> void:
	_is_lifting = false
	set_process(false)
	if _is_dragging:
		global_position = _last_mouse_global - _drag_offset
		_emit_hovered_cell()


func _update_drag(global_pos: Vector2) -> void:
	_last_mouse_global = global_pos
	# During the lift, _process handles the smoothed motion.
	if _is_lifting:
		return
	global_position = global_pos - _drag_offset
	_emit_hovered_cell()


func _end_drag(global_pos: Vector2) -> void:
	if not _is_dragging:
		return
	_is_dragging = false
	
	var elapsed = (Time.get_ticks_msec() / 1000.0) - _drag_start_time
	var dist = global_pos.distance_to(_drag_start_pos)
	if elapsed < 0.25 and dist < 10.0:
		# Tap/Click to rotate
		if GameState.chain_energy >= GameState.ROTATION_ENERGY_COST:
			GameState.chain_energy -= GameState.ROTATION_ENERGY_COST
			GameState.chain_energy_changed.emit(GameState.chain_energy)
			rotate_clockwise()
			AudioManager.play_sfx("button")
		else:
			AudioManager.play_sfx("invalid")
			
		bounce_back()
		return
		
	var origin := _hovered_cell()
	drop_requested.emit(self, origin)


func rotate_clockwise() -> void:
	if not shape:
		return
	var rotated_cells: Array[Vector2i] = []
	for c in shape.cells:
		rotated_cells.append(Vector2i(-c.y, c.x))
	shape.cells = rotated_cells
	shape.cells = shape.get_normalized_cells()
	setup(shape, color)


func _emit_hovered_cell() -> void:
	drag_moved.emit(self, _hovered_cell())


# Grid coordinate the top-left block overlaps, or (-1,-1) outside the grid.
# Probes the center of the top-left block so the piece snaps where the finger is.
func _hovered_cell() -> Vector2i:
	if grid == null:
		return Vector2i(-1, -1)
	var probe := global_position + Vector2(drag_block_size, drag_block_size) * 0.5
	return grid.global_to_cell(probe)


# --- Helpers --------------------------------------------------------------

func _apply_block_size(block_size: int) -> void:
	# Bail out if the piece has no shape (e.g. PieceLibrary failed to load
	# any .tres on Web) instead of crashing the input pipeline.
	if shape == null:
		push_warning("Piece._apply_block_size called with null shape — skipping")
		return
	for child in get_children():
		if child is Block:
			child.custom_minimum_size = Vector2(block_size, block_size)
			child.size = child.custom_minimum_size
	var i := 0
	for offset in shape.get_normalized_cells():
		var b: Block = get_child(i) as Block
		if b:
			b.position = Vector2(offset.x * block_size, offset.y * block_size)
		i += 1
	var bbox: Vector2i = shape.get_size()
	custom_minimum_size = Vector2(bbox.x * block_size, bbox.y * block_size)
	size = custom_minimum_size
	_update_block_connections()



func _end_drag_visuals() -> void:
	# Cancel any pickup tween and revert to the idle (in-slot) transform.
	if _lift_tween and _lift_tween.is_valid():
		_lift_tween.kill()
	_is_lifting = false
	set_process(false)
	scale = Vector2.ONE
	_apply_block_size(idle_block_size)


func _reparent_to(new_parent: Control) -> void:
	var prev_global: Vector2 = global_position
	var p := get_parent()
	if p:
		p.remove_child(self)
	new_parent.add_child(self)
	global_position = prev_global


func _clear_blocks() -> void:
	for c in get_children():
		c.queue_free()


func _update_block_connections() -> void:
	if shape == null:
		return
	var cells = shape.get_normalized_cells()
	var i := 0
	for offset in cells:
		var b = get_child(i) as Block
		if b:
			var conn_left = Vector2i(offset.x - 1, offset.y) in cells
			var conn_right = Vector2i(offset.x + 1, offset.y) in cells
			var conn_up = Vector2i(offset.x, offset.y - 1) in cells
			var conn_down = Vector2i(offset.x, offset.y + 1) in cells
			b.set_connections(conn_left, conn_right, conn_up, conn_down)
		i += 1
	_update_internal_lightning()
	_setup_piece_video_stream()


func _setup_piece_video_stream() -> void:
	var element_type = ThemeManager.get_element_type_for_color(color)
	var video_path := ThemeManager.get_element_video_path(element_type)
		
	if video_path == "":
		if video_player != null:
			video_player.queue_free()
			video_player = null
		_current_video_path = ""
		return
		
	if video_player != null and _current_video_path == video_path:
		_update_video_position()
		return
		
	if video_player != null:
		video_player.queue_free()
		video_player = null
		
	if ResourceLoader.exists(video_path):
		_current_video_path = video_path
		
		video_player = VideoStreamPlayer.new()
		video_player.stream = load(video_path)
		video_player.autoplay = true
		video_player.loop = true
		video_player.expand = true
		video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
		video_player.volume_db = -80.0
		
		# Set tint shader
		const TINT_SHADER := preload("res://Assets/Shaders/video_tint.gdshader")
		var mat := ShaderMaterial.new()
		mat.shader = TINT_SHADER
		mat.set_shader_parameter("target_color", color)
		video_player.material = mat
		
		add_child(video_player)
		_update_video_position()
		video_player.play()


# Finds the largest square of cells that fits entirely inside the piece's block shape cells.
func _find_largest_fit_square(cells: Array[Vector2i]) -> Dictionary:
	var cell_set = {}
	for pos in cells:
		cell_set[pos] = true
		
	# Find bounding box
	var min_x = cells[0].x
	var max_x = cells[0].x
	var min_y = cells[0].y
	var max_y = cells[0].y
	for pos in cells:
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y)
		
	var bbox_width = max_x - min_x + 1
	var bbox_height = max_y - min_y + 1
	var max_S = min(bbox_width, bbox_height)
	
	# Bounding box center
	var bbox_center = Vector2(min_x + max_x + 1, min_y + max_y + 1) * 0.5
	
	for S in range(max_S, 0, -1):
		var best_pos = Vector2i(-1, -1)
		var best_dist = INF
		var best_degree = -1
		
		# Search all possible top-left positions
		for y in range(min_y, max_y - S + 2):
			for x in range(min_x, max_x - S + 2):
				var valid = true
				for dy in range(S):
					for dx in range(S):
						if not Vector2i(x + dx, y + dy) in cell_set:
							valid = false
							break
					if not valid:
						break
						
				if valid:
					var sq_center = Vector2(x, y) + Vector2(S, S) * 0.5
					var dist = sq_center.distance_to(bbox_center)
					
					var degree = 0
					for dy in range(S):
						for dx in range(S):
							var cell = Vector2i(x + dx, y + dy)
							for offset in [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]:
								if (cell + offset) in cell_set:
									degree += 1
									
					if dist < best_dist - 0.001 or (abs(dist - best_dist) <= 0.001 and degree > best_degree):
						best_dist = dist
						best_degree = degree
						best_pos = Vector2i(x, y)
						
		if best_pos != Vector2i(-1, -1):
			return {"position": best_pos, "size": S}
			
	return {"position": cells[0], "size": 1}


func _update_video_position() -> void:
	if not is_instance_valid(video_player) or shape == null:
		return
	var b_size := idle_block_size
	if _is_dragging:
		b_size = drag_block_size
		
	var cells = shape.get_normalized_cells()
	if cells.is_empty():
		return
		
	var fit = _find_largest_fit_square(cells)
	var fit_pos: Vector2i = fit["position"]
	var S: int = fit["size"]
	
	var player_size = Vector2(S * b_size, S * b_size)
	video_player.size = player_size
	video_player.position = Vector2(fit_pos.x * b_size, fit_pos.y * b_size)
	
	# Make sure it renders behind Line2D and Blocks
	move_child(video_player, 0)


func _update_internal_lightning() -> void:
	if shape == null:
		return
		
	# Clear old Line2D children
	for child in get_children():
		if child is Line2D:
			child.queue_free()
			
	var cells = shape.get_normalized_cells()
	if cells.is_empty():
		return
		
	var element_type = ThemeManager.get_element_type_for_color(color)
	return
		
	# Find current block size
	var b_size := idle_block_size
	for child in get_children():
		if child is Block:
			b_size = int(child.size.x)
			break
	
	var bolt_tex = preload("res://addons/kenney_particle_pack/trace_01.png")
	var speed = 1.5
	var width = 12.0
	var is_spritesheet = false
	
	if element_type == ThemeManager.ElementChainType.FIRE:
		bolt_tex = load("res://addons/kenney_particle_pack/trace_07.png")
		speed = 2.2
		width = 16.0
	elif element_type == ThemeManager.ElementChainType.ICE:
		bolt_tex = load("res://addons/kenney_particle_pack/trace_06.png")
		speed = 1.5
		width = 14.0
		is_spritesheet = false
	elif element_type == ThemeManager.ElementChainType.EARTH:
		bolt_tex = load("res://addons/kenney_particle_pack/trace_03.png")
		speed = 1.2
		width = 14.0
	elif element_type == ThemeManager.ElementChainType.LIGHTNING:
		bolt_tex = load("res://addons/kenney_particle_pack/trace_02.png")
		speed = 3.6
		width = 18.0
	elif element_type == ThemeManager.ElementChainType.SOUL:
		bolt_tex = load("res://addons/kenney_particle_pack/trace_05.png")
		speed = 1.6
		width = 15.0

	if _glow_shader == null:
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

	var scale_ratio = float(b_size) / 64.0
	var final_width = width * scale_ratio
	
	for c1 in cells:
		var center1 = Vector2(c1.x + 0.5, c1.y + 0.5) * b_size
		
		# Right connection
		if Vector2i(c1.x + 1, c1.y) in cells:
			var c2 = Vector2i(c1.x + 1, c1.y)
			var center2 = Vector2(c2.x + 0.5, c2.y + 0.5) * b_size
			_create_internal_line(center1, center2, bolt_tex, final_width, is_spritesheet, speed)
			
		# Down connection
		if Vector2i(c1.x, c1.y + 1) in cells:
			var c2 = Vector2i(c1.x, c1.y + 1)
			var center2 = Vector2(c2.x + 0.5, c2.y + 0.5) * b_size
			_create_internal_line(center1, center2, bolt_tex, final_width, is_spritesheet, speed)


func _create_internal_line(from: Vector2, to: Vector2, tex: Texture2D, w: float, is_sheet: bool, spd: float) -> void:
	var line = Line2D.new()
	line.points = PackedVector2Array([from, to])
	line.texture = tex
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	if is_sheet:
		line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	else:
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
		
	line.width = w
	line.default_color = color * 1.4
	line.z_index = 0
	
	var mat = ShaderMaterial.new()
	mat.shader = _glow_shader
	mat.set_shader_parameter("line_texture", tex)
	mat.set_shader_parameter("line_color", color * 1.4)
	if is_sheet:
		mat.set_shader_parameter("is_spritesheet", true)
		mat.set_shader_parameter("hframes", 6.0)
		mat.set_shader_parameter("vframes", 4.0)
		mat.set_shader_parameter("fps", 30.0)
		mat.set_shader_parameter("time_offset", from.x * 0.01 + from.y * 0.07)
	else:
		mat.set_shader_parameter("is_spritesheet", false)
		mat.set_shader_parameter("speed", spd)
		
	line.material = mat
	add_child(line)
	move_child(line, 0)

