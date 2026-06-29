## Centralized audio playback. One AudioStreamPlayer for music plus a small
## pool of players for SFX so multiple sounds can overlap. Stream resources
## are referenced by name and loaded lazily — leave a slot empty (null) until
## the matching .ogg is added under Assets/Audio/.
extends Node

const SFX_POOL_SIZE: int = 8

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"

const MUSIC_PATH := "res://Audio/Music/music_loop.ogg"

var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC if _bus_exists(BUS_MUSIC) else BUS_MASTER
	add_child(_music_player)

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX if _bus_exists(BUS_SFX) else BUS_MASTER
		add_child(p)
		_sfx_pool.append(p)

	apply_saved_volumes()

	if has_node("/root/ThemeManager"):
		get_node("/root/ThemeManager").theme_changed.connect(_on_theme_changed)


func _on_theme_changed(_name: String, _config: Variant) -> void:
	if _music_player and _music_player.playing and _current_music_mode != "":
		# Smoothly transition to the new theme's BGM track
		var path = _get_music_path(_current_music_mode)
		_transition_to_music(path)



# Centralized base volume offsets (in dB) for specific SFX to achieve a balanced audio mix.
const SFX_VOLUME_OFFSETS := {
	"clear": -8.0,
	"combo": -8.0,
	"popup": -3.0,
	"drop": -2.0,
	"pick": -1.0,
	"button": -2.0,
	"invalid": -4.0,
}

# Plays a SFX by name; no-ops if missing. `pitch_variation` (0..1) randomizes
# pitch_scale within ±variation around custom_pitch. `volume_offset_db` adds runtime db adjustments.
func play_sfx(sfx_name: String, pitch_variation: float = 0.0, custom_pitch: float = 1.0, volume_offset_db: float = 0.0) -> void:
	var stream := _get_sfx(sfx_name)
	if stream == null:
		return
	var player := _get_free_sfx_player()
	if player == null:
		return
	player.stream = stream
	if pitch_variation > 0.0:
		var v: float = clamp(pitch_variation, 0.0, 0.95)
		player.pitch_scale = custom_pitch + randf_range(-v, v)
	else:
		player.pitch_scale = custom_pitch
		
	# Apply central volume balance adjustments
	var base_offset = SFX_VOLUME_OFFSETS.get(sfx_name, 0.0)
	player.volume_db = base_offset + volume_offset_db
	player.play()


func _enable_looping(stream: AudioStream) -> void:
	if stream == null:
		return
	if stream is AudioStreamWAV:
		stream.loop_mode = 1 # LOOP_FORWARD
	elif "loop" in stream:
		stream.set("loop", true)

# Helper to resolve BGM path dynamically based on the active theme
func _get_music_path(mode: String) -> String:
	var file_name = "Gameplay.ogg"
	# Try theme-specific folder first
	var theme_name = "default"
	if has_node("/root/ThemeManager"):
		theme_name = get_node("/root/ThemeManager").active_theme_name
		
	var path = "res://Audio/Music/" + theme_name + "/" + file_name
	if not ResourceLoader.exists(path):
		# Fallback to root music directory
		path = "res://Audio/Music/" + file_name
	return path


# Starts the looped music track. Set Loop in the import dock if the file doesn't loop.
func play_music() -> void:
	if _music_player.playing:
		return
	var path = _get_music_path("gameplay")
	if not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	_enable_looping(stream)
	_music_player.stream = stream
	_music_player.volume_db = 0.0
	_music_player.play()
	_current_music_mode = "gameplay"


func stop_music() -> void:
	if _music_player.playing:
		_music_player.stop()
	_current_music_mode = ""


var _current_music_mode: String = "" # Always "gameplay" for 1 single BGM loop

func set_music_mode(mode: String) -> void:
	# Disabled: 1 single BGM loop only to avoid unnecessary transitions
	return



func _transition_to_music(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: music file not found at " + path)
		return
		
	var new_stream = load(path) as AudioStream
	if new_stream == null:
		return
		
	_enable_looping(new_stream)
	
	if not _music_player.playing:
		_music_player.stream = new_stream
		_music_player.volume_db = 0.0
		_music_player.play()
		return
		
	var tw = create_tween()
	tw.tween_property(_music_player, "volume_db", -80.0, 0.8)
	tw.tween_callback(func():
		_music_player.stream = new_stream
		_music_player.play()
	)
	tw.tween_property(_music_player, "volume_db", 0.0, 0.8)

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
	return get_bus_volume(BUS_MASTER) <= 0.0001

func toggle_master_mute() -> bool:
	if is_master_muted():
		set_bus_volume(BUS_MASTER, 1.0)
		return false
	else:
		set_bus_volume(BUS_MASTER, 0.0)
		return true




# Reads volumes (linear 0..1) from SaveManager and applies them to the buses.
func apply_saved_volumes() -> void:
	_set_bus_volume(BUS_MASTER, SaveManager.get_volume(BUS_MASTER, 1.0))
	_set_bus_volume(BUS_MUSIC, SaveManager.get_volume(BUS_MUSIC, 0.7))
	_set_bus_volume(BUS_SFX, SaveManager.get_volume(BUS_SFX, 0.65))


func set_bus_volume(bus_name: String, linear_value: float) -> void:
	linear_value = clamp(linear_value, 0.0, 1.0)
	_set_bus_volume(bus_name, linear_value)
	SaveManager.set_volume(bus_name, linear_value)


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
