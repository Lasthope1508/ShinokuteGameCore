## Top-of-screen overlay showing current/best score and a Settings button.
## Subscribes to GameState signals and animates the score label tweens.
class_name HUD extends Control

signal settings_requested
signal leaderboard_requested

@onready var score_label: Label = $HBox/CenterCol/ScoreBox/ScoreLabel
@onready var best_label: Label = $HBox/LeftCol/Left/BestLabel
@onready var settings_button: TextureButton = $HBox/RightCol/Right/SettingsButton
@onready var leaderboard_button: TextureButton = $HBox/RightCol/Right/LeaderboardButton

var _score_tween: Tween
var _displayed_score: int = 0


func _ready() -> void:
	GameState.score_changed.connect(_on_score_changed)
	GameState.best_changed.connect(_on_best_changed)
	GameState.game_reset.connect(_on_game_reset)
	settings_button.pressed.connect(_on_settings_pressed)
	leaderboard_button.pressed.connect(_on_leaderboard_pressed)

	ThemeManager.theme_changed.connect(_on_theme_changed)
	_update_theme_styles()

	_displayed_score = GameState.current_score
	score_label.text = str(_displayed_score)
	best_label.text = str(GameState.best_score)
	$HBox/LeftCol/Left.visible = false


func _update_theme_styles() -> void:
	var active_theme = ThemeManager.get_active_theme()
	if active_theme:
		score_label.add_theme_color_override("font_color", active_theme.text_color)
		score_label.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.6))
		best_label.add_theme_color_override("font_color", active_theme.accent_color)
		best_label.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.8))


func _on_theme_changed(_name: String, _config: ThemeConfig) -> void:
	_update_theme_styles()


func _on_score_changed(new_score: int, _delta: int) -> void:
	if _score_tween and _score_tween.is_valid():
		_score_tween.kill()
	_score_tween = create_tween()
	_score_tween.tween_method(_set_displayed_score, _displayed_score, new_score, 0.4)


func _set_displayed_score(value: float) -> void:
	_displayed_score = int(round(value))
	score_label.text = str(_displayed_score)


func _on_best_changed(new_best: int) -> void:
	best_label.text = str(new_best)


func _on_game_reset() -> void:
	_displayed_score = 0
	score_label.text = "0"
	best_label.text = str(GameState.best_score)


func _on_settings_pressed() -> void:
	AudioManager.play_sfx("button")
	settings_requested.emit()


func _on_leaderboard_pressed() -> void:
	AudioManager.play_sfx("button")
	leaderboard_requested.emit()

