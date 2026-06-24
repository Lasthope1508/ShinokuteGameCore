## Game-over modal: countdown, score recap, ADReward (capped at 2 uses),
## Restart. Inherits the elastic animation from ElasticOverlay.gd.
extends "res://Scenes/Common/ElasticOverlay.gd"

const LEADERBOARD_OVERLAY := preload("res://Scenes/Game/Component/Overlays/LeaderboardOverlay.tscn")

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
@onready var leaderboard_button: Button = $Panel/Margin/VBox/Buttons/LeaderboardButton
@onready var countdown: Timer = $Countdown

var _seconds_left: int = 0


func _ready() -> void:
	super()
	restart_button.pressed.connect(_on_restart_pressed)
	ad_button.pressed.connect(_on_ad_pressed)
	leaderboard_button.pressed.connect(_on_leaderboard_pressed)
	countdown.timeout.connect(_on_countdown_tick)
	
	ThemeManager.theme_changed.connect(_on_theme_changed)
	_update_theme_styles()


func _update_theme_styles() -> void:
	var active_theme = ThemeManager.get_active_theme()
	if active_theme:
		var title_node = get_node_or_null("Panel/Margin/VBox/Title")
		if title_node:
			title_node.add_theme_color_override("font_color", active_theme.alert_color)
			title_node.add_theme_color_override("font_outline_color", active_theme.alert_color.darkened(0.8))
		
		var timer_node = get_node_or_null("Panel/Margin/VBox/TimerLabel")
		if timer_node:
			timer_node.add_theme_color_override("font_color", active_theme.accent_color)
			timer_node.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.8))

		var score_node = get_node_or_null("Panel/Margin/VBox/ScoreLabel")
		if score_node:
			score_node.add_theme_color_override("font_color", active_theme.text_color)
			score_node.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.8))

		var best_node = get_node_or_null("Panel/Margin/VBox/BestLabel")
		if best_node:
			best_node.add_theme_color_override("font_color", active_theme.accent_color)
			best_node.add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.8))


func _on_theme_changed(_name: String, _config: ThemeConfig) -> void:
	_update_theme_styles()


# Called by Game when GameState fires `game_over`.
func show_game_over() -> void:
	score_label.text = "Score: %d" % GameState.current_score
	best_label.text = "Best: %d" % GameState.best_score
	ad_button.visible = GameState.ad_rewards_used < GameState.MAX_AD_REWARDS
	_seconds_left = countdown_seconds
	timer_label.text = _format_time(_seconds_left)
	countdown.start(1.0)
	AudioManager.play_sfx("gameover")
	
	# Automatically submit best score to regional online leaderboard
	if GameState.best_score > 0:
		LeaderboardManager.submit_score(GameState.best_score)
		
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
	ad_button.disabled = true
	if not GameState.consume_ad_reward():
		ad_button.disabled = false
		return
	
	countdown.stop()
	# Call global AdManager to show the rewarded video
	AdManager.show_rewarded_video(self, "_on_ad_completed")


func _on_ad_completed(success: bool) -> void:
	if success:
		ad_reward_granted.emit()
		await close()
	else:
		# If the ad failed or was cancelled, resume the countdown
		if _seconds_left > 0:
			countdown.start(1.0)
	ad_button.disabled = false



func _request_restart() -> void:
	await close()
	restart_requested.emit()


func _format_time(seconds: int) -> String:
	return "%d s" % max(0, seconds)


func _on_leaderboard_pressed() -> void:
	AudioManager.play_sfx("button")
	countdown.stop()
	var overlay := LEADERBOARD_OVERLAY.instantiate()
	add_child(overlay)
	overlay.tree_exited.connect(func():
		if _seconds_left > 0:
			countdown.start(1.0)
	)
