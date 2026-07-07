extends Node3D

@export var theme_config: QuantumThemeConfig

func _ready() -> void:
	if _is_compatibility_renderer():
		# Reduce background and sun brightness when using the Compatibility renderer;
		# this tries to roughly match the appearance of Forward+.
		# This compensates for the different color space and light rendering for lights with shadows enabled.
		$Sun.light_energy = 0.24
		$Sun.shadow_opacity = 0.85
		$Environment.environment.background_energy_multiplier = 0.25
	if theme_config != null:
		if Audio.has_method("configure_events"):
			Audio.configure_events(theme_config.audio_event_paths)
		var applier := preload("res://scripts/theme_applier.gd").new()
		add_child(applier)
		applier.apply_theme(self, theme_config)

func _is_compatibility_renderer() -> bool:
	var rendering_method := str(ProjectSettings.get_setting("rendering/renderer/rendering_method", ""))
	var mobile_rendering_method := str(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", ""))
	return rendering_method == "gl_compatibility" or mobile_rendering_method == "gl_compatibility"
