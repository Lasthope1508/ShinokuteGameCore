# Lightning Arc VFX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add sparse lightning arc accents to powered pipe routes without duplicate effects on adjacent tiles.

**Architecture:** Keep `ThemeConfig` and `cyberpunk_theme.tres` as SSOT for texture, frame layout, timing, density, and caps. `PipeVfxLayer` owns lightning data and draw logic through `get_lightning_arcs(now)`, using `FlowVisualState`, geometry anchors, and canonical route points. Shared contacts use canonical edge keys so neighboring cells cannot both draw the same lightning arc.

**Tech Stack:** Godot 4.3 GDScript, `PipeVfxLayer`, `ThemeConfig`, `.tres` theme resources, headless Godot tests and capture scripts.

---

### Task 1: RED Contract Test

**Files:**
- Create: `Tests/test_pipe_vfx_lightning_arcs.gd`

- [x] **Step 1: Write the failing test**

Create a Godot `SceneTree` test that asserts:
- `ThemeConfig` owns lightning SSOT fields.
- `PipeVfxLayer` exposes `get_lightning_arcs(now)`.
- Lightning count is capped by `vfx_lightning_max_arcs`.
- Arcs have deterministic canonical `contact_key`.
- Adjacent powered cells do not duplicate one shared contact.

- [x] **Step 2: Run test to verify it fails**

Run:

```powershell
& 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe' --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' -s res://Tests/test_pipe_vfx_lightning_arcs.gd
```

Expected: FAIL because `get_lightning_arcs` and `vfx_lightning_*` fields do not exist yet.

### Task 2: Theme SSOT And Asset

**Files:**
- Copy: `C:\Users\Admin\Desktop\Godot Casual Games\VFX\lightning_boltarc_01_spritesheet.png` to `Assets\VFX\lightning_boltarc_01_spritesheet.png`
- Modify: `Resources/Classes/ThemeConfig.gd`
- Modify: `Resources/Data/Themes/cyberpunk_theme.tres`

- [x] **Step 1: Add exported SSOT fields**

Add lightning exports beside existing VFX fields:

```gdscript
@export var vfx_lightning_enabled: bool = true
@export var vfx_lightning_texture: Texture2D
@export var vfx_lightning_frame_size: Vector2i = Vector2i(256, 256)
@export var vfx_lightning_columns: int = 6
@export var vfx_lightning_rows: int = 4
@export var vfx_lightning_period: float = 0.42
@export var vfx_lightning_alpha: float = 0.72
@export var vfx_lightning_scale_ratio: float = 0.78
@export var vfx_lightning_max_arcs: int = 10
@export var vfx_lightning_cell_stride: int = 3
@export var vfx_lightning_min_order_progress: float = 0.18
@export var vfx_lightning_contact_bias: float = 0.68
```

- [x] **Step 2: Reference the spritesheet in cyber theme**

Add an `ExtResource` for `res://Assets/VFX/lightning_boltarc_01_spritesheet.png` and assign all lightning values in the theme resource. Do not add fallback paths.

### Task 3: GREEN Data And Draw

**Files:**
- Modify: `Scripts/pipe_vfx_layer.gd`

- [x] **Step 1: Add layer fields and theme application**

Mirror theme fields in `PipeVfxLayer`, scale frame draw size from `cell_size`, and queue redraw on theme apply.

- [x] **Step 2: Add `get_lightning_arcs(now)`**

Rules:
- Return empty if disabled, missing texture, no cell size, no flow, or max arcs is zero.
- Use only powered cells with non-empty `output_dirs` and non-zero `flow_mask`.
- Skip arcs until `order / max_order >= vfx_lightning_min_order_progress`.
- Prefer shared contacts with neighbors in flow state using a canonical key like `"x1,y1>x2,y2"`.
- Select one owner per shared contact by canonical key.
- Use deterministic sparse selection by `order`, `cell_stride`, and `now / period`.
- Cap output by `vfx_lightning_max_arcs`.

- [x] **Step 3: Draw lightning sheet frames**

Draw selected frame regions from the texture, rotated along the route segment/contact direction, using alpha and scale from theme. Draw after `idle_hum`, before `path_wave`.

- [x] **Step 4: Include active motion**

`has_active_motion()` returns true when lightning is enabled and can draw at least one arc.

### Task 4: Docs, Catalog, Checklist, Performance

**Files:**
- Modify: `docs/vfx_effect_parameters.md`
- Modify: `docs/fake3d_vfx_checklist.md`
- Modify: `Tests/test_vfx_effect_parameter_catalog.gd`
- Modify: `Tests/test_vfx_performance_10x10.gd`

- [x] **Step 1: Document `lightning_arc`**

Add trigger, anchor, duplicate rule, and parameter list to the VFX parameter catalog.

- [x] **Step 2: Add checklist step**

Add `## 25. Lightning Arc Accent` with SSOT, dedupe, sparse selection, tests, and capture status.

- [x] **Step 3: Extend catalog test**

Require `lightning_arc`, `vfx_lightning_texture`, `vfx_lightning_max_arcs`, `vfx_lightning_cell_stride`, and `canonical contact key`.

- [x] **Step 4: Extend performance test**

Include `get_lightning_arcs(SAMPLE_TIME)` in the total record count and assert it respects `vfx_lightning_max_arcs`.

### Task 5: Capture And Verification

**Files:**
- Create: `Tests/capture_vfx_lightning_arcs.gd`

- [x] **Step 1: Add visual capture**

Create a deterministic capture that opens a small board, enables lightning, waits for a frame, writes `debug/vfx_lightning_arcs.png`, and asserts at least one lightning arc record exists.

- [x] **Step 2: Run targeted tests**

Run:

```powershell
& 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe' --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' -s res://Tests/test_pipe_vfx_lightning_arcs.gd
& 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe' --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' -s res://Tests/test_vfx_effect_parameter_catalog.gd
& 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe' --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' -s res://Tests/test_vfx_performance_10x10.gd
& 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe' --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' -s res://Tests/capture_vfx_lightning_arcs.gd
```

Expected: all PASS and capture file written.
