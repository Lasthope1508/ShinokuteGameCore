extends Node

# Code adapted from KidsCanCode

var num_players = 12
var bus = "master"

var available = []  # The available players.
var queue = []  # The queue of sounds to play.
var event_paths := {}

func _ready():

	for i in num_players:
		var p = AudioStreamPlayer.new()
		add_child(p)
		
		available.append(p)
		
		p.volume_db = -10
		p.finished.connect(_on_stream_finished.bind(p))
		p.bus = bus


func _on_stream_finished(stream): available.append(stream)

func play(sound_path): queue.append(sound_path)

func configure_events(paths: Dictionary) -> void:
	event_paths = paths.duplicate()

func play_event(event_name: String) -> void:
	if not event_paths.has(event_name):
		push_warning("Audio event not configured: %s" % event_name)
		return
	play(event_paths[event_name])

func _process(_delta):

	if not queue.is_empty() and not available.is_empty():
		
		available[0].stream = load(queue.pop_front())
		available[0].play()
		available[0].pitch_scale = randf_range(0.9, 1.1)
		
		available.pop_front()
