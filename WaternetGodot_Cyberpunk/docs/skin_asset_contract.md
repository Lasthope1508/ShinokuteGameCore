# Skin Asset Contract

Purpose: keep every future skin compatible with gameplay, fake3D, energy overlays, and VFX without tuning `GameScene` per skin.

## SSOT

- Required asset keys come from `ThemeConfig.get_required_asset_keys()`.
- Geometry resources live on `ThemeConfig`: `cell`, `source`, `target`, `cap`, `I`, `L`, `T`, `X`.
- Every geometry resource must be an `AssetGeometryConfig`-compatible resource.
- Every skin must pass `ThemeConfig.validate_geometry_manifest()` before visual tuning.

## Geometry Fields

Each asset geometry must define:

- `asset_key`
- `frame_size`
- `draw_origin`
- `center`
- `content_rect`
- `energy_rect`
- `route_junction`
- `north_port`
- `east_port`
- `south_port`
- `west_port`

Frame, origin, rects, ports, and route junctions are asset data. Do not compensate for bad asset geometry inside `GameScene`.

Use `energy_rect` for glow centers and `route_junction` for pipe-flow routing. These points may differ.

## Required Checks

Run these after creating or changing a skin:

```powershell
& 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe' --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' -s 'res://Tests/test_skin_geometry_pipeline_contract.gd'
& 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe' --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' -s 'res://Tests/test_theme_geometry_ssot.gd'
& 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe' --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' -s 'res://Tests/test_asset_geometry_contract.gd'
& 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe' --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' -s 'res://Tests/test_asset_port_alignment.gd'
& 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe' --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' -s 'res://Tests/test_vfx_route_points.gd'
& 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe' --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' -s 'res://Tests/capture_fake3d_size_sweep.gd'
```

## Rule

If a pipe does not visually connect, fix the sprite sheet or geometry resource. Do not add a skin-specific offset, scale, or branch in `GameScene`.
