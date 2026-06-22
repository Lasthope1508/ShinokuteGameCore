## Top-of-screen overlay showing current/best score and a Settings button.
## Subscribes to GameState signals and animates the score label tweens.
class_name HUD extends Control

signal settings_requested

@onready var score_label: Label = $ScoreBox/ScoreLabel
@onready var best_label: Label = $Left/BestLabel
@onready var settings_button: TextureButton = $Right/SettingsButton

var _score_tween: Tween
var _displayed_score: int = 0


func _ready() -> void:
	GameState.score_changed.connect(_on_score_changed)
	GameState.best_changed.connect(_on_best_changed)
	GameState.game_reset.connect(_on_game_reset)
	settings_button.pressed.connect(_on_settings_pressed)

	_displayed_score = GameState.current_score
	score_label.text = str(_displayed_score)
	best_label.text = str(GameState.best_score)


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
