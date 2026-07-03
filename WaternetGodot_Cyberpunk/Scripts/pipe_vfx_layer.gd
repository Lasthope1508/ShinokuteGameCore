extends Node2D
class_name PipeVfxLayer

const VfxAnchorScript = preload("res://Scripts/vfx_anchor.gd")
const VfxRouteScript = preload("res://Scripts/vfx_route.gd")

var vfx_enabled := true
var debug_visible := false
var flow_state: Dictionary = {}
var transition_state: Dictionary = {}
var rotation_event_state: Dictionary = {}
var win_state: Dictionary = {}
var geometry_by_cell: Dictionary = {}
var grid_offset := Vector2.ZERO
var cell_size := 0.0
var debug_line_color := Color(0.22, 1.0, 0.08, 0.7)
var debug_line_width := 2.0
var contact_spark_color := Color(0.22, 1.0, 0.08, 0.9)
var contact_spark_duration := 0.22
var contact_spark_radius_ratio := 0.13
var trail_color := Color(0.22, 1.0, 0.08, 0.62)
var trail_draw_enabled := true
var trail_duration := 0.34
var trail_width := 4.0
var trail_min_alpha := 0.28
var path_wave_color := Color(0.65, 1.0, 0.22, 0.82)
var path_wave_draw_enabled := true
var path_wave_period := 0.95
var path_wave_segment_ratio := 0.22
var path_wave_width := 2.6
var path_wave_alpha := 0.72
var path_wave_max_effects := 80
var path_wave_min_particles_per_output := 1
var path_wave_max_particles_per_output := 4
var path_wave_density_curve := 1.35
var path_wave_order_phase_offset := 0.11
var energy_stream_enabled := true
var energy_stream_color := Color(0.36, 1.0, 0.78, 0.9)
var energy_stream_period := 0.7
var energy_stream_alpha := 0.7
var energy_stream_width := 3.2
var energy_stream_glow_width := 13.0
var energy_stream_shimmer_width := 5.2
var energy_stream_shimmer_segment_ratio := 0.34
var energy_stream_pulse_alpha_ratio := 0.28
var energy_stream_order_phase_offset := 0.09
var energy_stream_max_effects := 120
var target_pulse_color := Color(0.22, 1.0, 0.08, 0.82)
var target_pulse_duration := 0.48
var target_pulse_radius_ratio := 0.28
var target_pulse_ring_width := 3.5
var source_emission_color := Color(0.22, 1.0, 0.08, 0.78)
var source_emission_duration := 0.42
var source_emission_radius_ratio := 0.24
var source_emission_ring_width := 3.2
var idle_hum_color := Color(0.22, 1.0, 0.08, 0.34)
var idle_hum_delay := 0.72
var idle_hum_alpha := 0.34
var idle_hum_width := 1.8
var idle_hum_glow_width := 14.0
var idle_hum_core_width := 4.5
var idle_hum_radius_ratio := 0.23
var idle_hum_period := 0.75
var idle_hum_radius_pulse_ratio := 0.35
var idle_hum_alpha_pulse_ratio := 0.72
var disconnect_decay_color := Color(0.22, 1.0, 0.08, 0.32)
var disconnect_decay_duration := 0.32
var disconnect_decay_alpha := 0.28
var error_spark_color := Color(1.0, 0.28, 0.08, 0.82)
var error_spark_duration := 0.18
var error_spark_radius_ratio := 0.1
var rotation_spark_color := Color(0.92, 1.0, 0.18, 0.86)
var rotation_spark_duration := 0.26
var rotation_spark_radius_ratio := 0.31
var rotation_spark_ray_count := 8
var rotation_spark_width := 1.8
var win_burst_color := Color(0.32, 1.0, 0.96, 0.9)
var win_burst_duration := 0.9
var win_burst_radius_ratio := 0.34
var win_burst_ring_width := 2.8
var win_burst_max_cells := 36
var lightning_enabled := true
var lightning_texture = null
var lightning_frame_size := Vector2i(256, 256)
var lightning_columns := 16
var lightning_rows := 16
var lightning_frame_count := 250
var lightning_period := 4.1666667
var lightning_contact_period := 0.4
var lightning_color := Color(0.72, 0.92, 1.0, 0.86)
var lightning_alpha := 0.72
var lightning_scale_ratio := 0.78
var lightning_max_arcs := 10
var lightning_cell_stride := 3
var lightning_min_order_progress := 0.18
var lightning_contact_bias := 0.68
var debug_anchor_color := Color(1.0, 1.0, 1.0, 0.8)
var debug_input_color := Color(1.0, 0.32, 0.08, 0.85)
var debug_output_color := Color(0.22, 1.0, 0.08, 0.85)
var debug_order_color := Color(0.1, 0.75, 1.0, 0.85)

func set_visual_context(new_flow_state: Dictionary, new_geometry_by_cell: Dictionary, new_grid_offset: Vector2, new_cell_size: float) -> void:
	flow_state = new_flow_state.duplicate(true)
	geometry_by_cell = new_geometry_by_cell.duplicate(true)
	grid_offset = new_grid_offset
	cell_size = new_cell_size
	queue_redraw()

func set_vfx_enabled(value: bool) -> void:
	vfx_enabled = value
	queue_redraw()

func set_debug_visible(value: bool) -> void:
	debug_visible = value
	queue_redraw()

func set_transition_state(new_transition_state: Dictionary) -> void:
	transition_state = new_transition_state.duplicate(true)
	queue_redraw()

func get_transition_state() -> Dictionary:
	return transition_state.duplicate(true)

func clear_transition_state() -> void:
	transition_state.clear()
	queue_redraw()

func set_rotation_event(cell_pos: Vector2i, event_time: float) -> void:
	rotation_event_state = {
		"cell_pos": cell_pos,
		"event_time": event_time
	}
	queue_redraw()

func set_win_state(new_win_state: Dictionary) -> void:
	win_state = new_win_state.duplicate(true)
	queue_redraw()

func clear_runtime_events() -> void:
	rotation_event_state.clear()
	win_state.clear()
	queue_redraw()

func apply_theme_config(theme: Resource, current_cell_size: float) -> void:
	if theme == null:
		return
	vfx_enabled = bool(theme.get("vfx_enabled"))
	debug_visible = bool(theme.get("vfx_debug_visible"))
	debug_line_color = theme.get("vfx_debug_line_color")
	debug_line_width = max(1.0, current_cell_size * float(theme.get("vfx_debug_line_width_ratio")))
	contact_spark_color = theme.get("vfx_contact_spark_color")
	contact_spark_duration = max(0.01, float(theme.get("vfx_contact_spark_duration")))
	contact_spark_radius_ratio = max(0.0, float(theme.get("vfx_contact_spark_radius_ratio")))
	trail_color = theme.get("vfx_trail_color")
	trail_draw_enabled = bool(theme.get("vfx_trail_draw_enabled"))
	trail_duration = max(0.01, float(theme.get("vfx_trail_duration")))
	trail_width = max(1.0, current_cell_size * float(theme.get("vfx_trail_width_ratio")))
	trail_min_alpha = clampf(float(theme.get("vfx_trail_min_alpha")), 0.0, 1.0)
	path_wave_color = theme.get("vfx_path_wave_color")
	path_wave_draw_enabled = bool(theme.get("vfx_path_wave_draw_enabled"))
	path_wave_period = max(0.01, float(theme.get("vfx_path_wave_period")))
	path_wave_segment_ratio = clampf(float(theme.get("vfx_path_wave_segment_ratio")), 0.01, 1.0)
	path_wave_width = max(1.0, current_cell_size * float(theme.get("vfx_path_wave_width_ratio")))
	path_wave_alpha = clampf(float(theme.get("vfx_path_wave_alpha")), 0.0, 1.0)
	path_wave_max_effects = max(0, int(theme.get("vfx_path_wave_max_effects")))
	path_wave_min_particles_per_output = max(1, int(theme.get("vfx_path_wave_min_particles_per_output")))
	path_wave_max_particles_per_output = max(path_wave_min_particles_per_output, int(theme.get("vfx_path_wave_max_particles_per_output")))
	path_wave_density_curve = max(0.01, float(theme.get("vfx_path_wave_density_curve")))
	path_wave_order_phase_offset = float(theme.get("vfx_path_wave_order_phase_offset"))
	energy_stream_enabled = bool(theme.get("vfx_energy_stream_enabled"))
	energy_stream_color = theme.get("vfx_energy_stream_color")
	energy_stream_period = max(0.01, float(theme.get("vfx_energy_stream_period")))
	energy_stream_alpha = clampf(float(theme.get("vfx_energy_stream_alpha")), 0.0, 1.0)
	energy_stream_width = max(1.0, current_cell_size * float(theme.get("vfx_energy_stream_width_ratio")))
	energy_stream_glow_width = max(1.0, current_cell_size * float(theme.get("vfx_energy_stream_glow_width_ratio")))
	energy_stream_shimmer_width = max(1.0, current_cell_size * float(theme.get("vfx_energy_stream_shimmer_width_ratio")))
	energy_stream_shimmer_segment_ratio = clampf(float(theme.get("vfx_energy_stream_shimmer_segment_ratio")), 0.01, 1.0)
	energy_stream_pulse_alpha_ratio = clampf(float(theme.get("vfx_energy_stream_pulse_alpha_ratio")), 0.0, 1.0)
	energy_stream_order_phase_offset = float(theme.get("vfx_energy_stream_order_phase_offset"))
	energy_stream_max_effects = max(0, int(theme.get("vfx_energy_stream_max_effects")))
	target_pulse_color = theme.get("vfx_target_pulse_color")
	target_pulse_duration = max(0.01, float(theme.get("vfx_target_pulse_duration")))
	target_pulse_radius_ratio = max(0.0, float(theme.get("vfx_target_pulse_radius_ratio")))
	target_pulse_ring_width = max(1.0, current_cell_size * float(theme.get("vfx_target_pulse_ring_width_ratio")))
	source_emission_color = theme.get("vfx_source_emission_color")
	source_emission_duration = max(0.01, float(theme.get("vfx_source_emission_duration")))
	source_emission_radius_ratio = max(0.0, float(theme.get("vfx_source_emission_radius_ratio")))
	source_emission_ring_width = max(1.0, current_cell_size * float(theme.get("vfx_source_emission_ring_width_ratio")))
	idle_hum_color = theme.get("vfx_idle_hum_color")
	idle_hum_delay = max(0.0, float(theme.get("vfx_idle_hum_delay")))
	idle_hum_alpha = clampf(float(theme.get("vfx_idle_hum_alpha")), 0.0, 1.0)
	idle_hum_width = max(1.0, current_cell_size * float(theme.get("vfx_idle_hum_width_ratio")))
	idle_hum_glow_width = max(1.0, current_cell_size * float(theme.get("vfx_idle_hum_glow_width_ratio")))
	idle_hum_core_width = max(1.0, current_cell_size * float(theme.get("vfx_idle_hum_core_width_ratio")))
	idle_hum_radius_ratio = max(0.0, float(theme.get("vfx_idle_hum_radius_ratio")))
	idle_hum_period = max(0.01, float(theme.get("vfx_idle_hum_period")))
	idle_hum_radius_pulse_ratio = max(0.0, float(theme.get("vfx_idle_hum_radius_pulse_ratio")))
	idle_hum_alpha_pulse_ratio = clampf(float(theme.get("vfx_idle_hum_alpha_pulse_ratio")), 0.0, 1.0)
	disconnect_decay_color = theme.get("vfx_disconnect_decay_color")
	disconnect_decay_duration = max(0.01, float(theme.get("vfx_disconnect_decay_duration")))
	disconnect_decay_alpha = clampf(float(theme.get("vfx_disconnect_decay_alpha")), 0.0, 1.0)
	error_spark_color = theme.get("vfx_error_spark_color")
	error_spark_duration = max(0.01, float(theme.get("vfx_error_spark_duration")))
	error_spark_radius_ratio = max(0.0, float(theme.get("vfx_error_spark_radius_ratio")))
	rotation_spark_color = theme.get("vfx_rotation_spark_color")
	rotation_spark_duration = max(0.01, float(theme.get("vfx_rotation_spark_duration")))
	rotation_spark_radius_ratio = max(0.0, float(theme.get("vfx_rotation_spark_radius_ratio")))
	rotation_spark_ray_count = max(0, int(theme.get("vfx_rotation_spark_ray_count")))
	rotation_spark_width = max(1.0, current_cell_size * float(theme.get("vfx_rotation_spark_width_ratio")))
	win_burst_color = theme.get("vfx_win_burst_color")
	win_burst_duration = max(0.01, float(theme.get("vfx_win_burst_duration")))
	win_burst_radius_ratio = max(0.0, float(theme.get("vfx_win_burst_radius_ratio")))
	win_burst_ring_width = max(1.0, current_cell_size * float(theme.get("vfx_win_burst_ring_width_ratio")))
	win_burst_max_cells = max(0, int(theme.get("vfx_win_burst_max_cells")))
	lightning_enabled = bool(theme.get("vfx_lightning_enabled"))
	lightning_texture = theme.get("vfx_lightning_texture")
	lightning_frame_size = theme.get("vfx_lightning_frame_size")
	lightning_columns = max(1, int(theme.get("vfx_lightning_columns")))
	lightning_rows = max(1, int(theme.get("vfx_lightning_rows")))
	lightning_frame_count = max(1, int(theme.get("vfx_lightning_frame_count")))
	lightning_period = max(0.01, float(theme.get("vfx_lightning_period")))
	lightning_contact_period = max(0.01, float(theme.get("vfx_lightning_contact_period")))
	lightning_color = theme.get("vfx_lightning_color")
	lightning_alpha = clampf(float(theme.get("vfx_lightning_alpha")), 0.0, 1.0)
	lightning_scale_ratio = max(0.0, float(theme.get("vfx_lightning_scale_ratio")))
	lightning_max_arcs = max(0, int(theme.get("vfx_lightning_max_arcs")))
	lightning_cell_stride = max(1, int(theme.get("vfx_lightning_cell_stride")))
	lightning_min_order_progress = clampf(float(theme.get("vfx_lightning_min_order_progress")), 0.0, 1.0)
	lightning_contact_bias = clampf(float(theme.get("vfx_lightning_contact_bias")), 0.0, 1.0)
	debug_anchor_color = theme.get("vfx_debug_anchor_color")
	debug_input_color = theme.get("vfx_debug_input_color")
	debug_output_color = theme.get("vfx_debug_output_color")
	debug_order_color = theme.get("vfx_debug_order_color")
	queue_redraw()

func _process(_delta: float) -> void:
	if has_active_motion():
		queue_redraw()

func has_active_motion(now: float = -1.0) -> bool:
	if not vfx_enabled:
		return false
	var sample_time := now
	if sample_time < 0.0:
		sample_time = Time.get_ticks_msec() / 1000.0
	for raw_cell_pos in flow_state.keys():
		var cell_pos: Vector2i = raw_cell_pos
		var entry: Dictionary = flow_state[cell_pos]
		var age: float = max(0.0, float(entry.get("age", 0.0)))
		var input_dir: int = int(entry.get("input_dir", -1))
		var output_dirs: Array = entry.get("output_dirs", [])
		var geometry: Resource = geometry_by_cell.get(cell_pos, null)
		var asset_key: String = String(geometry.get("asset_key")) if geometry != null else ""
		if input_dir >= 0 and age <= contact_spark_duration:
			return true
		if trail_draw_enabled and not output_dirs.is_empty() and age <= trail_duration:
			return true
		if asset_key == "source" and not output_dirs.is_empty() and age <= source_emission_duration:
			return true
		if asset_key == "target" and input_dir >= 0 and age <= target_pulse_duration:
			return true
		if age >= idle_hum_delay and int(entry.get("flow_mask", 0)) != 0 and _is_idle_hum_animated():
			if asset_key != "source" and asset_key != "target":
				return true
		if energy_stream_enabled and not output_dirs.is_empty() and int(entry.get("flow_mask", 0)) != 0 and energy_stream_alpha > 0.0 and energy_stream_max_effects > 0:
			return true
		if path_wave_draw_enabled and not output_dirs.is_empty() and int(entry.get("flow_mask", 0)) != 0 and path_wave_alpha > 0.0 and path_wave_max_effects > 0:
			return true
	if lightning_enabled and lightning_texture != null and lightning_alpha > 0.0 and lightning_max_arcs > 0:
		if not get_lightning_arcs(sample_time).is_empty():
			return true
	var event_time := float(transition_state.get("event_time", -1.0))
	if event_time >= 0.0:
		var transition_age: float = max(0.0, sample_time - event_time)
		if not transition_state.get("lost_cells", []).is_empty() and transition_age <= disconnect_decay_duration:
			return true
		if not transition_state.get("lost_contacts", []).is_empty() and transition_age <= error_spark_duration:
			return true
	var rotation_time := float(rotation_event_state.get("event_time", -1.0))
	if rotation_time >= 0.0 and sample_time - rotation_time <= rotation_spark_duration:
		return true
	var win_time := float(win_state.get("event_time", -1.0))
	if win_time >= 0.0 and sample_time - win_time <= win_burst_duration:
		return true
	return false

func _is_idle_hum_animated() -> bool:
	return idle_hum_radius_pulse_ratio > 0.0 or idle_hum_alpha_pulse_ratio > 0.0

func get_contact_sparks() -> Array:
	var sparks := []
	if cell_size <= 0.0 or contact_spark_radius_ratio <= 0.0:
		return sparks
	for raw_cell_pos in flow_state.keys():
		var cell_pos: Vector2i = raw_cell_pos
		var entry: Dictionary = flow_state[cell_pos]
		var input_dir := int(entry.get("input_dir", -1))
		var age := float(entry.get("age", 0.0))
		if input_dir < 0 or age > contact_spark_duration:
			continue
		var geometry: Resource = geometry_by_cell.get(cell_pos, null)
		if geometry == null:
			continue
		var anchors := VfxAnchorScript.get_anchor_points(geometry, grid_offset, cell_size, cell_pos)
		var port_name: String = VfxAnchorScript.PORT_NAMES[input_dir]
		var progress := clampf(age / contact_spark_duration, 0.0, 1.0)
		var alpha := 1.0 - progress
		var radius := cell_size * contact_spark_radius_ratio * (0.55 + progress * 0.65)
		sparks.append({
			"cell_pos": cell_pos,
			"direction": input_dir,
			"position": anchors.get(port_name, anchors.get("center", Vector2.ZERO)),
			"radius": radius,
			"alpha": alpha,
			"color": contact_spark_color
		})
	return sparks

func get_directional_trails() -> Array:
	var trails := []
	if cell_size <= 0.0 or trail_width <= 0.0:
		return trails
	for raw_cell_pos in flow_state.keys():
		var cell_pos: Vector2i = raw_cell_pos
		var entry: Dictionary = flow_state[cell_pos]
		var output_dirs: Array = entry.get("output_dirs", [])
		if output_dirs.is_empty():
			continue
		if int(entry.get("flow_mask", 0)) == 0:
			continue
		var geometry: Resource = geometry_by_cell.get(cell_pos, null)
		if geometry == null:
			continue
		var anchors := VfxAnchorScript.get_anchor_points(geometry, grid_offset, cell_size, cell_pos)
		var input_dir := int(entry.get("input_dir", -1))
		var age: float = float(entry.get("age", 0.0))
		var progress: float = clampf(age / trail_duration, 0.0, 1.0)
		var alpha: float = max(trail_min_alpha, 1.0 - progress)
		for raw_output_dir in output_dirs:
			var output_dir := int(raw_output_dir)
			if output_dir < 0:
				continue
			trails.append({
				"cell_pos": cell_pos,
				"input_dir": input_dir,
				"output_dir": output_dir,
				"points": VfxRouteScript.get_route_points(geometry, input_dir, output_dir, anchors),
				"progress": progress,
				"alpha": alpha,
				"width": trail_width,
				"color": trail_color
			})
	return trails

func get_path_waves(now: float = -1.0) -> Array:
	var waves := []
	if cell_size <= 0.0 or path_wave_width <= 0.0 or path_wave_alpha <= 0.0 or path_wave_max_effects <= 0:
		return waves
	var sample_time := now
	if sample_time < 0.0:
		sample_time = Time.get_ticks_msec() / 1000.0
	var max_order := _get_max_flow_order()
	for raw_cell_pos in flow_state.keys():
		var cell_pos: Vector2i = raw_cell_pos
		var entry: Dictionary = flow_state[cell_pos]
		var output_dirs: Array = entry.get("output_dirs", [])
		if output_dirs.is_empty():
			continue
		var geometry: Resource = geometry_by_cell.get(cell_pos, null)
		if geometry == null:
			continue
		var anchors := VfxAnchorScript.get_anchor_points(geometry, grid_offset, cell_size, cell_pos)
		var input_dir := int(entry.get("input_dir", -1))
		var order: int = int(entry.get("order", 0))
		var particle_count := _get_path_wave_particle_count_for_order(order, max_order)
		var base_progress: float = fposmod((sample_time / path_wave_period) + float(order) * path_wave_order_phase_offset, 1.0)
		for raw_output_dir in output_dirs:
			var output_dir := int(raw_output_dir)
			if output_dir < 0:
				continue
			var route_points: Array = VfxRouteScript.get_route_points(geometry, input_dir, output_dir, anchors)
			for particle_index in range(particle_count):
				if waves.size() >= path_wave_max_effects:
					return waves
				var particle_offset := float(particle_index) / float(max(1, particle_count))
				var head_progress: float = fposmod(base_progress + particle_offset, 1.0)
				var tail_progress: float = max(0.0, head_progress - path_wave_segment_ratio)
				waves.append({
					"cell_pos": cell_pos,
					"input_dir": input_dir,
					"output_dir": output_dir,
					"points": route_points,
					"tail_progress": tail_progress,
					"head_progress": head_progress,
					"particle_index": particle_index,
					"particle_count": particle_count,
					"order": order,
					"density_progress": _get_path_wave_density_progress(order, max_order),
					"alpha": path_wave_alpha,
					"width": path_wave_width,
					"color": path_wave_color
				})
	return waves

func get_energy_streams(now: float = -1.0) -> Array:
	var streams := []
	if cell_size <= 0.0 or not energy_stream_enabled:
		return streams
	if energy_stream_width <= 0.0 or energy_stream_glow_width <= 0.0 or energy_stream_alpha <= 0.0 or energy_stream_max_effects <= 0:
		return streams
	var sample_time := now
	if sample_time < 0.0:
		sample_time = Time.get_ticks_msec() / 1000.0
	var max_order := _get_max_flow_order()
	for raw_cell_pos in flow_state.keys():
		var cell_pos: Vector2i = raw_cell_pos
		var entry: Dictionary = flow_state[cell_pos]
		if int(entry.get("flow_mask", 0)) == 0:
			continue
		var output_dirs: Array = entry.get("output_dirs", [])
		if output_dirs.is_empty():
			continue
		var geometry: Resource = geometry_by_cell.get(cell_pos, null)
		if geometry == null:
			continue
		var anchors := VfxAnchorScript.get_anchor_points(geometry, grid_offset, cell_size, cell_pos)
		var input_dir := int(entry.get("input_dir", -1))
		var order: int = int(entry.get("order", 0))
		var phase := fposmod((sample_time / energy_stream_period) + float(order) * energy_stream_order_phase_offset, 1.0)
		var wave_alpha := clampf(energy_stream_alpha * (1.0 - energy_stream_pulse_alpha_ratio * 0.5 + energy_stream_pulse_alpha_ratio * ((sin(phase * TAU) + 1.0) * 0.5)), 0.0, 1.0)
		var density_progress := _get_path_wave_density_progress(order, max_order)
		for raw_output_dir in output_dirs:
			if streams.size() >= energy_stream_max_effects:
				return streams
			var output_dir := int(raw_output_dir)
			if output_dir < 0:
				continue
			streams.append({
				"cell_pos": cell_pos,
				"input_dir": input_dir,
				"output_dir": output_dir,
				"points": VfxRouteScript.get_route_points(geometry, input_dir, output_dir, anchors),
				"alpha": wave_alpha,
				"density_progress": density_progress,
				"core_width": energy_stream_width,
				"glow_width": energy_stream_glow_width,
				"shimmer_width": energy_stream_shimmer_width,
				"shimmer_tail_progress": phase - energy_stream_shimmer_segment_ratio,
				"shimmer_head_progress": phase,
				"color": energy_stream_color
			})
	return streams

func get_lightning_arcs(now: float = -1.0) -> Array:
	var arcs := []
	if cell_size <= 0.0:
		return arcs
	if lightning_enabled == false:
		return arcs
	if lightning_texture == null:
		return arcs
	if lightning_alpha <= 0.0 or lightning_scale_ratio <= 0.0 or lightning_max_arcs <= 0:
		return arcs
	if lightning_frame_size.x <= 0 or lightning_frame_size.y <= 0:
		return arcs
	var sample_time := now
	if sample_time < 0.0:
		sample_time = Time.get_ticks_msec() / 1000.0
	if sample_time < 0.0:
		return arcs
	var max_order := _get_max_flow_order()
	if max_order <= 0:
		return arcs
	var total_frames: int = mini(lightning_frame_count, lightning_columns * lightning_rows)
	if total_frames < 1:
		total_frames = 1
	var contact_cycle_index: int = int(sample_time / lightning_contact_period)
	if contact_cycle_index < 0:
		return arcs
	var sheet_frame_index: int = int(fposmod(sample_time / lightning_period, 1.0) * float(total_frames))
	sheet_frame_index = clampi(sheet_frame_index, 0, total_frames - 1)
	var seen_contacts := {}
	for raw_cell_pos in flow_state.keys():
		if arcs.size() >= lightning_max_arcs:
			break
		var cell_pos: Vector2i = raw_cell_pos
		var entry: Dictionary = flow_state[cell_pos]
		if int(entry.get("flow_mask", 0)) == 0:
			continue
		var output_dirs: Array = entry.get("output_dirs", [])
		if output_dirs.is_empty():
			continue
		var order: int = int(entry.get("order", 0))
		var order_progress := clampf(float(max(0, order)) / float(max_order), 0.0, 1.0)
		if order_progress < lightning_min_order_progress:
			continue
		if lightning_cell_stride > 1:
			if ((order + contact_cycle_index) % lightning_cell_stride) != 0:
				continue
		var input_dir := int(entry.get("input_dir", -1))
		for raw_output_dir in output_dirs:
			if arcs.size() >= lightning_max_arcs:
				break
			var output_dir := int(raw_output_dir)
			if output_dir < 0 or output_dir >= VfxAnchorScript.PORT_NAMES.size():
				continue
			var neighbor_pos: Vector2i = cell_pos + _get_direction_offset(output_dir)
			if not flow_state.has(neighbor_pos):
				continue
			var contact_key := _make_contact_key(cell_pos, neighbor_pos)
			if seen_contacts.has(contact_key):
				continue
			seen_contacts[contact_key] = true
			var direction_offset := _get_direction_offset(output_dir)
			var direction_vector := Vector2(direction_offset.x, direction_offset.y)
			var cell_center := grid_offset + Vector2(cell_pos) * cell_size + Vector2(cell_size * 0.5, cell_size * 0.5)
			var position := cell_center + direction_vector * cell_size * (0.2 + lightning_contact_bias * 0.26)
			var route_points := [cell_center, position]
			var rotation := direction_vector.angle()
			var frame_index: int = int(abs(sheet_frame_index + order * 5 + output_dir * 3)) % total_frames
			arcs.append({
				"cell_pos": cell_pos,
				"neighbor_pos": neighbor_pos,
				"contact_key": contact_key,
				"input_dir": input_dir,
				"output_dir": output_dir,
				"points": route_points,
				"position": position,
				"rotation": rotation,
				"frame_index": frame_index,
				"order": order,
				"order_progress": order_progress,
				"scale": (cell_size * lightning_scale_ratio) / float(lightning_frame_size.x),
				"color": lightning_color,
				"alpha": lightning_alpha
			})
	return arcs

func _get_max_flow_order() -> int:
	var max_order := 0
	for raw_cell_pos in flow_state.keys():
		var cell_pos: Vector2i = raw_cell_pos
		var entry: Dictionary = flow_state[cell_pos]
		max_order = max(max_order, int(entry.get("order", 0)))
	return max_order

func _get_flow_cells_sorted_by_order() -> Array:
	return flow_state.keys()

func _get_path_wave_density_progress(order: int, max_order: int) -> float:
	if max_order <= 0:
		return 0.0
	var normalized := clampf(float(max(0, order)) / float(max_order), 0.0, 1.0)
	return pow(normalized, path_wave_density_curve)

func _get_path_wave_particle_count_for_order(order: int, max_order: int) -> int:
	var density := _get_path_wave_density_progress(order, max_order)
	var count := int(round(lerpf(float(path_wave_min_particles_per_output), float(path_wave_max_particles_per_output), density)))
	return clampi(count, path_wave_min_particles_per_output, path_wave_max_particles_per_output)

func get_target_pulses() -> Array:
	var pulses := []
	if cell_size <= 0.0 or target_pulse_radius_ratio <= 0.0:
		return pulses
	for raw_cell_pos in flow_state.keys():
		var cell_pos: Vector2i = raw_cell_pos
		var geometry: Resource = geometry_by_cell.get(cell_pos, null)
		if geometry == null or geometry.get("asset_key") != "target":
			continue
		var entry: Dictionary = flow_state[cell_pos]
		if int(entry.get("input_dir", -1)) < 0:
			continue
		var age: float = float(entry.get("age", 0.0))
		if age > target_pulse_duration:
			continue
		var anchors := VfxAnchorScript.get_anchor_points(geometry, grid_offset, cell_size, cell_pos)
		var progress: float = clampf(age / target_pulse_duration, 0.0, 1.0)
		var alpha: float = 1.0 - progress
		var radius: float = cell_size * target_pulse_radius_ratio * (0.7 + progress * 0.65)
		pulses.append({
			"cell_pos": cell_pos,
			"position": anchors.get("energy_center", anchors.get("center", Vector2.ZERO)),
			"radius": radius,
			"ring_width": target_pulse_ring_width,
			"alpha": alpha,
			"color": target_pulse_color
		})
	return pulses

func get_source_emissions() -> Array:
	var emissions := []
	if cell_size <= 0.0 or source_emission_radius_ratio <= 0.0:
		return emissions
	for raw_cell_pos in flow_state.keys():
		var cell_pos: Vector2i = raw_cell_pos
		var geometry: Resource = geometry_by_cell.get(cell_pos, null)
		if geometry == null or geometry.get("asset_key") != "source":
			continue
		var entry: Dictionary = flow_state[cell_pos]
		var output_dirs: Array = entry.get("output_dirs", [])
		if output_dirs.is_empty():
			continue
		var age: float = float(entry.get("age", 0.0))
		if age > source_emission_duration:
			continue
		var anchors := VfxAnchorScript.get_anchor_points(geometry, grid_offset, cell_size, cell_pos)
		var progress: float = clampf(age / source_emission_duration, 0.0, 1.0)
		var alpha: float = 1.0 - progress
		var radius: float = cell_size * source_emission_radius_ratio * (0.65 + progress * 0.75)
		emissions.append({
			"cell_pos": cell_pos,
			"output_dirs": output_dirs.duplicate(),
			"position": anchors.get("energy_center", anchors.get("center", Vector2.ZERO)),
			"radius": radius,
			"ring_width": source_emission_ring_width,
			"alpha": alpha,
			"color": source_emission_color
		})
	return emissions

func get_idle_hums(now: float = -1.0) -> Array:
	var hums := []
	if cell_size <= 0.0 or idle_hum_glow_width <= 0.0 or idle_hum_core_width <= 0.0 or idle_hum_alpha <= 0.0:
		return hums
	var sample_time := now
	if sample_time < 0.0:
		sample_time = Time.get_ticks_msec() / 1000.0
	for raw_cell_pos in flow_state.keys():
		var cell_pos: Vector2i = raw_cell_pos
		var entry: Dictionary = flow_state[cell_pos]
		var age: float = float(entry.get("age", 0.0))
		if age < idle_hum_delay:
			continue
		var flow_mask := int(entry.get("flow_mask", 0))
		if flow_mask == 0:
			continue
		var geometry: Resource = geometry_by_cell.get(cell_pos, null)
		if geometry == null:
			continue
		var asset_key := String(geometry.get("asset_key"))
		if asset_key == "source" or asset_key == "target":
			continue
		var output_dirs: Array = entry.get("output_dirs", [])
		if output_dirs.is_empty():
			continue
		var anchors := VfxAnchorScript.get_anchor_points(geometry, grid_offset, cell_size, cell_pos)
		var order: int = int(entry.get("order", 0))
		var input_dir := int(entry.get("input_dir", -1))
		var phase: float = fposmod((sample_time / idle_hum_period) + float(order) * 0.17, 1.0) * TAU
		var pulse: float = (sin(phase) + 1.0) * 0.5
		var width_pulse: float = 1.0 + idle_hum_radius_pulse_ratio * pulse
		var alpha: float = clampf(idle_hum_alpha * (1.0 - idle_hum_alpha_pulse_ratio * 0.5 + idle_hum_alpha_pulse_ratio * pulse), 0.0, 1.0)
		for raw_output_dir in output_dirs:
			var output_dir := int(raw_output_dir)
			if output_dir < 0:
				continue
			hums.append({
				"cell_pos": cell_pos,
				"flow_mask": flow_mask,
				"input_dir": input_dir,
				"output_dir": output_dir,
				"points": VfxRouteScript.get_route_points(geometry, input_dir, output_dir, anchors),
				"core_width": idle_hum_core_width * width_pulse,
				"glow_width": idle_hum_glow_width * width_pulse,
				"width": idle_hum_width,
				"alpha": alpha,
				"pulse": pulse,
				"color": idle_hum_color
			})
	return hums

func get_disconnect_decays(now: float = -1.0) -> Array:
	var decays := []
	if cell_size <= 0.0 or disconnect_decay_alpha <= 0.0:
		return decays
	var event_time := float(transition_state.get("event_time", -1.0))
	if event_time < 0.0:
		return decays
	var sample_time := now
	if sample_time < 0.0:
		sample_time = Time.get_ticks_msec() / 1000.0
	var age: float = max(0.0, sample_time - event_time)
	if age > disconnect_decay_duration:
		return decays
	var progress: float = clampf(age / disconnect_decay_duration, 0.0, 1.0)
	var alpha: float = disconnect_decay_alpha * (1.0 - progress)
	for raw_cell_pos in transition_state.get("lost_cells", []):
		var cell_pos: Vector2i = raw_cell_pos
		var geometry: Resource = geometry_by_cell.get(cell_pos, null)
		if geometry == null:
			continue
		var anchors: Dictionary = VfxAnchorScript.get_anchor_points(geometry, grid_offset, cell_size, cell_pos)
		decays.append({
			"cell_pos": cell_pos,
			"position": anchors.get("energy_center", anchors.get("center", Vector2.ZERO)),
			"radius": cell_size * idle_hum_radius_ratio,
			"width": idle_hum_width,
			"alpha": alpha,
			"color": disconnect_decay_color
		})
	return decays

func get_error_sparks(now: float = -1.0) -> Array:
	var sparks := []
	if cell_size <= 0.0 or error_spark_radius_ratio <= 0.0:
		return sparks
	var event_time := float(transition_state.get("event_time", -1.0))
	if event_time < 0.0:
		return sparks
	var sample_time := now
	if sample_time < 0.0:
		sample_time = Time.get_ticks_msec() / 1000.0
	var age: float = max(0.0, sample_time - event_time)
	if age > error_spark_duration:
		return sparks
	var progress: float = clampf(age / error_spark_duration, 0.0, 1.0)
	var alpha: float = 1.0 - progress
	var radius: float = cell_size * error_spark_radius_ratio * (0.55 + progress * 0.55)
	for raw_contact in transition_state.get("lost_contacts", []):
		var contact: Dictionary = raw_contact
		var cell_pos: Vector2i = contact.get("cell_pos", Vector2i(-1, -1))
		var direction := int(contact.get("direction", -1))
		if direction < 0 or direction >= VfxAnchorScript.PORT_NAMES.size():
			continue
		var geometry: Resource = geometry_by_cell.get(cell_pos, null)
		if geometry == null:
			continue
		var anchors: Dictionary = VfxAnchorScript.get_anchor_points(geometry, grid_offset, cell_size, cell_pos)
		var port_name: String = VfxAnchorScript.PORT_NAMES[direction]
		sparks.append({
			"cell_pos": cell_pos,
			"direction": direction,
			"neighbor_pos": contact.get("neighbor_pos", Vector2i(-1, -1)),
			"position": anchors.get(port_name, anchors.get("center", Vector2.ZERO)),
			"radius": radius,
			"alpha": alpha,
			"color": error_spark_color
		})
	return sparks

func get_rotation_sparks(now: float = -1.0) -> Array:
	var sparks := []
	if cell_size <= 0.0 or rotation_spark_radius_ratio <= 0.0 or rotation_spark_ray_count <= 0:
		return sparks
	var event_time := float(rotation_event_state.get("event_time", -1.0))
	if event_time < 0.0:
		return sparks
	var sample_time := now
	if sample_time < 0.0:
		sample_time = Time.get_ticks_msec() / 1000.0
	var age: float = max(0.0, sample_time - event_time)
	if age > rotation_spark_duration:
		return sparks
	var cell_pos: Vector2i = rotation_event_state.get("cell_pos", Vector2i(-1, -1))
	var geometry: Resource = geometry_by_cell.get(cell_pos, null)
	var position := grid_offset + Vector2(cell_pos) * cell_size + Vector2(cell_size * 0.5, cell_size * 0.5)
	if geometry != null:
		var anchors: Dictionary = VfxAnchorScript.get_anchor_points(geometry, grid_offset, cell_size, cell_pos)
		position = anchors.get("energy_center", anchors.get("center", position))
	var progress: float = clampf(age / rotation_spark_duration, 0.0, 1.0)
	sparks.append({
		"cell_pos": cell_pos,
		"position": position,
		"radius": cell_size * rotation_spark_radius_ratio * (0.5 + progress * 0.7),
		"ray_count": rotation_spark_ray_count,
		"width": rotation_spark_width,
		"alpha": 1.0 - progress,
		"color": rotation_spark_color
	})
	return sparks

func get_win_bursts(now: float = -1.0) -> Array:
	var bursts := []
	if cell_size <= 0.0 or win_burst_radius_ratio <= 0.0 or win_burst_max_cells <= 0:
		return bursts
	var event_time := float(win_state.get("event_time", -1.0))
	if event_time < 0.0:
		return bursts
	var sample_time := now
	if sample_time < 0.0:
		sample_time = Time.get_ticks_msec() / 1000.0
	var age: float = max(0.0, sample_time - event_time)
	if age > win_burst_duration:
		return bursts
	var progress: float = clampf(age / win_burst_duration, 0.0, 1.0)
	var cells := flow_state.keys()
	cells.sort_custom(func(a, b): return int(flow_state[a].get("order", 0)) < int(flow_state[b].get("order", 0)))
	for raw_cell_pos in cells:
		if bursts.size() >= win_burst_max_cells:
			break
		var cell_pos: Vector2i = raw_cell_pos
		var geometry: Resource = geometry_by_cell.get(cell_pos, null)
		if geometry == null:
			continue
		var anchors: Dictionary = VfxAnchorScript.get_anchor_points(geometry, grid_offset, cell_size, cell_pos)
		var order: int = int(flow_state[cell_pos].get("order", 0))
		var stagger: float = clampf(progress - float(order) * 0.018, 0.0, 1.0)
		bursts.append({
			"cell_pos": cell_pos,
			"position": anchors.get("energy_center", anchors.get("center", Vector2.ZERO)),
			"radius": cell_size * win_burst_radius_ratio * (0.4 + stagger * 1.1),
			"ring_width": win_burst_ring_width,
			"alpha": (1.0 - progress) * (0.65 + stagger * 0.35),
			"color": win_burst_color
		})
	return bursts

func get_debug_segments() -> Array:
	var segments := []
	if cell_size <= 0.0:
		return segments
	for raw_cell_pos in flow_state.keys():
		var cell_pos: Vector2i = raw_cell_pos
		var geometry: Resource = geometry_by_cell.get(cell_pos, null)
		if geometry == null:
			continue
		var anchors := VfxAnchorScript.get_anchor_points(geometry, grid_offset, cell_size, cell_pos)
		var entry: Dictionary = flow_state[cell_pos]
		var input_dir := int(entry.get("input_dir", -1))
		for raw_output_dir in entry.get("output_dirs", []):
			var output_dir := int(raw_output_dir)
			if output_dir >= 0:
				var points: Array = VfxRouteScript.get_route_points(geometry, input_dir, output_dir, anchors)
				for point_index in range(points.size() - 1):
					segments.append({
						"cell_pos": cell_pos,
						"direction": output_dir,
						"is_input": input_dir >= 0 and point_index == 0,
						"from": points[point_index],
						"to": points[point_index + 1]
					})
	return segments

func get_debug_anchors() -> Array:
	var debug_anchors := []
	if cell_size <= 0.0:
		return debug_anchors
	for raw_cell_pos in flow_state.keys():
		var cell_pos: Vector2i = raw_cell_pos
		var geometry: Resource = geometry_by_cell.get(cell_pos, null)
		if geometry == null:
			continue
		var anchors: Dictionary = VfxAnchorScript.get_anchor_points(geometry, grid_offset, cell_size, cell_pos)
		var entry: Dictionary = flow_state[cell_pos]
		debug_anchors.append({
			"cell_pos": cell_pos,
			"order": int(entry.get("order", -1)),
			"energy_center": anchors.get("energy_center", anchors.get("center", Vector2.ZERO)),
			"route_junction": anchors.get("route_junction", anchors.get("center", Vector2.ZERO)),
			"input_dir": int(entry.get("input_dir", -1)),
			"output_dirs": entry.get("output_dirs", []).duplicate(),
			"anchors": anchors
		})
	return debug_anchors

func _draw() -> void:
	if not vfx_enabled:
		return
	for emission in get_source_emissions():
		var emission_color: Color = emission["color"]
		emission_color.a *= float(emission["alpha"])
		draw_arc(emission["position"], float(emission["radius"]), 0.0, TAU, 40, emission_color, float(emission["ring_width"]))
		draw_circle(emission["position"], float(emission["radius"]) * 0.28, Color(emission_color.r, emission_color.g, emission_color.b, emission_color.a * 0.28))
	for decay in get_disconnect_decays():
		var decay_color: Color = decay["color"]
		decay_color.a *= float(decay["alpha"])
		draw_arc(decay["position"], float(decay["radius"]), 0.0, TAU, 36, decay_color, float(decay["width"]))
		draw_circle(decay["position"], float(decay["radius"]) * 0.38, Color(decay_color.r, decay_color.g, decay_color.b, decay_color.a * 0.22))
	for hum in get_idle_hums():
		var hum_color: Color = hum["color"]
		hum_color.a *= float(hum["alpha"])
		_draw_pipe_aura(hum, hum_color)
	for stream in get_energy_streams():
		_draw_energy_stream(stream)
	for arc in get_lightning_arcs():
		_draw_lightning_arc(arc)
	if path_wave_draw_enabled:
		for wave in get_path_waves():
			_draw_path_wave(wave)
	if trail_draw_enabled:
		for trail in get_directional_trails():
			_draw_directional_trail(trail)
	for burst in get_win_bursts():
		_draw_win_burst(burst)
	for pulse in get_target_pulses():
		var pulse_color: Color = pulse["color"]
		pulse_color.a *= float(pulse["alpha"])
		draw_arc(pulse["position"], float(pulse["radius"]), 0.0, TAU, 40, pulse_color, float(pulse["ring_width"]))
		draw_circle(pulse["position"], float(pulse["radius"]) * 0.36, Color(pulse_color.r, pulse_color.g, pulse_color.b, pulse_color.a * 0.35))
	for spark in get_contact_sparks():
		var color: Color = spark["color"]
		color.a *= float(spark["alpha"])
		var position: Vector2 = spark["position"]
		var radius := float(spark["radius"])
		draw_circle(position, radius, color)
		draw_arc(position, radius * 1.45, 0.0, TAU, 24, Color(color.r, color.g, color.b, color.a * 0.55), max(1.0, debug_line_width))
	for spark in get_error_sparks():
		var error_color: Color = spark["color"]
		error_color.a *= float(spark["alpha"])
		var error_position: Vector2 = spark["position"]
		var error_radius := float(spark["radius"])
		draw_circle(error_position, error_radius, error_color)
		draw_arc(error_position, error_radius * 1.6, 0.0, TAU, 18, Color(error_color.r, error_color.g, error_color.b, error_color.a * 0.5), max(1.0, debug_line_width))
	for spark in get_rotation_sparks():
		_draw_rotation_spark(spark)
	if debug_visible:
		for debug_anchor in get_debug_anchors():
			_draw_debug_anchor(debug_anchor)
		for segment in get_debug_segments():
			var segment_color := debug_input_color if bool(segment.get("is_input", false)) else debug_output_color
			draw_line(segment["from"], segment["to"], segment_color, debug_line_width)

func _draw_path_wave(wave: Dictionary) -> void:
	var points: Array = wave.get("points", [])
	if points.size() < 2:
		return
	var color: Color = wave.get("color", path_wave_color)
	color.a *= float(wave.get("alpha", 1.0))
	var width := float(wave.get("width", path_wave_width))
	var head_progress := clampf(float(wave.get("head_progress", 1.0)), 0.0, 1.0)
	var head := _get_point_on_polyline(points, head_progress)
	draw_circle(head, width * 2.6, Color(color.r, color.g, color.b, color.a * 0.24))
	draw_circle(head, width * 1.35, Color(color.r, color.g, color.b, color.a * 0.58))
	draw_circle(head, max(1.0, width * 0.58), color)

func _draw_energy_stream(stream: Dictionary) -> void:
	var points: Array = stream.get("points", [])
	if points.size() < 2:
		return
	var color: Color = stream.get("color", energy_stream_color)
	color.a *= float(stream.get("alpha", 1.0))
	var glow_width := float(stream.get("glow_width", energy_stream_glow_width))
	var core_width := float(stream.get("core_width", energy_stream_width))
	var shimmer_width := float(stream.get("shimmer_width", energy_stream_shimmer_width))
	_draw_polyline(points, Color(color.r, color.g, color.b, color.a * 0.18), glow_width)
	_draw_polyline(points, Color(color.r, color.g, color.b, color.a * 0.44), max(core_width * 1.7, core_width + 1.0))
	_draw_polyline(points, Color(color.r, color.g, color.b, color.a * 0.78), core_width)
	var tail_progress := float(stream.get("shimmer_tail_progress", 0.0))
	var head_progress := float(stream.get("shimmer_head_progress", 1.0))
	_draw_wrapped_polyline_window(points, tail_progress, head_progress, Color(color.r, color.g, color.b, min(1.0, color.a * 1.28)), shimmer_width)

func _draw_lightning_arc(arc: Dictionary) -> void:
	var texture = lightning_texture
	if texture == null:
		return
	var frame_index: int = int(arc.get("frame_index", 0))
	var frame_width: int = lightning_frame_size.x
	var frame_height: int = lightning_frame_size.y
	if frame_width <= 0 or frame_height <= 0:
		return
	var column: int = frame_index % lightning_columns
	var row: int = int(frame_index / lightning_columns) % lightning_rows
	var source_rect := Rect2(Vector2(column * frame_width, row * frame_height), Vector2(frame_width, frame_height))
	var draw_rect := Rect2(Vector2(-frame_width * 0.5, -frame_height * 0.5), Vector2(frame_width, frame_height))
	var color: Color = arc.get("color", lightning_color)
	color.a *= clampf(float(arc.get("alpha", lightning_alpha)), 0.0, 1.0)
	var position = arc.get("position", Vector2.ZERO)
	var rotation: float = float(arc.get("rotation", 0.0))
	var scale: float = float(arc.get("scale", 1.0))
	draw_set_transform(position, rotation, Vector2.ONE * scale)
	draw_texture_rect_region(texture, draw_rect, source_rect, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_pipe_aura(hum: Dictionary, color: Color) -> void:
	var points: Array = hum.get("points", [])
	if points.size() < 2:
		return
	var glow_width := float(hum.get("glow_width", idle_hum_glow_width))
	var core_width := float(hum.get("core_width", idle_hum_core_width))
	_draw_polyline(points, Color(color.r, color.g, color.b, color.a * 0.16), glow_width)
	_draw_polyline(points, Color(color.r, color.g, color.b, color.a * 0.34), max(core_width * 1.8, core_width + 1.0))
	_draw_polyline(points, Color(color.r, color.g, color.b, color.a * 0.72), core_width)

func _draw_polyline(points: Array, color: Color, width: float) -> void:
	for i in range(points.size() - 1):
		var start: Vector2 = points[i]
		var end: Vector2 = points[i + 1]
		draw_line(start, end, color, width)

func _draw_wrapped_polyline_window(points: Array, tail_progress: float, head_progress: float, color: Color, width: float) -> void:
	var tail := tail_progress
	var head := fposmod(head_progress, 1.0)
	if tail < 0.0:
		_draw_polyline(_get_polyline_window(points, 0.0, head), color, width)
		_draw_polyline(_get_polyline_window(points, 1.0 + tail, 1.0), color, width)
		return
	_draw_polyline(_get_polyline_window(points, tail, head), color, width)

func _draw_directional_trail(trail: Dictionary) -> void:
	var points: Array = trail.get("points", [])
	if points.size() < 2:
		return
	var color: Color = trail.get("color", trail_color)
	color.a *= float(trail.get("alpha", 1.0))
	var width := float(trail.get("width", trail_width))
	var progress := clampf(float(trail.get("progress", 1.0)), 0.0, 1.0)
	var partial_points := _get_partial_polyline(points, progress)
	for i in range(partial_points.size() - 1):
		draw_line(partial_points[i], partial_points[i + 1], color, width)
		draw_line(partial_points[i], partial_points[i + 1], Color(color.r, color.g, color.b, color.a * 0.35), width * 2.1)

func _draw_rotation_spark(spark: Dictionary) -> void:
	var color: Color = spark.get("color", rotation_spark_color)
	color.a *= float(spark.get("alpha", 1.0))
	var position: Vector2 = spark.get("position", Vector2.ZERO)
	var radius := float(spark.get("radius", cell_size * rotation_spark_radius_ratio))
	var width := float(spark.get("width", rotation_spark_width))
	var ray_count: int = max(1, int(spark.get("ray_count", rotation_spark_ray_count)))
	for i in range(ray_count):
		var angle: float = TAU * float(i) / float(ray_count)
		var inner: Vector2 = position + Vector2(cos(angle), sin(angle)) * radius * 0.35
		var outer: Vector2 = position + Vector2(cos(angle), sin(angle)) * radius
		draw_line(inner, outer, color, width)
	draw_arc(position, radius * 0.55, 0.0, TAU, 24, Color(color.r, color.g, color.b, color.a * 0.58), width)

func _draw_win_burst(burst: Dictionary) -> void:
	var color: Color = burst.get("color", win_burst_color)
	color.a *= float(burst.get("alpha", 1.0))
	var position: Vector2 = burst.get("position", Vector2.ZERO)
	var radius := float(burst.get("radius", cell_size * win_burst_radius_ratio))
	var width := float(burst.get("ring_width", win_burst_ring_width))
	draw_arc(position, radius, 0.0, TAU, 36, color, width)
	draw_circle(position, radius * 0.18, Color(color.r, color.g, color.b, color.a * 0.25))

func _get_partial_polyline(points: Array, progress: float) -> Array:
	if points.size() <= 1:
		return points
	var total_length := 0.0
	for i in range(points.size() - 1):
		total_length += (points[i + 1] as Vector2).distance_to(points[i] as Vector2)
	if total_length <= 0.0:
		return [points[0]]
	var remaining := total_length * clampf(progress, 0.0, 1.0)
	var result := [points[0]]
	for i in range(points.size() - 1):
		var start: Vector2 = points[i]
		var end: Vector2 = points[i + 1]
		var segment_length := start.distance_to(end)
		if remaining >= segment_length:
			result.append(end)
			remaining -= segment_length
		else:
			var t := remaining / segment_length if segment_length > 0.0 else 0.0
			result.append(start.lerp(end, t))
			break
	return result

func _get_polyline_window(points: Array, start_progress: float, end_progress: float) -> Array:
	if points.size() <= 1:
		return points
	var start := clampf(start_progress, 0.0, 1.0)
	var end := clampf(end_progress, 0.0, 1.0)
	if end <= start:
		return [_get_point_on_polyline(points, end)]
	var result := [_get_point_on_polyline(points, start)]
	for i in range(points.size()):
		var point_progress := _get_point_progress_on_polyline(points, i)
		if point_progress > start and point_progress < end:
			result.append(points[i])
	result.append(_get_point_on_polyline(points, end))
	return result

func _get_point_on_polyline(points: Array, progress: float) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	if points.size() == 1:
		return points[0]
	var total_length := _get_polyline_length(points)
	if total_length <= 0.0:
		return points[0]
	var remaining := total_length * clampf(progress, 0.0, 1.0)
	for i in range(points.size() - 1):
		var start: Vector2 = points[i]
		var end: Vector2 = points[i + 1]
		var segment_length := start.distance_to(end)
		if remaining <= segment_length:
			var t := remaining / segment_length if segment_length > 0.0 else 0.0
			return start.lerp(end, t)
		remaining -= segment_length
	return points[points.size() - 1]

func _get_point_progress_on_polyline(points: Array, point_index: int) -> float:
	if point_index <= 0:
		return 0.0
	var total_length := _get_polyline_length(points)
	if total_length <= 0.0:
		return 0.0
	var length := 0.0
	for i in range(min(point_index, points.size() - 1)):
		length += (points[i + 1] as Vector2).distance_to(points[i] as Vector2)
	return clampf(length / total_length, 0.0, 1.0)

func _get_polyline_length(points: Array) -> float:
	var total_length := 0.0
	for i in range(points.size() - 1):
		total_length += (points[i + 1] as Vector2).distance_to(points[i] as Vector2)
	return total_length

func _make_contact_key(a: Vector2i, b: Vector2i) -> String:
	var first := a
	var second := b
	if b.x < a.x or (b.x == a.x and b.y < a.y):
		first = b
		second = a
	return "%d,%d>%d,%d" % [first.x, first.y, second.x, second.y]

func _get_direction_offset(direction: int) -> Vector2i:
	match direction:
		0:
			return Vector2i(0, -1)
		1:
			return Vector2i(1, 0)
		2:
			return Vector2i(0, 1)
		3:
			return Vector2i(-1, 0)
	return Vector2i.ZERO

func _draw_debug_anchor(debug_anchor: Dictionary) -> void:
	var anchors: Dictionary = debug_anchor.get("anchors", {})
	var center: Vector2 = debug_anchor.get("energy_center", Vector2.ZERO)
	var junction: Vector2 = debug_anchor.get("route_junction", center)
	draw_circle(center, max(2.0, cell_size * 0.028), debug_order_color)
	draw_circle(junction, max(2.0, cell_size * 0.024), debug_output_color)
	for port_name in VfxAnchorScript.PORT_NAMES:
		if anchors.has(port_name):
			draw_circle(anchors[port_name], max(1.5, cell_size * 0.018), debug_anchor_color)
