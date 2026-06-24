## Top-level coordinator of a play session. Owns the Grid, HUD and PieceTray
## and orchestrates piece pickup → placement → clears → refill → game over.
extends Control

const SETTINGS_OVERLAY := preload("res://Scenes/Game/Component/Overlays/SettingsOverlay.tscn")
const LEADERBOARD_OVERLAY := preload("res://Scenes/Game/Component/Overlays/LeaderboardOverlay.tscn")
const GAMEOVER_OVERLAY := preload("res://Scenes/Game/Component/Overlays/GameOverOverlay.tscn")
const SCORE_POPUP := preload("res://Scenes/Game/Component/HUD/ScorePopup.tscn")
const LINE_CLEAR_PARTICLES := preload("res://Scenes/Game/Component/Grid/LineClearParticles.tscn")

const THEME_PATH := "res://Resources/Data/default_theme.tres"

@onready var background: ColorRect = $Background
@onready var background_texture_rect: TextureRect = $BackgroundTexture
@onready var hud: HUD = $Layout/HUD
@onready var progress_bar_widget: ScoreProgressBar = $Layout/ProgressFrame/ScoreProgressBar
@onready var grid: Grid = $Layout/GridFrame/AspectRatio/Grid
@onready var tray: PieceTray = $Layout/Tray
@onready var drag_layer: Control = $DragLayer

var _theme_config: ThemeConfig
var _active_piece: Piece
var _background_texture_new: TextureRect
var _fade_tween: Tween
var _current_bg_index: int = -1
var _shuffled_bg_indices: Array[int] = []

# --- Camera shake -------------------------------------------------------
# Strength scales with combo (clamped at shake_max_combo). 0 disables it.
@export_range(0.0, 40.0, 0.5) var shake_base_strength: float = 12.0
@export_range(0.05, 1.0, 0.05) var shake_base_duration: float = 0.40
@export_range(1, 12) var shake_max_combo: int = 6
# Fixed shake used on score-bar level-ups.
@export_range(0, 12) var shake_levelup_combo: int = 3

var _shake_remaining: float = 0.0
var _shake_total: float = 0.0
var _shake_strength: float = 0.0
var _shake_base_transform: Transform2D = Transform2D.IDENTITY

# --- Tutorial state ------------------------------------------------------
# _tutorial_step: 0 = inactive, 1/2 = active step.
const TUTORIAL_CURSOR_PATH := "res://Assets/Sprites/tutorial_cursor.png"
const TUTORIAL_PIECE_SCENE := preload("res://Scenes/Game/Component/Piece/Piece.tscn")
# Fingertip position inside the cursor texture, as a fraction from top-left.
# The cursor is placed so this hotspot lands on the target point.
const TUTORIAL_CURSOR_HOTSPOT_RATIO: Vector2 = Vector2(0.2, 0.2)
var _tutorial_step: int = 0
var _tutorial_expected_origin: Vector2i = Vector2i(-1, -1)
var _tutorial_cursor: TextureRect
var _tutorial_cursor_tween: Tween
var _tutorial_ghost: Piece


func _ready() -> void:
	# Create BackgroundTextureNew dynamically for cross-fade transitions
	_background_texture_new = TextureRect.new()
	_background_texture_new.name = "BackgroundTextureNew"
	_background_texture_new.anchor_right = 1.0
	_background_texture_new.anchor_bottom = 1.0
	_background_texture_new.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background_texture_new.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background_texture_new.visible = false
	_background_texture_new.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var bg_idx = background_texture_rect.get_index()
	add_child(_background_texture_new)
	move_child(_background_texture_new, bg_idx + 1)

	ThemeManager.theme_changed.connect(_on_theme_changed)
	GameState.score_changed.connect(_on_score_changed)
	GameState.game_reset.connect(_on_game_reset)
	resized.connect(_update_background_layout)
	_update_theme()

	GameState.reset_run()
	tray.setup(grid, drag_layer)


	hud.settings_requested.connect(_on_settings_requested)
	hud.leaderboard_requested.connect(_on_leaderboard_requested)
	tray.piece_picked.connect(_on_piece_picked)
	GameState.game_over.connect(_on_game_over)
	progress_bar_widget.level_up_triggered.connect(_on_level_up_triggered)

	# First launch → tutorial. Returning players resume a saved run if any.
	if not SaveManager.is_tutorial_completed():
		_start_tutorial()
	elif SaveManager.has_saved_game():
		_load_saved_game()
	else:
		if GameState.start_mode == "chaos":
			grid.generate_random_start_blocks(10)
		tray.refill()
		tray.update_availability()


func _update_theme() -> void:
	_theme_config = ThemeManager.get_active_theme()
	grid.theme_config = _theme_config
	tray.theme_config = _theme_config
	
	if _theme_config:
		background.color = Color(0.08, 0.06, 0.15, 1.0)

		_update_background(GameState.current_score, true)


func _on_theme_changed(_name: String, _config: ThemeConfig) -> void:
	_update_theme()


func _on_score_changed(new_score: int, _delta: int) -> void:
	_update_background(new_score)


func _update_background_layout() -> void:
	if not is_inside_tree():
		return
	_scale_texture_rect_to_bottom(background_texture_rect)
	_scale_texture_rect_to_bottom(_background_texture_new)


func _scale_texture_rect_to_bottom(tex_rect: TextureRect) -> void:
	if not tex_rect or not tex_rect.texture:
		return
		
	tex_rect.anchor_left = 0
	tex_rect.anchor_top = 0
	tex_rect.anchor_right = 0
	tex_rect.anchor_bottom = 0
	
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	
	var parent_size = size
	var texture_size = tex_rect.texture.get_size()
	if texture_size.x == 0 or texture_size.y == 0:
		return
		
	var aspect_parent = parent_size.x / parent_size.y
	var aspect_tex = texture_size.x / texture_size.y
	
	if aspect_parent > aspect_tex:
		var scale_factor = parent_size.x / texture_size.x
		var new_width = parent_size.x
		var new_height = texture_size.y * scale_factor
		tex_rect.size = Vector2(new_width, new_height)
		tex_rect.position = Vector2(0, parent_size.y - new_height)
	else:
		var scale_factor = parent_size.y / texture_size.y
		var new_width = texture_size.x * scale_factor
		var new_height = parent_size.y
		tex_rect.size = Vector2(new_width, new_height)
		tex_rect.position = Vector2((parent_size.x - new_width) / 2.0, 0)


func _update_background(score: int, force_immediate: bool = false) -> void:
	if not _theme_config:
		return
		
	var target_bg = ThemeManager.shared_background_texture
	var target_index = 0
	
	if not ThemeManager.shared_milestone_backgrounds.is_empty():
		var level = GameState.get_level_for_score(score)
		if _shuffled_bg_indices.is_empty():
			_initialize_shuffled_backgrounds()
			
		if not _shuffled_bg_indices.is_empty():
			var shuffled_pos = level % _shuffled_bg_indices.size()
			target_index = _shuffled_bg_indices[shuffled_pos]
			if ThemeManager.shared_milestone_backgrounds[target_index] != null:
				target_bg = ThemeManager.shared_milestone_backgrounds[target_index]
			
	if target_index == _current_bg_index and not force_immediate:
		return
		
	_current_bg_index = target_index
	
	if force_immediate or not is_inside_tree() or _background_texture_new == null:
		if target_bg:
			background_texture_rect.texture = target_bg
			background_texture_rect.visible = true
			background_texture_rect.modulate.a = 1.0
		else:
			background_texture_rect.texture = null
			background_texture_rect.visible = false
		_update_background_layout()
		return
		
	# Cross-fade transition
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
		
	if target_bg:
		_background_texture_new.texture = target_bg
		_background_texture_new.modulate.a = 0.0
		_background_texture_new.visible = true
		_update_background_layout()
		
		_fade_tween = create_tween()
		_fade_tween.tween_property(_background_texture_new, "modulate:a", 1.0, 0.6)
		_fade_tween.tween_callback(func():
			background_texture_rect.texture = target_bg
			background_texture_rect.visible = true
			_background_texture_new.visible = false
			_update_background_layout()
		)
	else:
		_fade_tween = create_tween()
		_fade_tween.tween_property(background_texture_rect, "modulate:a", 0.0, 0.6)
		_fade_tween.tween_callback(func():
			background_texture_rect.texture = null
			background_texture_rect.visible = false
			background_texture_rect.modulate.a = 1.0
			_update_background_layout()
		)



# --- Drag-and-drop pipeline ----------------------------------------------

func _on_piece_picked(piece: Piece) -> void:
	if _active_piece and is_instance_valid(_active_piece):
		_disconnect_piece(_active_piece)
	# Defensive in case signals were left connected from a previous pick.
	_disconnect_piece(piece)
	_active_piece = piece
	piece.drag_moved.connect(_on_drag_moved)
	piece.drop_requested.connect(_on_drop_requested)

	# Stale-state guard: if the picked piece doesn't fit anywhere (e.g. a refill
	# happened and update_availability hasn't dimmed this slot yet), auto-bounce
	# and dim the slot. Tutorial steps bypass this — they force a fixed origin.
	if _tutorial_step == 0 and piece.shape and grid:
		var occupancy: Array = grid.snapshot_occupancy()
		if not GridSolver.can_shape_fit(occupancy, piece.shape):
			AudioManager.play_sfx("invalid")
			piece.cancel_drag()
			_disconnect_piece(piece)
			_active_piece = null
			var slot: PieceSlot = tray.find_slot(piece)
			if slot:
				slot.set_enabled(false)


# Safe to call multiple times.
func _disconnect_piece(piece: Piece) -> void:
	if piece == null or not is_instance_valid(piece):
		return
	if piece.drag_moved.is_connected(_on_drag_moved):
		piece.drag_moved.disconnect(_on_drag_moved)
	if piece.drop_requested.is_connected(_on_drop_requested):
		piece.drop_requested.disconnect(_on_drop_requested)


func _on_drag_moved(_piece: Piece, hovered_cell: Vector2i) -> void:
	if hovered_cell.x < 0:
		grid.clear_preview()
		return
	grid.project_preview(_piece.shape, hovered_cell, _piece.color)


func _on_drop_requested(piece: Piece, target_origin: Vector2i) -> void:
	grid.clear_preview()
	# Tutorial gate: only the scripted origin is accepted.
	if _tutorial_step > 0 and target_origin != _tutorial_expected_origin:
		AudioManager.play_sfx("invalid")
		piece.bounce_back()
		_disconnect_piece(piece)
		_active_piece = null
		return
	if not grid.can_place(piece.shape, target_origin):
		AudioManager.play_sfx("invalid")
		piece.bounce_back()
		_disconnect_piece(piece)
		_active_piece = null
		return

	var color: Color = piece.color
	var placed_count: int = grid.place(piece.shape, target_origin, color)

	# Phase 1: placement scoring. Awarded immediately; HUD score tween (~0.4s)
	# animates the placement bonus before the match bonus is added.
	var placement_delta: int = GameState.award_placement(placed_count)
	_spawn_score_popup_at_cells(piece.shape, target_origin, placement_delta, 0.2)
	AudioManager.play_sfx("drop")

	var slot: PieceSlot = tray.find_slot(piece)
	# Piece may have been reparented to drag_layer; free it either way.
	piece.queue_free()
	if slot:
		slot.current_piece = null

	_active_piece = null

	# Short hold so the placement number is readable before the clear cascade.
	await get_tree().create_timer(0.2).timeout

	# Phase 2: match scoring (rows / cols / quadrants).
	await _resolve_clears(target_origin)

	if _tutorial_step == 1:
		await _start_tutorial_step_2()
		return
	elif _tutorial_step == 2:
		_complete_tutorial()
		return

	# Refill rules:
	#  • Default: refill the whole tray only when all three slots are empty.
	#  • Exception: if a slot holds an unplayable piece, refill the empty slots
	#    now so the player isn't stuck waiting on a piece no clear can free up.
	var refilled: bool = false
	if tray.is_fully_empty():
		tray.refill()
		refilled = true
	elif tray.has_blocked_slots():
		refilled = tray.regenerate_empty_slots()

	# Wait for the spawn bump (~0.55s + 0.20s stagger over 3 slots) before
	# update_availability so players see new pieces at full scale before dim.
	if refilled:
		await get_tree().create_timer(0.85).timeout

	tray.update_availability()
	_save_game_state()
	if not tray.has_any_enabled():
		await _run_game_over_sequence(refilled)


func _get_streak_pitch(streak_val: int) -> float:
	return ThemeManager.get_streak_pitch(streak_val)



# Detects and animates row / column / quadrant clears from the last placement.
# Sequence: SFX → cascade → optional "COMBO xN" popup → match popup.
func _resolve_clears(_origin: Vector2i) -> void:
	var clears: Dictionary = grid.compute_clears()
	var cells: Array[Vector2i] = clears["cells"]
	var rows: Array[int] = clears["rows"]
	var cols: Array[int] = clears["cols"]
	var quadrants: Array[Vector2i] = clears["quadrants"]
	if cells.is_empty():
		GameState.reset_streak()
		return

	var combo: int = GameState.compute_combo(rows.size(), cols.size(), quadrants.size())
	
	# Increment streak and calculate pitch scale using pentatonic steps
	var streak: int = GameState.increment_streak()
	var pitch: float = _get_streak_pitch(streak)
	print("[AUDIO LOG] Clear Streak: ", streak, " | Pitch Scale: ", pitch)
	
	# Base clear sting fires here; the "combo" SFX fires later in sync with the popup.
	AudioManager.play_sfx("clear", 0.0, pitch)
	_camera_shake(combo)

	# Spawn sword slash VFX
	var slash_color = _theme_config.accent_color if _theme_config else Color(1.0, 0.78, 0.05)
	
	for y in rows:
		var p_start = grid._grid_origin + Vector2(0, (y + 0.5) * grid.cell_size)
		var p_end = grid._grid_origin + Vector2(Grid.SIZE * grid.cell_size, (y + 0.5) * grid.cell_size)
		_spawn_slash(p_start, p_end, slash_color)
		
	for x in cols:
		var p_start = grid._grid_origin + Vector2((x + 0.5) * grid.cell_size, 0)
		var p_end = grid._grid_origin + Vector2((x + 0.5) * grid.cell_size, Grid.SIZE * grid.cell_size)
		_spawn_slash(p_start, p_end, slash_color)
		
	for q in quadrants:
		# Top-left to bottom-right diagonal
		var p_start1 = grid._grid_origin + Vector2(q.x * 3 * grid.cell_size, q.y * 3 * grid.cell_size)
		var p_end1 = grid._grid_origin + Vector2((q.x * 3 + 3) * grid.cell_size, (q.y * 3 + 3) * grid.cell_size)
		_spawn_slash(p_start1, p_end1, slash_color)
		
		# Top-right to bottom-left diagonal
		var p_start2 = grid._grid_origin + Vector2((q.x * 3 + 3) * grid.cell_size, q.y * 3 * grid.cell_size)
		var p_end2 = grid._grid_origin + Vector2(q.x * 3 * grid.cell_size, (q.y * 3 + 3) * grid.cell_size)
		_spawn_slash(p_start2, p_end2, slash_color)

	# Spawn particle explosion for each cleared cell
	for cell in cells:
		var particles = LINE_CLEAR_PARTICLES.instantiate()
		particles.global_position = grid.cell_center_to_global(Vector2(cell))
		var cell_color = grid.get_cell_color(cell)
		if particles.has_method("set_particle_color"):
			particles.set_particle_color(cell_color)
		add_child(particles)

	# Cascade first: spinning blocks fly off before any score readout.
	await grid.clear_cells(cells)

	# Combo label appears letter-by-letter before the score popup.
	if combo >= 2:
		await _spawn_combo_popup(combo)

	# Consecutive clear streak label appears letter-by-letter.
	if streak >= 2:
		await _spawn_streak_popup(streak)

	var clear_value: int = GameState.award_clears(cells.size(), combo)
	var magnitude: float = clamp(0.4 + 0.15 * (rows.size() + cols.size() + quadrants.size() * 2), 0.4, 1.0)
	_spawn_match_popup(clear_value, magnitude)


func _spawn_slash(p_start: Vector2, p_end: Vector2, color: Color) -> void:
	# Glow line (thick, colored)
	var glow_line := Line2D.new()
	glow_line.points = PackedVector2Array([p_start, p_end])
	glow_line.width = 18.0
	glow_line.default_color = color
	glow_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	glow_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	glow_line.antialiased = true
	grid.cells_layer.add_child(glow_line)
	
	# Core line (thin, white)
	var core_line := Line2D.new()
	core_line.points = PackedVector2Array([p_start, p_end])
	core_line.width = 4.0
	core_line.default_color = Color.WHITE
	core_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	core_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	core_line.antialiased = true
	grid.cells_layer.add_child(core_line)
	
	# Tween to animate width and opacity
	var tween := create_tween().set_parallel(true)
	
	# Fade width to 0
	tween.tween_property(glow_line, "width", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(core_line, "width", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Fade color (alpha)
	var glow_target_color := color
	glow_target_color.a = 0.0
	var core_target_color := Color.WHITE
	core_target_color.a = 0.0
	
	tween.tween_property(glow_line, "default_color", glow_target_color, 0.2)
	tween.tween_property(core_line, "default_color", core_target_color, 0.2)
	
	# Free when done
	tween.finished.connect(func():
		if is_instance_valid(glow_line):
			glow_line.queue_free()
		if is_instance_valid(core_line):
			core_line.queue_free()
	)


# --- Score popups ---------------------------------------------------------

func _spawn_score_popup_at_cells(shape: PieceShape, origin: Vector2i, value: int, magnitude: float) -> void:
	if value <= 0:
		return
	var bbox: Vector2i = shape.get_size()
	# Geometric center of the placed piece (may be fractional).
	var center_cell := Vector2(origin.x + (bbox.x - 1) * 0.5, origin.y + (bbox.y - 1) * 0.5)
	_spawn_score_popup(grid.cell_center_to_global(center_cell), value, magnitude)


func _spawn_score_popup_at_grid_center(value: int, magnitude: float) -> void:
	if value <= 0:
		return
	@warning_ignore("integer_division")
	var center := grid.cell_to_global(Vector2i(Grid.SIZE / 2, Grid.SIZE / 2))
	_spawn_score_popup(center, value, magnitude)


# Free-form awaitable announcement at screen center, e.g. "Out of Space".
func _spawn_announcement_popup(label_text: String, color: Color = Color(0.95, 0.18, 0.12)) -> void:
	var popup: ScorePopup = SCORE_POPUP.instantiate()
	add_child(popup)
	await get_tree().process_frame
	if not is_instance_valid(popup):
		return
	await popup.play_announcement(label_text, color)


# "COMBO xN" popup at screen center, awaited so the clear phase pauses on it.
func _spawn_combo_popup(combo: int) -> void:
	var popup: ScorePopup = SCORE_POPUP.instantiate()
	add_child(popup)
	await get_tree().process_frame
	if not is_instance_valid(popup):
		return
		
	# Get pitch multiplier from SSOT
	var combo_config = ThemeManager.get_combo_config(combo)
	var combo_multiplier = combo_config["sfx_pitch"] if combo_config else 1.0
	
	# Harmonize with current streak pitch
	var streak_pitch = _get_streak_pitch(GameState.current_streak)
	var final_pitch = min(3.0, streak_pitch * combo_multiplier)
	print("[AUDIO LOG] Combo: ", combo, " | Multiplier: ", combo_multiplier, " | Final Pitch: ", final_pitch)
	
	AudioManager.play_sfx("combo", 0.0, final_pitch)
	
	await popup.play_combo(combo)


# "STREAK xN" popup at screen center, awaited so the clear phase pauses on it.
func _spawn_streak_popup(streak: int) -> void:
	var popup: ScorePopup = SCORE_POPUP.instantiate()
	add_child(popup)
	await get_tree().process_frame
	if not is_instance_valid(popup):
		return
		
	var pitch = _get_streak_pitch(streak)
	AudioManager.play_sfx("popup", 0.0, pitch)
	await popup.play_streak(streak)


# Match popup spawned at screen center with an elastic bump. Lives on Game
# root so it renders above the grid and tray.
func _spawn_match_popup(value: int, magnitude: float) -> void:
	if value <= 0:
		return
	var popup: ScorePopup = SCORE_POPUP.instantiate()
	add_child(popup)
	await get_tree().process_frame
	if not is_instance_valid(popup):
		return
	# Use Game's own size: get_viewport_rect() returns physical viewport
	# pixels which can drift under stretch modes.
	popup.position = (size - popup.size) * 0.5
	AudioManager.play_sfx("popup")
	popup.play_match(value, magnitude)


func _spawn_score_popup(global_pos: Vector2, value: int, magnitude: float) -> void:
	var popup: ScorePopup = SCORE_POPUP.instantiate()
	var layer: Control = grid.get_popups_layer()
	layer.add_child(popup)
	await get_tree().process_frame
	if not is_instance_valid(popup):
		return
	var local: Vector2 = layer.get_global_transform().affine_inverse() * global_pos
	local -= popup.size * 0.5
	# Clamp inside the grid rect so popups near the edges stay on-screen.
	var max_x: float = max(0.0, layer.size.x - popup.size.x)
	var max_y: float = max(0.0, layer.size.y - popup.size.y)
	local.x = clamp(local.x, 0.0, max_x)
	local.y = clamp(local.y, 0.0, max_y)
	popup.position = local
	AudioManager.play_sfx("popup")
	popup.play(value, magnitude)


# --- Overlays -------------------------------------------------------------

func _on_settings_requested() -> void:
	var overlay := SETTINGS_OVERLAY.instantiate()
	# In-game settings: enable the Restart / Main Menu actions.
	overlay.show_game_actions = true
	overlay.restart_requested.connect(_on_restart_requested.bind(overlay))
	overlay.main_menu_requested.connect(_on_main_menu_requested.bind(overlay))
	add_child(overlay)
	overlay.open()


func _on_leaderboard_requested() -> void:
	var overlay := LEADERBOARD_OVERLAY.instantiate()
	add_child(overlay)



func _on_restart_requested(overlay: Node) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	_restart_run()


func _on_main_menu_requested(overlay: Node) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	SceneRouter.change_scene("res://Scenes/MainMenu/MainMenu.tscn")


# Visual lead-up to the game-over overlay. Caller must have already:
#  (a) resolved clears from the last placement (grid in stable state);
#  (b) called tray.update_availability().
# Steps:
#  1. Populate empty slots so the unplayable state is fully visible.
#  2. Wait for spawn-bumps, then re-evaluate availability.
#  3. Re-check has_any_enabled() — a late regenerate could unblock the run.
#  4. Show "Out of Space" announcement.
#  5. Wipe save and trigger the overlay.
func _run_game_over_sequence(refilled_already: bool) -> void:
	var did_late_refill: bool = false
	if tray.is_fully_empty():
		tray.refill()
		did_late_refill = true
	elif tray.has_empty_slots():
		tray.regenerate_empty_slots()
		did_late_refill = true

	if refilled_already or did_late_refill:
		await get_tree().create_timer(0.85).timeout
		tray.update_availability()
		await get_tree().create_timer(0.35).timeout

	# Late refill could have produced a playable piece — abort if so.
	if tray.has_any_enabled():
		return

	# Fire-and-forget banner: the label has its own ~1.5s lifecycle; we only
	# wait 1s so the overlay arrives while the readout is still visible.
	AudioManager.play_sfx("fail")
	_spawn_announcement_popup("Out of Space")
	await get_tree().create_timer(1.0).timeout

	SaveManager.clear_saved_game()
	GameState.trigger_game_over()


func _on_game_over() -> void:
	var overlay := GAMEOVER_OVERLAY.instantiate()
	add_child(overlay)
	overlay.restart_requested.connect(_on_gameover_restart_requested.bind(overlay))
	overlay.ad_reward_granted.connect(_on_ad_reward_granted.bind(overlay))
	overlay.show_game_over()


func _on_gameover_restart_requested(overlay: Node) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	_restart_run()


func _on_ad_reward_granted(overlay: Node) -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
	# Replace remaining pieces with single-blocks so a move is guaranteed.
	tray.fill_with_single_blocks()
	tray.update_availability()
	_save_game_state()
	# is_game_over was reset inside GameState.consume_ad_reward().


func _restart_run() -> void:
	SaveManager.clear_saved_game()
	GameState.reset_run()
	grid.reset()
	if GameState.start_mode == "chaos":
		grid.generate_random_start_blocks(10)
	tray.refill()
	tray.update_availability()


# --- Persistence ---------------------------------------------------------

# Persists score + grid + slots so the run can be resumed later.
func _save_game_state() -> void:
	SaveManager.save_game({
		"score": GameState.current_score,
		"grid": grid.snapshot_grid_state(),
		"slots": tray.snapshot_state(),
		"assists_used": GameState.assists_used,
		"shuffled_bg_indices": _shuffled_bg_indices,
	})


# Restores a previously-saved run. Called from _ready() on resume.
func _load_saved_game() -> void:
	var data: Dictionary = SaveManager.load_game()
	# Set + emit so the HUD ticks up to the loaded value.
	var saved_score: int = int(data.get("score", 0))
	GameState.current_score = saved_score
	GameState.score_changed.emit(saved_score, 0)
	GameState.assists_used = int(data.get("assists_used", 0))
	
	# Load or initialize shuffled background sequence
	_shuffled_bg_indices.clear()
	var saved_indices = data.get("shuffled_bg_indices", [])
	if saved_indices is Array and not saved_indices.is_empty():
		for idx in saved_indices:
			_shuffled_bg_indices.append(int(idx))
	else:
		_initialize_shuffled_backgrounds()
		
	grid.restore_grid_state(data.get("grid", []))
	tray.restore_state(data.get("slots", []))
	if tray.is_fully_empty():
		tray.refill()
	tray.update_availability()
	progress_bar_widget.refresh_from_state()


func _on_game_reset() -> void:
	_initialize_shuffled_backgrounds()


func _initialize_shuffled_backgrounds() -> void:
	_shuffled_bg_indices.clear()
	if not ThemeManager.shared_milestone_backgrounds.is_empty():
		for i in range(ThemeManager.shared_milestone_backgrounds.size()):
			_shuffled_bg_indices.append(i)
		_shuffled_bg_indices.shuffle()

	# Saved run already in a dead-end → roll straight into game-over.
	if not tray.has_any_enabled():
		# Wait a frame so the UI finishes layout before the banner is positioned.
		await get_tree().process_frame
		await _run_game_over_sequence(false)


# --- Camera shake -------------------------------------------------------

func _on_level_up_triggered() -> void:
	# Fixed level (shake_levelup_combo) for consistency regardless of score.
	_camera_shake(shake_levelup_combo)


# Screen-shake scaling with combo, decaying linearly over shake_base_duration.
func _camera_shake(combo: int) -> void:
	if shake_base_strength <= 0.0 or shake_base_duration <= 0.0:
		return
	
	# Fetch shake intensity from SSOT
	var combo_config = ThemeManager.get_combo_config(combo)
	var intensity: float = combo_config["shake_intensity"] if combo_config else float(combo)
	
	_shake_strength = shake_base_strength * intensity
	_shake_total = shake_base_duration
	_shake_remaining = _shake_total
	# Cache the canvas transform so we offset relative to it (preserves any
	# stretch / dpi scaling Godot already applied).
	_shake_base_transform = get_viewport().canvas_transform
	set_process(true)


func _process(delta: float) -> void:
	if _shake_remaining <= 0.0:
		return
	_shake_remaining -= delta
	if _shake_remaining <= 0.0:
		get_viewport().canvas_transform = _shake_base_transform
		set_process(false)
		return
	# Linear decay: punchy at the start, soft at the tail.
	var t_norm: float = _shake_remaining / _shake_total
	var s: float = _shake_strength * t_norm
	var offset := Vector2(randf_range(-s, s), randf_range(-s, s))
	var t := _shake_base_transform
	t.origin += offset
	get_viewport().canvas_transform = t


# --- Tutorial ------------------------------------------------------------
# First-launch only. Two scripted placements:
#   STEP 1 — two near-complete center rows + vertical domino on column 4 (combo).
#   STEP 2 — center 3x3 quadrant missing one cell + single block on (4,4).
# After step 2 the tutorial flag is persisted; it won't replay unless the
# save file is wiped.

func _start_tutorial() -> void:
	GameState.reset_run()
	grid.reset()
	_spawn_tutorial_cursor()
	# Lock + grey-out the Settings button so the player can't open the menu mid-tutorial.
	hud.settings_button.disabled = true
	hud.settings_button.modulate.a = 0.4
	# Re-anchor cursor + ghost on viewport resize, otherwise the tween would
	# keep heading toward stale coordinates.
	var vp := get_viewport()
	if not vp.size_changed.is_connected(_on_tutorial_viewport_resized):
		vp.size_changed.connect(_on_tutorial_viewport_resized)
	await _start_tutorial_step_1()


func _on_tutorial_viewport_resized() -> void:
	if _tutorial_step <= 0:
		return
	if _tutorial_expected_origin == Vector2i(-1, -1):
		return
	# Wait a frame so the slot / grid finish their resize layout.
	await get_tree().process_frame
	if _tutorial_step <= 0:
		return
	_animate_cursor_hint(1, _tutorial_expected_origin)


func _spawn_tutorial_cursor() -> void:
	if _tutorial_cursor and is_instance_valid(_tutorial_cursor):
		return
	_tutorial_cursor = TextureRect.new()
	_tutorial_cursor.texture = load(TUTORIAL_CURSOR_PATH)
	_tutorial_cursor.custom_minimum_size = Vector2(96, 96)
	_tutorial_cursor.size = _tutorial_cursor.custom_minimum_size
	_tutorial_cursor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tutorial_cursor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_tutorial_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_cursor.modulate.a = 0.0
	_tutorial_cursor.z_index = 90
	add_child(_tutorial_cursor)


# Step 1 — vertical domino on (4,3) to clear rows 3 and 4.
func _start_tutorial_step_1() -> void:
	_tutorial_step = 1
	_tutorial_expected_origin = Vector2i(4, 3)

	# Pre-fill rows 3 and 4 except the central column.
	var fill_color: Color = ThemeManager.get_block_color(3)
	for x in range(Grid.SIZE):
		if x == 4:
			continue
		grid._fill_single(x, 3, fill_color)
		grid._fill_single(x, 4, fill_color)

	tray.lock_all_except(1)
	var shape := PieceShape.new()
	shape.cells = [Vector2i(0, 0), Vector2i(0, 1)]
	shape.display_name = "tutorial_domino_v"
	shape.weight = 0.0
	var piece_color: Color = ThemeManager.get_block_color(0)
	tray.populate_slot_manual(1, shape, piece_color)

	# Wait for the spawn bump to settle, then animate the cursor hint loop.
	await get_tree().create_timer(0.55).timeout
	_animate_cursor_hint(1, _tutorial_expected_origin)


# Step 2 — single block on (4,4) to clear the center 3x3 quadrant.
func _start_tutorial_step_2() -> void:
	_stop_cursor_animation()
	_tutorial_step = 2
	_tutorial_expected_origin = Vector2i(4, 4)

	var fill_color: Color = ThemeManager.get_block_color(5)
	for y in range(3, 6):
		for x in range(3, 6):
			if x == 4 and y == 4:
				continue
			grid._fill_single(x, y, fill_color)

	tray.lock_all_except(1)
	var shape := PieceShape.new()
	shape.cells = [Vector2i(0, 0)]
	shape.display_name = "tutorial_mono"
	shape.weight = 0.0
	var piece_color: Color = ThemeManager.get_block_color(1)
	tray.populate_slot_manual(1, shape, piece_color)

	await get_tree().create_timer(0.55).timeout
	_animate_cursor_hint(1, _tutorial_expected_origin)


func _complete_tutorial() -> void:
	_stop_cursor_animation()
	if _tutorial_cursor and is_instance_valid(_tutorial_cursor):
		_tutorial_cursor.queue_free()
		_tutorial_cursor = null
	_tutorial_step = 0
	_tutorial_expected_origin = Vector2i(-1, -1)
	var vp := get_viewport()
	if vp.size_changed.is_connected(_on_tutorial_viewport_resized):
		vp.size_changed.disconnect(_on_tutorial_viewport_resized)
	hud.settings_button.disabled = false
	hud.settings_button.modulate.a = 1.0
	SaveManager.set_tutorial_completed(true)
	tray.unlock_all()
	tray.refill()
	tray.update_availability()


# Loops a cursor + ghost piece between the slot and the target cell to suggest
# the drag. Stops via _stop_cursor_animation when the step advances.
func _animate_cursor_hint(slot_index: int, target_origin: Vector2i) -> void:
	if _tutorial_cursor == null:
		return
	# Extra frame so the slot piece + grid finish their responsive layout.
	await get_tree().process_frame

	var slot: PieceSlot = tray.get_slot(slot_index)
	if slot == null:
		return

	# Translucent ghost of the slot piece, travels with the cursor.
	if _tutorial_ghost and is_instance_valid(_tutorial_ghost):
		_tutorial_ghost.queue_free()
		_tutorial_ghost = null
	var slot_piece := slot.peek()
	if slot_piece and slot_piece.shape:
		_tutorial_ghost = TUTORIAL_PIECE_SCENE.instantiate() as Piece
		_tutorial_ghost.grid = grid
		_tutorial_ghost.drag_layer = self
		_tutorial_ghost.idle_block_size = grid.cell_size
		add_child(_tutorial_ghost)
		_tutorial_ghost.setup(slot_piece.shape, slot_piece.color)
		_tutorial_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tutorial_ghost.modulate.a = 0.0
		_tutorial_ghost.z_index = 89
		await get_tree().process_frame
		if not is_instance_valid(_tutorial_ghost):
			return

	# Align the fingertip hotspot with the slot center at start and the cell
	# center at the end.
	var cursor_hotspot: Vector2 = _tutorial_cursor.size * TUTORIAL_CURSOR_HOTSPOT_RATIO
	var slot_global: Vector2 = slot.global_position + slot.size * 0.5
	var target_cell_center_global: Vector2 = grid.cell_to_global(target_origin) \
		+ Vector2(grid.cell_size, grid.cell_size) * 0.5
	var inv := get_global_transform().affine_inverse()
	var cursor_start: Vector2 = inv * slot_global - cursor_hotspot
	var cursor_end: Vector2 = inv * target_cell_center_global - cursor_hotspot

	# Ghost: top-left over the slot center at start, over target_origin at end.
	var ghost_start: Vector2 = Vector2.ZERO
	var ghost_end: Vector2 = Vector2.ZERO
	if _tutorial_ghost:
		ghost_start = inv * slot_global - _tutorial_ghost.size * 0.5
		ghost_end = inv * grid.cell_to_global(target_origin)

	if _tutorial_cursor_tween and _tutorial_cursor_tween.is_valid():
		_tutorial_cursor_tween.kill()

	_tutorial_cursor.position = cursor_start
	_tutorial_cursor.modulate.a = 0.0
	if _tutorial_ghost:
		_tutorial_ghost.position = ghost_start
		_tutorial_ghost.modulate.a = 0.0

	_tutorial_cursor_tween = create_tween().set_loops()
	_tutorial_cursor_tween.tween_property(_tutorial_cursor, "modulate:a", 1.0, 0.20)
	if _tutorial_ghost:
		_tutorial_cursor_tween.parallel().tween_property(_tutorial_ghost, "modulate:a", 0.55, 0.20)
	_tutorial_cursor_tween.tween_interval(0.20)
	_tutorial_cursor_tween.tween_property(_tutorial_cursor, "position", cursor_end, 0.85) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if _tutorial_ghost:
		_tutorial_cursor_tween.parallel().tween_property(_tutorial_ghost, "position", ghost_end, 0.85) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tutorial_cursor_tween.tween_interval(0.30)
	_tutorial_cursor_tween.tween_property(_tutorial_cursor, "modulate:a", 0.0, 0.20)
	if _tutorial_ghost:
		_tutorial_cursor_tween.parallel().tween_property(_tutorial_ghost, "modulate:a", 0.0, 0.20)
	_tutorial_cursor_tween.tween_callback(func() -> void:
		if _tutorial_cursor and is_instance_valid(_tutorial_cursor):
			_tutorial_cursor.position = cursor_start
		if _tutorial_ghost and is_instance_valid(_tutorial_ghost):
			_tutorial_ghost.position = ghost_start
	)
	_tutorial_cursor_tween.tween_interval(0.25)


func _stop_cursor_animation() -> void:
	if _tutorial_cursor_tween and _tutorial_cursor_tween.is_valid():
		_tutorial_cursor_tween.kill()
	if _tutorial_cursor and is_instance_valid(_tutorial_cursor):
		_tutorial_cursor.modulate.a = 0.0
	# Ghost is rebuilt for each step.
	if _tutorial_ghost and is_instance_valid(_tutorial_ghost):
		_tutorial_ghost.queue_free()
		_tutorial_ghost = null
