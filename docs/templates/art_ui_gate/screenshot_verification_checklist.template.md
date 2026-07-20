# {{GAME_NAME}} Screenshot Verification Checklist

## Runtime Visual Acceptance Status

| Status | Meaning |
|---|---|
| `CAPTURED_RAW` | screenshot exists but is not accepted |
| `RUNTIME_FIT_PASS` | rendered control geometry fits composition after `OWNER_PLACEMENT_APPROVED` |
| `RUNTIME_FIT_BLOCKED` | visible runtime blocker remains |
| `OWNER_APPROVED` | owner accepted final look |

## Art Design Approval Gate

RUNTIME_FIT_PASS is not final art design approval.

| State | Meaning |
|---|---|
| `ART_DESIGN_PENDING` | runtime can be tested, but board/art design is not final-approved |
| `OWNER_APPROVED` | owner accepted final look after runtime fit and art review |

## Screenshot Capture Policy

Approved capture methods:

- `godot_scene_capture_runtime_stretch`
- `foreground_window_capture`

Forbidden capture method:

- `PrintWindow`

Every screenshot proof must be nonblank and inspected visually before any claim is made from it. A raw file that looks right in text but comes from wrong window or stale GPU swapchain does not count.

## Manual Placement Gate

Text-bearing RUNTIME_FIT_PASS rows must have matching `manual_placement` editor config, generated HTML, export JSON, editable slot ids, and `OWNER_PLACEMENT_APPROVED` in `docs/art_ui_gate_contract.json`.
`READY_FOR_OWNER_ADJUSTMENT` is draft-only and cannot prove runtime fit.
Manual placement screenshots must use clean shell/frame backgrounds. Runtime text, icon, image, and control payloads must be removed from the background and shown only as editor side-panel references.
Each row must also have `clean_background_audit` proof. A background image that only "looks clean" without audit JSON is not accepted.
Repeated component instances must use one owner-adjusted template plus derived slot exports. Do not require owner placement for every duplicate card, row, button, or tile.

| Screen | Desktop evidence | Mobile evidence | Runtime fit evidence | Status | Art design gate | Blocker |
|---|---|---|---|---|---|---|
| {{SCREEN_NAME}} | `{{DESKTOP_SCREENSHOT}}` | `{{MOBILE_SCREENSHOT}}` | {{RUNTIME_FIT_EVIDENCE}} | `CAPTURED_RAW` | `ART_DESIGN_PENDING` | {{BLOCKER}} |
