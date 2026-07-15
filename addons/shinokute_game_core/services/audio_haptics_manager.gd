class_name ShinokuteAudioHapticsManager
extends Node

var theme_manager: Node
var sfx_enabled := true
var bgm_enabled := true
var haptics_enabled := true
var _players: Dictionary = {}
var _bgm_player: AudioStreamPlayer
var _current_bgm_path := ""
var _sfx_bus := "Master"
var _bgm_bus := "Master"
var _sfx_pool_size := 8
var _audio_unlocked := false
var _pending_bgm_path := ""
var _pending_bgm_fade_seconds := 0.0
var _pending_bgm_volume_db := -12.0

func configure(manager: Node = null) -> void:
	theme_manager = manager

func configure_audio_runtime(config: Dictionary = {}) -> void:
	_sfx_bus = String(config.get("sfx_bus", _sfx_bus))
	_bgm_bus = String(config.get("bgm_bus", _bgm_bus))
	_sfx_pool_size = int(max(1, int(config.get("sfx_pool_size", _sfx_pool_size))))

func set_audio_enabled(value: bool) -> void:
	set_sfx_enabled(value)

func is_audio_enabled() -> bool:
	return is_sfx_enabled()

func set_sfx_enabled(value: bool) -> void:
	sfx_enabled = value

func is_sfx_enabled() -> bool:
	return sfx_enabled

func set_bgm_enabled(value: bool) -> void:
	bgm_enabled = value
	if not bgm_enabled and _bgm_player != null:
		_bgm_player.stop()
	elif bgm_enabled and _bgm_player != null and not _current_bgm_path.is_empty():
		_bgm_player.play()

func is_bgm_enabled() -> bool:
	return bgm_enabled

func set_haptics_enabled(value: bool) -> void:
	haptics_enabled = value

func is_haptics_enabled() -> bool:
	return haptics_enabled

func get_audio_path(event_name: String) -> String:
	if theme_manager != null and theme_manager.has_method("get_audio_path"):
		return theme_manager.get_audio_path(event_name)
	return ""

func unlock_audio() -> void:
	_audio_unlocked = true

func is_audio_unlocked() -> bool:
	return _audio_unlocked

func audio_debug_state() -> Dictionary:
	return {
		"sfx_enabled": sfx_enabled,
		"bgm_enabled": bgm_enabled,
		"haptics_enabled": haptics_enabled,
		"sfx_bus": _sfx_bus,
		"bgm_bus": _bgm_bus,
		"sfx_pool_size": _sfx_pool_size,
		"audio_unlocked": _audio_unlocked,
		"current_bgm_path": _current_bgm_path,
		"pending_bgm_path": _pending_bgm_path,
		"pending_bgm_fade_seconds": _pending_bgm_fade_seconds,
		"pending_bgm_volume_db": _pending_bgm_volume_db,
		"pooled_events": _players.keys()
	}

func play_event(event_name: String) -> int:
	if not sfx_enabled:
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
		player.bus = _sfx_bus
		add_child(player)
		_players[event_name] = player
	_players[event_name].play()
	return OK

func play_bgm(path: String, volume_db: float = -12.0) -> int:
	_current_bgm_path = path
	if not bgm_enabled:
		return ERR_SKIP
	if path.strip_edges().is_empty():
		return ERR_DOES_NOT_EXIST
	var stream = load(path)
	if stream == null:
		return ERR_CANT_OPEN
	if _bgm_player == null:
		_bgm_player = AudioStreamPlayer.new()
		add_child(_bgm_player)
	_bgm_player.stream = stream
	_bgm_player.bus = _bgm_bus
	_bgm_player.volume_db = volume_db
	_bgm_player.play()
	return OK

func play_bgm_event(event_name: String, volume_db: float = -12.0) -> int:
	var path := get_audio_path(event_name)
	return play_bgm(path, volume_db)

func request_bgm_crossfade(path: String, fade_seconds: float = 0.5, volume_db: float = -12.0) -> Dictionary:
	_pending_bgm_path = path
	_pending_bgm_fade_seconds = max(0.0, fade_seconds)
	_pending_bgm_volume_db = volume_db
	return {"status": "queued", "path": path, "fade_seconds": _pending_bgm_fade_seconds, "volume_db": volume_db}

func stop_bgm() -> void:
	if _bgm_player != null:
		_bgm_player.stop()

func vibrate(milliseconds: int = 30) -> int:
	if not haptics_enabled:
		return ERR_SKIP
	if milliseconds <= 0:
		return ERR_INVALID_PARAMETER
	Input.vibrate_handheld(milliseconds)
	return OK
