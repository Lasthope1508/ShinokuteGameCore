extends SceneTree

const PipeVfxLayerScript = preload("res://Scripts/pipe_vfx_layer.gd")
const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	var layer = PipeVfxLayerScript.new()
	layer.apply_theme_config(theme, 100.0)

	passed = passed and _assert_true(layer.has_method("has_active_motion"), "PipeVfxLayer should expose active motion state")
	passed = passed and _assert_true(layer.has_method("_process"), "PipeVfxLayer should own runtime redraw scheduling")

	if layer.has_method("has_active_motion"):
		layer.set_visual_context(_make_flow_state(0.08), {Vector2i(1, 0): theme.get_asset_geometry("I")}, Vector2.ZERO, 100.0)
		passed = passed and _assert_true(layer.has_active_motion(), "Fresh trail should keep VFX layer animating")

		layer.set_visual_context(_make_flow_state(5.0, 0), {Vector2i(1, 0): theme.get_asset_geometry("I")}, Vector2.ZERO, 100.0)
		passed = passed and _assert_false(layer.has_active_motion(), "Expired non-transition flow should stop runtime redraw")

		var event_time := Time.get_ticks_msec() / 1000.0 - 0.05
		layer.set_transition_state({
			"lost_cells": [Vector2i(1, 0)],
			"lost_contacts": [{"cell_pos": Vector2i(1, 0), "direction": 1, "neighbor_pos": Vector2i(2, 0)}],
			"event_time": event_time
		})
		passed = passed and _assert_true(layer.has_active_motion(event_time + 0.06), "Active transition effect should keep VFX layer animating")
		passed = passed and _assert_false(layer.has_active_motion(event_time + 5.0), "Expired transition effect should stop runtime redraw")

	layer.free()
	if passed:
		print("test_pipe_vfx_motion_redraw_contract: PASS")
		quit(0)
	else:
		print("test_pipe_vfx_motion_redraw_contract: FAIL")
		quit(1)

func _make_flow_state(age: float, flow_mask: int = 10) -> Dictionary:
	return {
		Vector2i(1, 0): {
			"cell_pos": Vector2i(1, 0),
			"input_dir": 3,
			"output_dirs": [1],
			"age": age,
			"flow_mask": flow_mask,
			"order": 1
		}
	}

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true

func _assert_false(condition: bool, message: String) -> bool:
	if condition:
		push_error("%s: expected false" % message)
		return false
	return true
