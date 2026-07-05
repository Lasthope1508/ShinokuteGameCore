extends SceneTree

const CATALOG_PATH = "res://docs/vfx_effect_parameters.md"

func _init() -> void:
	var passed := true
	var required_terms := [
		"contact_spark",
		"directional_trail",
		"source_emission",
		"vfx_source_idle_enabled",
		"vfx_source_idle_period",
		"vfx_source_idle_alpha_min_ratio",
		"vfx_source_idle_alpha_pulse_ratio",
		"vfx_source_idle_radius_pulse_ratio",
		"target_pulse",
		"idle_hum",
		"energy_stream",
		"path_wave",
		"rotation_spark",
		"disconnect_decay",
		"error_spark",
		"win_burst",
		"vfx_path_wave_period",
		"vfx_rotation_spark_duration",
		"vfx_win_burst_duration",
		"vfx_path_wave_max_effects",
		"vfx_path_wave_min_particles_per_output",
		"vfx_path_wave_max_particles_per_output",
		"vfx_path_wave_density_curve",
		"vfx_energy_stream_enabled",
		"vfx_energy_stream_color",
		"vfx_energy_stream_period",
		"vfx_energy_stream_shimmer_segment_ratio",
		"vfx_energy_stream_max_effects",
		"vfx_win_burst_max_cells",
		"energy_overlay_draw_enabled",
		"target_energy_overlay_draw_enabled",
		"target_core_blink",
		"lightning_arc",
		"target_core_idle_alpha_min",
		"target_core_powered_alpha_max",
		"vfx_idle_hum_glow_width_ratio",
		"vfx_idle_hum_core_width_ratio",
		"vfx_trail_draw_enabled",
		"vfx_path_wave_draw_enabled",
		"vfx_lightning_texture",
		"vfx_lightning_color",
		"vfx_lightning_frame_count",
		"vfx_lightning_contact_period",
		"vfx_lightning_max_arcs",
		"vfx_lightning_cell_stride",
		"canonical contact key",
		"60 FPS",
		"route_junction",
		"energy_center"
	]

	passed = passed and _assert_true(FileAccess.file_exists(CATALOG_PATH), "VFX parameter catalog should exist")
	var text := ""
	if FileAccess.file_exists(CATALOG_PATH):
		var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
		text = file.get_as_text() if file != null else ""
	for term in required_terms:
		passed = passed and _assert_true(text.find(term) >= 0, "Catalog should mention %s" % term)

	if passed:
		print("test_vfx_effect_parameter_catalog: PASS")
		quit(0)
	else:
		print("test_vfx_effect_parameter_catalog: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
