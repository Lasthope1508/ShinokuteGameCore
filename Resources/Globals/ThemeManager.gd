extends Node

const SAVE_KEY := "active_theme"
const DEFAULT_THEME := "brick_theme"

const THEME_PATHS = {
	"fruit_theme": "res://Resources/Data/Themes/fruit_theme/theme_config.tres",
	"brick_theme": "res://Resources/Data/Themes/brick_theme/theme_config.tres",
	"neon_theme": "res://Resources/Data/Themes/neon_theme/theme_config.tres",
	"gold_theme": "res://Resources/Data/Themes/gold_theme/theme_config.tres",
	"soul_theme": "res://Resources/Data/Themes/soul_theme/theme_config.tres",
	"candy_theme": "res://Resources/Data/Themes/candy_theme/theme_config.tres",
	"ice_theme": "res://Resources/Data/Themes/ice_theme/theme_config.tres",
	"lava_theme": "res://Resources/Data/Themes/lava_theme/theme_config.tres",
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
	# Load greeting_bg.png directly from disk to bypass Godot import caching
	if FileAccess.file_exists("res://Assets/Sprites/greeting_bg.png"):
		var img = Image.load_from_file("res://Assets/Sprites/greeting_bg.png")
		if img:
			shared_background_texture = ImageTexture.create_from_image(img)
	if not shared_background_texture:
		shared_background_texture = preload("res://Assets/Sprites/greeting_bg.png")
		
	# Load shared SSOT background assets from fruit theme configuration
	var fruit_config = load("res://Resources/Data/Themes/fruit_theme/theme_config.tres")
	if fruit_config:
		var raw_bgs = fruit_config.get("milestone_backgrounds")
		shared_milestone_backgrounds.clear()
		for bg in raw_bgs:
			if bg and bg.resource_path.begins_with("res://"):
				var path = bg.resource_path
				if FileAccess.file_exists(path):
					var img = Image.load_from_file(path)
					if img:
						shared_milestone_backgrounds.append(ImageTexture.create_from_image(img))
						continue
			shared_milestone_backgrounds.append(bg)

	active_skin = "brick"
	active_theme_name = DEFAULT_THEME
	var target_theme = "brick_theme"
	if OS.has_feature("web"):
		var search = JavaScriptBridge.eval("window.location.search")
		if search and search is String and not search.is_empty():
			var params = search.substr(1).split("&")
			for param in params:
				var parts = param.split("=")
				if parts.size() == 2 and parts[0] == "theme":
					var web_theme = parts[1].strip_edges()
					if THEME_PATHS.has(web_theme) and web_theme != "fruit_theme":
						target_theme = web_theme
						active_skin = "brick"
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
		# Update corner radii and border widths for all button states
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			var sb = main_theme.get_stylebox(state, "Button") as StyleBoxFlat
			if sb:
				sb.set_corner_radius_all(active_theme.button_corner_radius)
				sb.set_border_width_all(active_theme.button_border_width)
				
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

func get_random_piece_color_for_score(score: int) -> Color:
	# Ignore score to unlock all colors right from the start (多样 colors from start)
	return get_random_piece_color()


# Single Source of Truth (SSOT) for Elemental Chains mapping
enum ElementChainType { FIRE, ICE, EARTH, LIGHTNING, SOUL }

const ELEMENT_COLORS: Dictionary = {
	ElementChainType.FIRE: Color(0.95, 0.2, 0.2),       # Red
	ElementChainType.ICE: Color(0.0, 0.55, 1.0),        # Blue
	ElementChainType.EARTH: Color(0.1, 0.8, 0.2),      # Green
	ElementChainType.LIGHTNING: Color(1.0, 0.85, 0.0),  # Yellow
	ElementChainType.SOUL: Color(0.65, 0.1, 0.95)       # Purple
}

const ELEMENTAL_VFX_CONFIGS: Dictionary = {
	ElementChainType.FIRE: {
		"color": Color(1.0, 0.3, 0.15),
		"video_path": "",
		"extra_scene_path": "res://effects/2d_explosion/source/explosion.tscn",
		"extra_scene_scale": Vector2(0.4, 0.4),
		"extra_scene_speed_scale": 4.0,
		"particles_texture": "res://addons/kenney_particle_pack/spark_01.png",
		"particles_amount": 26,
		"particles_explosiveness": 0.92,
		"particles_lifetime": 0.55,
		"particles_spread": 180.0,
		"particles_gravity": Vector2(0, 320),
		"particles_velocity_min": 160.0,
		"particles_velocity_max": 320.0,
		"particles_scale_min": 0.05,
		"particles_scale_max": 0.12,
		"particles_modulate_multiplier": 1.3,
		
		"pop_texture": "res://addons/kenney_particle_pack/flame_05.png",
		"pop_gravity": Vector2(0, -60),
		"pop_scale_min": 0.03,
		"pop_scale_max": 0.07,
		"pop_velocity": 80.0
	},
	ElementChainType.ICE: {
		"color": Color(0.2, 0.7, 1.0),
		"video_path": "",
		"ring_texture": "res://addons/kenney_particle_pack/magic_03.png",
		"ring_modulate": Color(0.25, 0.8, 1.0, 1.4),
		"ring_scale_target": Vector2(1.8, 1.8),
		"ring_tween_duration": 0.25,
		"particles_texture": "res://addons/kenney_particle_pack/spark_02.png",
		"particles_amount": 18,
		"particles_explosiveness": 0.92,
		"particles_lifetime": 0.58,
		"particles_spread": 180.0,
		"particles_gravity": Vector2(0, 150),
		"particles_velocity_min": 140.0,
		"particles_velocity_max": 240.0,
		"particles_scale_min": 0.05,
		"particles_scale_max": 0.12,
		"particles_damping_min": 100.0,
		"particles_damping_max": 150.0,
		"particles_modulate": Color(0.4, 0.9, 1.0, 1.5),
		
		"pop_texture": "res://addons/kenney_particle_pack/spark_02.png",
		"pop_gravity": Vector2(0, 100),
		"pop_scale_min": 0.03,
		"pop_scale_max": 0.06,
		"pop_velocity": 80.0
	},
	ElementChainType.EARTH: {
		"color": Color(0.1, 0.8, 0.2),
		"video_path": "",
		"wave_texture": "res://addons/kenney_particle_pack/dirt_02.png",
		"wave_modulate": Color(0.2, 0.62, 0.32, 0.8),
		"wave_scale_target": Vector2(1.5, 1.5),
		"wave_tween_duration": 0.32,
		"particles_texture": "res://addons/kenney_particle_pack/dirt_01.png",
		"particles_amount": 16,
		"particles_explosiveness": 0.88,
		"particles_lifetime": 0.65,
		"particles_spread": 180.0,
		"particles_gravity": Vector2(0, 240),
		"particles_velocity_min": 100.0,
		"particles_velocity_max": 200.0,
		"particles_scale_min": 0.04,
		"particles_scale_max": 0.1,
		"particles_angular_velocity_min": -180.0,
		"particles_angular_velocity_max": 180.0,
		"particles_damping_min": 50.0,
		"particles_damping_max": 100.0,
		"particles_modulate": Color(0.3, 0.8, 0.4, 1.4),
		
		"pop_texture": "res://addons/kenney_particle_pack/spark_01.png",
		"pop_gravity": Vector2(0, 150),
		"pop_scale_min": 0.02,
		"pop_scale_max": 0.05,
		"pop_velocity": 80.0
	},
	ElementChainType.LIGHTNING: {
		"color": Color(1.0, 0.9, 0.25),
		"video_path": "",
		"particles_texture": "res://addons/kenney_particle_pack/spark_05.png",
		"particles_amount": 14,
		"particles_explosiveness": 0.9,
		"particles_lifetime": 0.5,
		"particles_spread": 180.0,
		"particles_gravity": Vector2(0, 100),
		"particles_velocity_min": 80.0,
		"particles_velocity_max": 160.0,
		"particles_scale_min": 0.03,
		"particles_scale_max": 0.07,
		"particles_modulate": Color(1.0, 0.9, 0.2, 1.5),
		
		"lightning_width": 4.5,
		"lightning_color": Color.WHITE,
		"glow_width": 14.0,
		"glow_color": Color(1.0, 0.85, 0.1, 0.45),
		"lightning_start_x_range": 40.0,
		"lightning_start_y": -240.0,
		"lightning_segments": 5,
		"lightning_perp_range": 18.0,
		"flash_1_duration": 0.06,
		"flash_2_start_x_range": 30.0,
		"flash_2_perp_range": 15.0,
		"flash_2_width": 3.5,
		"flash_2_duration": 0.1,
		
		"pop_texture": "res://addons/kenney_particle_pack/spark_05.png",
		"pop_gravity": Vector2(0, 150),
		"pop_scale_min": 0.02,
		"pop_scale_max": 0.05,
		"pop_velocity": 120.0
	},
	ElementChainType.SOUL: {
		"color": Color(0.65, 0.1, 0.95),
		"video_path": "",
		"extra_scene_path": "res://effects/2d_vortex/source/vortex.tscn",
		"extra_scene_pivot": Vector2(136, 136),
		"extra_scene_modulate": Color(0.75, 0.15, 0.9, 1.3),
		"vortex_scale_1": Vector2(0.35, 0.35),
		"vortex_dur_1": 0.15,
		"vortex_interval": 0.18,
		"vortex_scale_2": Vector2(0.5, 0.5),
		"vortex_dur_2": 0.22,
		"particles_texture": "res://addons/kenney_particle_pack/star_05.png",
		"particles_amount": 14,
		"particles_explosiveness": 0.55,
		"particles_lifetime": 0.75,
		"particles_direction": Vector2(0, -1),
		"particles_spread": 35.0,
		"particles_gravity": Vector2(0, -50),
		"particles_velocity_min": 60.0,
		"particles_velocity_max": 120.0,
		"particles_scale_min": 0.04,
		"particles_scale_max": 0.09,
		"particles_modulate": Color(0.85, 0.2, 0.95, 1.5),
		
		"pop_texture": "res://addons/kenney_particle_pack/spark_01.png",
		"pop_gravity": Vector2(0, 150),
		"pop_scale_min": 0.02,
		"pop_scale_max": 0.05,
		"pop_velocity": 80.0
	}
}

const DEFAULT_VFX_CONFIG: Dictionary = {
	"flash_texture": "res://addons/kenney_particle_pack/flare_01.png",
	"flash_scale_1": Vector2(2.4, 2.4),
	"flash_dur_1": 0.07,
	"flash_scale_2": Vector2.ZERO,
	"flash_dur_2": 0.09,
	
	"ring_texture": "res://addons/kenney_particle_pack/circle_02.png",
	"ring_scale": Vector2(0.3, 0.3),
	"ring_scale_target": Vector2(4.5, 4.5),
	"ring_dur": 0.28,
	
	"particles_texture": "res://addons/kenney_particle_pack/spark_01.png",
	"particles_amount": 26,
	"particles_explosiveness": 0.92,
	"particles_lifetime": 0.55,
	"particles_spread": 180.0,
	"particles_gravity": Vector2(0, 320),
	"particles_velocity_min": 160.0,
	"particles_velocity_max": 320.0,
	"particles_scale_min": 0.05,
	"particles_scale_max": 0.12,
	
	"pop_texture": "res://addons/kenney_particle_pack/spark_01.png",
	"pop_gravity": Vector2(0, 150),
	"pop_scale_min": 0.02,
	"pop_scale_max": 0.05,
	"pop_velocity": 80.0
}

func get_element_vfx_config(element_type: int) -> Dictionary:
	if ELEMENTAL_VFX_CONFIGS.has(element_type):
		return ELEMENTAL_VFX_CONFIGS[element_type]
	return {}

func get_default_vfx_config() -> Dictionary:
	return DEFAULT_VFX_CONFIG

func get_element_video_path(element_type: int) -> String:
	return ""


func get_element_type_for_color(color: Color) -> int:
	var min_dist := 999.0
	var best_element: int = ElementChainType.FIRE
	for element in ELEMENT_COLORS.keys():
		var ec: Color = ELEMENT_COLORS[element]
		var dist = Vector3(color.r - ec.r, color.g - ec.g, color.b - ec.b).length()
		if dist < min_dist:
			min_dist = dist
			best_element = element
	return best_element

func get_sfx(sfx_name: String) -> AudioStream:
	if GENERAL_SFX_MAP.has(sfx_name):
		return GENERAL_SFX_MAP[sfx_name]
	return null

func get_active_skin() -> String:
	return active_skin

func set_active_skin(skin_name: String) -> void:
	if skin_name == "brick":
		active_skin = "brick"
		SaveManager.set_setting(SKIN_SAVE_KEY, active_skin)
		load_theme("brick_theme")


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

