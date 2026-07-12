extends Node

# Code adapted from KidsCanCode

const RuntimeThemeConfig := preload("res://Resources/QuantumRuntimeThemeConfig.gd")

var num_players = 12
var bus = "master"

var available = []  # The available players.
var queue = []  # The queue of sounds to play.
var event_paths := {}
var sfx_enabled := true
var bgm_enabled := true
var sfx_volume_db := -10.0
var bgm_volume_db := -14.0
var bgm_player: AudioStreamPlayer
var bgm_path := ""

func _ready():

	for i in num_players:
		var p = AudioStreamPlayer.new()
		add_child(p)
		
		available.append(p)
		
		p.volume_db = sfx_volume_db
		p.finished.connect(_on_stream_finished.bind(p))
		p.bus = bus
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGM"
	bgm_player.bus = bus
	bgm_player.volume_db = bgm_volume_db
	add_child(bgm_player)


func _on_stream_finished(stream): available.append(stream)

func _exit_tree() -> void:
	queue.clear()
	for child in get_children():
		if child is AudioStreamPlayer:
			var player := child as AudioStreamPlayer
			player.stop()
			player.stream = null
	if bgm_player != null:
		bgm_player.stream = null

func play(sound_path):
	if not sfx_enabled:
		return
	queue.append(sound_path)

func configure_events(paths: Dictionary) -> void:
	event_paths = paths.duplicate()

func configure_from_theme(theme_config: RuntimeThemeConfig) -> void:
	if theme_config == null:
		return
	configure_events(theme_config.audio_event_paths)
	sfx_volume_db = theme_config.sfx_volume_db
	bgm_volume_db = theme_config.bgm_volume_db
	for player in available:
		player.volume_db = sfx_volume_db
	if bgm_player != null:
		bgm_player.volume_db = bgm_volume_db
	if DisplayServer.get_name() != "headless":
		play_bgm(theme_config.bgm_track_path, bgm_volume_db)

func play_event(event_name: String) -> void:
	if not sfx_enabled:
		return
	if not event_paths.has(event_name):
		push_warning("Audio event not configured: %s" % event_name)
		return
	play(event_paths[event_name])

func set_sfx_enabled(value: bool) -> void:
	sfx_enabled = value
	if not sfx_enabled:
		queue.clear()
		for player in available:
			player.stop()

func is_sfx_enabled() -> bool:
	return sfx_enabled

func set_bgm_enabled(value: bool) -> void:
	bgm_enabled = value
	if bgm_player == null:
		return
	if not bgm_enabled:
		bgm_player.stop()
	elif not bgm_path.is_empty() and bgm_player.stream != null:
		bgm_player.play()

func is_bgm_enabled() -> bool:
	return bgm_enabled

func play_bgm(path: String, volume_db: float = -14.0) -> void:
	bgm_path = path
	if bgm_player == null or path.strip_edges().is_empty():
		return
	var stream = load(path)
	if stream == null:
		push_warning("BGM not found: %s" % path)
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	bgm_player.stream = stream
	bgm_player.volume_db = volume_db
	if bgm_enabled:
		bgm_player.play()

func _process(_delta):

	if not queue.is_empty() and not available.is_empty():
		
		available[0].stream = load(queue.pop_front())
		available[0].play()
		available[0].pitch_scale = randf_range(0.9, 1.1)
		
		available.pop_front()
