class_name ShinokuteThemeManager
extends Node

var theme_config: Resource

func configure(config: Resource) -> void:
	theme_config = config

func has_theme() -> bool:
	return theme_config != null

func get_color(key: String, default_color: Color = Color.WHITE) -> Color:
	if theme_config != null and theme_config.has_method("get_color"):
		return theme_config.get_color(key, default_color)
	return default_color

func get_font_path(key: String) -> String:
	if theme_config != null and theme_config.has_method("get_font_path"):
		return theme_config.get_font_path(key)
	return ""

func get_asset_path(key: String) -> String:
	if theme_config != null and theme_config.has_method("get_asset_path"):
		return theme_config.get_asset_path(key)
	return ""

func get_audio_path(key: String) -> String:
	if theme_config != null and theme_config.has_method("get_audio_path"):
		return theme_config.get_audio_path(key)
	return ""

func get_metric(key: String, default_value: Variant = null) -> Variant:
	if theme_config != null and theme_config.has_method("get_metric"):
		return theme_config.get_metric(key, default_value)
	return default_value
