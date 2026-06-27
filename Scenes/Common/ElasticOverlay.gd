## Reusable base scene for modal overlays with a "bump elastic" open/close
## animation. Concrete overlays (Settings, GameOver) are inherited scenes
## of this one, so their custom UI lives inside the Panel and inherits the
## entry/exit animation for free.
extends CanvasLayer

signal opened
signal closed

@export var open_duration: float = 0.45
@export var close_duration: float = 0.25
@export var dim_alpha: float = 0.55

@onready var dim: ColorRect = $Dim
@onready var panel: Control = $Panel

var _tween: Tween


func _ready() -> void:
	visible = false
	dim.modulate.a = 0.0
	panel.scale = Vector2.ZERO
	panel.pivot_offset = panel.size * 0.5


# Elastic open animation. Awaits a plain timer instead of tween.finished
# because Safari iOS occasionally drops the signal and would deadlock callers.
func open() -> void:
	visible = true
	# Recompute pivot in case the layout changed.
	panel.pivot_offset = panel.size * 0.5
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(dim, "modulate:a", dim_alpha, open_duration * 0.5)
	_tween.tween_property(panel, "scale", Vector2.ONE, open_duration) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(open_duration + 0.05).timeout
	opened.emit()


func close() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(dim, "modulate:a", 0.0, close_duration)
	_tween.tween_property(panel, "scale", Vector2.ZERO, close_duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(close_duration + 0.05).timeout
	visible = false
	closed.emit()
