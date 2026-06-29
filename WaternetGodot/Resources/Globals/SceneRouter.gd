## Handles scene transitions with a global fade. The fade overlay lives on a
## CanvasLayer above everything, so it survives scene swaps and produces a
## smooth fade-out → change → fade-in sequence.
extends Node

const FADE_SCENE_PATH := "res://Scenes/Common/FadeTransition.tscn"

@export var fade_duration: float = 0.4

var _fade: CanvasLayer
var _is_busy: bool = false


func _ready() -> void:
	# Defer so the SceneTree root is ready before attaching the overlay
	# (autoload _ready() runs too early on Web otherwise).
	call_deferred("_spawn_fade_layer")


# Replaces the current scene with a fade-out / fade-in transition.
func change_scene(scene_path: String) -> void:
	if _is_busy:
		return
	_is_busy = true
	await _internal_fade(1.0)
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("SceneRouter: change_scene_to_file failed (%d) for %s" % [err, scene_path])
	await _internal_fade(0.0)
	_is_busy = false


# Awaitable fade to opaque. No-op while a change_scene is in flight (otherwise
# the in-flight tween would die and leave _is_busy stuck).
func fade_out() -> void:
	if _is_busy:
		return
	await _internal_fade(1.0)


# Awaitable fade back to transparent. Same busy-guard as fade_out.
func fade_in() -> void:
	if _is_busy:
		return
	await _internal_fade(0.0)


# Internal fade used by change_scene — bypasses the _is_busy guard.
func _internal_fade(target_alpha: float) -> void:
	if _fade == null:
		await get_tree().process_frame
		if _fade == null:
			return
	await _fade.fade_to(target_alpha, fade_duration)


func _spawn_fade_layer() -> void:
	if not ResourceLoader.exists(FADE_SCENE_PATH):
		push_warning("SceneRouter: missing FadeTransition scene at %s" % FADE_SCENE_PATH)
		return
	var packed := load(FADE_SCENE_PATH) as PackedScene
	_fade = packed.instantiate() as CanvasLayer
	# Attach to root so the fade persists across scene changes.
	get_tree().root.add_child(_fade)
