# Default Skin Size SSOT

Last updated: 2026-07-09

This file is the baseline size map for reskin work. It must exist before any visual design, image generation, model wrapper, sheet extraction, or runtime UI replacement.

## Rule

- Measure the default skin first.
- Map every default role to a Candy Sky Islands role before creating new art.
- Preserve gameplay envelopes unless a separate owner-approved size change exists.
- For 2D/image assets, record source pixel size and runtime rect when used in UI.
- For 3D assets, record model or scene AABB in Godot units.
- For 3D obby player characters, define visual scale policy before integration. The replacement model must be scaled into the player readability envelope instead of accepting the raw imported model size.
- 3D parity rule: if the default asset is a 3D model or 3D scene with nonzero depth/volume, the accepted production replacement must also preserve 3D volume/depth unless the owner explicitly approves a flat 2D downgrade. `Sprite3D`, billboard sprites, flat screenshots, and reference PNGs are references or temporary wrappers, not full 3D replacements for volumetric roles.
- 3D character-from-2D rule: if the owner supplies a 2D character image or sprite sheet for the player, read `docs/reskin_2d_character_to_3d_runbook.md` first. The mandatory order is owner source, Photoroom full source, polygon source-pose extraction, 9Router reference-based turnaround/multiview sprite generation, Photoroom full generated sheet, polygon extraction for each view/sprite, then 3D reconstruction/render. The 3D player replacement must visibly use that exact extracted 2D character as the source surface/identity. A multiview-derived mesh, texture-projected model, or rig/model whose surface comes from the extracted/generated character views is allowed; a Blender piece-built approximation, primitive kitbash, single flat extrusion, or manually reinterpreted character is not a valid production replacement unless the owner explicitly approves a redesign or flat downgrade.
- For wrappers, record `wrapper_done, legacy_model_kept` until full model replacement is approved.
- For audio, record route/replacement state here, but do not treat SFX/BGM as visual size work.
- Do not resize generated outputs blindly to match a bounding box. Use this table to preserve role scale, then validate in game.
- Do not mark dummy primitive meshes, rough placeholder geometry, or primitive-only Blender output as production replacements. Production visuals must derive from approved reference art, Photoroom/outline extraction, owner-approved generated art, or a model whose silhouette/material cues are traceable to those references.

## Measurement Source

- Tool: `res://tools/audit_skin_size_ssot.gd`
- Godot: `C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe`
- Project: `C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter`
- 3D size unit: Godot units, combined mesh AABB.
- UI runtime size: Control rect in pixels from `scenes/main.tscn`.

Command:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tools\audit_skin_size_ssot.gd"
```

## Size Map

| Role key | Default asset | Default size | Default runtime/in-game size | Candy Sky Islands asset | Candy source size | Candy runtime/in-game size | Reskin state | Checklist |
|---|---|---:|---:|---|---:|---:|---|---|
| app.icon | `res://icon.png` | 256x256 px | root icon 256x256 px | `res://icon.png`, source `res://assets/themes/candy_sky_islands/branding/app_icon_source.png` | 1024x1024 source, 256x256 root | root icon 256x256 px | done | Keep square production root icon. |
| app.splash | `res://splash-screen.png` | 2560x1440 px | startup splash 16:9 | `res://splash-screen.png`, source `res://assets/themes/candy_sky_islands/branding/splash_candy_sky_islands.png` | 2560x1440 px | startup splash 16:9 | done | Keep 2560x1440 production splash. |
| env.skybox | `res://sprites/skybox.png` | 4096x2048 px | panorama sky material | `res://assets/themes/candy_sky_islands/sky_panel_islands.png` | 307x170 px | routed through `scenes/main-environment.tres` | replacement_done | Validate readability after any new skybox because source pixel size is much smaller. |
| hud.coin.icon | `res://sprites/coin.png` | 128x128 px | old HUD icon node removed | `res://assets/themes/candy_sky_islands/star_collectible.png` | 305x272 px | embedded in score frame and asset-family HUD proof | replacement_done | No old `HUD/Icon` node may return. |
| hud.score.frame | no default frame; old HUD used coin icon plus text | icon 128x128 px, text rect 224x59 px | old text owner rect `x=144,y=64,w=224,h=59` | `res://assets/themes/candy_sky_islands/hud_score_frame_clean_9router.png` | 1909x747 px | `CandyScoreFrame` rect 313x127 px from `theme_config.tres` `hud_score_frame_rect`; `EXPAND_IGNORE_SIZE`; `STRETCH_KEEP_ASPECT_CENTERED` | replacement_done | Runtime rect, not natural PNG size, is the size contract. |
| hud.coin.text | `HUD/Coins` in `scenes/main.tscn` | label text | `x=144,y=64,w=224,h=59` baseline | `HUD/Coins` plus theme owner rect | label text | corrected owner rect `x=160,y=88,w=160,h=54`; centered alignment; dark palette text | themed_done | Keep text inside score frame and after the star icon; mobile not approved yet. |
| hud.font.main | `res://fonts/lilita_one_regular.ttf` | font file | 48 px label setting baseline | same | same | 44 px label setting for cleaned HUD frame | reused | Change only with font approval. |
| player.model | `res://models/character.glb` | 1.200x1.100x0.635 u | `objects/player.tscn` controller/collider preserved; collider capsule radius 0.3, height 1.0, center y 0.55 | `res://assets/themes/candy_sky_islands/models/character_chr077_skeleton_mage.glb` via `res://objects/character.tscn` | CHR077 raw audit before scale was 1.938x2.588x1.735 u; production scale slot is 0.5, giving visual target near 0.969x1.294x0.868 u | 3D obby player scale envelope: player.visual_target_height = 1.30 u; player.visual_allowed_height = 1.10..1.35 u; source basis = default player height 1.100 u plus prior validated player replacements around 1.320..1.332 u; player.visual_scale_policy = scale replacement model under `CHR077SkeletonMageSlot`, never by letting AnimationPlayer overwrite base scale; player controller/collider unchanged; `AnimationPlayer` keeps `idle`, `walk`, `jump` and adds future `run`; animation step is 1/60s | glb_replacement_done | Legacy character GLB scene reference, Candy marshmallow visual, and rejected Shinokute human visual replaced; CHR077 Skeleton Mage uses KayKit CC0 source and is scaled into the canonical 3D obby player readability envelope before production. |
| player.shadow | `res://sprites/blob_shadow.png` | 256x256 px | decal shadow scale `Vector3(1,2,1)` | `res://assets/themes/candy_sky_islands/player_shadow_soft.png` | 256x256 px | decal shadow scale `Vector3(1,2,1)` | replacement_done | Local authored 2D alpha shadow; no AI sheet extraction; preserves runtime decal scale. |
| player.trail.dust | `res://meshes/dust.res` | 0.363x0.330x0.363 u | player run particles | `res://objects/player.tscn` `CandyTrailSparkle` | wrapper scene 1.240x1.219x0.705 u | local VFX added | wrapper_done, legacy_mesh_kept | Legacy dust mesh still present. |
| collectible.coin.model | `res://models/coin.glb` | 0.415x0.417x0.167 u | `Area3D` pickup collider preserved | `res://assets/themes/candy_sky_islands/models/star_candy_collectible.glb` via `res://objects/coin.tscn` | scene AABB 0.609x0.595x0.199 u | pickup behavior unchanged | glb_replacement_done | Candy GLB visual replaces legacy coin mesh and Sprite3D wrapper; root, collision, pickup signal, score behavior, and `Audio.play_event("coin")` unchanged. |
| collectible.coin.particle | `res://sprites/particle.png` | 128x128 px | pickup particles | `res://objects/coin.tscn` `CandyPickupHalo`, `res://assets/themes/candy_sky_islands/meshes/star_candy_halo_mesh.tres`, and particle cleanup | star halo mesh `outer=0.32`, `inner=0.15`; coin scene AABB 0.609x0.595x0.199 u | local VFX added; halo follows real star collectible silhouette and owns `Material_StarCandyHaloSurface` | wrapper_done, legacy_texture_kept | Legacy particle texture still present for pickup sparkle only; `CandyPickupHalo` must not use square `QuadMesh`, must keep a real surface material, and must be excluded from coin body recolor passes. |
| platform.small | `res://models/platform.glb` | 2.000x0.550x2.000 u | collider unchanged | `res://assets/themes/candy_sky_islands/models/platform_candy_small.glb` via `res://objects/platform.tscn` | scene AABB 2.000x0.630x2.000 u | collider/layout unchanged | glb_replacement_done | Candy GLB visual replaces legacy platform GLB; collider node unchanged. |
| platform.medium | `res://models/platform-medium.glb` | 3.000x0.550x3.000 u | collider unchanged | `res://assets/themes/candy_sky_islands/models/platform_candy_medium.glb` via `res://objects/platform_medium.tscn` | scene AABB 3.000x0.630x3.000 u | collider/layout unchanged | glb_replacement_done | Candy GLB visual replaces legacy platform-medium GLB; collider node unchanged. |
| platform.falling | `res://models/platform-falling.glb` | 2.200x0.500x2.200 u | trigger/collider/fall logic unchanged | `res://assets/themes/candy_sky_islands/models/platform_candy_falling.glb` via `res://objects/platform_falling.tscn` | scene AABB 2.200x0.592x2.200 u | trigger/collider/fall logic unchanged | glb_replacement_done | Candy GLB visual replaces legacy falling GLB; Area3D, signal, script, collider, fall logic unchanged. |
| platform.round.large | `res://models/platform-grass-large-round.glb` | 5.000x0.500x5.000 u | static body/collider unchanged | `res://assets/themes/candy_sky_islands/models/platform_candy_round_large.glb` via `res://objects/platform_grass_large_round.tscn` | scene AABB 5.000x0.849x5.000 u | collider/layout unchanged | glb_replacement_done | Candy GLB visual replaces legacy round platform GLB; collider node unchanged. |
| platform.large.unused_candidate | `res://models/platform-large.glb` | 5.000x0.550x5.000 u | no direct scene use found | none | N/A | N/A | unused_candidate | Do not claim reskinned unless it becomes production. |
| block.coin.unused_candidate | `res://models/block-coin.glb` | 1.083x1.000x1.083 u | no direct scene use found | none | N/A | N/A | unused_candidate | Do not claim reskinned unless it becomes production. |
| obstacle.brick | `res://models/brick.glb` | 0.750x0.750x0.750 u | collision/bottom detector preserved | `res://assets/themes/candy_sky_islands/models/brick_candy_wafer.glb` via `res://objects/brick.tscn` | scene AABB 0.940x0.650x0.860 u | collision/break behavior unchanged | glb_replacement_done | Candy GLB visual replaces legacy brick GLB; `StaticBody3D`, collider, bottom detector, break particles, and script behavior unchanged. |
| obstacle.brick.particle | `res://meshes/brick.res` from `models/brick-particle.glb` import | 0.500x0.583x0.583 u | brick break particles | `res://objects/brick.tscn` candy crumb material/process | scene envelope 0.940x0.650x0.860 u | break behavior unchanged | material_done, legacy_mesh_kept | Source `.glb.import` has invalid import flag; use `meshes/brick.res` as measured baseline. |
| goal.flag | `res://models/flag.glb` | 0.200x1.235x0.685 u | `World/flag` transform preserved | `res://assets/themes/candy_sky_islands/models/goal_candy_pennant.glb` via `res://objects/goal_flag.tscn` | scene AABB 1.020x1.615x0.160 u | world placement unchanged | glb_replacement_done | Candy GLB visual replaces legacy flag GLB; root `flag` scene and main transform unchanged. |
| prop.cloud | `res://models/cloud.glb` | 1.000x1.000x1.000 u | scene transforms preserved; default is volumetric 3D | `res://assets/themes/candy_sky_islands/models/cloud_candy_volume.glb` via `res://objects/cloud.tscn` `CloudModel`, reference `res://assets/themes/candy_sky_islands/cloud_large.png` | 332x227 px extracted Photoroom reference; Blender 4.2 alpha-silhouette volume GLB | background prop placement and movement script unchanged; scene AABB 1.694x0.779x0.689 u | glb_replacement_done | reference-derived volumetric Candy cloud GLB replaces the flat `Sprite3D` interim visual and preserves real 3D depth. The mesh is built from the approved Photoroom cloud reference alpha silhouette; primitive-only `cloud_candy.glb` remains rejected evidence, not production. |
| prop.grass | `res://models/grass.glb` | 0.511x0.309x0.536 u | used on round platform | `res://assets/themes/candy_sky_islands/models/grass_candy.glb` via `res://objects/platform_grass_large_round.tscn` | round scene envelope 5.000x0.849x5.000 u | round platform layout unchanged | glb_replacement_done | Legacy grass visual refs replaced in round platform scene. |
| prop.grass.small | `res://models/grass-small.glb` | 0.248x0.258x0.313 u | used on round platform | `res://assets/themes/candy_sky_islands/models/grass_candy_small.glb` via `res://objects/platform_grass_large_round.tscn` | round scene envelope 5.000x0.849x5.000 u | round platform layout unchanged | glb_replacement_done | Legacy small grass visual ref replaced in round platform scene. |
| material.colormap | `res://models/Textures/colormap.png` | 512x512 px | shared material texture | none | N/A | no active production scene reference found | unused_candidate, justified | File remains on disk as legacy source evidence; active coin/platform/cloud/obstacle/goal scenes no longer reference it. |
| audio.bgm.candy_island_main | none | BGM | none | `res://sounds/candy_sky_islands/bgm_candy_island_main.ogg` | 76.02s / 1.13 MB | BGM setting gate, plays from theme SSOT | audio_replaced | Loop_1 + Loop_2 trimmed with `silenceremove` before concat; OGG Vorbis q=4 for mobile. |
| audio.jump | `res://sounds/jump.ogg` | SFX | event routed | `res://sounds/candy_sky_islands/sfx_jump.ogg` | 0.054s | event routed through theme SSOT | audio_replaced | Source `sfx_energy_pulse.wav`; SFX setting gate applies. |
| audio.land | `res://sounds/land.ogg` | SFX | event routed | `res://sounds/candy_sky_islands/sfx_land.ogg` | 0.108s | event routed through theme SSOT | audio_replaced | Source `sfx_drop.wav`; SFX setting gate applies. |
| audio.coin | `res://sounds/coin.ogg` | SFX | event routed | `res://sounds/candy_sky_islands/sfx_coin.ogg` | 0.124s | event routed through theme SSOT | audio_replaced | Source `sfx_pick.wav`; SFX setting gate applies. |
| audio.walking | `res://sounds/walking.ogg` | SFX | event routed | `res://sounds/candy_sky_islands/sfx_walking.ogg` | 0.168s | footstep stream with SFX setting gate | audio_replaced | Source `sfx_pipe_rotate_soft.wav`; player pauses footsteps when SFX is off. |
| audio.break | `res://sounds/break.ogg` | SFX | event routed | `res://sounds/candy_sky_islands/sfx_break.ogg` | 1.746s | event routed through theme SSOT | audio_replaced | Source `sfx_clear.wav`; SFX setting gate applies. |
| audio.fall | `res://sounds/fall.ogg` | SFX | event routed | `res://sounds/candy_sky_islands/sfx_fall.ogg` | 0.292s | event routed through theme SSOT | audio_replaced | Source `sfx_fail.wav`; SFX setting gate applies. |

## Baseline Checklist

- [x] Default image pixel sizes recorded.
- [x] Default 3D AABB sizes recorded.
- [x] Player visual scale policy and target height recorded.
- [x] Default HUD runtime rects recorded.
- [x] Candy Sky Islands mapped asset or state recorded for every default visual role.
- [x] Wrapper roles explicitly marked as `legacy_mesh_kept`; player and platform kit GLB replacements now marked `glb_replacement_done`.
- [x] Pending roles explicitly marked. `material.colormap` is justified as an unused legacy source candidate after active scene cleanup.
- [x] Audio roles record replacement state and processing manifest.
- [x] Contract test added: `res://tests/test_default_skin_size_ssot_contract.gd`.

## Future Gate Blocker

Before any future reskin design option, generation prompt, Photoroom extraction, local model wrapper, or model replacement:

1. Read this file.
2. Check the role row.
3. Decide whether the target must preserve source size, runtime size, collider envelope, or UI rect.
4. Update this file when the role changes.
5. For 3D obby player characters, define `player.visual_target_height`, `player.visual_allowed_height`, and `player.visual_scale_policy` before scene integration. The current canonical source basis is default player height `1.100 u` plus prior validated replacements around `1.320..1.332 u`.
6. Run `test_default_skin_size_ssot_contract.gd` and `test_player_visual_scale_contract.gd`.
7. For 3D roles, check 3D parity. If the default role has nonzero depth/volume, do not mark a flat `Sprite3D`/billboard/reference PNG as a full replacement unless the owner explicitly approved a flat downgrade.
8. Reject primitive-only dummy replacements before production integration.
9. For player characters supplied as 2D art, follow `docs/reskin_2d_character_to_3d_runbook.md`: use 9Router with the extracted character as reference to generate the required views/sprites, run Photoroom on the full generated sheet, polygon-extract each view, and only then start 3D reconstruction/render. Verify the final 3D visual keeps the supplied character image identity on the rendered surface; do not accept a piece-built approximation as production.
