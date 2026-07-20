# {{GAME_NAME}} UI Composition Contracts

No UI art generation before a surface row exists here.

## Required Surface Rows

| Surface id | Layer owner | Owner rect SSOT | Content contract | State assets | Required proof |
|---|---|---|---|---|---|
| `{{SURFACE_ID}}` | UI/art | `{{OWNER_RECT_KEY}}` | {{CONTENT_CONTRACT}} | {{STATE_ASSETS}} | {{REQUIRED_PROOF}} |

## Visual Composition Rules

Mirror every active screen-facing surface into `docs/art_ui_gate_contract.json` under `visual_composition_rules`.

Required fields:

- `max_surface_viewport_area_ratio`
- `text_safe_zones`
- `art_safe_zones`
- `slot_rects`
- `ornament_exclusion_zones`
- `safe_padding`
- `manual_placement`

Every `RUNTIME_FIT_PASS` row must have a matching owner-approved visual composition surface rule. Every text safe zone must sit inside a matching art-safe zone. No title, label, or dynamic text may overlap decorative ornament zones. No board or modal may exceed its density cap.

## Manual Placement Editor

Every text-bearing `RUNTIME_FIT_PASS` row must also have a matching `manual_placement.surfaces` entry in `docs/art_ui_gate_contract.json` with `OWNER_PLACEMENT_APPROVED`.
New project templates start with `manual_placement.required = false` and empty `manual_placement.surfaces`.
Add surface rows only after owner placement is intentionally enabled for the project.

Required fields:

- `status`: `READY_FOR_OWNER_ADJUSTMENT` or `OWNER_PLACEMENT_APPROVED`
- `editor_config`
- `editor_html`
- `export_json`
- `clean_background_audit`
- `min_background_size`
- `applies_to`
- `surface_asset_keys`
- `runtime_asset_paths`
- `background_runtime_basis = clean_composite_from_surface_asset_keys`

The HTML editor is game-owned tooling. Use it to drag text/icon slots over a high-quality runtime screenshot that meets `min_background_size`. `READY_FOR_OWNER_ADJUSTMENT` is draft-only. Apply exported values to runtime SSOT only after owner approval.
System skill rule: do not invent a local drag-region HTML tool when `html-asset-drag-region-editor` exists. Generate placement editors through the system skill `scripts/create_drag_region_editor.py` or through a thin game wrapper that delegates to that skill. If a project needs extra behavior, update the system skill or document the wrapper extension boundary before generating HTML.
The clean-background audit is mandatory. It must prove that every placement background has `contains_runtime_text/icon/image/control = false` and that removed slot kinds cover every editor payload kind.
The editor config must declare the exact runtime shell/image assets that compose the clean placement image. A background screenshot without `surface_asset_keys` and matching `runtime_asset_paths` is not a valid owner placement source.
Placement basis sync is mandatory. If runtime centers, fits, stretches, or otherwise composes the surface before display, the owner HTML background must be the same clean asset composite for the exact surface, generated from canonical asset paths plus theme/runtime metrics. Runtime screenshots/captures are QA proof, not owner placement sources. Standalone shell/card art, contact sheets, cropped panels, diagnostic redraws, or agent-made preview images are invalid placement backgrounds.
If the owner is placing shell/image objects, declare `clean_background_asset_keys` and `placeable_surface_asset_keys`. Clean-background keys may be baked into image 1. Placeable keys must not be baked into image 1 and must appear only as payload references or draggable owner regions.

Every manual placement editor must keep three layers independent:

- placement image: clean shell/frame proof only, no runtime payload
- content panel: text/icon/image/control payload reference
- stage overlay: yellow draggable coordinate frames, plus separate DOM payload preview for icon/image/placeable shell slots when `stage_preview_enabled` is true

Every manual placement editor must support owner group editing:

- `Ctrl` / `Shift` / `Meta` click toggles multi-select.
- Selected yellow frames use a visibly different state.
- `Select all` and `Clear` controls are present.
- Dragging one selected frame moves all selected frames.
- Resizing one selected handle scales every selected frame proportionally from the selected group bounds.

Every editor config must include `layer_contract`, `surface_asset_keys`, `runtime_asset_paths`, `background_runtime_basis`, `clean_background_payload_slot_kinds_removed`, `slot_kind`, and `sample_text`; image/icon regions also require `sample_asset` and `stage_preview_enabled = true`. Placeable shell regions also require `sample_asset` and `stage_preview_enabled = true`; clean-background shell regions may set it false.
When identical component instances share the same slot geometry, add `repeated_region_groups` and make the owner drag one canonical template. Export concrete derived slots for runtime use.
Do not list repeated indexed editable regions such as `card_1_title`, `card_2_title`, and `card_3_title` directly in `regions`. Core validation treats that as duplicate manual work and fails the gate unless those concrete slots are derived from a template group.

## State Matrix

| State | Required for final | Notes |
|---|---|---|
| normal | yes | default state |
| hover | desktop yes | mouse/web |
| pressed | yes | click/touch feedback |
| disabled | yes | unavailable/loading |
| focus | if keyboard/gamepad | accessibility |
| selected | if selectable | selected item |
| loading | if async | async state |
| error | if async/input | error state |

## Approval Rule

A screen is final only when runtime fit passes, art design is not pending, owner approval is recorded, and screenshots exist for required viewports.
