# Art UI Design Gate

Core owns this reusable gate. Each game owns its concrete art, UI layout, screenshots, asset keys, style bible, and contract values.

Purpose:
- stop agents from calling runtime-fit screens "done"
- stop agents from starting placement or wiring before master theme and source art are approved
- force asset counting before generation
- force composition contracts before final art
- separate core process from game-owned presentation

## Ownership

Core owns:
- status vocabulary
- required gate order
- generic validator shape
- reusable templates
- no-fallback doctrine
- reusable `image_quality_profile` definitions for generated/runtime UI image density
- generic `visual_composition_rules` validation for layout density, text-safe regions, art-safe regions, slot rects, and ornament exclusion
- generic `manual_placement` validation that requires a game-owned HTML drag editor and export record before runtime-fit screens can be accepted
- generic `art_process` validation that blocks generation, runtime-fit, owner approval, and manual placement until the game records the correct pipeline state
- generic `source_extraction` validation that blocks auto-hull, auto-bbox, grid slicing, and agent-picked rectangles from masquerading as owner polygon extraction
- generic `ssot_registry` validation that enforces `one_function_one_canonical` across canonical files, generated artifacts, evidence, and runtime consumers

Game owns:
- art direction and style bible
- asset keys and paths
- owner rects, text slots, icon slots, safe areas, font sizes, colors, screenshots
- selected `image_quality_profile`, concrete UI asset paths, owner sizes, source scale, and exact/minimum size policy
- concrete `visual_composition_rules` values such as `max_surface_viewport_area_ratio`, `text_safe_zones`, `art_safe_zones`, `slot_rects`, `ornament_exclusion_zones`, and `safe_padding`
- concrete `manual_placement` values: editor config path, generated HTML path, export JSON path, editable slots, status, and owner approval record
- concrete `art_process` values: reset/active state, master-theme approval state, source-asset approval state, old-art rejection state, manual-placement allowed flag, and owner approval evidence
- concrete `source_extraction` values: sheet paths, Photoroom alpha paths, owner polygon editor paths, owner outline JSON paths, asset keys, and approval status
- concrete `ssot_registry` rows that identify each function id, canonical file, derived files, evidence files, and runtime consumers
- concrete surface list and asset counts
- owner approval records

Do not move game art, game UI skins, theme values, PNG paths, or game names into core.

## Gate Zero: Art Process State

Games add `art_process` to `docs/art_ui_gate_contract.json`.
This is the first gate. It runs before screenshot dimensions, image quality,
visual composition, or manual placement.

Valid process states:

| Field | Valid values | Meaning |
|---|---|---|
| `status` | `ART_PIPELINE_RESET`, `ART_PIPELINE_ACTIVE`, `ART_PIPELINE_FINAL_REVIEW` | Current art-pipeline phase. |
| `master_theme_status` | `MASTER_THEME_PENDING`, `MASTER_THEME_APPROVED` | Whether owner-approved master theme/reference/style bible is locked. |
| `source_asset_status` | `ART_SOURCE_NOT_READY`, `SOURCE_ASSET_APPROVED` | Whether source art masters passed generation and source QA. |
| `old_art_status` | `OLD_ART_REJECTED`, `OLD_ART_PROTOTYPE_ONLY`, `OLD_ART_APPROVED_REFERENCE_ONLY` | Whether old assets can be used as anything beyond function-test/reference material. |
| `manual_placement_allowed` | `true`, `false` | Whether owner placement may begin. |

When `status = ART_PIPELINE_RESET`, the validator requires:

- `master_theme_status = MASTER_THEME_PENDING`
- `source_asset_status = ART_SOURCE_NOT_READY`
- `old_art_status = OLD_ART_REJECTED`
- `manual_placement_allowed = false`
- `manual_placement.required = false`
- `manual_placement.surfaces = {}`
- no screenshot row may claim `RUNTIME_FIT_PASS`, `OWNER_APPROVED`, `READY_FOR_OWNER_ADJUSTMENT`, or `OWNER_PLACEMENT_APPROVED`

When either `master_theme_status != MASTER_THEME_APPROVED` or
`source_asset_status != SOURCE_ASSET_APPROVED`, no screen may claim
`RUNTIME_FIT_PASS` or `OWNER_APPROVED`.

Manual placement begins only after source masters are approved and runtime
packages exist. Do not create or refresh drag editors from rejected/prototype
assets.

## Gate Two: Owner Polygon Source Extraction

Games add `source_extraction` to `docs/art_ui_gate_contract.json` when source sheets need object extraction.

Core owns the generic rule:

- full approved sheet goes through background removal before any crop
- owner polygon editor is required before extraction
- `outline_author` must be `owner_manual_polygon`
- `status = OWNER_POLYGON_OUTLINE_PENDING` means extraction is blocked
- `extraction_allowed` must be `false` while owner polygon is pending
- approved outline JSON must contain `outline_author = owner_manual_polygon`, one row per required asset key, at least three polygon points, and `computed_rect`
- auto-hull, auto-bbox, rectangle guessing, grid slicing, and raw-sheet crop are forbidden

Game owns:

- source sheet path
- Photoroom alpha sheet path
- generated owner polygon HTML editor
- owner-saved outline JSON
- concrete asset key list
- approval state

No agent may self-cut source sheets or generate extraction regions by image analysis and call them owner-approved.

## Gate One: Reference Lock

Games add `reference_lock` to `docs/art_ui_gate_contract.json`.

Core owns the generic rule:

- source assets cannot be approved before `REFERENCE_SHEET_LOCKED`
- source assets cannot be approved before `GENERATION_SPEC_LOCKED`
- locked reference sheets must have `10-30` rows unless the game declares different min/max values
- every reference row must include `Reference`, `Bucket`, `Learn This`, `Do Not Copy`, and `Source Use`
- every required bucket declared by the game must appear at least once
- locked generation specs must name runtime jobs, asset families, provider/model, extraction path, and naming boundary

Game owns:

- concrete reference URLs or project screenshots
- concrete visual buckets
- concrete generation prompt content
- concrete asset-family source specs

Core must not contain game theme names, asset paths, prompt text, or gameplay ids.

## Required Statuses

## Art Design Approval Gate

| Status | Meaning |
|---|---|
| `CAPTURED_RAW` | Screenshot exists, but it is not accepted. |
| `RUNTIME_FIT_PASS` | Rendered text, icons, controls, and geometry fit the game composition contract after owner placement is approved. |
| `RUNTIME_FIT_BLOCKED` | Screenshot exposes a runtime blocker. |
| `ART_DESIGN_PENDING` | Runtime can be tested, but board/art design is not final-approved. |
| `OWNER_APPROVED` | Owner accepted final look after runtime fit and art design review. |

RUNTIME_FIT_PASS is not final art design approval.

## Hard Gates

- No SSOT-like file may be created or edited before the game `ssot_registry` row is checked. The registry policy is `one_function_one_canonical`.
- No fallback asset, fallback metric, fallback label, or fallback art path.
- No legacy service fallback or missing-value helper may be used as an exception to the art/UI gate. Settings defaults, missing-value return helpers, and localization missing-key behavior are not reskin fallbacks and must never create UI/art assets, labels, metrics, paths, placement, or owner approval.
- No art/UI contract key, asset id, manual-placement field, or visual-composition field may contain `fallback`, `*_fallback`, `fallback_*`, `default_*`, or `*_default`. Use explicit canonical asset keys, owner rects, and owner-approved placement fields.
- No final art claim while any required row is `ART_DESIGN_PENDING`.
- No UI/art generation before a composition contract exists.
- No asset wiring before an asset inventory row exists.
- No runtime text baked into board, card, button, or panel art unless it is explicitly static branding.
- No source image used as runtime art without extraction or an approved source-only exception recorded by the game.
- No parallel SSOT files for one function. Every game must declare `ssot_registry.policy = one_function_one_canonical`; generated artifacts and evidence must trace back to one canonical file.
- No duplicate runtime image source. A game theme/runtime asset manifest must map one canonical runtime asset key to one active PNG path, active runtime PNG files must match that path set 1:1, image hashes must not duplicate, and resource registries must not create alias image keys for the same PNG.
- No extracted source asset may pass by auto-hull, auto-bbox, grid slicing, or agent-picked rectangle. Owner polygon extraction is required when the game declares `source_extraction`.
- No generated/runtime UI image may pass the gate below the selected core `image_quality_profile` density.
- No UI source asset may omit `resize_mode`. Use `cover_crop_exact` only for art that may be cropped to fill the owner ratio. Use `contain_with_bleed_exact` for cards, buttons, frames, or objects where transparent bleed must survive exact packaging.
- No mobile final-art pass may use a prototype-grade source scale.
- No desktop-only approval for mobile games.
- No screenshot proof may come from Windows `PrintWindow` for Godot/Vulkan. It can produce a black or stale swapchain image. Use `godot_scene_capture_runtime_stretch` or `foreground_window_capture`, then inspect the pixels.
- No screenshot proof may pass as a blank, near-solid, wrong-window, or stale capture. The gate must run a nonblank pixel audit and the owner/agent must view the image before making any visual claim.
- No diagnostic redraw may be used as owner proof. An agent-rendered image that redraws yellow regions, owner boxes, or comparison overlays is diagnostic only and must not be stored under an owner-proof path. Owner proof must come from the game-owned HTML editor, export JSON, clean-background audit, or a real runtime screenshot.
- No art/UI gate contract may omit `owner_proof_policy`; forbidden owner-proof directories and globs must be explicit in the game contract, not hidden in agent memory.
- No board or modal may pass runtime fit when its `max_surface_viewport_area_ratio` is exceeded.
- No runtime text may overlap `ornament_exclusion_zones`.
- No `RUNTIME_FIT_PASS` or `OWNER_APPROVED` screenshot row may omit its matching `visual_composition_rules.surfaces` entry.
- No text safe zone may omit a matching `art_safe_zones` entry. The text zone must sit inside a quiet art-safe region, not only inside the board owner rect.
- No icon/card/control `slot_rects` may overlap text safe zones.
- No text safe zone may omit `safe_padding` when ornamental art surrounds it.
- No `RUNTIME_FIT_PASS` or `OWNER_APPROVED` screenshot row may omit a matching `manual_placement.surfaces` entry.
- No agent may hand-place runtime text and claim fit without a game-owned HTML drag editor generated from the composition contract.
- No agent-picked or draft placement may claim `RUNTIME_FIT_PASS`. Text, icon, image, and control slots must be `OWNER_PLACEMENT_APPROVED` before runtime-fit acceptance.
- No `DRAFT_SEED_ONLY` editor value may be copied into runtime/theme SSOT. Games must add validators for their owner-input-to-runtime conversion pairs and fail when draft placement equals runtime metrics.
- No manual placement generator may invent a status. `config.status` is required; missing status must throw or fail validation, never fallback to `READY_FOR_OWNER_ADJUSTMENT`.
- No project may invent a parallel manual-placement HTML tool when a system skill exists. For drag-region editors, `html-asset-drag-region-editor` and its `scripts/create_drag_region_editor.py` are the canonical capability. A game tool may only be a thin wrapper around that skill, or a documented extension after the system skill is updated. Silent forks, copied generators, and reimplemented missing controls are forbidden.
- No manual placement editor may merge image, sample text, and coordinate frame into one baked layer. The editor must expose the placement image, the text/slot content, and the yellow draggable frame as independent parts.
- No manual placement background may contain runtime payload slots. Text, icon, image, and control payloads must be removed from the clean background. Icon, image, and placeable shell payloads that runtime draws inside owner slots must also appear as separate DOM payload previews inside the yellow frame through `stage_preview_enabled`; side-panel-only preview is not enough.
- No manual placement background may pass on declaration alone. Every runtime-fit surface must include a `clean_background_audit` JSON proof that records each background image, removed slot kinds, capture method, verification basis, and `contains_runtime_text/icon/image/control = false`.
- No owner-picked manual placement may be applied to runtime SSOT until the game records the export JSON and owner says the values are final.
- No generated manual placement editor may omit multi-select. Repeated or related slots must support `Ctrl` / `Shift` / `Meta` click, visible selected-state styling, `Select all`, `Clear`, group drag, and proportional group scale from selected bounds.

## Required Game Files

Every game using this gate must provide game-owned equivalents of:

- `GAME_ART_UI.md`
- `docs/ssot_registry.json`
- `docs/asset_count_matrix.md`
- `docs/asset_coverage_matrix.md`
- `docs/ui_composition_contracts.md`
- `docs/screenshot_verification_checklist.md`
- `docs/art_pipeline_validation_gate.md`

Use `docs/templates/art_ui_gate/` as starting templates. Fill game data before editing scenes.
The contract template must start in `ART_PIPELINE_RESET` with `manual_placement_allowed = false`,
`manual_placement.required = false`, and empty `manual_placement.surfaces`.
Do not seed a project template with an active `READY_FOR_OWNER_ADJUSTMENT` surface.
That status is valid only after the game deliberately enables manual placement and creates
the canonical owner editor bundle for that surface.

The game `docs/ssot_registry.json` is the first write gate for all SSOT-like work, not only art/UI. If the target function already has a row, edit its `canonical_file` and regenerate traced derived artifacts. If the row is missing, add the row before creating the file.

## Generic Validator

Use:

```powershell
python <core>/tools/validate_art_ui_gate.py --game-root <game> --contract <game>/docs/art_ui_gate_contract.json
```

The validator is generic. The game contract supplies required surfaces, asset keys, row names, screenshot names, and pending-art rows.

## SSOT Registry Gate

Games add `ssot_registry` to `docs/art_ui_gate_contract.json`:

```json
{
  "ssot_registry": {
    "path": "docs/ssot_registry.json"
  }
}
```

Core owns the rule and schema described in `docs/ssot_registry.md`.
Game owns the concrete registry rows.

Required policy: `one_function_one_canonical`.

Each row must define:

- `function_id`: stable function key, such as `upgrade_overlay_placement`.
- `canonical_role`: one of `runtime_ssot`, `owner_input_ssot`, `doc_contract`, `generated_artifact`, or `evidence`.
- `canonical_file`: the one source of truth for that function.
- `derived_files`: generated HTML/export/report files with `source` pointing to `canonical_file`.
- `evidence_files`: screenshots, audits, QC, or approval records.
- `runtime_consumers`: files allowed to consume the canonical runtime result.

Derived files and evidence files cannot answer canonical questions. They either regenerate from the canonical file or prove it.

## Image Quality Profiles

Games add `image_quality_profile` to `docs/art_ui_gate_contract.json`.
Core owns the profile names and minimums; games own concrete paths and sizes.

| Profile | Use | Minimum runtime UI source scale | Minimum manual-placement background |
|---|---|---:|---:|
| `prototype` | Early function proof only | `3` | `480x270` |
| `mobile_high_quality` | Mobile/web production art pass | `4` | `1280x720` |
| `mobile_ultra` | Premium/high-density proof pass | `6` | `1920x1080` |

The profile contract must include:

- `profile`: one of the core profile names above.
- `runtime_ui_source_scale`: game SSOT value used to generate UI source PNGs.
- `ui_reference_viewport`: logical UI viewport used by the game.
- `min_editor_background_size`: minimum screenshot/reference image size for manual placement editors.
- `ui_source_assets`: one row per runtime UI image that must meet profile density.

Each `ui_source_assets` row must include:

- `path`: game-relative PNG path or `res://` path.
- `owner_size` or `owner_rect`: logical owner dimensions.
- `source_scale`: required generation/export scale.
- `size_policy`: `exact` for UI shells tied to owner rects, `minimum` for images allowed to exceed owner-scale size.
- `resize_mode`: `cover_crop_exact` or `contain_with_bleed_exact`.

Core validates PNG dimensions against `owner_size * source_scale`, requires an explicit resize mode, plus editor background minimums. Core does not inspect game theme files, generate art, choose coordinates, or approve style. A game can keep a small logical viewport, but generated runtime UI images must still satisfy the selected high-quality profile.

## Visual Composition Rules

Games can add `visual_composition_rules` to `docs/art_ui_gate_contract.json`.
These rules are game-owned values checked by the core validator:

- `viewport_size`: logical viewport used for the composition proof.
- `surface_rect`: board, modal, HUD, or control surface rect in the same coordinate space.
- `max_surface_viewport_area_ratio`: maximum allowed surface area divided by viewport area.
- `text_safe_zones`: named rectangles reserved for rendered labels.
- `art_safe_zones`: matching named rectangles where the game has cleared or designed quiet art under rendered labels.
- `slot_rects`: named icon, card, or control rectangles.
- `ornament_exclusion_zones`: named decorative art zones that must not touch text.
- `safe_padding`: minimum gap used when checking overlap.
- `rect_semantic_boundary`: optional strict role map for surfaces where owner placement and runtime controls are separate. Use it to declare `control_owner_rect`, `visual_shell_rect`, text/icon slot rects, and each role's `coordinate_space` before values are copied to runtime SSOT.

Core validates contract geometry and pass coverage only. Core does not own game art, labels, images, or style. A game may not claim `RUNTIME_FIT_PASS` for a screen unless that screen has a `visual_composition_rules.surfaces` entry and every text safe zone has a matching art-safe zone.

Rect semantic boundary rule:

- `control_owner_rect` means the runtime Control/Button/Hitbox size. It must come from game theme/UI SSOT, not from a drawn frame or yellow owner-placement box.
- `visual_shell_rect` means where shell art is visually placed. It may be centered under a control, but it must not silently replace the control owner size.
- `text_safe_rect` and `icon_slot_rect` mean payload placement. They must not be reused as hitboxes or art source sizes.
- `coordinate_space` must be explicit for each role: stage, surface-local, panel-local, component-local, or viewport.
- Any conversion between owner HTML coordinates and runtime SSOT must name the source role and target role. No single rect may answer multiple layout questions.
- If a repeated component uses one template, the game must derive instances through declared rules rather than copy three unrelated rect tables.

The core validator checks `rect_semantic_boundary` when a game enables it. Core does not choose coordinates; it blocks missing role/source/coordinate-space declarations so future agents cannot mix owner placement, visual shell placement, and runtime control sizing.

## Manual Placement Rules

Games add `manual_placement` to `docs/art_ui_gate_contract.json`.
These rules force a visual editor step before runtime-fit acceptance:

- `required`: must be `true` when any screenshot row claims `RUNTIME_FIT_PASS` or `OWNER_APPROVED`.
- `surfaces`: one row for every runtime-fit screen name.
- `status`: `READY_FOR_OWNER_ADJUSTMENT` while the HTML editor is ready but owner values are not final; this status can only support draft or blocked evidence. `OWNER_PLACEMENT_APPROVED` is required before any `RUNTIME_FIT_PASS` or `OWNER_APPROVED` screenshot row.
- `editor_config`: game-relative JSON config used to generate the editor.
- `editor_html`: game-relative generated HTML editor path.
- `export_json`: game-relative JSON export or draft export.
- `clean_background_audit`: game-relative JSON proof that every placement background is shell/frame only and contains no runtime payload.
- `min_background_size`: minimum pixel size for every editor background screenshot or reference image.
- `applies_to`: exact text/icon slot ids from `text_safe_zones` and `slot_rects`.
- `surface_asset_keys`: exact runtime shell/image asset keys that compose the clean placement background.
- `runtime_asset_paths`: game-relative or `res://` paths for every `surface_asset_keys` entry.
- `background_runtime_basis`: must be `clean_composite_from_surface_asset_keys` so screenshot backgrounds cannot float free from runtime art.
- `rect semantic boundary`: owner placement export may feed runtime SSOT only through a declared conversion from owner coordinate space to the exact runtime role such as `control_owner_rect` or `visual_shell_rect`.

Core validates that files exist, JSON is readable, all manual-placement surfaces have rows, all declared text/icon/control slots are present in editor config and export JSON, every editor config declares runtime surface lineage, shell preview assets match declared runtime paths, the HTML editor has a menu link, every editor background image meets `min_background_size`, and clean-background audit proof says no runtime payload remains. Core does not choose coordinates. The game records draft values only for owner adjustment. Runtime-fit acceptance requires `OWNER_PLACEMENT_APPROVED`.
Core also blocks generated editor JavaScript that defaults missing status to `READY_FOR_OWNER_ADJUSTMENT`. Games must require explicit status in editor config and in generated export JSON.
System skill use is mandatory. Before creating or editing any manual placement HTML, use `html-asset-drag-region-editor`. Do not author a new local HTML generator to reproduce behavior already owned by that skill. If a project needs extra panels, repeat-group export, or game-specific fields, either extend the system skill first or keep a game wrapper that delegates editor creation to the system skill and documents the extension boundary.
Core validator rejects fallback/default-looking contract keys before manual placement, image quality, and screenshot gates run. Missing-value helper parameters inside generic non-art services are implementation details only; game art/UI contracts must still name concrete canonical values.

Diagnostic redraw policy: tools may create temporary images for local debugging, but those images are not owner evidence. The core validator blocks known agent-drawn owner-proof folders and `owner_*yellow*regions*.png` screenshot artifacts. If a game needs proof, record the canonical editor config/export/audit and capture a real runtime screenshot; do not synthesize the owner layer again.

## Screenshot Capture Policy

Games add `screenshot_capture_policy` to `docs/art_ui_gate_contract.json` whenever `expected_screenshots` is declared.

Approved proof methods:

- `godot_scene_capture_runtime_stretch`: in-engine scene capture that renders the project reference viewport and uses the same stretch assumptions as runtime.
- `foreground_window_capture`: OS screen capture after bringing the actual Godot runtime window to foreground.

Forbidden proof method:

- `PrintWindow`: blocked for Godot/Vulkan because it can return a black or stale GPU swapchain surface while the game is rendering correctly.

Every expected screenshot must pass dimensions and nonblank pixel audit. Visual inspection is still required; pixel audit only catches blank/wrong capture classes.

Every editor config region must include:

- `slot_kind`: one of `text`, `image`, `icon`, or `control`.
- `sample_text`: the runtime text or slot content the owner needs to place. For image/icon slots, describe the image/icon role.
- `sample_asset`: required for `image` and `icon` slots so the owner can inspect the payload in the side panel without baking it into the placement image.

Every editor config must include:

- `layer_contract.background.contains_runtime_payload = false`
- `layer_contract.content_panel.drawn_on_stage = true` when `stage_preview_enabled` is true, otherwise false
- `layer_contract.stage_overlay.draws_payload = true` only for separate DOM payload preview, never for baked background payload
- `layer_contract.stage_overlay.payload_preview_is_baked = false`
- `surface_asset_keys`: unique runtime surface asset keys for the background shell/frame.
- `runtime_asset_paths`: one concrete path for each `surface_asset_keys` entry.
- `background_runtime_basis = clean_composite_from_surface_asset_keys`
- `clean_background_payload_slot_kinds_removed`: every payload slot kind present in `regions`; exclude `shell` because clean shell/frame art must remain visible as the placement basis.
- `repeated_region_groups`: optional, but required when multiple identical component instances share one slot template. The owner drags the template once; the game derives concrete slot exports for each instance.

Every generated HTML editor must expose three independent panels:

- `Image - mobile_ultra placement proof`
- `Text or slot content`
- `Yellow frame coordinates`

The yellow frame is the only draggable coordinate object. Runtime text, icons, images, and control payloads must not be baked into the placement image. Icon, image, and placeable shell preview may render inside the yellow frame only as a separate DOM layer, so the owner sees the same slot fit runtime will use.
Editors must also support owner group operations: `Ctrl` / `Shift` / `Meta` click toggles selection, selected yellow frames visibly change state, `Select all` and `Clear` are available, dragging any selected frame moves the group, and resizing a selected handle scales every selected frame proportionally from the selected group bounds.

Placement basis sync is mandatory for every game. If the runtime surface is rendered through a viewport, centered/fitted panel resolver, or stretch pipeline, the owner HTML background must be the matching clean asset composite for that exact surface, generated from canonical asset paths plus theme/runtime metrics. Runtime screenshots/captures are QA proof, not owner placement sources. Standalone shell/card art, cropped panel art, contact sheets, diagnostic redraws, and agent-made preview images are invalid placement backgrounds because they use a different origin or scale. Game validators must fail when an owner-approved editor background is not the canonical clean composite named by the game contract.
Clean/placeable split is mandatory when a surface has objects that the owner is positioning. `clean_background_asset_keys` are the only assets allowed to be baked into the placement image. `placeable_surface_asset_keys` are assets that must stay out of the placement image and appear only as side-panel references or owner-controlled regions. A key cannot be both clean-background and placeable.
If three cards, rows, buttons, or tiles use the same component geometry, the editor must not ask the owner to place each copy separately. Use a canonical template region plus derived instance exports.
The generic validator rejects repeated indexed editable regions such as `card_1_title`, `card_2_title`, and `card_3_title` when they are listed directly in `regions` without a `repeated_region_groups` mapping. The editable region must be a canonical template such as `card_title_template`; concrete slots belong in derived exports.

Every `clean_background_audit` must include:

- `status = PASS`
- `background_payload_policy = clean_shell_frame_only`
- `capture_method`: how payload was hidden before screenshot capture
- `verification_basis`: `asset_composition_from_canonical_assets_and_theme_metrics`, `capture_pipeline_hidden_payload_nodes`, or `visual_inspection_and_capture_pipeline`
- `checked_backgrounds`: one row per editor background mode
- each checked background row: `path`, `contains_runtime_text`, `contains_runtime_icon`, `contains_runtime_image`, `contains_runtime_control`, and `removed_slot_kinds`

## Completion Rule

A screen is done only when:

- runtime fit is pass or owner-approved
- manual placement editor and export exist for every runtime-fit surface
- art design is no longer pending
- owner approval is recorded where final art is claimed
- screenshots exist for required viewports
- game-owned tests and the core gate pass

If any of these is missing, report the exact missing gate. Do not say "done".
