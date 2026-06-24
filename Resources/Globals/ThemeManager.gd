extends Node

const SAVE_KEY := "active_theme"
const DEFAULT_THEME := "brick_theme"

const THEME_PATHS = {
	"fruit_theme": "res://Resources/Data/Themes/fruit_theme/theme_config.tres",
	"brick_theme": "res://Resources/Data/Themes/brick_theme/theme_config.tres",
}

const SKIN_SAVE_KEY := "active_skin"
var active_skin: String = "brick"

const GENERAL_SFX_MAP: Dictionary = {
	"pick": preload("res://Audio/SFX/sfx_pick.wav"),
	"drop": preload("res://Audio/SFX/sfx_drop.wav"),
	"invalid": preload("res://Audio/SFX/sfx_invalid.wav"),
	"clear": preload("res://Audio/SFX/sfx_clear.wav"),
	"combo": preload("res://Audio/SFX/sfx_combo.wav"),
	"button": preload("res://Audio/SFX/sfx_button.wav"),
	"populate_slot": preload("res://Audio/SFX/sfx_populateSlot.wav"),
	"popup": preload("res://Audio/SFX/sfx_popup.wav"),
	"levelup": preload("res://Audio/SFX/sfx_levelup.wav"),
	"gameover": preload("res://Audio/SFX/sfx_gameover.wav"),
	"timeout": preload("res://Audio/SFX/sfx_timeout.wav"),
	"fail": preload("res://Audio/SFX/sfx_fail.wav"),
}

var active_theme_name: String = DEFAULT_THEME
var active_theme: ThemeConfig

var shared_background_texture: Texture2D
var shared_milestone_backgrounds: Array[Texture2D] = []

signal theme_changed(new_theme_name: String, theme_config: ThemeConfig)

func _ready() -> void:
	# Load shared SSOT background assets from fruit theme configuration
	var fruit_config = load("res://Resources/Data/Themes/fruit_theme/theme_config.tres")
	if fruit_config:
		shared_background_texture = fruit_config.get("background_texture")
		shared_milestone_backgrounds = fruit_config.get("milestone_backgrounds")

	active_skin = SaveManager.get_setting(SKIN_SAVE_KEY, "brick")
	active_theme_name = SaveManager.get_setting(SAVE_KEY, DEFAULT_THEME)
	
	var target_theme = "fruit_theme" if active_skin == "fruits" else "brick_theme"
	if OS.has_feature("web"):
		var search = JavaScriptBridge.eval("window.location.search")
		if search and search is String and not search.is_empty():
			var params = search.substr(1).split("&")
			for param in params:
				var parts = param.split("=")
				if parts.size() == 2 and parts[0] == "theme":
					var web_theme = parts[1].strip_edges()
					if THEME_PATHS.has(web_theme):
						target_theme = web_theme
						active_skin = "fruits" if web_theme == "fruit_theme" else "brick"
						SaveManager.set_setting(SKIN_SAVE_KEY, active_skin)
						break
	load_theme(target_theme)

var _is_loading: bool = false

func load_theme(theme_name: String) -> void:
	if _is_loading:
		return
	_is_loading = true
	
	if not THEME_PATHS.has(theme_name):
		theme_name = DEFAULT_THEME
	active_theme_name = theme_name
	var path: String = THEME_PATHS[theme_name]
	if ResourceLoader.exists(path):
		active_theme = load(path) as ThemeConfig
	else:
		active_theme = load("res://Resources/Data/default_theme.tres") as ThemeConfig
	
	# Apply stylebox and font overrides to the shared main theme resource
	var main_theme: Theme = load("res://Resources/Theme/main_theme.tres")
	if main_theme and active_theme:
		var normal_sb = main_theme.get_stylebox("normal", "Button") as StyleBoxFlat
		if normal_sb:
			normal_sb.bg_color = active_theme.button_normal_bg
			normal_sb.border_color = active_theme.button_border_color
		
		var hover_sb = main_theme.get_stylebox("hover", "Button") as StyleBoxFlat
		if hover_sb:
			hover_sb.bg_color = active_theme.button_hover_bg
			hover_sb.border_color = active_theme.button_border_color
		
		var pressed_sb = main_theme.get_stylebox("pressed", "Button") as StyleBoxFlat
		if pressed_sb:
			pressed_sb.bg_color = active_theme.button_pressed_bg
			pressed_sb.border_color = active_theme.button_border_color
			
		var focus_sb = main_theme.get_stylebox("focus", "Button") as StyleBoxFlat
		if focus_sb:
			focus_sb.bg_color = active_theme.button_hover_bg
			focus_sb.border_color = active_theme.button_border_color
		
		var panel_sb = main_theme.get_stylebox("panel", "PanelContainer") as StyleBoxFlat
		if panel_sb:
			panel_sb.bg_color = active_theme.panel_bg_color
			panel_sb.border_color = active_theme.panel_border_color
			
		# Set global Label colors in the main theme
		main_theme.set_color("font_color", "Label", active_theme.text_color)
		main_theme.set_color("font_outline_color", "Label", active_theme.accent_color.darkened(0.7))
		
		# Set global Button font colors in the main theme
		main_theme.set_color("font_color", "Button", active_theme.text_color)
		main_theme.set_color("font_outline_color", "Button", active_theme.accent_color.darkened(0.7))
			
		if active_theme.custom_font != null:
			main_theme.default_font = active_theme.custom_font
		else:
			main_theme.default_font = load("res://Assets/Fonts/Alegreya-ExtraBold.ttf")
	
	SaveManager.set_setting(SAVE_KEY, active_theme_name)
	_is_loading = false
	theme_changed.emit(active_theme_name, active_theme)

func get_active_theme() -> ThemeConfig:
	if active_theme == null and not _is_loading:
		load_theme(active_theme_name)
	return active_theme

func find_color_index(color: Color) -> int:
	var theme = get_active_theme()
	if theme:
		for i in range(theme.piece_colors.size()):
			var c = theme.piece_colors[i]
			if abs(c.r - color.r) < 0.02 and abs(c.g - color.g) < 0.02 and abs(c.b - color.b) < 0.02:
				return i
	return -1

func get_block_texture(color_index: int) -> Texture2D:
	var theme = get_active_theme()
	if theme and theme.block_textures.size() > color_index:
		return theme.block_textures[color_index]
	return null

func get_block_color(color_index: int) -> Color:
	var theme = get_active_theme()
	if theme and theme.piece_colors.size() > color_index:
		return theme.piece_colors[color_index]
	return Color.WHITE

func get_random_piece_color() -> Color:
	var theme = get_active_theme()
	if theme and not theme.piece_colors.is_empty():
		return theme.piece_colors.pick_random()
	return Color.WHITE

func get_sfx(sfx_name: String) -> AudioStream:
	if GENERAL_SFX_MAP.has(sfx_name):
		return GENERAL_SFX_MAP[sfx_name]
	return null

func get_active_skin() -> String:
	return active_skin

func set_active_skin(skin_name: String) -> void:
	if skin_name == "brick" or skin_name == "fruits":
		active_skin = skin_name
		SaveManager.set_setting(SKIN_SAVE_KEY, active_skin)
		var target_theme = "fruit_theme" if skin_name == "fruits" else "brick_theme"
		load_theme(target_theme)


# Single Source of Truth (SSOT) for Combo & Streak VFX and Pitch Scaling
const BRICK_COMBO_CONFIGS: Dictionary = {
	2: {
		"text": "DOUBLE CLEAR!",
		"font_size": 52,
		"outline_size": 12,
		"scale_multiplier": 1.0,
		"shake_intensity": 1.0,
		"sfx_pitch": 1.25
	},
	3: {
		"text": "TRIPLE CLEAR!",
		"font_size": 56,
		"outline_size": 14,
		"scale_multiplier": 1.08,
		"shake_intensity": 1.3,
		"sfx_pitch": 1.50
	},
	4: {
		"text": "MEGA COMBO!",
		"font_size": 60,
		"outline_size": 16,
		"scale_multiplier": 1.15,
		"shake_intensity": 1.6,
		"sfx_pitch": 1.68
	},
	5: {
		"text": "SUPER COMBO!",
		"font_size": 64,
		"outline_size": 18,
		"scale_multiplier": 1.22,
		"shake_intensity": 2.0,
		"sfx_pitch": 2.00
	},
	6: {
		"text": "HYPER COMBO!",
		"font_size": 68,
		"outline_size": 20,
		"scale_multiplier": 1.3,
		"shake_intensity": 2.4,
		"sfx_pitch": 2.50
	},
	7: {
		"text": "LEGENDARY COMBO!",
		"font_size": 72,
		"outline_size": 22,
		"scale_multiplier": 1.38,
		"shake_intensity": 2.8,
		"sfx_pitch": 3.00
	}
}

const FRUIT_COMBO_CONFIGS: Dictionary = {
	2: {
		"text": "JUICY SPLASH!",
		"font_size": 52,
		"outline_size": 12,
		"scale_multiplier": 1.0,
		"shake_intensity": 1.0,
		"sfx_pitch": 1.25
	},
	3: {
		"text": "FRUIT SALAD!",
		"font_size": 56,
		"outline_size": 14,
		"scale_multiplier": 1.08,
		"shake_intensity": 1.3,
		"sfx_pitch": 1.50
	},
	4: {
		"text": "SWEET FRENZY!",
		"font_size": 60,
		"outline_size": 16,
		"scale_multiplier": 1.15,
		"shake_intensity": 1.6,
		"sfx_pitch": 1.68
	},
	5: {
		"text": "DELICIOUS BLAST!",
		"font_size": 64,
		"outline_size": 18,
		"scale_multiplier": 1.22,
		"shake_intensity": 2.0,
		"sfx_pitch": 2.00
	},
	6: {
		"text": "MEGA HARVEST!",
		"font_size": 68,
		"outline_size": 20,
		"scale_multiplier": 1.3,
		"shake_intensity": 2.4,
		"sfx_pitch": 2.50
	},
	7: {
		"text": "FRUIT PARADISE!",
		"font_size": 72,
		"outline_size": 22,
		"scale_multiplier": 1.38,
		"shake_intensity": 2.8,
		"sfx_pitch": 3.00
	}
}

const STREAK_CONFIGS: Dictionary = {
	2: {
		"text": "STREAK x2!",
		"font_size": 52,
		"outline_size": 12,
		"scale_multiplier": 1.0,
	},
	3: {
		"text": "STREAK x3!",
		"font_size": 56,
		"outline_size": 14,
		"scale_multiplier": 1.08,
	},
	4: {
		"text": "STREAK x4!",
		"font_size": 60,
		"outline_size": 16,
		"scale_multiplier": 1.15,
	},
	5: {
		"text": "STREAK x5!",
		"font_size": 64,
		"outline_size": 18,
		"scale_multiplier": 1.22,
	},
	6: {
		"text": "STREAK x6!",
		"font_size": 68,
		"outline_size": 20,
		"scale_multiplier": 1.3,
	},
	7: {
		"text": "STREAK x7!",
		"font_size": 72,
		"outline_size": 22,
		"scale_multiplier": 1.38,
	}
}

# Diatonic Major Scale semitones for streak pitch calculation
const STREAK_DIATONIC_STEPS: Array[int] = [0, 2, 4, 5, 7, 9, 11]
const MAX_STREAK_PITCH: float = 3.0

const POPUP_CONFIGS: Dictionary = {
	"score": {
		"outline_size": 16,
		"min_scale": 0.9,
		"max_scale": 1.6,
		"rise_amount": 60.0,
		"lifetime": 0.9
	},
	"match": {
		"outline_size": 25,
		"min_font_size": 78,
		"max_font_size": 112,
		"vertical_offset_ratio": 0.20,
		"lifetime": 1.30
	},
	"announcement": {
		"outline_size": 25,
		"font_size": 80,
		"vertical_offset_ratio": 0.05,
		"lifetime": 1.50
	}
}


func get_popup_config(type: String) -> Dictionary:
	if POPUP_CONFIGS.has(type):
		return POPUP_CONFIGS[type]
	return {}



func get_combo_config(combo_value: int) -> Dictionary:
	var configs = FRUIT_COMBO_CONFIGS if active_skin == "fruits" else BRICK_COMBO_CONFIGS
	if configs.has(combo_value):
		return configs[combo_value]
		
	var max_key = configs.keys().max()
	var base = configs[max_key].duplicate()
	if active_skin == "fruits":
		base["text"] = "FRUIT GODLIKE x%d!" % combo_value
	else:
		base["text"] = "GODLIKE COMBO x%d!" % combo_value
	base["font_size"] = min(96, base["font_size"] + (combo_value - max_key) * 5)
	base["outline_size"] = min(28, base["outline_size"] + (combo_value - max_key) * 1)
	base["scale_multiplier"] = min(1.6, base["scale_multiplier"] + (combo_value - max_key) * 0.08)
	base["shake_intensity"] = min(4.0, base["shake_intensity"] + (combo_value - max_key) * 0.3)
	return base


func get_streak_config(streak_value: int) -> Dictionary:
	if STREAK_CONFIGS.has(streak_value):
		return STREAK_CONFIGS[streak_value]
		
	var max_key = STREAK_CONFIGS.keys().max()
	var base = STREAK_CONFIGS[max_key].duplicate()
	base["text"] = "STREAK x%d!" % streak_value
	base["font_size"] = min(96, base["font_size"] + (streak_value - max_key) * 5)
	base["outline_size"] = min(28, base["outline_size"] + (streak_value - max_key) * 1)
	base["scale_multiplier"] = min(1.6, base["scale_multiplier"] + (streak_value - max_key) * 0.08)
	return base


func get_streak_pitch(streak_val: int) -> float:
	if streak_val <= 0:
		return 1.0
	var index = streak_val - 1
	var semitones = 0
	if index < STREAK_DIATONIC_STEPS.size():
		semitones = STREAK_DIATONIC_STEPS[index]
	else:
		var octaves = index / STREAK_DIATONIC_STEPS.size()
		var remainder = index % STREAK_DIATONIC_STEPS.size()
		semitones = STREAK_DIATONIC_STEPS[remainder] + octaves * 12
	return min(MAX_STREAK_PITCH, pow(2.0, semitones / 12.0))

