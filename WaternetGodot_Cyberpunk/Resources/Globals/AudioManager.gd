## Centralized audio playback. One AudioStreamPlayer for music plus a small
## pool of players for SFX so multiple sounds can overlap. Stream resources
## are referenced by name and loaded lazily — leave a slot empty (null) until
## the matching .ogg is added under Assets/Audio/.
extends Node

const SFX_POOL_SIZE: int = 8

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const WEB_AUDIO_DEBUG_DATASET_KEY := "glyphflowAudioDebug"

var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _web_audio_unlock_attempted := false
var _web_audio_unlock_input_count := 0


func _ready() -> void:
	_ensure_canonical_audio_buses()

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_sfx_pool.append(p)

	apply_saved_volumes()
	_publish_web_debug_state()

	if has_node("/root/ThemeManager"):
		get_node("/root/ThemeManager").theme_changed.connect(_on_theme_changed)

func _input(event: InputEvent) -> void:
	if not OS.has_feature("web"):
		return
	if _web_audio_unlock_attempted:
		return
	if not _is_web_audio_unlock_event(event):
		return
	_unlock_web_audio_after_user_gesture()

func _exit_tree() -> void:
	if _music_player != null and is_instance_valid(_music_player):
		_music_player.stop()
		_music_player.stream = null
		_music_player.free()
		_music_player = null
	for player in _sfx_pool:
		if player != null and is_instance_valid(player):
			player.stop()
			player.stream = null
			player.free()
	_sfx_pool.clear()

func _on_theme_changed(_name: String, _config: Variant) -> void:
	if _music_player and _music_player.playing and _current_music_mode != "":
		# Smoothly transition to the new theme's BGM track
		var path = _get_music_path(_current_music_mode)
		_transition_to_music(path)


# Plays a SFX by name; no-ops if missing. `pitch_variation` (0..1) randomizes
# pitch_scale within ±variation around custom_pitch. `volume_offset_db` adds runtime db adjustments.
func play_sfx(sfx_name: String, pitch_variation: float = 0.0, custom_pitch: float = 1.0, volume_offset_db: float = 0.0) -> void:
	var stream := _get_sfx(sfx_name)
	if stream == null:
		_publish_web_debug_state()
		return
	var player := _get_free_sfx_player()
	if player == null:
		_publish_web_debug_state()
		return
	player.stream = stream
	var theme_manager = get_node_or_null("/root/ThemeManager")
	var resolved_pitch_variation := pitch_variation
	if resolved_pitch_variation <= 0.0 and theme_manager != null and theme_manager.has_method("get_sfx_pitch_variation"):
		resolved_pitch_variation = float(theme_manager.get_sfx_pitch_variation(sfx_name))
	if resolved_pitch_variation > 0.0:
		var v: float = clamp(resolved_pitch_variation, 0.0, 0.95)
		player.pitch_scale = custom_pitch + randf_range(-v, v)
	else:
		player.pitch_scale = custom_pitch

	var base_offset := 0.0
	if theme_manager != null and theme_manager.has_method("get_sfx_volume_offset"):
		base_offset = float(theme_manager.get_sfx_volume_offset(sfx_name))
	player.volume_db = base_offset + volume_offset_db
	player.play()
	_publish_web_debug_state()


func _enable_looping(stream: AudioStream) -> void:
	if stream == null:
		return
	if stream is AudioStreamWAV:
		stream.loop_mode = 1 # LOOP_FORWARD
	elif "loop" in stream:
		stream.set("loop", true)

# Helper to resolve BGM path dynamically based on the active theme
func _get_music_path(mode: String) -> String:
	if has_node("/root/ThemeManager"):
		var theme_manager = get_node("/root/ThemeManager")
		var theme = theme_manager.get_active_theme()
		if theme != null:
			return theme.get_bgm_path()
	return ""


# Starts the looped music track. Set Loop in the import dock if the file doesn't loop.
func play_music() -> void:
	if _is_headless_runtime():
		_publish_web_debug_state()
		return
	if _music_player.playing:
		_publish_web_debug_state()
		return
	var path = _get_music_path("gameplay")
	if path.is_empty() or not ResourceLoader.exists(path):
		_publish_web_debug_state()
		return
	var stream := load(path) as AudioStream
	if stream == null:
		_publish_web_debug_state()
		return
	_enable_looping(stream)
	_music_player.stream = stream
	_music_player.volume_db = 0.0
	_music_player.play()
	_current_music_mode = "gameplay"
	_publish_web_debug_state()


func stop_music() -> void:
	if _music_player.playing:
		_music_player.stop()
	_music_player.stream = null
	_current_music_mode = ""
	_publish_web_debug_state()


var _current_music_mode: String = "" # Always "gameplay" for 1 single BGM loop

func set_music_mode(mode: String) -> void:
	# Disabled: 1 single BGM loop only to avoid unnecessary transitions
	return



func _transition_to_music(path: String) -> void:
	if _is_headless_runtime():
		_publish_web_debug_state()
		return
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: music file not found at " + path)
		_publish_web_debug_state()
		return
		
	var new_stream = load(path) as AudioStream
	if new_stream == null:
		_publish_web_debug_state()
		return
		
	_enable_looping(new_stream)
	
	if not _music_player.playing:
		_music_player.stream = new_stream
		_music_player.volume_db = 0.0
		_music_player.play()
		_publish_web_debug_state()
		return
		
	var tw = create_tween()
	tw.tween_property(_music_player, "volume_db", -80.0, 0.8)
	tw.tween_callback(func():
		_music_player.stream = new_stream
		_music_player.play()
		_publish_web_debug_state()
	)
	tw.tween_property(_music_player, "volume_db", 0.0, 0.8)

func _is_web_audio_unlock_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.pressed
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventKey:
		return event.pressed and not event.echo
	return false

func _unlock_web_audio_after_user_gesture() -> void:
	_web_audio_unlock_attempted = true
	_web_audio_unlock_input_count += 1
	_ensure_canonical_audio_buses()
	if _music_player == null:
		_publish_web_debug_state()
		return
	if _music_player.stream == null:
		play_music()
		return
	var resume_from := 0.0
	if _music_player.playing:
		resume_from = _music_player.get_playback_position()
		_music_player.stop()
	if not is_music_muted():
		_music_player.play(resume_from)
	_publish_web_debug_state()

func is_music_muted() -> bool:
	return get_bus_volume(BUS_MUSIC) <= 0.0001

func toggle_music_mute() -> bool:
	if is_music_muted():
		set_bus_volume(BUS_MUSIC, 0.7)
		return false
	else:
		set_bus_volume(BUS_MUSIC, 0.0)
		return true

func is_master_muted() -> bool:
	return get_bus_volume(BUS_MUSIC) <= 0.0001 and get_bus_volume(BUS_SFX) <= 0.0001

func toggle_master_mute() -> bool:
	if is_master_muted():
		set_bus_volume(BUS_MUSIC, 0.7)
		set_bus_volume(BUS_SFX, 0.65)
		return false
	else:
		set_bus_volume(BUS_MUSIC, 0.0)
		set_bus_volume(BUS_SFX, 0.0)
		return true




# Reads volumes (linear 0..1) from SaveManager and applies them to the buses.
func apply_saved_volumes() -> void:
	_ensure_canonical_audio_buses()
	_set_bus_volume(BUS_MASTER, 1.0)
	if SaveManager.get_volume(BUS_MASTER, 1.0) <= 0.0001:
		SaveManager.set_volume(BUS_MASTER, 1.0)
	_set_bus_volume(BUS_MUSIC, SaveManager.get_volume(BUS_MUSIC, 0.7))
	_set_bus_volume(BUS_SFX, SaveManager.get_volume(BUS_SFX, 0.65))
	_publish_web_debug_state()


func set_bus_volume(bus_name: String, linear_value: float) -> void:
	_ensure_canonical_audio_buses()
	linear_value = clamp(linear_value, 0.0, 1.0)
	_set_bus_volume(bus_name, linear_value)
	SaveManager.set_volume(bus_name, linear_value)
	if bus_name != BUS_MASTER and linear_value > 0.0001:
		_set_bus_volume(BUS_MASTER, 1.0)
		SaveManager.set_volume(BUS_MASTER, 1.0)
	_publish_web_debug_state()


func get_bus_volume(bus_name: String) -> float:
	var default_val := 1.0
	if bus_name == BUS_SFX:
		default_val = 0.65
	elif bus_name == BUS_MUSIC:
		default_val = 0.7
	return SaveManager.get_volume(bus_name, default_val)


func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if linear_value <= 0.0001:
		AudioServer.set_bus_mute(idx, true)
		return
	AudioServer.set_bus_mute(idx, false)
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear_value))

func get_debug_state() -> Dictionary:
	_ensure_canonical_audio_buses()
	var music_idx := AudioServer.get_bus_index(BUS_MUSIC)
	var sfx_idx := AudioServer.get_bus_index(BUS_SFX)
	var master_idx := AudioServer.get_bus_index(BUS_MASTER)
	var music_stream_path := ""
	var music_stream_class := ""
	if _music_player != null and _music_player.stream != null:
		music_stream_path = _music_player.stream.resource_path
		music_stream_class = _music_player.stream.get_class()
	var bgm_path := _get_music_path("gameplay")
	return {
		"music_playing": _music_player != null and _music_player.playing,
		"music_stream_path": music_stream_path,
		"music_stream_class": music_stream_class,
		"music_player_bus": _music_player.bus if _music_player != null else "",
		"music_bus_index": music_idx,
		"music_bus_muted": music_idx >= 0 and AudioServer.is_bus_mute(music_idx),
		"music_bus_volume": get_bus_volume(BUS_MUSIC),
		"sfx_bus_index": sfx_idx,
		"sfx_bus_muted": sfx_idx >= 0 and AudioServer.is_bus_mute(sfx_idx),
		"sfx_bus_volume": get_bus_volume(BUS_SFX),
		"master_bus_index": master_idx,
		"master_bus_muted": master_idx >= 0 and AudioServer.is_bus_mute(master_idx),
		"master_bus_volume": get_bus_volume(BUS_MASTER),
		"current_music_mode": _current_music_mode,
		"bgm_path": bgm_path,
		"bgm_exists": not bgm_path.is_empty() and ResourceLoader.exists(bgm_path),
		"sfx_pool_size": _sfx_pool.size(),
		"web_audio_unlock_attempted": _web_audio_unlock_attempted,
		"web_audio_unlock_input_count": _web_audio_unlock_input_count,
	}

func _publish_web_debug_state() -> void:
	if not OS.has_feature("web"):
		return
	var json := JSON.stringify(get_debug_state()).json_escape()
	JavaScriptBridge.eval("document.documentElement.dataset.%s=\"%s\";" % [WEB_AUDIO_DEBUG_DATASET_KEY, json], true)


func _is_headless_runtime() -> bool:
	return DisplayServer.get_name() == "headless"


func _get_sfx(sfx_name: String) -> AudioStream:
	var theme_manager = get_node_or_null("/root/ThemeManager")
	if theme_manager:
		return theme_manager.get_sfx(sfx_name)
	return null


func _get_free_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_pool:
		if not p.playing:
			return p
	# Pool exhausted: steal the oldest.
	return _sfx_pool[0]


func _bus_exists(bus_name: String) -> bool:
	return AudioServer.get_bus_index(bus_name) >= 0

func _ensure_canonical_audio_buses() -> void:
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)

func _ensure_bus(bus_name: String) -> void:
	if _bus_exists(bus_name):
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, BUS_MASTER)
