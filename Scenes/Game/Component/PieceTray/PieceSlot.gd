## A single slot hosting a Piece while it waits to be picked up. The slot is
## just a sized container — the Piece manages its own drag input.
class_name PieceSlot extends Control

const PIECE_SCENE := preload("res://Scenes/Game/Component/Piece/Piece.tscn")

signal piece_picked(slot: PieceSlot, piece: Piece)
signal piece_consumed(slot: PieceSlot)

var current_piece: Piece
var _enabled: bool = true
var _state_tween: Tween


@onready var background: NinePatchRect = $Aspect/Background


func _ready() -> void:
	# Re-center the piece on responsive layout changes.
	resized.connect(_on_slot_resized)
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_update_theme()


func _update_theme() -> void:
	var active_theme = ThemeManager.get_active_theme()
	if active_theme:
		if active_theme.piece_slot_texture != null:
			background.texture = active_theme.piece_slot_texture
		else:
			background.texture = load("res://Assets/Sprites/piece_slot.png")
	else:
		background.texture = load("res://Assets/Sprites/piece_slot.png")


func _on_theme_changed(_name: String, _config: ThemeConfig) -> void:
	_update_theme()



func _on_slot_resized() -> void:
	# Skip while dragging — the piece lives on the drag layer then.
	if is_empty():
		return
	if current_piece.get_parent() != self:
		return
	# Pass -1.0 to skip the spawn bump.
	_center_piece(current_piece, -1.0)


func is_empty() -> bool:
	return current_piece == null or not is_instance_valid(current_piece)


# Forwards presses on the slot rect to the hosted piece, enlarging the touch
# target on mobile and for small pieces (mono / domino).
func _gui_input(event: InputEvent) -> void:
	if is_empty() or not _enabled:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			current_piece.begin_drag(mb.global_position)
			accept_event()


# Toggles pick-up availability. Disabled slots fade to a dim tint.
func set_enabled(value: bool) -> void:
	if _enabled == value:
		return
	_enabled = value
	var target: Color = Color(1.0, 1.0, 1.0, 1.0) if value else Color(0.45, 0.45, 0.5, 0.55)
	if _state_tween and _state_tween.is_valid():
		_state_tween.kill()
	_state_tween = create_tween()
	_state_tween.tween_property(self, "modulate", target, 0.20) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func is_enabled() -> bool:
	return _enabled


# Hides + blocks the slot entirely (vs. set_enabled which only dims).
# Used by the tutorial to keep only the central slot active.
func set_locked(value: bool) -> void:
	_enabled = not value
	visible = not value


# Spawns a piece in the slot. `spawn_delay` staggers the entry bump across slots.
func populate(shape: PieceShape, color: Color, grid: Grid, drag_layer: Control, spawn_delay: float = 0.0) -> void:
	clear()
	var p: Piece = PIECE_SCENE.instantiate()
	p.grid = grid
	p.drag_layer = drag_layer
	add_child(p)
	p.setup(shape, color)
	p.drag_started.connect(_on_piece_drag_started)
	_center_piece(p, spawn_delay)
	current_piece = p


func clear() -> void:
	if current_piece and is_instance_valid(current_piece):
		current_piece.queue_free()
	current_piece = null


func peek() -> Piece:
	return current_piece


func _center_piece(p: Piece, spawn_delay: float = -1.0) -> void:
	# Wait a frame so piece size settles, then align to the square background
	# (centered by AspectRatioContainer) rather than the rectangular slot.
	await get_tree().process_frame
	if not (p and is_instance_valid(p)):
		return
	var bg_rect: Rect2 = $Aspect/Background.get_rect()
	p.position = bg_rect.position + (bg_rect.size - p.size) * 0.5
	if spawn_delay >= 0.0:
		_play_spawn_bump(p, spawn_delay)


# Pop-in bump used when the tray refills.
# Uses explicit `set_parallel(true/false)` toggles instead of chained
# `.parallel()` calls — the latter behaved inconsistently on HTML5 exports
# (modulate.a stayed at 0 and pieces were invisible but still interactive).
# The trailing callback forces the final state as a safety net.
func _play_spawn_bump(p: Piece, delay: float) -> void:
	if not is_instance_valid(p):
		return
	p.pivot_offset = p.size * 0.5
	p.scale = Vector2(0.2, 0.2)
	p.modulate.a = 0.0
	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_callback(func() -> void:
		AudioManager.play_sfx("populate_slot", 0.18)
	)
	tw.set_parallel(true)
	tw.tween_property(p, "modulate:a", 1.0, 0.10)
	tw.tween_property(p, "scale", Vector2.ONE, 0.45) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	# Safety net for HTML5 — force the final visible state.
	tw.set_parallel(false)
	tw.tween_callback(func() -> void:
		if is_instance_valid(p):
			p.modulate.a = 1.0
			p.scale = Vector2.ONE
	)


func _on_piece_drag_started(p: Piece) -> void:
	piece_picked.emit(self, p)


# Called by Game after a successful placement.
func mark_consumed() -> void:
	if current_piece and is_instance_valid(current_piece):
		current_piece.consume()
	current_piece = null
	piece_consumed.emit(self)
