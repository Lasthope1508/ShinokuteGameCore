class_name ShinokuteThemeConfig
extends Resource

@export var theme_id: String = "default"
@export var display_name: String = "Default"
@export var colors: Dictionary = {}
@export var fonts: Dictionary = {}
@export var asset_paths: Dictionary = {}
@export var audio_events: Dictionary = {}
@export var ui_metrics: Dictionary = {}

func get_color(key: String, default_color: Color = Color.WHITE) -> Color:
	var value = colors.get(key, default_color)
	if value is Color:
		return value
	return default_color

func get_font_path(key: String) -> String:
	return String(fonts.get(key, ""))

func get_asset_path(key: String) -> String:
	return String(asset_paths.get(key, ""))

func get_audio_path(key: String) -> String:
	return String(audio_events.get(key, ""))

func get_metric(key: String, default_value: Variant = null) -> Variant:
	return ui_metrics.get(key, default_value)
