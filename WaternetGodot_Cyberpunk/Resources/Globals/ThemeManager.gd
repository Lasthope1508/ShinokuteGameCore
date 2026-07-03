extends Node

const ThemeConfig = preload("res://Resources/Classes/ThemeConfig.gd")

const SAVE_KEY := "active_theme"
const DEFAULT_THEME := "cyberpunk_theme"

const THEME_PATHS := {
	"cyberpunk_theme": "res://Resources/Data/Themes/cyberpunk_theme.tres"
}

var active_theme_name: String = DEFAULT_THEME
var active_theme: ThemeConfig
var _sfx_cache: Dictionary = {}


signal theme_changed(new_theme_name: String, theme_config: ThemeConfig)

func _ready() -> void:
	load_theme("cyberpunk_theme")

func load_theme(theme_name: String) -> void:
	if not THEME_PATHS.has(theme_name):
		push_error("ThemeManager: theme is not registered in SSOT: %s" % theme_name)
		return
		
	active_theme_name = theme_name
	var path: String = THEME_PATHS[theme_name]
	
	if not ResourceLoader.exists(path):
		push_error("ThemeManager: theme resource missing: %s" % path)
		return
	active_theme = load(path) as ThemeConfig
	
	if active_theme == null:
		push_error("ThemeManager: theme resource failed to load: %s" % path)
		return
		
	# Apply stylebox and font overrides to the shared main theme resource
	var main_theme: Theme = load("res://Resources/Theme/main_theme.tres")
	if main_theme and active_theme:
		var states = ["normal", "hover", "pressed", "focus", "disabled"]
		for state in states:
			var sb = main_theme.get_stylebox(state, "Button")
			if not (sb is StyleBoxFlat):
				sb = StyleBoxFlat.new()
				main_theme.set_stylebox(state, "Button", sb)
			
			sb.set_corner_radius_all(active_theme.button_corner_radius)
			
			# Border width
			sb.border_width_left = active_theme.button_border_width
			sb.border_width_right = active_theme.button_border_width
			sb.border_width_top = active_theme.button_border_width
			sb.border_width_bottom = active_theme.button_border_width
			
			# Colors per state
			if state == "normal":
				sb.bg_color = active_theme.button_normal_bg
				sb.border_color = active_theme.button_border_color
			elif state == "hover" or state == "focus":
				sb.bg_color = active_theme.button_hover_bg
				sb.border_color = active_theme.accent_color
			elif state == "pressed":
				sb.bg_color = active_theme.button_pressed_bg
				sb.border_color = active_theme.accent_color
			elif state == "disabled":
				sb.bg_color = active_theme.button_normal_bg.darkened(0.5)
				sb.border_color = active_theme.button_border_color.darkened(0.5)
		
		var panel_sb = main_theme.get_stylebox("panel", "PanelContainer")
		if not (panel_sb is StyleBoxFlat):
			panel_sb = StyleBoxFlat.new()
			main_theme.set_stylebox("panel", "PanelContainer", panel_sb)
			
		panel_sb.bg_color = active_theme.panel_bg_color
		panel_sb.border_color = active_theme.panel_border_color
		var border_w = active_theme.popup_border_width
		panel_sb.border_width_left = border_w
		panel_sb.border_width_right = border_w
		panel_sb.border_width_top = border_w
		panel_sb.border_width_bottom = border_w
		panel_sb.set_corner_radius_all(active_theme.popup_corner_radius)
		
		# Set global Label colors in the main theme
		main_theme.set_color("font_color", "Label", active_theme.text_color)
		main_theme.set_color("font_outline_color", "Label", active_theme.accent_color.darkened(0.7))
		
		# Set global Button font colors in the main theme
		main_theme.set_color("font_color", "Button", active_theme.text_color)
		main_theme.set_color("font_outline_color", "Button", active_theme.accent_color.darkened(0.7))
			
		if active_theme.custom_font != null:
			main_theme.default_font = active_theme.custom_font
			
	if has_node("/root/SaveManager"):
		SaveManager.set_setting(SAVE_KEY, active_theme_name)
		
	theme_changed.emit(active_theme_name, active_theme)

func get_active_theme() -> ThemeConfig:
	return active_theme


func get_sfx(sfx_name: String) -> AudioStream:
	var cache_key = active_theme_name + "_" + sfx_name
	if _sfx_cache.has(cache_key):
		return _sfx_cache[cache_key]
	if active_theme == null:
		push_warning("ThemeManager: active theme missing for SFX: " + sfx_name)
		return null
	var path := active_theme.get_sfx_path(sfx_name)
	if path.is_empty():
		push_warning("ThemeManager: SFX event not mapped: " + sfx_name)
		return null
	if ResourceLoader.exists(path):
		var stream = load(path) as AudioStream
		_sfx_cache[cache_key] = stream
		return stream
	push_warning("ThemeManager: SFX mapped file not found: " + sfx_name + " -> " + path)
	return null

func get_sfx_volume_offset(sfx_name: String) -> float:
	if active_theme == null:
		return 0.0
	return active_theme.get_sfx_volume_offset(sfx_name)

func get_sfx_pitch_variation(sfx_name: String) -> float:
	if active_theme == null:
		return 0.0
	return active_theme.get_sfx_pitch_variation(sfx_name)
