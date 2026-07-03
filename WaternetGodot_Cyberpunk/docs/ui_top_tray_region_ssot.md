# Top Tray Region Coordinate SSOT

Purpose: prevent beautiful generated top tray assets from drifting in Godot because controls are placed by manual offsets.

## Rule

`ThemeConfig.ui_top_tray_region_sets` is the source of truth for all interactive and informational zones inside the gameplay top tray when a theme has separate dark/light top tray source canvases. `ThemeConfig.ui_top_tray_regions` remains the dark/legacy fallback for older themes and tests. Neither field is the placement source for generated art components that form the tray shell.

Runtime nodes must use these regions:

- `LogoCore`
- `TotalPlayTimeLabel`
- `TopLeftStatLabel`
- `TopRightStatLabel`
- `LeftFloatingMenu`
- `RightFloatingReplay`

Generated tray art components use a different contract:

- `GeneratedTopTrayLayer`
- `GeneratedStatsCapsule`
- `GeneratedLogoSocket`

`ThemeConfig.ui_top_tray_art_stack` chooses which generated art components are active. Current cyber value is `["top_tray_layer"]`, so only `GeneratedTopTrayLayer` renders. `stats_capsule` and `logo_socket` remain library assets, but they are inactive until the stack SSOT includes them.

Active tray art nodes stack across the same full `TopTrayLayer` rect. Their placement comes from `ThemeConfig.ui_generated_asset_geometry[*].runtime_region = "full_source"` and the top tray control size, not from `ui_top_tray_regions`.

Do not place these nodes by scene offsets, ad hoc ratios, or visual guessing. Runtime selects `ui_top_tray_region_sets[ThemeConfig.ui_generated_asset_mode]` first, then falls back to `ui_top_tray_regions`.

## Coordinate Space

Each region is a normalized `Vector4(x, y, w, h)`.

- `x`: left edge divided by rendered full `top_tray_layer` source canvas width.
- `y`: top edge divided by rendered full `top_tray_layer` source canvas height.
- `w`: region width divided by rendered full `top_tray_layer` source canvas width.
- `h`: region height divided by rendered full `top_tray_layer` source canvas height.

The basis is the generated top tray asset canvas used by the owner region editor. It is not `TopTrayLayer` control size, not the viewport, and not `top_tray_layer.alpha_bbox`. Runtime fits the full top tray source canvas into `TopTrayLayer`, then places every top tray child from that one rendered canvas rect.

Owner region editors must load clean production object assets such as `top_tray_layer_photoroom.png`. Do not use runtime layout screenshots, because they may already contain text, icons, debug overlays, board captures, or mode-specific composition that would poison the coordinate basis.

Runtime formula:

```gdscript
var basis := _get_top_tray_region_basis(theme, tray_size)
offset_left = basis.position.x + region.x * basis.size.x
offset_top = basis.position.y + region.y * basis.size.y
offset_right = offset_left + region.z * basis.size.x
offset_bottom = offset_top + region.w * basis.size.y
```

## Current Cyber Values

Stored in `Resources/Data/Themes/cyberpunk_theme.tres`.

Dark source canvas: `Vector2(2032, 774)`. Light source canvas: `Vector2(1829, 860)`. The two modes intentionally have separate normalized region sets because the generated source canvases do not share the same aspect ratio.

### Dark

| Region | Vector4 | Runtime meaning |
|---|---:|---|
| `left_floating_menu` | `Vector4(0.0544, 0.7751, 0.0688, 0.2167)` | purple settings/menu button pod, mirrored from replay |
| `left_floating_menu_icon` | `Vector4(0.0862, 0.84, 0.0331, 0.0868)` | optical settings/menu symbol placement inside the button pod |
| `left_stats_readout` | `Vector4(0.147, 0.3494, 0.1843, 0.1843)` | left stat/readout panel, mirrored against the right time/moves panel |
| `logo_core` | `Vector4(0.3908, 0.3076, 0.2122, 0.3988)` | real project logo inside the center socket |
| `right_floating_replay` | `Vector4(0.8768, 0.7751, 0.0688, 0.2167)` | yellow replay button pod |
| `right_floating_replay_icon` | `Vector4(0.9043, 0.84, 0.0331, 0.0868)` | optical replay symbol placement inside the button pod |
| `right_stats_readout` | `Vector4(0.6145, 0.3409, 0.0977, 0.1794)` | right stat/readout panel |
| `total_play_time_readout` | `Vector4(0.6687, 0.3494, 0.1843, 0.1843)` | elapsed play time from level start to solved state |

For the dark `top_tray_layer` source canvas `Vector2(2032, 774)`, these map to local source pixels:

| Region | Pixel rect |
|---|---:|
| `left_floating_menu` | `x=111, y=600, w=140, h=168` |
| `left_floating_menu_icon` | `x=175, y=650, w=67, h=67` |
| `left_stats_readout` | `x=299, y=270, w=374, h=143` |
| `logo_core` | `x=794, y=238, w=431, h=309` |
| `right_floating_replay` | `x=1782, y=600, w=140, h=168` |
| `right_floating_replay_icon` | `x=1838, y=650, w=67, h=67` |
| `right_stats_readout` | `x=1249, y=264, w=199, h=139` |
| `total_play_time_readout` | `x=1359, y=270, w=374, h=143` |

`ThemeConfig.ui_top_tray_region_pixel_rects` stores these pixel rects for audit. Runtime placement still uses `ThemeConfig.ui_top_tray_regions`.

### Light

Owner-approved light values are stored in `ThemeConfig.ui_top_tray_region_sets.light`. The same top tray source canvas is used in portrait and landscape, so icon adjustments remain canonical against `Vector2(1829, 860)`.

| Region | Vector4 | Pixel rect on `Vector2(1829, 860)` |
|---|---:|---:|
| `left_floating_menu` | `Vector4(0.1433, 0.8066, 0.0742, 0.1934)` | `x=262, y=694, w=136, h=166` |
| `left_floating_menu_icon` | `Vector4(0.163958, 0.849153, 0.035616, 0.092832)` | `x=300, y=730, w=65, h=80` |
| `left_stats_readout` | `Vector4(0.1542, 0.4166, 0.1683, 0.129)` | `x=282, y=358, w=308, h=111` |
| `logo_core` | `Vector4(0.41, 0.29, 0.18, 0.36)` | `x=750, y=249, w=329, h=310` |
| `right_floating_replay` | `Vector4(0.7817, 0.8084, 0.0767, 0.1916)` | `x=1430, y=695, w=140, h=165` |
| `right_floating_replay_icon` | `Vector4(0.798786, 0.850601, 0.036816, 0.091968)` | `x=1461, y=732, w=67, h=79` |
| `right_stats_readout` | `Vector4(0.6767, 0.4219, 0.1608, 0.1219)` | `x=1238, y=363, w=294, h=105` |
| `total_play_time_readout` | `Vector4(0.6767, 0.4219, 0.1608, 0.1219)` | `x=1238, y=363, w=294, h=105` |

## Button Icon Ownership

Generated floating button PNGs are button shells only. Runtime overlays the actual symbols from `ThemeConfig.ui_top_tray_button_icon_paths`:

| Button region | Icon region | Icon path |
|---|---|---|
| `left_floating_menu` | `left_floating_menu_icon` | `res://Assets/Icons/menuList.png` |
| `right_floating_replay` | `right_floating_replay_icon` | `res://Assets/Icons/return.png` |

Icon placement comes from explicit `_icon` regions in the active mode region set, not from centered runtime scaling. `ThemeConfig.ui_top_tray_button_icon_scale` is legacy-reserved and must not drive current cyber placement. Do not bake these symbols into the generated shell unless the shell set is regenerated and the SSOT contract is updated.

Owner-approved dark portrait button placement was made in the drag editor against the full PhotoRoom PNGs. Therefore `floating_menu_button_default` and `floating_replay_button_default` must set `runtime_region = "full_source"`. Their `alpha_bbox` values remain audit metadata only; using those bboxes for runtime crop makes Godot diverge from the approved editor preview.

## Text Ownership

Current active top tray text has exactly one owner path:

- `TotalPlayTimeLabel`: elapsed duration on the first row, round move count on the second row, right-aligned. Elapsed time freezes when the level is solved.
- `LeftStatsLabel`: player username on the first row, best wave on the second row, left-aligned inside `left_stats_readout`.

Future stat text owner paths remain reserved but inactive until the text pass:

- `TopRightStatLabel`: `BEST` and score

Legacy `LevelLabel`, `MovesLabel`, and `BestLabel` nodes under `StatsReadout` are forbidden. `StatsCapsule/StatsReadout` may remain as transparent structure only; it must not own text.

`TotalPlayTimeLabel` typography is owned by `ThemeConfig.ui_top_tray_time_*` fields and `ThemeConfig.ui_top_tray_moves_label_prefix`. Current cyber uses `res://Assets/Fonts/Poppins-Bold.ttf`, energy-green text, dark outline, and cyan-green shadow for readability on the generated tray.

`total_play_time_readout` is a hard visual limit, not a loose anchor. Runtime must enable `clip_contents` on `TotalPlayTimeLabel` and fit the font against the owner region after subtracting `ui_top_tray_time_fit_padding_ratio`, outline, and shadow bleed.

`LeftStatsLabel` uses the same font/color/fit contract as `TotalPlayTimeLabel`, but is left-aligned. Username comes from `SaveManager.get_username()`, falling back to `ThemeConfig.ui_top_tray_default_username`. Best wave comes from `SaveManager.get_setting("max_unlocked_level_id", level_id)`.

## Logo Ownership

`res://Assets/Icons/logo.png` is physically trimmed. `ThemeConfig.ui_project_logo_alpha_bbox` must cover the full file, currently `Vector4(0, 0, 423, 485)`. Runtime uses an `AtlasTexture` sourced from the trimmed logo and places `LogoCore` from `ui_top_tray_regions.logo_core`. Text remains blocked until the separate text pass.

## Skin Porting Workflow

1. Generate or import the new top tray asset.
2. Identify the intended readout, logo, menu, and replay zones in the asset.
3. Convert those zones to normalized `Vector4` values relative to the full generated top tray source canvas for that mode.
4. Store normalized values in `ui_top_tray_region_sets[mode]`, source size in `ui_top_tray_region_source_sizes[mode]`, and matching pixel rects in `ui_top_tray_region_pixel_rect_sets[mode]`. Keep `ui_top_tray_regions`, `ui_top_tray_region_source_size`, and `ui_top_tray_region_pixel_rects` as the dark/legacy fallback unless the theme is single-mode.
5. Run:

```powershell
cmd /c ""C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk" --script res://Tests/test_theme_ui_asset_ssot.gd 2>NUL"
cmd /c ""C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk" --script res://Tests/test_game_scene_generated_ui_hooks.gd 2>NUL"
```

6. Run windowed capture:

```powershell
& 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe' --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' --script res://Tests/capture_generated_ui_layout_sweep.gd
```

7. Inspect dark/light portrait/landscape screenshots.

## Forbidden

- Do not tune `LogoCore`, `TotalPlayTimeLabel`, menu, replay, or stat offsets directly in `GameScene.tscn`.
- Do not add per-orientation hand offsets unless they are first represented as SSOT region variants.
- Do not render generated `stats_capsule` or `logo_socket` unless `ThemeConfig.ui_top_tray_art_stack` explicitly enables them.
- Do not scale generated `stats_capsule` or `logo_socket` into text/logo regions; if enabled, they are full top-tray stack components.
- Do not replace the real logo with generated art.
