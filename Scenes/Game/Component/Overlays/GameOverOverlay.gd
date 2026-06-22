## Game-over modal: countdown, score recap, ADReward (capped at 2 uses),
## Restart. Inherits the elastic animation from ElasticOverlay.gd.
extends "res://Scenes/Common/ElasticOverlay.gd"

# Fired on Restart button or countdown expiration.
signal restart_requested
# Fired when the player confirms the ADReward and the tray should be filled
# with single-block pieces.
signal ad_reward_granted

@export var countdown_seconds: int = 10

@onready var score_label: Label = $Panel/Margin/VBox/ScoreLabel
@onready var best_label: Label = $Panel/Margin/VBox/BestLabel
@onready var timer_label: Label = $Panel/Margin/VBox/TimerLabel
@onready var restart_button: Button = $Panel/Margin/VBox/Buttons/RestartButton
@onready var ad_button: Button = $Panel/Margin/VBox/Buttons/AdButton
@onready var countdown: Timer = $Countdown

var _seconds_left: int = 0


func _ready() -> void:
	super()
	restart_button.pressed.connect(_on_restart_pressed)
	ad_button.pressed.connect(_on_ad_pressed)
	countdown.timeout.connect(_on_countdown_tick)


# Called by Game when GameState fires `game_over`.
func show_game_over() -> void:
	score_label.text = "Score: %d" % GameState.current_score
	best_label.text = "Best: %d" % GameState.best_score
	ad_button.visible = GameState.ad_rewards_used < GameState.MAX_AD_REWARDS
	_seconds_left = countdown_seconds
	timer_label.text = _format_time(_seconds_left)
	countdown.start(1.0)
	AudioManager.play_sfx("gameover")
	open()


func _on_countdown_tick() -> void:
	_seconds_left -= 1
	if _seconds_left <= 0:
		countdown.stop()
		_request_restart()
		return
	timer_label.text = _format_time(_seconds_left)
	AudioManager.play_sfx("timeout")


func _on_restart_pressed() -> void:
	AudioManager.play_sfx("button")
	countdown.stop()
	_request_restart()


func _on_ad_pressed() -> void:
	AudioManager.play_sfx("button")
	# TODO: integrate AdMob / equivalent here. Simulated with a short delay so
	# the integration point is obvious.
	ad_button.disabled = true
	if not GameState.consume_ad_reward():
		ad_button.disabled = false
		return
	await get_tree().create_timer(0.5).timeout
	countdown.stop()
	ad_reward_granted.emit()
	await close()
	ad_button.disabled = false


func _request_restart() -> void:
	await close()
	restart_requested.emit()


func _format_time(seconds: int) -> String:
	return "%d s" % max(0, seconds)
