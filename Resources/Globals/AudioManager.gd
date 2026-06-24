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
	play_music()

	if has_node("/root/ThemeManager"):
		get_node("/root/ThemeManager").theme_changed.connect(_on_theme_changed)


func _on_theme_changed(_name: String, _config: ThemeConfig) -> void:
	pass


# Plays a SFX by name; no-ops if missing. `pitch_variation` (0..1) randomizes
# pitch_scale within ±variation around custom_pitch.
func play_sfx(sfx_name: String, pitch_variation: float = 0.0, custom_pitch: float = 1.0) -> void:
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
	player.play()


# Starts the looped music track. Set Loop in the import dock if the file doesn't loop.
func play_music() -> void:
	if _music_player.playing:
		return
	if not ResourceLoader.exists(MUSIC_PATH):
		return
	var stream := load(MUSIC_PATH) as AudioStream
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.play()


# Reads volumes (linear 0..1) from SaveManager and applies them to the buses.
func apply_saved_volumes() -> void:
	_set_bus_volume(BUS_MASTER, SaveManager.get_volume(BUS_MASTER, 1.0))
	_set_bus_volume(BUS_MUSIC, SaveManager.get_volume(BUS_MUSIC, 0.7))
	_set_bus_volume(BUS_SFX, SaveManager.get_volume(BUS_SFX, 1.0))


func set_bus_volume(bus_name: String, linear_value: float) -> void:
	linear_value = clamp(linear_value, 0.0, 1.0)
	_set_bus_volume(bus_name, linear_value)
	SaveManager.set_volume(bus_name, linear_value)


func get_bus_volume(bus_name: String) -> float:
	return SaveManager.get_volume(bus_name, 1.0)


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
