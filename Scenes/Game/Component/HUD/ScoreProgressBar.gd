## Progress bar showing distance to the next score milestone. On reach, the
## bar fills, drains, and the target label flips to the next goal. Targets
## follow `25 * n² + 75 * n` — forgiving early (100 → 250), steeper later
## (..., 1350, 1750).
class_name ScoreProgressBar extends PanelContainer

# Fired at the start of every level-up animation. Game.gd uses it to sync
# a camera shake with the bar reaching its target.
signal level_up_triggered

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var target_label: Label = $TargetLabel

var _current_level: int = 0
var _prev_target: int = 0
var _next_target: int = 0
var _value_tween: Tween
var _processing: bool = false


func _ready() -> void:
	_refresh_targets()
	progress_bar.value = float(GameState.current_score)
	GameState.score_changed.connect(_on_score_changed)
	GameState.game_reset.connect(_on_game_reset)
	
	ThemeManager.theme_changed.connect(_on_theme_changed)
	
	# Layout settings
	progress_bar.custom_minimum_size = Vector2(0, 20)
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	target_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	_update_theme_styles()


func _update_theme_styles() -> void:
	var active_theme = ThemeManager.get_active_theme()
	if active_theme:
		# Use bright text color with dark outline for centered progress text overlay
		target_label.add_theme_color_override("font_color", Color.WHITE)
		target_label.add_theme_font_size_override("font_size", 12)
		target_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		target_label.add_theme_constant_override("outline_size", 4)
		
		# Transparent container stylebox since we are nested in the center capsule
		var badge_sb = StyleBoxEmpty.new()
		add_theme_stylebox_override("panel", badge_sb)
		
		# Style inner ProgressBar
		var bg_sb = progress_bar.get_theme_stylebox("background").duplicate() as StyleBoxFlat
		if bg_sb:
			bg_sb.bg_color = Color(0.08, 0.06, 0.15, 0.5)
			bg_sb.border_width_left = 0
			bg_sb.border_width_top = 0
			bg_sb.border_width_right = 0
			bg_sb.border_width_bottom = 0
			bg_sb.set_corner_radius_all(active_theme.inner_button_corner_radius)
			progress_bar.add_theme_stylebox_override("background", bg_sb)
			
		var fill_sb = progress_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
		if fill_sb:
			fill_sb.bg_color = active_theme.accent_color
			fill_sb.border_width_left = 0
			fill_sb.border_width_top = 0
			fill_sb.border_width_right = 0
			fill_sb.border_width_bottom = 0
			fill_sb.set_corner_radius_all(active_theme.inner_button_corner_radius)
			fill_sb.shadow_color = active_theme.accent_color
			fill_sb.shadow_color.a = 0.3
			fill_sb.shadow_size = 2
			progress_bar.add_theme_stylebox_override("fill", fill_sb)


func _on_theme_changed(_name: String, _config: ThemeConfig) -> void:
	_update_theme_styles()


func _update_text(score: int) -> void:
	target_label.text = "%d / %d" % [score, _next_target]


func _refresh_targets() -> void:
	_prev_target = GameState.get_target_for_level(_current_level)
	_next_target = GameState.get_target_for_level(_current_level + 1)
	progress_bar.min_value = 0.0
	progress_bar.max_value = float(_next_target)
	_update_text(GameState.current_score)


func _on_score_changed(new_score: int, _delta: int) -> void:
	# Re-entrant safety: _process_score_change loops until it catches up.
	if _processing:
		return
	_processing = true
	await _process_score_change(new_score)
	_processing = false


# Catches the bar up to `target_score`, performing N level-ups if needed.
# Per level-up: tween to full → drain → refresh targets and update the label.
func _process_score_change(target_score: int) -> void:
	while target_score >= _next_target:
		await _animate_to_full()
		await _animate_drain()
		_current_level += 1
		_refresh_targets()
		# value < new min snaps the bar visually to 0% fill.
		progress_bar.value = 0.0
	_animate_to_value(float(target_score))


func _animate_to_value(value: float) -> void:
	_update_text(int(round(value)))
	if _value_tween and _value_tween.is_valid():
		_value_tween.kill()
	_value_tween = create_tween()
	_value_tween.tween_property(progress_bar, "value", value, 0.40) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Awaitable: tweens the bar to its current max, holds a beat. Plays the
# level-up SFX and emits level_up_triggered.
func _animate_to_full() -> void:
	if _value_tween and _value_tween.is_valid():
		_value_tween.kill()
	AudioManager.play_sfx("levelup")
	level_up_triggered.emit()
	_update_text(_next_target)
	_value_tween = create_tween()
	_value_tween.tween_property(progress_bar, "value", progress_bar.max_value, 0.30) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Pulse the bar so the player notices the milestone.
	_value_tween.parallel().tween_property(self, "scale", Vector2(1.05, 1.0), 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_value_tween.tween_property(self, "scale", Vector2.ONE, 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await _value_tween.finished
	await get_tree().create_timer(0.15).timeout


# Animates the bar from full to empty inside the CURRENT range, so the
# player visibly sees it deplete before the target label flips.
func _animate_drain() -> void:
	if _value_tween and _value_tween.is_valid():
		_value_tween.kill()
	_value_tween = create_tween()
	_value_tween.tween_property(progress_bar, "value", 0.0, 0.40) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _value_tween.finished
	# Brief pause with empty bar before the target label flips.
	await get_tree().create_timer(0.08).timeout


func _on_game_reset() -> void:
	_current_level = 0
	_processing = false
	if _value_tween and _value_tween.is_valid():
		_value_tween.kill()
	_refresh_targets()
	progress_bar.value = 0.0


# Snaps the bar to the current score without animation (post-load).
func refresh_from_state() -> void:
	_processing = false
	if _value_tween and _value_tween.is_valid():
		_value_tween.kill()
	_current_level = GameState.get_level_for_score(GameState.current_score)
	_refresh_targets()
	progress_bar.value = float(GameState.current_score)

