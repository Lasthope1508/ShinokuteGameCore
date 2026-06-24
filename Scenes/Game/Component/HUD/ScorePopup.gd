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
	
	var config = ThemeManager.get_popup_config("score")
	var outline_sz = config.get("outline_size", 16)
	var min_scale = config.get("min_scale", 0.9)
	var max_scale = config.get("max_scale", 1.6)
	var rise_amt = config.get("rise_amount", 60.0)
	var life = config.get("lifetime", 0.9)
	
	var active_theme = ThemeManager.get_active_theme()
	if active_theme:
		add_theme_color_override("font_color", active_theme.text_color)
		add_theme_color_override("font_outline_color", active_theme.accent_color.darkened(0.8))
		add_theme_constant_override("outline_size", outline_sz)
		
	pivot_offset = size * 0.5
	var base_scale: float = lerp(min_scale, max_scale, clamp(magnitude, 0.0, 1.0))
	scale = Vector2.ZERO
	modulate.a = 0.0

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.08)
	tw.tween_property(self, "scale", Vector2(base_scale, base_scale), 0.45) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", position.y - rise_amt, life)
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
	await get_tree().create_timer(life + 0.05).timeout
	queue_free()


# Match popup for line / quadrant clears. Elastic burst at screen center.
# Animates font_size directly to re-rasterize the glyph at each step — no
# upscale blur, no MSDF artifacts.
func play_match(amount: int, magnitude: float = 0.5) -> void:
	text = "+%d" % amount
	z_index = 100
	
	var config = ThemeManager.get_popup_config("match")
	var outline_sz = config.get("outline_size", 25)
	var min_font = config.get("min_font_size", 78)
	var max_font = config.get("max_font_size", 112)
	var offset_ratio = config.get("vertical_offset_ratio", 0.20)
	var life = config.get("lifetime", 1.30)
	
	# Dynamic alert color, distinct from placement popup.
	var active_theme = ThemeManager.get_active_theme()
	var main_color = active_theme.alert_color if active_theme else Color(0.95, 0.18, 0.12)
	add_theme_color_override("font_color", main_color)
	add_theme_color_override("font_outline_color", main_color.darkened(0.8))
	add_theme_constant_override("outline_size", outline_sz)
	# Sit ~1/5 of screen height above the vertical center.
	_vertical_offset_ratio = offset_ratio

	var peak_size: int = int(lerp(float(min_font), float(max_font), clamp(magnitude, 0.0, 1.0)))
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
	await get_tree().create_timer(life).timeout
	queue_free()


# "COMBO xN" popup revealed letter-by-letter, between the placement and
# match popups.
func play_combo(combo: int) -> void:
	z_index = 100
	var active_theme = ThemeManager.get_active_theme()
	var main_color = active_theme.accent_color if active_theme else Color(1.0, 0.78, 0.05)
	
	# Fetch configurations from SSOT
	var combo_config = ThemeManager.get_combo_config(combo)
	var combo_text = combo_config["text"]
	var font_sz = combo_config["font_size"]
	var outline_sz = combo_config["outline_size"]
	var scale_mult = combo_config["scale_multiplier"]
	
	add_theme_color_override("font_color", main_color)
	add_theme_color_override("font_outline_color", main_color.darkened(0.8))
	add_theme_constant_override("outline_size", outline_sz)
	add_theme_font_size_override("font_size", font_sz)
	
	horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_vertical_offset_ratio = 0.05

	var full_text: String = combo_text
	text = full_text
	await get_tree().process_frame
	var final_size: Vector2 = size
	custom_minimum_size = final_size
	text = ""
	modulate.a = 1.0
	
	pivot_offset = final_size * 0.5
	
	# Scale clamping to prevent screen overflow
	var p := get_parent()
	if p is Control:
		var ps: Vector2 = (p as Control).size
		var max_width = ps.x - 40.0 # 20px padding left/right
		if (final_size.x * scale_mult) > max_width:
			scale_mult = max_width / final_size.x
			
	scale = Vector2.ONE * scale_mult
	
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


# "STREAK xN" popup. Works similarly to play_combo but styled with alert_color
# and offset lower to prevent overlaps.
func play_streak(streak: int) -> void:
	z_index = 100
	var active_theme = ThemeManager.get_active_theme()
	var main_color = active_theme.alert_color if active_theme else Color(0.95, 0.18, 0.12)
	
	# Fetch configurations from SSOT
	var streak_config = ThemeManager.get_streak_config(streak)
	var streak_text = streak_config["text"]
	var font_sz = streak_config["font_size"]
	var outline_sz = streak_config["outline_size"]
	var scale_mult = streak_config["scale_multiplier"]
	
	add_theme_color_override("font_color", main_color)
	add_theme_color_override("font_outline_color", main_color.darkened(0.8))
	add_theme_constant_override("outline_size", outline_sz)
	add_theme_font_size_override("font_size", font_sz)
	
	horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_vertical_offset_ratio = -0.10 # Slightly lower than combo to avoid overlapping

	var full_text: String = streak_text
	text = full_text
	await get_tree().process_frame
	var final_size: Vector2 = size
	custom_minimum_size = final_size
	text = ""
	modulate.a = 1.0
	
	pivot_offset = final_size * 0.5
	
	# Scale clamping to prevent screen overflow
	var p := get_parent()
	if p is Control:
		var ps: Vector2 = (p as Control).size
		var max_width = ps.x - 40.0
		if (final_size.x * scale_mult) > max_width:
			scale_mult = max_width / final_size.x
			
	scale = Vector2.ONE * scale_mult
	
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
	await get_tree().create_timer(0.40).timeout
	queue_free()


# Awaitable announcement popup (e.g. "Out of Space"): elastic bump, hold, fade.
func play_announcement(label_text: String, color: Color = Color.TRANSPARENT) -> void:
	z_index = 100
	var config = ThemeManager.get_popup_config("announcement")
	var outline_sz = config.get("outline_size", 25)
	var font_sz = config.get("font_size", 80)
	var offset_ratio = config.get("vertical_offset_ratio", 0.05)
	var life = config.get("lifetime", 1.50)
	
	var active_theme = ThemeManager.get_active_theme()
	var main_color = color
	if main_color == Color.TRANSPARENT:
		main_color = active_theme.alert_color if active_theme else Color(0.95, 0.18, 0.12)
	add_theme_color_override("font_color", main_color)
	add_theme_color_override("font_outline_color", main_color.darkened(0.8))
	add_theme_constant_override("outline_size", outline_sz)
	add_theme_font_size_override("font_size", font_sz)
	text = label_text
	_vertical_offset_ratio = offset_ratio

	# Wait one frame so the Label measures itself before centering.
	await get_tree().process_frame
	_recenter_in_parent()
	pivot_offset = size * 0.5

	scale = Vector2.ZERO
	modulate.a = 0.0
	
	var target_scale = 1.0
	var p := get_parent()
	if p is Control:
		var ps: Vector2 = (p as Control).size
		var max_width = ps.x - 40.0
		if size.x > max_width:
			target_scale = max_width / size.x

	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.10)
	tw.tween_property(self, "scale", Vector2.ONE * target_scale, 0.55) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	# Wait for (life - fade_in - fade_out) time
	tw.chain().tween_interval(life - 0.10 - 0.30)
	tw.chain().tween_property(self, "modulate:a", 0.0, 0.30)
	# Safety timer (Safari iOS may drop tween-finished signals).
	await get_tree().create_timer(life + 0.05).timeout
	queue_free()


func _apply_font_size(value: int) -> void:
	add_theme_font_size_override("font_size", value)
	# Keep centered as the text grows.
	_recenter_in_parent()
	pivot_offset = size * 0.5
	
	# Scale clamping to prevent screen overflow
	var p := get_parent()
	if p is Control:
		var ps: Vector2 = (p as Control).size
		var max_width = ps.x - 40.0
		if size.x > max_width:
			scale = Vector2.ONE * (max_width / size.x)
		else:
			scale = Vector2.ONE


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
