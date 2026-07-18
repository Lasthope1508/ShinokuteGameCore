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

Game owns:
- art direction and style bible
- asset keys and paths
- owner rects, text slots, icon slots, safe areas, font sizes, colors, screenshots
- selected `image_quality_profile`, concrete UI asset paths, owner sizes, source scale, and exact/minimum size policy
- concrete `visual_composition_rules` values such as `max_surface_viewport_area_ratio`, `text_safe_zones`, `art_safe_zones`, `slot_rects`, `ornament_exclusion_zones`, and `safe_padding`
- concrete `manual_placement` values: editor config path, generated HTML path, export JSON path, editable slots, status, and owner approval record
- concrete `art_process` values: reset/active state, master-theme approval state, source-asset approval state, old-art rejection state, manual-placement allowed flag, and owner approval evidence
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

- No fallback asset, fallback metric, fallback label, or fallback art path.
- No final art claim while any required row is `ART_DESIGN_PENDING`.
- No UI/art generation before a composition contract exists.
- No asset wiring before an asset inventory row exists.
- No runtime text baked into board, card, button, or panel art unless it is explicitly static branding.
- No source image used as runtime art without extraction or an approved source-only exception recorded by the game.
- No generated/runtime UI image may pass the gate below the selected core `image_quality_profile` density.
- No mobile final-art pass may use a prototype-grade source scale.
- No desktop-only approval for mobile games.
- No board or modal may pass runtime fit when its `max_surface_viewport_area_ratio` is exceeded.
- No runtime text may overlap `ornament_exclusion_zones`.
- No `RUNTIME_FIT_PASS` or `OWNER_APPROVED` screenshot row may omit its matching `visual_composition_rules.surfaces` entry.
- No text safe zone may omit a matching `art_safe_zones` entry. The text zone must sit inside a quiet art-safe region, not only inside the board owner rect.
- No icon/card/control `slot_rects` may overlap text safe zones.
- No text safe zone may omit `safe_padding` when ornamental art surrounds it.
- No `RUNTIME_FIT_PASS` or `OWNER_APPROVED` screenshot row may omit a matching `manual_placement.surfaces` entry.
- No agent may hand-place runtime text and claim fit without a game-owned HTML drag editor generated from the composition contract.
- No agent-picked or draft placement may claim `RUNTIME_FIT_PASS`. Text, icon, image, and control slots must be `OWNER_PLACEMENT_APPROVED` before runtime-fit acceptance.
- No manual placement editor may merge image, sample text, and coordinate frame into one baked layer. The editor must expose the placement image, the text/slot content, and the yellow draggable frame as independent parts.
- No manual placement background may contain runtime payload slots. Text, icon, image, and control payloads must be removed from the clean background and shown only as side-panel references.
- No manual placement background may pass on declaration alone. Every runtime-fit surface must include a `clean_background_audit` JSON proof that records each background image, removed slot kinds, capture method, verification basis, and `contains_runtime_text/icon/image/control = false`.
- No owner-picked manual placement may be applied to runtime SSOT until the game records the export JSON and owner says the values are final.

## Required Game Files

Every game using this gate must provide game-owned equivalents of:

- `GAME_ART_UI.md`
- `docs/asset_count_matrix.md`
- `docs/asset_coverage_matrix.md`
- `docs/ui_composition_contracts.md`
- `docs/screenshot_verification_checklist.md`
- `docs/art_pipeline_validation_gate.md`

Use `docs/templates/art_ui_gate/` as starting templates. Fill game data before editing scenes.

## Generic Validator

Use:

```powershell
python <core>/tools/validate_art_ui_gate.py --game-root <game> --contract <game>/docs/art_ui_gate_contract.json
```

The validator is generic. The game contract supplies required surfaces, asset keys, row names, screenshot names, and pending-art rows.

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

Core validates PNG dimensions against `owner_size * source_scale`, plus editor background minimums. Core does not inspect game theme files, generate art, choose coordinates, or approve style. A game can keep a small logical viewport, but generated runtime UI images must still satisfy the selected high-quality profile.

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

Core validates contract geometry and pass coverage only. Core does not own game art, labels, images, or style. A game may not claim `RUNTIME_FIT_PASS` for a screen unless that screen has a `visual_composition_rules.surfaces` entry and every text safe zone has a matching art-safe zone.

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

Core validates that files exist, JSON is readable, all manual-placement surfaces have rows, all declared text/icon/control slots are present in editor config and export JSON, the HTML editor has a menu link, every editor background image meets `min_background_size`, and clean-background audit proof says no runtime payload remains. Core does not choose coordinates. The game records draft values only for owner adjustment. Runtime-fit acceptance requires `OWNER_PLACEMENT_APPROVED`.

Every editor config region must include:

- `slot_kind`: one of `text`, `image`, `icon`, or `control`.
- `sample_text`: the runtime text or slot content the owner needs to place. For image/icon slots, describe the image/icon role.
- `sample_asset`: required for `image` and `icon` slots so the owner can inspect the payload in the side panel without baking it into the placement image.

Every editor config must include:

- `layer_contract.background.contains_runtime_payload = false`
- `layer_contract.content_panel.drawn_on_stage = false`
- `layer_contract.stage_overlay.draws_payload = false`
- `clean_background_payload_slot_kinds_removed`: every slot kind present in `regions`
- `repeated_region_groups`: optional, but required when multiple identical component instances share one slot template. The owner drags the template once; the game derives concrete slot exports for each instance.

Every generated HTML editor must expose three independent panels:

- `Image - mobile_ultra placement proof`
- `Text or slot content`
- `Yellow frame coordinates`

The yellow frame is the only draggable coordinate object. Runtime text, icons, images, and control payloads must not be baked into the placement image or into the yellow frame.
If three cards, rows, buttons, or tiles use the same component geometry, the editor must not ask the owner to place each copy separately. Use a canonical template region plus derived instance exports.
The generic validator rejects repeated indexed editable regions such as `card_1_title`, `card_2_title`, and `card_3_title` when they are listed directly in `regions` without a `repeated_region_groups` mapping. The editable region must be a canonical template such as `card_title_template`; concrete slots belong in derived exports.

Every `clean_background_audit` must include:

- `status = PASS`
- `background_payload_policy = clean_shell_frame_only`
- `capture_method`: how payload was hidden before screenshot capture
- `verification_basis`: `capture_pipeline_hidden_payload_nodes` or `visual_inspection_and_capture_pipeline`
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
