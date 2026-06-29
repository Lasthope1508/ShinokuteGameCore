## Fullscreen black ColorRect on its own CanvasLayer. Used by SceneRouter
## to fade between scenes.
extends CanvasLayer

@onready var rect: ColorRect = $Rect

var _tween: Tween


func _ready() -> void:
	# Sit above every other CanvasLayer.
	layer = 100
	rect.modulate.a = 0.0


# Awaitable alpha tween. Uses a plain timer because tween.finished is
# unreliable on Safari iOS and would deadlock SceneRouter mid-transition.
func fade_to(target_alpha: float, duration: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(rect, "modulate:a", target_alpha, duration)
	rect.mouse_filter = Control.MOUSE_FILTER_STOP if target_alpha > 0.05 else Control.MOUSE_FILTER_IGNORE
	await get_tree().create_timer(duration + 0.05).timeout
