# Shinokute Character 3D SSOT

Last updated: 2026-07-08

This file is the required coordinate source of truth before any Shinokute 2D-to-3D material projection, decal placement, retopo cleanup, rigging, or Godot integration.

## Rule

- Do not guess body material zones directly from a raw mesh render.
- Establish source-sprite coordinates and 3D mesh coordinate bands first.
- Every texture/material/decal action must point back to an approved source view, a normalized body zone, and a validation screenshot.
- Mirrored front/right texture with reversed hoodie text is allowed only because owner explicitly approved that exception on 2026-07-08. Future text/logo flips are rejected unless separately approved.
- Hunyuan Paint texture generation is preferred, but currently blocked until native Hunyuan texture renderer dependencies are available: `custom_rasterizer` needs CUDA Toolkit / `CUDA_HOME` and `nvcc`, not only PyTorch CUDA runtime.

## Source Views

| View key | Source path | Status | Notes |
|---|---|---|---|
| front | `res://assets/themes/candy_sky_islands/source/shinokute_player/standing_multiview_pool/shinokute_standing_front.png` | accepted | Primary identity, hoodie text, face, black hoodie, black shorts, red/black shoes. |
| left_side | `res://assets/themes/candy_sky_islands/source/shinokute_player/standing_multiview_pool/shinokute_standing_left_side.png` | accepted | Side silhouette and depth cues. |
| back | `res://assets/themes/candy_sky_islands/source/shinokute_player/standing_multiview_pool/shinokute_standing_back.png` | accepted | Back hoodie and shorts. |
| front_left_3q | `res://assets/themes/candy_sky_islands/source/shinokute_player/standing_multiview_pool/shinokute_standing_front_left_3q.png` | accepted | Front 3q texture reference. |
| front_right_3q | `res://assets/themes/candy_sky_islands/source/shinokute_player/standing_multiview_pool/shinokute_standing_front_right_3q.png` | owner-approved flip exception | Geometry and production texture allowed by owner despite reversed hoodie text. |
| right_back_3q_candidate | `res://assets/themes/candy_sky_islands/source/shinokute_player/standing_multiview_pool/shinokute_standing_right_back_3q_candidate.png` | accepted as back/side support | Side/back silhouette support. |

## Hunyuan Mesh Baseline

Candidate mesh:

- `res://assets/themes/candy_sky_islands/models/character_shinokute_hunyuan_mv_candidate.glb`
- Generated from front, left, and back accepted views.
- Vertices: `58000`
- Faces: `185784`
- Current status: geometry candidate only, not production-integrated.

Blender measured world bounds:

| Axis | Min | Max | Size |
|---|---:|---:|---:|
| X | -0.333434 | 0.293977 | 0.627411 |
| Y | -0.218296 | 0.238681 | 0.456977 |
| Z | -0.998404 | 0.958888 | 1.957292 |

Coordinate convention:

- `Z` normalized body height: `(z - min_z) / size_z`.
- Negative `Y` is current preview front.
- `X` is left/right width.
- All material zones below are candidate zones and must be confirmed against preview renders before integration.

## Material Zone SSOT

| Zone key | Source view | Normalized 3D coordinate | Material target | QA gate |
|---|---|---|---|---|
| hair | front, side, back | `z_norm >= 0.78`, except face mask | near-black hair | Hair must not cover entire face. |
| face | front | `front_y`, `0.72 <= z_norm <= 0.88`, center `abs(x) <= 0.16` | skin | Face must remain visible and not be black. |
| hoodie_body | front, back, 3q | `0.48 <= z_norm < 0.74`, torso center | black fabric | No beige/skin chest patch. |
| hoodie_sleeves | side/front | arms beside torso, `0.40 <= z_norm <= 0.70` | black fabric | Hands remain skin, sleeves remain black. |
| hands | front/side | wrist/hand blobs near side of shorts, lower sleeve ends | skin | Hands not black. |
| shorts | front/back | `0.31 <= z_norm < 0.49` | black fabric | Shorts separated from hoodie by waist. |
| legs | front/back | `0.15 <= z_norm < 0.35`, center leg regions | skin | Legs not black shorts. |
| socks | front/back | `0.10 <= z_norm < 0.18` | black | Socks visible above shoes. |
| shoes | front/side | `z_norm < 0.12` | red/black/white | Red/black shoes, not full red blocks. |
| hoodie_text | front | decal at chest, `z_norm ~= 0.62`, front negative `Y` | white text/decal | Text sits on upper chest, not belly/shorts. |

## Blocked/Fallback Texture Paths

Preferred path:

1. Use Hunyuan Paint texture generation from accepted multiview sprites.
2. Build `custom_rasterizer` and `differentiable_renderer` native modules.
3. Generate textured candidate GLB.
4. Render 6-view preview.
5. Owner/agent visual QA.

Current blocker:

- `Hunyuan3DPaintPipeline` import works after pinning `diffusers==0.31.0`, `transformers==4.46.3`, `accelerate==1.1.1`, `tokenizers==0.20.3`, and restoring `torch==2.4.1+cu121` with `torchvision==0.19.1+cu121`.
- Texture generation then fails because `custom_rasterizer` is not built.
- Building `custom_rasterizer` fails because `CUDA_HOME` is not set and no CUDA Toolkit / `nvcc` is visible.

Allowed fallback while blocker exists:

- Create an explicitly marked `styled_candidate` GLB with coarse materials derived from this SSOT and extracted Shinokute source views.
- Do not mark it production until preview QA passes and owner accepts.
- Do not use the rejected Shinokute two-half lentil/image-shell method as a fallback. Owner rejected that method on 2026-07-08. The next valid production path is clean multiview inputs, owner-approved AI 3D generation or Blender plugin/API, then Blender cleanup/retopo/UV/bake/rig/export.

Preferred open-source reconstruction stack while Hunyuan Paint native texture generation is blocked:

| Tool | Shinokute use | Gate |
|---|---|---|
| `Unique3D` | Primary next attempt for a real textured Shinokute mesh from the accepted clean character reference/multiview source. | Must preserve hoodie, face, shorts, legs, shoes, and childlike proportions from source views; raw output is not production until Blender cleanup and Godot validation pass. |
| `TripoSR` | Fast draft fallback to test silhouette, scale, and rough volume. | Draft only; use for feedback or comparison, not final production by itself. |
| `SculptMate` | Optional Blender-side convenience if testing an image-to-mesh addon path. | Same cleanup/export gates; not a quality guarantee. |
| `blender-2d-to-3d-plugin` | Diagnostic only for flat/extruded cutout behavior. | Not valid for the Shinokute volumetric player replacement. |

Repo/source notes checked on 2026-07-08:

- `Unique3D`: <https://github.com/AiuniAI/Unique3D>, MIT repo metadata, Windows setup notes, and README input guidance favoring orthographic front-facing/rest-pose images with low occlusion.
- `TripoSR`: <https://github.com/VAST-AI-Research/TripoSR>, MIT repo metadata/README, `python run.py ...`, about 6GB VRAM by default for a single image, and optional texture baking.
- `SculptMate`: <https://github.com/shravan-d/SculptMate>, Blender add-on draft/convenience path, not a Shinokute production guarantee by itself.
- `blender-2d-to-3d-plugin`: <https://github.com/iamameme/blender-2d-to-3d-plugin>, diagnostic/flat-extrude only for this player.

Future agent skill shape for this character:

1. Input accepted Shinokute source image or multiview list from this SSOT.
2. Confirm Photoroom and polygon extraction evidence exists for each source.
3. Reconstruct with `Unique3D`; fallback to `TripoSR` only for quick draft or failure comparison.
4. Run Blender cleanup/retopo/UV/bake/rig/export.
5. Render 6-view contact sheet.
6. Validate Godot player size, movement, camera, material readability, and animation contract before any scene integration.

## Validation Checklist

- [x] 6-view preview exists for geometry candidate: `res://docs/screenshots/shinokute_hunyuan_mv_candidate_preview/contact_sheet.png`.
- [x] 6-view preview exists for styled/texture candidate: `res://docs/screenshots/shinokute_hunyuan_mv_styled_candidate_preview/contact_sheet.png`.
- [ ] Face visible from front. Current styled candidate fails: face remains too dark/black.
- [x] Hoodie torso black, no skin-colored chest patch.
- [x] Hoodie text placed on chest.
- [x] Shorts black and separated from hoodie.
- [x] Legs skin and socks black.
- [ ] Shoes have red/black/white cues, not full red blobs. Current styled candidate fails.
- [x] Mesh still has real 3D volume.
- [x] Candidate not integrated into `objects/character.tscn` until accepted.

Current styled candidate QA:

- Report: `res://assets/themes/candy_sky_islands/source/shinokute_player/shinokute_hunyuan_mv_styled_candidate_qc.json`
- Status: rejected candidate, not integrated.
- Reason: SSOT body-band material fallback is still too crude for production identity. Continue with Hunyuan Paint native renderer setup or real UV/projection workflow.
