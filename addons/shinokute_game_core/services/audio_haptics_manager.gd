class_name ShinokuteAudioHapticsManager
extends Node

var theme_manager: Node
var audio_enabled := true
var haptics_enabled := true
var _players: Dictionary = {}

func configure(manager: Node = null) -> void:
	theme_manager = manager

func set_audio_enabled(value: bool) -> void:
	audio_enabled = value

func is_audio_enabled() -> bool:
	return audio_enabled

func set_haptics_enabled(value: bool) -> void:
	haptics_enabled = value

func is_haptics_enabled() -> bool:
	return haptics_enabled

func get_audio_path(event_name: String) -> String:
	if theme_manager != null and theme_manager.has_method("get_audio_path"):
		return theme_manager.get_audio_path(event_name)
	return ""

func play_event(event_name: String) -> int:
	if not audio_enabled:
		return ERR_SKIP
	var path := get_audio_path(event_name)
	if path.is_empty():
		return ERR_DOES_NOT_EXIST
	if not _players.has(event_name):
		var stream = load(path)
		if stream == null:
			return ERR_CANT_OPEN
		var player := AudioStreamPlayer.new()
		player.stream = stream
		add_child(player)
		_players[event_name] = player
	_players[event_name].play()
	return OK

func vibrate(milliseconds: int = 30) -> int:
	if not haptics_enabled:
		return ERR_SKIP
	if milliseconds <= 0:
		return ERR_INVALID_PARAMETER
	Input.vibrate_handheld(milliseconds)
	return OK
