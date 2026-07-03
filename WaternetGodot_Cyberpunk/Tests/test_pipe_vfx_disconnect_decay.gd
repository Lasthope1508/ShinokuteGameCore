extends SceneTree

const PipeVfxLayerScript = preload("res://Scripts/pipe_vfx_layer.gd")
const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var layer = PipeVfxLayerScript.new()
	layer.apply_theme_config(theme, 100.0)
	layer.set_visual_context(
		{},
		{Vector2i(1, 0): theme.get_asset_geometry("I")},
		Vector2.ZERO,
		100.0
	)

	passed = passed and _assert_true(layer.has_method("set_transition_state"), "PipeVfxLayer should accept transition state")
	passed = passed and _assert_true(layer.has_method("get_disconnect_decays"), "PipeVfxLayer should expose disconnect decay data")
	if layer.has_method("set_transition_state") and layer.has_method("get_disconnect_decays"):
		layer.set_transition_state({
			"lost_cells": [Vector2i(1, 0)],
			"event_time": Time.get_ticks_msec() / 1000.0 - 0.05
		})
		var decays: Array = layer.get_disconnect_decays()
		passed = passed and _assert_equal(decays.size(), 1, "One lost cell should produce one decay")
		if decays.size() == 1:
			var decay: Dictionary = decays[0]
			passed = passed and _assert_equal(decay.get("cell_pos", Vector2i(-1, -1)), Vector2i(1, 0), "Decay should belong to lost cell")
			passed = passed and _assert_vec2_close(decay.get("position", Vector2.ZERO), Vector2(150.0, 50.0), "Decay should use geometry energy center")
			passed = passed and _assert_equal(decay.get("color", Color.BLACK), theme.vfx_disconnect_decay_color, "Decay color should come from theme")
			passed = passed and _assert_true(float(decay.get("alpha", 0.0)) > 0.0, "Decay alpha should be positive inside duration")

	layer.free()
	if passed:
		print("test_pipe_vfx_disconnect_decay: PASS")
		quit(0)
	else:
		print("test_pipe_vfx_disconnect_decay: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true

func _assert_vec2_close(actual: Vector2, expected: Vector2, message: String) -> bool:
	if actual.distance_to(expected) > 0.01:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true
