## Progress bar showing distance to the next score milestone. On reach, the
## bar fills, drains, and the target label flips to the next goal. Targets
## follow `25 * n² + 75 * n` — forgiving early (100 → 250), steeper later
## (..., 1350, 1750).
class_name ScoreProgressBar extends Control

# Fired at the start of every level-up animation. Game.gd uses it to sync
# a camera shake with the bar reaching its target.
signal level_up_triggered

@onready var progress_bar: ProgressBar = $HBox/ProgressBar
@onready var target_label: Label = $HBox/TargetLabel

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
	_update_theme_styles()


func _update_theme_styles() -> void:
	var active_theme = ThemeManager.get_active_theme()
	if active_theme:
		target_label.add_theme_color_override("font_color", active_theme.text_color)
		target_label.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.8))
		target_label.add_theme_constant_override("outline_size", 8)
		
		var bg_sb = progress_bar.get_theme_stylebox("background").duplicate() as StyleBoxFlat
		if bg_sb:
			var base_bg = active_theme.panel_bg_color
			bg_sb.bg_color = base_bg.darkened(0.3)
			bg_sb.border_color = active_theme.panel_border_color
			progress_bar.add_theme_stylebox_override("background", bg_sb)
			
		var fill_sb = progress_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
		if fill_sb:
			fill_sb.bg_color = active_theme.accent_color
			fill_sb.border_color = active_theme.accent_color.darkened(0.5)
			fill_sb.shadow_color = active_theme.accent_color
			fill_sb.shadow_color.a = 0.45
			progress_bar.add_theme_stylebox_override("fill", fill_sb)


func _on_theme_changed(_name: String, _config: ThemeConfig) -> void:
	_update_theme_styles()


func _refresh_targets() -> void:
	_prev_target = GameState.get_target_for_level(_current_level)
	_next_target = GameState.get_target_for_level(_current_level + 1)
	progress_bar.min_value = float(_prev_target)
	progress_bar.max_value = float(_next_target)
	target_label.text = str(_next_target)


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
		progress_bar.value = float(_prev_target)
	_animate_to_value(float(target_score))


func _animate_to_value(value: float) -> void:
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
	_value_tween.tween_property(progress_bar, "value", progress_bar.min_value, 0.40) \
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
