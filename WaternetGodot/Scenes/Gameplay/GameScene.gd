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
var moves := 0
var level_id := 1

# HUD node references
@onready var hud_layer: CanvasLayer = $HUD
@onready var level_label: Label = $HUD/MarginContainer/VBoxContainer/HBoxHeader/LevelLabel
@onready var moves_label: Label = $HUD/MarginContainer/VBoxContainer/HBoxHeader/MovesLabel
@onready var solved_popup: PanelContainer = $HUD/SolvedPopup
@onready var popup_title: Label = $HUD/SolvedPopup/MarginContainer/VBoxContainer/PopupTitle
@onready var popup_moves: Label = $HUD/SolvedPopup/MarginContainer/VBoxContainer/PopupMoves
@onready var next_btn: Button = $HUD/SolvedPopup/MarginContainer/VBoxContainer/NextBtn

func _ready() -> void:
	level_id = GameState.current_level_id
	
	# Generate level procedurally
	var LevelGeneratorScript = preload("res://Scripts/level_generator.gd")
	var lvl = LevelGeneratorScript.generate_level(level_id, false)
	
	grid = PipeGridScript.new()
	grid.initialize(lvl)
	
	solver = ConnectionSolverScript.new()
	is_solved = solver.check_connection(grid)
	
	# Connect to window size changes
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Register theme changes
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_on_theme_changed(ThemeManager.active_theme_name, ThemeManager.active_theme)
	
	_recalculate_layout()
	_update_hud()
	_update_mute_button()

	
	# Hide solved popup initially
	solved_popup.visible = false
	
	if has_node("/root/AudioManager"):
		AudioManager.play_music()
		AudioManager.set_music_mode("relax")


func _on_theme_changed(name: String, config: ThemeConfig) -> void:
	if level_label:
		level_label.add_theme_color_override("font_color", config.text_color)
	if moves_label:
		moves_label.add_theme_color_override("font_color", config.accent_color)
	if popup_title:
		popup_title.add_theme_color_override("font_color", config.text_color)
	queue_redraw()

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
		
	var theme = ThemeManager.get_active_theme()
	var padding_x = theme.game_side_padding if theme else 40.0
	var max_w = safe_rect.size.x - padding_x
	
	var top_margin = theme.game_top_margin if theme else 160.0
	var bottom_margin = theme.game_bottom_margin if theme else 200.0
	var max_h = safe_rect.size.y - safe_rect.position.y - top_margin - bottom_margin
	
	var cell_w = max_w / grid.width
	var cell_h = max_h / grid.height
	CELL_SIZE = min(cell_w, cell_h)
	
	var grid_w = grid.width * CELL_SIZE
	var grid_h = grid.height * CELL_SIZE
	GRID_OFFSET.x = safe_rect.position.x + (safe_rect.size.x - grid_w) / 2.0
	GRID_OFFSET.y = safe_rect.position.y + top_margin + (max_h - grid_h) / 2.0
	
	queue_redraw()

func _on_viewport_size_changed() -> void:
	_recalculate_layout()

func _update_hud() -> void:
	if level_label:
		level_label.text = "LEVEL: %d" % level_id
	if moves_label:
		moves_label.text = "MOVES: %d" % moves

func _draw() -> void:
	if grid == null:
		return
		
	var theme = ThemeManager.get_active_theme()
	
	# Draw background covering the viewport
	var viewport_size = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), theme.panel_bg_color if theme else Color(0.05, 0.05, 0.1))
	
	var has_textures = theme and theme.cell_bg_texture != null and theme.pipe_i_texture != null
	
	var bg_cell_color = theme.panel_bg_color.lightened(0.05) if theme else Color(0.2, 0.2, 0.2)
	var border_color = theme.panel_border_color if theme else Color(0.4, 0.4, 0.4)
	var text_color = theme.text_color if theme else Color(0.9, 0.9, 0.9)
	var source_color = theme.accent_color if theme else Color(0.1, 0.3, 0.6)
	var target_color = theme.alert_color if theme else Color(0.6, 0.1, 0.1)
	
	var dot_ratio = theme.pipe_center_dot_ratio if theme else 0.07
	var line_ratio = theme.pipe_line_width_ratio if theme else 0.06
	var tip_ratio = theme.arrow_tip_ratio if theme else 0.42
	var base_ratio = theme.arrow_base_ratio if theme else 0.18
	
	var line_width: float = CELL_SIZE * line_ratio
	var ext := CELL_SIZE / 2.0
	
	# Get currently watered tiles for real-time flow visual feedback
	var watered_tiles = solver.get_watered_tiles(grid)
	
	# PASS 1: Draw board cells
	for y in range(grid.height):
		for x in range(grid.width):
			var cell_rect := Rect2(GRID_OFFSET + Vector2(x, y) * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE))
			
			if has_textures:
				# Draw soil/grass tray background cell
				draw_texture_rect(theme.cell_bg_texture, cell_rect, false)
			else:
				# Vector cell backgrounds with bevel recessed 3D depth
				var cell_color = bg_cell_color
				if Vector2i(x, y) == grid.source_pos:
					cell_color = source_color
				elif Vector2i(x, y) == grid.target_pos:
					cell_color = target_color
					
				draw_rect(cell_rect, cell_color)
				
				# 3D Bevel recessed shadow / highlight effect
				var shadow_c = Color(0.0, 0.0, 0.0, 0.35)
				var highlight_c = Color(1.0, 1.0, 1.0, 0.12)
				draw_line(cell_rect.position, Vector2(cell_rect.end.x, cell_rect.position.y), shadow_c, 2.0)
				draw_line(cell_rect.position, Vector2(cell_rect.position.x, cell_rect.end.y), shadow_c, 2.0)
				draw_line(Vector2(cell_rect.position.x, cell_rect.end.y), cell_rect.end, highlight_c, 2.0)
				draw_line(Vector2(cell_rect.end.x, cell_rect.position.y), cell_rect.end, highlight_c, 2.0)
				
				# Cell border outline
				draw_rect(cell_rect, border_color, false, 1.0)
				
	# PASS 2 & 3: Draw Pipes / Hoses / Water Pumps
	if has_textures:
		for y in range(grid.height):
			for x in range(grid.width):
				var cell_pos := Vector2i(x, y)
				var center := GRID_OFFSET + Vector2(x, y) * CELL_SIZE + Vector2(CELL_SIZE/2, CELL_SIZE/2)
				var tr = _get_tile_texture_and_rotation(x, y, theme)
				
				if tr.texture != null:
					var tex = tr.texture
					var tex_size = tex.get_size()
					var scale_factor = Vector2(CELL_SIZE / tex_size.x, CELL_SIZE / tex_size.y)
					
					# Determine flow modulation (watered tiles glow blue/cyan) - Disabled for raw texture preview
					var is_watered = watered_tiles.has(cell_pos)
					var mod_color = Color(1.0, 1.0, 1.0)
					
					draw_set_transform(center, tr.rotation, scale_factor)
					draw_texture_rect(tex, Rect2(-tex_size / 2.0, tex_size), false, mod_color)
					draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
					
					# Special visual juice: draw a glowing water indicator overlay if watered - Disabled for raw preview
					# if is_watered and not (cell_pos == grid.source_pos or cell_pos == grid.target_pos):
					# 	var ports = grid.get_tile_ports(x, y)
					# 	var flow_color = Color(0.0, 0.8, 1.0, 0.6) # semi-transparent water blue
					# 	var flow_w = line_width * 1.5
					# 	
					# 	# Draw small animated water flow lines
					# 	if ports[0]:
					# 		draw_line(center, center + Vector2(0, -ext), flow_color, flow_w)
					# 	if ports[1]:
					# 		draw_line(center, center + Vector2(ext, 0), flow_color, flow_w)
					# 	if ports[2]:
					# 		draw_line(center, center + Vector2(0, ext), flow_color, flow_w)
					# 	if ports[3]:
					# 		draw_line(center, center + Vector2(-ext, 0), flow_color, flow_w)
					# 	draw_circle(center, CELL_SIZE * dot_ratio * 1.2, flow_color)
	else:
		# PASS 2: Draw Pipe Outlines (creates thick dark contours for physical depth)
		var outline_color = Color(0.0, 0.0, 0.0, 0.75)
		var outline_width = line_width * 1.6
		for y in range(grid.height):
			for x in range(grid.width):
				var center := GRID_OFFSET + Vector2(x, y) * CELL_SIZE + Vector2(CELL_SIZE/2, CELL_SIZE/2)
				var ports = grid.get_tile_ports(x, y)
				var is_source = Vector2i(x, y) == grid.source_pos
				var is_target = Vector2i(x, y) == grid.target_pos
				
				if not (is_source or is_target):
					if ports[0]:
						draw_line(center, center + Vector2(0, -ext), outline_color, outline_width)
					if ports[1]:
						draw_line(center, center + Vector2(ext, 0), outline_color, outline_width)
					if ports[2]:
						draw_line(center, center + Vector2(0, ext), outline_color, outline_width)
					if ports[3]:
						draw_line(center, center + Vector2(-ext, 0), outline_color, outline_width)
					draw_circle(center, CELL_SIZE * dot_ratio * 1.3, outline_color)
					
		# PASS 3: Draw Pipe Cores and Source/Target Arrow HUDs
		for y in range(grid.height):
			for x in range(grid.width):
				var cell_pos := Vector2i(x, y)
				var center := GRID_OFFSET + Vector2(x, y) * CELL_SIZE + Vector2(CELL_SIZE/2, CELL_SIZE/2)
				var ports = grid.get_tile_ports(x, y)
				var is_source = cell_pos == grid.source_pos
				var is_target = cell_pos == grid.target_pos
				
				# Live watered path coloring
				var is_watered = watered_tiles.has(cell_pos)
				var pipe_color = source_color if is_watered else text_color
				
				if is_source or is_target:
					var directions_vec = [
						Vector2(0, -1), # Top
						Vector2(1, 0),  # Right
						Vector2(0, 1),  # Bottom
						Vector2(-1, 0)  # Left
					]
					var arrow_color = source_color if is_watered else Color.BLACK
					draw_circle(center, CELL_SIZE * dot_ratio, Color.BLACK if not is_watered else Color.DARK_BLUE)
					for i in range(4):
						if ports[i]:
							var dir_vec = directions_vec[i]
							var tip = center + dir_vec * (CELL_SIZE * tip_ratio)
							var perp = Vector2(-dir_vec.y, dir_vec.x)
							var base = center + dir_vec * (CELL_SIZE * base_ratio)
							var left_p = base + perp * (CELL_SIZE * 0.12)
							var right_p = base - perp * (CELL_SIZE * 0.12)
							
							draw_line(center, base, arrow_color, line_width)
							draw_polygon(
								PackedVector2Array([tip, left_p, right_p]),
								PackedColorArray([arrow_color])
							)
				else:
					if ports[0]:
						draw_line(center, center + Vector2(0, -ext), pipe_color, line_width)
					if ports[1]:
						draw_line(center, center + Vector2(ext, 0), pipe_color, line_width)
					if ports[2]:
						draw_line(center, center + Vector2(0, ext), pipe_color, line_width)
					if ports[3]:
						draw_line(center, center + Vector2(-ext, 0), pipe_color, line_width)
					draw_circle(center, CELL_SIZE * dot_ratio, pipe_color)

func _unhandled_input(event: InputEvent) -> void:
	if is_solved:
		return
		
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = event.position - GRID_OFFSET
		var x = int(mouse_pos.x / CELL_SIZE)
		var y = int(mouse_pos.y / CELL_SIZE)
		
		if x >= 0 and x < grid.width and y >= 0 and y < grid.height:
			# Play click sfx
			if has_node("/root/AudioManager"):
				AudioManager.play_sfx("button", 0.05)
				
			grid.rotate_tile(x, y)
			moves += 1
			_update_hud()
			
			if moves > 15 and has_node("/root/AudioManager"):
				AudioManager.set_music_mode("danger")
				
			is_solved = solver.check_connection(grid)
			queue_redraw()

			
			if is_solved:
				_on_level_solved()

func _on_level_solved() -> void:
	# Play levelup sfx
	if has_node("/root/AudioManager"):
		AudioManager.set_music_mode("relax")
		AudioManager.play_sfx("levelup")

		
	# Update save progress
	if has_node("/root/SaveManager"):
		var max_unlocked = SaveManager.get_setting("max_unlocked_level_id", 1)
		if level_id >= max_unlocked:
			SaveManager.set_setting("max_unlocked_level_id", level_id + 1)
			
	# Submit high score to LeaderboardManager
	if has_node("/root/LeaderboardManager"):
		LeaderboardManager.submit_score(moves, "classic")
		
	# Trigger AdManager interstitial ad
	if has_node("/root/AdManager"):
		AdManager.show_interstitial()
		
	# Populate solved popup
	if popup_moves:
		popup_moves.text = "MOVES USED: %d" % moves
	
	# With procedural levels, there is always a next level
	if next_btn:
		next_btn.text = "NEXT LEVEL"
		
	solved_popup.visible = true

func _on_reset_btn_pressed() -> void:
	if is_solved:
		return
	moves = 0
	_update_hud()
	if has_node("/root/AudioManager"):
		AudioManager.set_music_mode("relax")

	var LevelGeneratorScript = preload("res://Scripts/level_generator.gd")
	var lvl = LevelGeneratorScript.generate_level(level_id)
	grid.initialize(lvl)
	is_solved = solver.check_connection(grid)
	queue_redraw()

func _on_back_btn_pressed() -> void:
	if get_node_or_null("/root/SceneRouter"):
		SceneRouter.change_scene("res://Scenes/Main/LevelSelect.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Main/LevelSelect.tscn")

func _on_mute_btn_pressed() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.toggle_master_mute()
		_update_mute_button()

func _update_mute_button() -> void:
	var mute_btn = get_node_or_null("HUD/MarginContainer/VBoxContainer/HBoxHeader/MuteBtn")
	if has_node("/root/AudioManager") and mute_btn:
		var is_muted = AudioManager.is_master_muted()
		mute_btn.text = ""
		mute_btn.expand_icon = true
		if is_muted:
			mute_btn.icon = load("res://Assets/Icons/audioOff.png")
		else:
			mute_btn.icon = load("res://Assets/Icons/audioOn.png")




func _on_next_btn_pressed() -> void:
	var next_lvl = level_id + 1
	GameState.current_level_id = next_lvl
	if get_node_or_null("/root/SceneRouter"):
		SceneRouter.change_scene("res://Scenes/Gameplay/GameScene.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Gameplay/GameScene.tscn")

# Helper to determine which texture and rotation angle to draw for a tile at (x, y)
func _get_tile_texture_and_rotation(x: int, y: int, theme: ThemeConfig) -> Dictionary:
	var ports = grid.get_tile_ports(x, y)
	var is_source = Vector2i(x, y) == grid.source_pos
	var is_target = Vector2i(x, y) == grid.target_pos
	
	if is_source:
		var rot = 0.0
		# Default to first active port
		for i in range(4):
			if ports[i]:
				rot = i * PI / 2.0
				break
		# If watered, align with the actual watered outgoing connection
		var watered_tiles = solver.get_watered_tiles(grid)
		var dirs = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
		for i in range(4):
			if ports[i]:
				var neighbor_pos = Vector2i(x, y) + dirs[i]
				if grid.is_valid_pos(neighbor_pos) and watered_tiles.has(neighbor_pos):
					var neighbor_ports = grid.get_tile_ports(neighbor_pos.x, neighbor_pos.y)
					var opposite_port = (i + 2) % 4
					if neighbor_ports[opposite_port]:
						rot = i * PI / 2.0
						break
		return {"texture": theme.source_texture, "rotation": rot}
		
	if is_target:
		var rot = 0.0
		# Default to first active port
		for i in range(4):
			if ports[i]:
				rot = i * PI / 2.0
				break
		# If watered, align with the actual watered incoming connection
		var watered_tiles = solver.get_watered_tiles(grid)
		if watered_tiles.has(Vector2i(x, y)):
			var dirs = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
			for i in range(4):
				if ports[i]:
					var neighbor_pos = Vector2i(x, y) + dirs[i]
					if grid.is_valid_pos(neighbor_pos) and watered_tiles.has(neighbor_pos):
						var neighbor_ports = grid.get_tile_ports(neighbor_pos.x, neighbor_pos.y)
						var opposite_port = (i + 2) % 4
						if neighbor_ports[opposite_port]:
							rot = i * PI / 2.0
							break
		return {"texture": theme.target_texture, "rotation": rot}
		
	var active_indices = []
	for i in range(4):
		if ports[i]:
			active_indices.append(i)
			
	var count = active_indices.size()
	
	if count == 0:
		return {"texture": null, "rotation": 0.0}
	elif count == 1:
		# Cap: Rotates based on the single active port
		return {"texture": theme.pipe_cap_texture, "rotation": active_indices[0] * PI / 2.0}
	elif count == 2:
		# Check if opposite
		var diff = abs(active_indices[0] - active_indices[1])
		if diff == 2:
			# Straight pipe: 0 if top/bottom (0 and 2), PI/2 if left/right (1 and 3)
			var rot = 0.0
			if active_indices[0] == 1 or active_indices[0] == 3:
				rot = PI / 2.0
			return {"texture": theme.pipe_i_texture, "rotation": rot}
		else:
			# Corner L-pipe:
			# top-right (0, 1) -> 0.0
			# right-bottom (1, 2) -> PI/2
			# bottom-left (2, 3) -> PI
			# left-top (0, 3) -> 3*PI/2
			var rot = 0.0
			if active_indices[0] == 0 and active_indices[1] == 1:
				rot = 0.0
			elif active_indices[0] == 1 and active_indices[1] == 2:
				rot = PI / 2.0
			elif active_indices[0] == 2 and active_indices[1] == 3:
				rot = PI
			elif active_indices[0] == 0 and active_indices[1] == 3:
				rot = 3.0 * PI / 2.0
			return {"texture": theme.pipe_l_texture, "rotation": rot}
	elif count == 3:
		# T-junction: Rotates based on which port is FALSE (closed)
		var closed_index = -1
		for i in range(4):
			if not ports[i]:
				closed_index = i
				break
		# If left (3) is closed -> 0.0
		# If top (0) is closed -> PI/2
		# If right (1) is closed -> PI
		# If bottom (2) is closed -> 3*PI/2
		var rot = 0.0
		if closed_index == 3:
			rot = 0.0
		elif closed_index == 0:
			rot = PI / 2.0
		elif closed_index == 1:
			rot = PI
		elif closed_index == 2:
			rot = 3.0 * PI / 2.0
		return {"texture": theme.pipe_t_texture, "rotation": rot}
	elif count == 4:
		# Cross
		return {"texture": theme.pipe_x_texture, "rotation": 0.0}
		
	return {"texture": null, "rotation": 0.0}
