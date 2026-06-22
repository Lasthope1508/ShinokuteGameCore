## Floating "+N" label spawned when the player scores. Self-frees once the
## tween finishes. Visual emphasis scales with the magnitude of the award.
class_name ScorePopup extends Label

@export var rise_amount: float = 60.0
@export var lifetime: float = 0.9

# Lifts the popup above parent's vertical center (used by _recenter_in_parent).
var _vertical_offset_ratio: float = 0.0


# Animates the popup. magnitude in 0..1 controls visual emphasis.
func play(amount: int, magnitude: float = 0.3) -> void:
	text = "+%d" % amount
	# Above grid blocks raised to z_index = 10 during clears.
	z_index = 100
	pivot_offset = size * 0.5
	var base_scale: float = lerp(0.9, 1.6, clamp(magnitude, 0.0, 1.0))
	scale = Vector2.ZERO
	modulate.a = 0.0

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.08)
	tw.tween_property(self, "scale", Vector2(base_scale, base_scale), 0.45) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", position.y - rise_amount, lifetime)
	tw.chain().tween_property(self, "modulate:a", 0.0, 0.25)
	if magnitude >= 0.6:
		# Horizontal shake for big scores.
		var start_x: float = position.x
		var shake := create_tween().set_loops(4)
		shake.tween_property(self, "position:x", start_x - 6.0, 0.04)
		shake.tween_property(self, "position:x", start_x + 6.0, 0.04)
		shake.tween_property(self, "position:x", start_x, 0.04)
	# Plain timer instead of tw.finished — Safari iOS drops the signal
	# occasionally, which would leave popups hanging on the screen forever.
	await get_tree().create_timer(lifetime + 0.05).timeout
	queue_free()


# Match popup for line / quadrant clears. Elastic burst at screen center.
# Animates font_size directly to re-rasterize the glyph at each step — no
# upscale blur, no MSDF artifacts.
func play_match(amount: int, magnitude: float = 0.5) -> void:
	text = "+%d" % amount
	z_index = 100
	# Red, distinct from the yellow placement popup.
	add_theme_color_override("font_color", Color(0.95, 0.18, 0.12))
	add_theme_color_override("font_outline_color", Color(0.20, 0.02, 0.02))
	add_theme_constant_override("outline_size", 25)
	# Sit ~1/5 of screen height above the vertical center.
	_vertical_offset_ratio = 0.20

	var peak_size: int = int(lerp(78.0, 112.0, clamp(magnitude, 0.0, 1.0)))
	var settled_size: int = int(peak_size * 0.92)

	add_theme_font_size_override("font_size", 1)
	modulate.a = 0.0

	# Wait a frame so the Label re-measures with the override before centering.
	await get_tree().process_frame
	_recenter_in_parent()
	pivot_offset = size * 0.5

	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.08)
	# Elastic burst: font_size 1 → peak with overshoot.
	tw.tween_method(_apply_font_size, 1, peak_size, 0.55) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	# Settle slightly under peak so the readout looks stable.
	tw.chain().tween_method(_apply_font_size, peak_size, settled_size, 0.18) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.chain().tween_interval(0.20)
	tw.chain().tween_property(self, "modulate:a", 0.0, 0.30)
	# Plain timer (Safari iOS drops tween-finished signals occasionally).
	await get_tree().create_timer(1.30).timeout
	queue_free()


# "COMBO xN" popup revealed letter-by-letter, between the placement and
# match popups.
func play_combo(combo: int) -> void:
	z_index = 100
	# Amber, distinct from red match / yellow placement popups.
	add_theme_color_override("font_color", Color(1.0, 0.78, 0.05))
	add_theme_color_override("font_outline_color", Color(0.20, 0.06, 0.0))
	add_theme_constant_override("outline_size", 25)
	add_theme_font_size_override("font_size", 88)
	# Anchor so the FINAL text ends up centered while letters grow rightward.
	horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_vertical_offset_ratio = 0.05

	var full_text: String = "COMBO x%d" % combo
	# Measure full text first, then reveal one char at a time.
	text = full_text
	await get_tree().process_frame
	var final_size: Vector2 = size
	# Lock the rect so the Label doesn't resize as letters are added.
	custom_minimum_size = final_size
	text = ""
	modulate.a = 1.0
	var p := get_parent()
	if p is Control:
		var ps: Vector2 = (p as Control).size
		position = Vector2(
			(ps.x - final_size.x) * 0.5,
			(ps.y - final_size.y) * 0.5 - ps.y * _vertical_offset_ratio,
		)

	var per_letter: float = 0.05
	for i in range(full_text.length()):
		text = full_text.substr(0, i + 1)
		await get_tree().create_timer(per_letter).timeout

	await get_tree().create_timer(0.35).timeout
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.35)
	# Plain timer (see Safari iOS note in play_match).
	await get_tree().create_timer(0.40).timeout
	queue_free()


# Awaitable announcement popup (e.g. "Out of Space"): elastic bump, hold, fade.
func play_announcement(label_text: String, color: Color = Color(0.95, 0.18, 0.12)) -> void:
	z_index = 100
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_outline_color", Color(0.20, 0.02, 0.02))
	add_theme_constant_override("outline_size", 25)
	add_theme_font_size_override("font_size", 80)
	text = label_text
	_vertical_offset_ratio = 0.05

	# Wait one frame so the Label measures itself before centering.
	await get_tree().process_frame
	_recenter_in_parent()
	pivot_offset = size * 0.5

	scale = Vector2.ZERO
	modulate.a = 0.0

	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.10)
	tw.tween_property(self, "scale", Vector2.ONE, 0.55) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(0.6)
	tw.chain().tween_property(self, "modulate:a", 0.0, 0.30)
	# Safety timer (Safari iOS may drop tween-finished signals).
	await get_tree().create_timer(0.55 + 0.6 + 0.30 + 0.05).timeout
	queue_free()


func _apply_font_size(value: int) -> void:
	add_theme_font_size_override("font_size", value)
	# Keep centered as the text grows.
	_recenter_in_parent()
	pivot_offset = size * 0.5


# Centers in the parent Control. `_vertical_offset_ratio` shifts upward by
# that fraction of parent height (0 = exact center).
func _recenter_in_parent() -> void:
	var p := get_parent()
	if p is Control and (p as Control).size.length_squared() > 0:
		var ps: Vector2 = (p as Control).size
		position = Vector2(
			(ps.x - size.x) * 0.5,
			(ps.y - size.y) * 0.5 - ps.y * _vertical_offset_ratio,
		)
