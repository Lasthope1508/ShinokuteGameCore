# 2D Character To 3D Player Runbook

Use this when the owner provides a 2D character image or sprite sheet and asks to replace the 3D player with that character.

## Rule

The supplied 2D character is the identity source. A production 3D player must be derived from that character image and must preserve real 3D volume/depth. Do not replace it with a Blender primitive kitbash, a manually reinterpreted character, or a single flat extrusion unless the owner explicitly approves that downgrade or redesign.

## Required Order

1. Read `docs/default_skin_size_ssot.md` and the `player.model` row. Preserve the player controller, collider envelope, scene scale, animation contract, and camera target unless the owner approves a size or behavior change.
2. Preserve the owner-supplied sheet unchanged as source evidence.
3. Run Photoroom on the full owner sheet/image before any pose extraction if the source needs alpha cleanup.
4. Extract the clean source pose or source sprite only from the Photoroom alpha sheet using polygon outline data. Do not crop the raw sheet first. Do not grid-slice.
5. Use 9Router image generation with that extracted character as the reference image. This is the required 9Router reference-based turnaround/multiview sprite generation step. In this workspace use `cx/gpt-5.5-image`; prefer `NINEROUTER_IMAGE_KEY`, then owner-approved system-key fallback in `AGENTS.md` if the image key is missing. Do not print secrets.
6. Generate a character turnaround or pose sheet with enough views for 3D reconstruction:
   - `front`
   - `left`
   - `right`
   - `back`
   - `front_left_3q`
   - `front_right_3q`
   - optional `back_left_3q` and `back_right_3q` if the back design is complex
7. Prompt 9Router to keep the same exact character identity, face, hair, outfit, proportions, color palette, pose family, and lighting. Use a plain background for clean Photoroom extraction. Negative prompt must reject redesigned outfit, different face, extra limbs, cropped body, watermark, text, inconsistent hairstyle, and perspective distortion.
8. Visually QA the generated sheet before extraction. Reject and regenerate if the character identity drifts, a view is missing, a body part is cropped, or the pose is unusable.
9. Run Photoroom on the full generated turnaround sheet before any sprite/view extraction.
10. Create polygon outline data for every generated view/sprite. Each view is extracted from the Photoroom alpha sheet with a polygon mask and then alpha-trimmed with small padding. Do not use square selection as the final object boundary. Do not use grid slicing.
11. QA every extracted sprite/view:
    - output is `RGBA`,
    - alpha extrema include `0` and `255`,
    - crop edges are not cutting foreground,
    - feet/pivot baseline is consistent,
    - source path is the Photoroom alpha sheet, not the raw generated sheet.
    - mirrored views with visible text, logos, asymmetric marks, or readable symbols are rejected as production textures unless the owner explicitly approves the reversed detail; without that approval, use the mirror only for geometry/silhouette guidance and regenerate or reference-edit the texture view.
12. Only after the clean multiview sprites pass QA, start 3D reconstruction/render:
    - preferred: multiview image-to-3D such as Hunyuan3D-2mv using `front`, `left`, and `back` views when the local dependency stack is ready;
    - approved practical orchestration path: the agent coordinates prompts, locks style, builds clean multiview inputs, submits the multiview source to an owner-approved AI 3D generator or Blender plugin/API, then opens Blender for cleanup/export;
    - approved open-source ladder when Hunyuan3D-2mv/Paint is blocked: use `Unique3D` as the primary free/quality image-to-3D path, `TripoSR` as the fast draft fallback, `SculptMate` only as a Blender convenience wrapper/draft path, and `blender-2d-to-3d-plugin` only for flat/extruded icons, tiles, cutouts, or diagnostic meshes;
    - external AI 3D paths are allowed only as approved generators in this step; their output still must pass Blender cleanup, material/UV validation, and Godot validation before production use;
    - fallback: single-image-to-3D only if multiview fails, and record it as weaker evidence;
    - Blender must handle post-AI cleanup before production export: align origin/scale, check symmetry, merge close vertices, fill holes, reduce excessive polycount, retopo or keep clean quad-like topology where animation/game use needs it, UV unwrap when needed, bake vertex color/projection detail into real texture maps, auto-rig or prepare rig targets, then export FBX/GLB;
    - Blender may be used for cleanup, scale, retopo, texture projection, rigging, UV/bake, and export, not for replacing the supplied identity with primitive parts.
    - Before Blender work, read `docs/blender_mcp_discovery_runbook.md`. Discover Blender MCP in the current tool surface first. If `mcp__blender` is not exposed, check `C:\Users\Admin\.gemini\config\mcp_config.json` and `C:\Users\Admin\.gemini\config\skills\blender_mcp\SKILL.md`; this machine has a configured `blender` MCP server under `C:\Users\Admin\.gemini\antigravity\mcp\blender-mcp`. Use the local Blender 4.2 CLI fallback `C:\Users\Admin\.gemini\antigravity\bin\Blender\blender-4.2.0-windows-x64\blender.exe` only when MCP is configured but unavailable in the current thread.
    - Before material assignment, texture projection, or decal placement, create/read the character coordinate SSOT. For Shinokute, this is `docs/shinokute_character_3d_ssot.md` plus `assets/themes/candy_sky_islands/source/shinokute_player/shinokute_character_3d_ssot.json`.
13. Texture or surface detail must come from the extracted character views, generated identity-preserving views, or a documented projection/bake from those sources. If the AI 3D output has only vertex colors, bake or convert that surface detail to a real UV texture before game integration unless the owner explicitly approves vertex-color-only runtime use.
14. Rig or animation setup must preserve Godot player scene contracts:
    - `objects/player.tscn` root behavior unchanged,
    - `objects/character.tscn` exposes `AnimationPlayer`,
    - `idle`, `walk`, `jump`, and `run` exist when the source asks for them,
    - animation sampling supports 60 FPS,
    - idle is an active pose when the owner requests non-static idle.
15. Validate the final GLB in game before calling it production:
    - size audit against `player.model`,
    - Godot import,
    - player movement, jump, double jump, in-place fall retry,
    - camera rotate and zoom,
    - screenshot proof from gameplay,
    - docs and manifest updated.

## AI 3D Tool Ladder

Use this ladder when the project needs a real 3D character from the approved 2D identity source and the native Hunyuan3D path is blocked or too slow.

| Tool | Role | Input rule | Output gate | Not allowed for |
|---|---|---|---|---|
| `Unique3D` | Primary free/quality reconstruction path | Use clean character reference image, preferably front-facing/rest pose or clean multiview references derived from the owner source | Export textured mesh, then Blender cleanup/retopo/UV/bake/rig/export | Skipping source-reference identity, skipping Blender cleanup, or treating raw output as production |
| `TripoSR` | Fast draft and batch concept test fallback | Use clean single character image when quick mesh feedback is needed | Export draft mesh, then Blender decimate/cleanup/bake checks | Final production without later quality pass |
| `SculptMate` | Blender convenience wrapper/draft addon | Use only after clean alpha/source image exists | Use for quick in-Blender mesh experiment, then same cleanup gates | Claiming full character production quality by itself |
| `blender-2d-to-3d-plugin` | Flat/extruded PNG mesh path | Use transparent PNG/cutout only | Use for icon, tile, simple prop, cutout, or diagnostic mesh | Full volumetric character replacement |

Source notes checked on 2026-07-08:

- `Unique3D`: <https://github.com/AiuniAI/Unique3D>, MIT repo metadata, single-image textured mesh generation, Windows setup notes, and README guidance that orthographic front-facing/rest-pose images with fewer occlusions produce better reconstructions.
- `TripoSR`: <https://github.com/VAST-AI-Research/TripoSR>, MIT repo metadata/README, `python run.py ...` inference path, about 6GB VRAM for default single-image input, and `--bake-texture` support.
- `SculptMate`: <https://github.com/shravan-d/SculptMate>, Blender add-on described as image-to-mesh within about a minute; use only as convenience/draft unless separately validated.
- `blender-2d-to-3d-plugin`: <https://github.com/iamameme/blender-2d-to-3d-plugin>, flat/extrude-style path only unless separately validated.

Agent skill wrapper design:

1. Receive approved source image or multiview input list.
2. Verify source files came from the required Photoroom plus polygon extraction path.
3. Choose `Unique3D` first for quality; choose `TripoSR` only for quick draft or fallback.
4. Run local reconstruction to `GLB`/`OBJ`.
5. Open Blender headless or Blender MCP.
6. Run cleanup: recenter, scale, merge close vertices, fill holes, inspect symmetry, decimate if needed, unwrap or keep UVs, bake texture/vertex color to image maps when needed.
7. Prepare rig or animation export targets.
8. Export `GLB`/`FBX`.
9. Render preview contact sheet and run Godot import/gameplay validation before integration.

Do not install or clone these large model repos during a reskin task unless the owner approves the install step and target folder.

## Required Artifacts

- Original owner sheet/image.
- Photoroom output for the full owner sheet/image.
- Polygon outline JSON for source pose extraction.
- Clean source pose or source sprite.
- 9Router raw turnaround sheet generated from the character reference.
- Photoroom output for the full turnaround sheet.
- Polygon outline JSON for every generated view/sprite.
- Extracted and trimmed multiview sprites.
- QA JSON for source and generated views.
- 3D reconstruction input list.
- Production or interim GLB.
- Size audit, screenshot proof, and validation logs.

## Rejection Rules

- Reject if the 9Router views no longer look like the supplied character.
- Reject if any required view is missing or cropped.
- Reject mirrored front/3q texture views when text, logos, or asymmetric marks become reversed, unless the owner explicitly approves that exact reversed detail.
- Reject if any sprite/view was cut from the raw sheet before Photoroom.
- Reject if grid slicing was used.
- Reject if the final 3D player is a primitive kitbash or manually redrawn approximation.
- Reject if the result is only a flat `Sprite3D`, billboard, single-card extrusion, two-half lentil shell, front/back image shell, card-rig, or bean-like shell while the default player is volumetric, unless the owner explicitly approves a flat downgrade.
- Reject the Shinokute two-half lentil/image-shell method by default. It was tested as `character_shinokute_lentil_shell_candidate.glb` and rejected by the owner on 2026-07-08; keep it only as diagnostic evidence.
- Reject if the model is integrated without updating `docs/asset_manifest.md`, `docs/reskin_checklist.md`, `docs/reskin_state.md`, and `docs/default_skin_size_ssot.md`.
