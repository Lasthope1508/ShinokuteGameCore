class_name BottomTimerDigits extends Control

var atlas_texture: Texture2D
var glyph_rects: Dictionary = {}
var time_text: String = "00:00"
var spacing_ratio: float = 0.035
var pixel_height_ratio: float = 0.9

func configure(texture: Texture2D, rects: Dictionary, spacing: float, height_ratio: float) -> void:
	atlas_texture = texture
	glyph_rects = rects.duplicate(true)
	spacing_ratio = max(0.0, spacing)
	pixel_height_ratio = clampf(height_ratio, 0.1, 1.0)
	queue_redraw()

func set_time_text(value: String) -> void:
	if time_text == value:
		return
	time_text = value
	queue_redraw()

func _draw() -> void:
	if atlas_texture == null or time_text.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return
	var glyphs := _get_draw_glyphs()
	if glyphs.is_empty():
		return
	var max_height := _get_max_glyph_height(glyphs)
	if max_height <= 0.0:
		return
	var spacing_px := size.y * spacing_ratio
	var scale := (size.y * pixel_height_ratio) / max_height
	var total_width := _get_total_width(glyphs, scale, spacing_px)
	if total_width > size.x:
		scale *= size.x / total_width
		spacing_px *= size.x / total_width
		total_width = _get_total_width(glyphs, scale, spacing_px)
	var cursor_x := (size.x - total_width) * 0.5
	for glyph in glyphs:
		var source := _to_rect2(glyph_rects.get(glyph, Vector4.ZERO))
		var draw_size := source.size * scale
		var draw_y := (size.y - draw_size.y) * 0.5
		draw_texture_rect_region(atlas_texture, Rect2(Vector2(cursor_x, draw_y), draw_size), source)
		cursor_x += draw_size.x + spacing_px

func _get_draw_glyphs() -> Array:
	var glyphs := []
	for index in range(time_text.length()):
		var glyph := time_text.substr(index, 1)
		if glyph_rects.has(glyph):
			glyphs.append(glyph)
	return glyphs

func _get_max_glyph_height(glyphs: Array) -> float:
	var max_height := 0.0
	for glyph in glyphs:
		var rect := _to_rect2(glyph_rects.get(glyph, Vector4.ZERO))
		max_height = max(max_height, rect.size.y)
	return max_height

func _get_total_width(glyphs: Array, scale: float, spacing_px: float) -> float:
	var total := 0.0
	for index in range(glyphs.size()):
		var rect := _to_rect2(glyph_rects.get(glyphs[index], Vector4.ZERO))
		total += rect.size.x * scale
		if index < glyphs.size() - 1:
			total += spacing_px
	return total

func _to_rect2(value) -> Rect2:
	if not (value is Vector4):
		return Rect2()
	var rect: Vector4 = value
	return Rect2(rect.x, rect.y, rect.z, rect.w)
