# Live VFX Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build live electric VFX transitions for gameplay rotations while keeping solver and `FlowVisualState` as SSOT.

**Architecture:** Add a focused transition diff helper, feed transition data from `GameScene.try_rotate_cell(...)` into `PipeVfxLayer`, and let `PipeVfxLayer` draw decay/error/debug effects from theme-configured SSOT fields. Existing source emission, target pulse, contact spark, directional trail, and idle hum stay in the VFX layer.

**Tech Stack:** Godot 4.3 GDScript, existing `SceneTree` test scripts, `ThemeConfig` resource fields, `PipeVfxLayer` drawing.

---

## File Structure

- Create `Scripts/vfx_transition_state.gd`: pure data helper for diffing previous/current `FlowVisualState`.
- Modify `Scripts/pipe_vfx_layer.gd`: store transition data, expose decay/error/debug data methods, draw new effects.
- Modify `Scenes/Gameplay/GameScene.gd`: capture previous flow, recompute current flow, send transition to VFX layer, clear transition on reset.
- Modify `Resources/Classes/ThemeConfig.gd`: add VFX SSOT fields for disconnect decay, error spark, debug overlay.
- Modify `Resources/Data/Themes/cyberpunk_theme.tres`: assign cyber values to new fields.
- Create tests:
  - `Tests/test_vfx_transition_state.gd`
  - `Tests/test_pipe_vfx_disconnect_decay.gd`
  - `Tests/test_pipe_vfx_error_spark.gd`
  - `Tests/test_game_scene_vfx_transition_hooks.gd`
  - `Tests/test_vfx_debug_overlay_contract.gd`
- Create captures:
  - `Tests/capture_live_vfx_integration.gd`
  - `Tests/capture_vfx_debug_overlay.gd`
- Modify `docs/fake3d_vfx_checklist.md`: check off Step 17 after verification.

---

### Task 1: Transition State Diff Helper

**Files:**
- Create: `Scripts/vfx_transition_state.gd`
- Test: `Tests/test_vfx_transition_state.gd`

- [ ] **Step 1: Write failing test**

Create `Tests/test_vfx_transition_state.gd`:

```gdscript
extends SceneTree

const VfxTransitionStateScript = preload("res://Scripts/vfx_transition_state.gd")

func _init() -> void:
	var passed := true
	var previous := {
		Vector2i(0, 0): {"cell_pos": Vector2i(0, 0), "input_dir": -1, "output_dirs": [1], "age": 0.5},
		Vector2i(1, 0): {"cell_pos": Vector2i(1, 0), "input_dir": 3, "output_dirs": [1], "age": 0.4},
		Vector2i(2, 0): {"cell_pos": Vector2i(2, 0), "input_dir": 3, "output_dirs": [], "age": 0.3}
	}
	var current := {
		Vector2i(0, 0): {"cell_pos": Vector2i(0, 0), "input_dir": -1, "output_dirs": [2], "age": 0.0},
		Vector2i(0, 1): {"cell_pos": Vector2i(0, 1), "input_dir": 0, "output_dirs": [], "age": 0.0}
	}
	var transition: Dictionary = VfxTransitionStateScript.build(previous, current, Vector2i(0, 0), 9.5)

	passed = passed and _assert_equal(transition.get("changed_cell"), Vector2i(0, 0), "changed cell should be stored")
	passed = passed and _assert_equal(transition.get("event_time"), 9.5, "event time should be stored")
	passed = passed and _assert_true(transition.get("entered_cells", []).has(Vector2i(0, 1)), "entered cells should include new powered cell")
	passed = passed and _assert_true(transition.get("lost_cells", []).has(Vector2i(1, 0)), "lost cells should include removed powered cell")
	passed = passed and _assert_true(transition.get("lost_cells", []).has(Vector2i(2, 0)), "lost cells should include old target")
	passed = passed and _assert_true(_has_contact(transition.get("entered_contacts", []), Vector2i(0, 0), 2, Vector2i(0, 1)), "entered contacts should include source south")
	passed = passed and _assert_true(_has_contact(transition.get("lost_contacts", []), Vector2i(0, 0), 1, Vector2i(1, 0)), "lost contacts should include broken east")

	if passed:
		print("test_vfx_transition_state: PASS")
		quit(0)
	else:
		print("test_vfx_transition_state: FAIL")
		quit(1)

func _has_contact(contacts: Array, cell_pos: Vector2i, direction: int, neighbor_pos: Vector2i) -> bool:
	for contact in contacts:
		if contact.get("cell_pos") == cell_pos and int(contact.get("direction", -1)) == direction and contact.get("neighbor_pos") == neighbor_pos:
			return true
	return false

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
```

- [ ] **Step 2: Run test to verify RED**

Run:

```powershell
& 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe' --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' -s 'res://Tests/test_vfx_transition_state.gd'
```

Expected: FAIL because `res://Scripts/vfx_transition_state.gd` does not exist.

- [ ] **Step 3: Implement helper**

Create `Scripts/vfx_transition_state.gd`:

```gdscript
extends RefCounted
class_name VfxTransitionState

const DIRECTIONS := [
	Vector2i(0, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0)
]

static func build(previous_flow_state: Dictionary, current_flow_state: Dictionary, changed_cell: Vector2i, event_time: float) -> Dictionary:
	var previous_copy := previous_flow_state.duplicate(true)
	var current_copy := current_flow_state.duplicate(true)
	return {
		"previous_flow_state": previous_copy,
		"current_flow_state": current_copy,
		"changed_cell": changed_cell,
		"entered_cells": _get_entered_cells(previous_copy, current_copy),
		"lost_cells": _get_lost_cells(previous_copy, current_copy),
		"entered_contacts": _get_entered_contacts(previous_copy, current_copy),
		"lost_contacts": _get_lost_contacts(previous_copy, current_copy),
		"event_time": event_time
	}
```

Add private helpers `_get_entered_cells`, `_get_lost_cells`, `_get_contacts`, `_get_entered_contacts`, `_get_lost_contacts`, and `_contact_key` in the same file. Use `input_dir` and each `output_dirs` direction to build contact dictionaries.

- [ ] **Step 4: Run GREEN**

Run same command. Expected: `test_vfx_transition_state: PASS`.

---

### Task 2: Theme SSOT Fields

**Files:**
- Modify: `Resources/Classes/ThemeConfig.gd`
- Modify: `Resources/Data/Themes/cyberpunk_theme.tres`
- Test: `Tests/test_vfx_debug_overlay_contract.gd`

- [ ] **Step 1: Write failing SSOT test**

Create `Tests/test_vfx_debug_overlay_contract.gd`:

```gdscript
extends SceneTree

const THEME_PATH = "res://Resources/Data/Themes/cyberpunk_theme.tres"

func _init() -> void:
	var passed := true
	var theme = load(THEME_PATH)
	for property_name in [
		"vfx_disconnect_decay_duration",
		"vfx_disconnect_decay_alpha",
		"vfx_error_spark_color",
		"vfx_error_spark_duration",
		"vfx_error_spark_radius_ratio",
		"vfx_debug_anchor_color",
		"vfx_debug_input_color",
		"vfx_debug_output_color",
		"vfx_debug_order_color"
	]:
		passed = passed and _assert_true(_has_property(theme, property_name), "Theme should own %s" % property_name)
	passed = passed and _assert_true(float(theme.get("vfx_disconnect_decay_duration")) > 0.0, "Disconnect decay duration should be positive")
	passed = passed and _assert_true(float(theme.get("vfx_error_spark_duration")) > 0.0, "Error spark duration should be positive")

	if passed:
		print("test_vfx_debug_overlay_contract: PASS")
		quit(0)
	else:
		print("test_vfx_debug_overlay_contract: FAIL")
		quit(1)

func _has_property(resource: Resource, property_name: String) -> bool:
	for info in resource.get_property_list():
		if String(info.get("name", "")) == property_name:
			return true
	return false

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
```

- [ ] **Step 2: Run RED**

Expected: FAIL naming missing fields.

- [ ] **Step 3: Add fields**

Add to `ThemeConfig.gd` under `"VFX Visuals"`:

```gdscript
@export var vfx_disconnect_decay_color: Color = Color(0.22, 1.0, 0.08, 0.32)
@export var vfx_disconnect_decay_duration: float = 0.32
@export var vfx_disconnect_decay_alpha: float = 0.28
@export var vfx_error_spark_color: Color = Color(1.0, 0.28, 0.08, 0.82)
@export var vfx_error_spark_duration: float = 0.18
@export var vfx_error_spark_radius_ratio: float = 0.1
@export var vfx_debug_anchor_color: Color = Color(1.0, 1.0, 1.0, 0.8)
@export var vfx_debug_input_color: Color = Color(1.0, 0.32, 0.08, 0.85)
@export var vfx_debug_output_color: Color = Color(0.22, 1.0, 0.08, 0.85)
@export var vfx_debug_order_color: Color = Color(0.1, 0.75, 1.0, 0.85)
```

Add corresponding values to `cyberpunk_theme.tres`.

- [ ] **Step 4: Run GREEN**

Expected: `test_vfx_debug_overlay_contract: PASS`.

---

### Task 3: PipeVfxLayer Transition Effects

**Files:**
- Modify: `Scripts/pipe_vfx_layer.gd`
- Test: `Tests/test_pipe_vfx_disconnect_decay.gd`
- Test: `Tests/test_pipe_vfx_error_spark.gd`

- [ ] **Step 1: Write failing disconnect decay test**

Create `Tests/test_pipe_vfx_disconnect_decay.gd` with a `PipeVfxLayer`, cyber theme geometry, a transition containing `lost_cells`, and assertions that `get_disconnect_decays()` returns one decay using theme color/alpha/duration and geometry `energy_center`.

- [ ] **Step 2: Run RED**

Expected: FAIL because `get_disconnect_decays()` is missing.

- [ ] **Step 3: Write failing error spark test**

Create `Tests/test_pipe_vfx_error_spark.gd` with a transition containing a `lost_contacts` entry and assert `get_error_sparks()` returns one spark at the lost contact port anchor.

- [ ] **Step 4: Run RED**

Expected: FAIL because `get_error_sparks()` is missing.

- [ ] **Step 5: Implement minimal layer API**

Add to `PipeVfxLayer`:

```gdscript
var transition_state: Dictionary = {}
var disconnect_decay_color := Color(0.22, 1.0, 0.08, 0.32)
var disconnect_decay_duration := 0.32
var disconnect_decay_alpha := 0.28
var error_spark_color := Color(1.0, 0.28, 0.08, 0.82)
var error_spark_duration := 0.18
var error_spark_radius_ratio := 0.1
var debug_anchor_color := Color(1.0, 1.0, 1.0, 0.8)
var debug_input_color := Color(1.0, 0.32, 0.08, 0.85)
var debug_output_color := Color(0.22, 1.0, 0.08, 0.85)
var debug_order_color := Color(0.1, 0.75, 1.0, 0.85)

func set_transition_state(new_transition_state: Dictionary) -> void:
	transition_state = new_transition_state.duplicate(true)
	queue_redraw()

func clear_transition_state() -> void:
	transition_state.clear()
	queue_redraw()
```

Add `get_disconnect_decays()` and `get_error_sparks()` using `transition_state.event_time`, `Time.get_ticks_msec() / 1000.0`, `geometry_by_cell`, and `VfxAnchorScript.get_anchor_points(...)`.

- [ ] **Step 6: Draw effects**

In `_draw()`, draw disconnect decays before active trails and error sparks after normal contact sparks.

- [ ] **Step 7: Run GREEN**

Expected: both new tests PASS.

---

### Task 4: GameScene Transition Hook

**Files:**
- Modify: `Scenes/Gameplay/GameScene.gd`
- Test: `Tests/test_game_scene_vfx_transition_hooks.gd`

- [ ] **Step 1: Write failing test**

Create `Tests/test_game_scene_vfx_transition_hooks.gd` that instantiates `GameScene`, installs a small grid, installs a `PipeVfxLayer`, calls `try_rotate_cell(...)`, and asserts `pipe_vfx_layer.transition_state` contains `previous_flow_state`, `current_flow_state`, `changed_cell`, `entered_cells`, and `lost_contacts`.

- [ ] **Step 2: Run RED**

Expected: FAIL because `GameScene` does not send transition state.

- [ ] **Step 3: Implement hook**

Add preload:

```gdscript
const VfxTransitionStateScript = preload("res://Scripts/vfx_transition_state.gd")
```

In `try_rotate_cell(...)`, capture previous state before rotation, rebuild current state after solver update, then:

```gdscript
var transition := VfxTransitionStateScript.build(previous_flow_state, flow_visual_state, cell_pos, Time.get_ticks_msec() / 1000.0)
if pipe_vfx_layer != null and pipe_vfx_layer.has_method("set_transition_state"):
	pipe_vfx_layer.set_transition_state(transition)
```

In `reset_current_level(...)`, call `pipe_vfx_layer.clear_transition_state()` when available.

- [ ] **Step 4: Run GREEN**

Expected: `test_game_scene_vfx_transition_hooks: PASS`.

---

### Task 5: Debug Overlay Data

**Files:**
- Modify: `Scripts/pipe_vfx_layer.gd`
- Test: `Tests/test_vfx_debug_overlay_contract.gd`

- [ ] **Step 1: Extend test**

Extend `test_vfx_debug_overlay_contract.gd` to instantiate `PipeVfxLayer`, set flow context, set `debug_visible`, and assert `get_debug_anchors()` returns anchor/order/input/output dictionaries.

- [ ] **Step 2: Run RED**

Expected: FAIL because `get_debug_anchors()` is missing.

- [ ] **Step 3: Implement debug data and draw**

Add `get_debug_anchors()` returning data-only entries:

```gdscript
{
	"cell_pos": cell_pos,
	"order": int(entry.get("order", -1)),
	"energy_center": energy_center,
	"input_dir": input_dir,
	"output_dirs": output_dirs.duplicate(),
	"anchors": anchors
}
```

In `_draw()`, when `debug_visible`, draw small circles for anchors and colored lines for input/output directions using theme colors.

- [ ] **Step 4: Run GREEN**

Expected: debug overlay test PASS.

---

### Task 6: Live Captures

**Files:**
- Create: `Tests/capture_live_vfx_integration.gd`
- Create: `Tests/capture_vfx_debug_overlay.gd`

- [ ] **Step 1: Add live VFX capture**

Create a deterministic scene fixture that captures:

- `debug/live_vfx_before.png`
- `debug/live_vfx_connected.png`
- `debug/live_vfx_disconnected.png`

It must rotate through `try_rotate_cell(...)`, assert transition state exists, assert VFX layer reports trail/spark/pulse/decay/error data, and save screenshots.

- [ ] **Step 2: Run capture**

Expected: `capture_live_vfx_integration: PASS`.

- [ ] **Step 3: Add debug overlay capture**

Create `capture_vfx_debug_overlay.gd` that enables `pipe_vfx_layer.debug_visible`, captures `debug/vfx_debug_overlay.png`, and asserts debug anchor data exists.

- [ ] **Step 4: Run capture**

Expected: `capture_vfx_debug_overlay: PASS`.

---

### Task 7: Checklist And Verification

**Files:**
- Modify: `docs/fake3d_vfx_checklist.md`

- [ ] **Step 1: Check off Step 17 items**

Mark only items implemented and verified.

- [ ] **Step 2: Run full tests**

Run all `Tests/test_*.gd`. Expected: every test exits code 0.

- [ ] **Step 3: Run all captures**

Run all `Tests/capture_*.gd`. Expected: every capture exits code 0 and PNGs exist.

- [ ] **Step 4: Restart Godot debug**

Restart helper and verify `127.0.0.1:9090` is listening.

