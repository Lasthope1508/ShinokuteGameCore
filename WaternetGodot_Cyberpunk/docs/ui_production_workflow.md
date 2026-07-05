# UI Production Workflow

Purpose: define the canonical UI production process for this project and future mobile game skins. This workflow comes before any scene tweaking, asset wiring, or Godot layout changes.

## Rule

MUST READ BEFORE RESKIN: `../../Shared/ShinokuteGameCore/docs/reskin_core_skin_boundary.md`.

Reskin ownership rule: Core = behavior; Game skin = game-specific art; Function skin = game-specific presentation for a shared feature. No fallback unless owner approves the exact fallback for this project.

MUST READ BEFORE ANY GODOT WORK: `res://docs/godot_working_guide.md`. This is the single canonical Godot process document; do not split new Godot notes into side docs.

Do not design professional game UI by hand-tweaking Godot controls first.

The correct order is:

1. Define responsive layout.
2. Ask owner to approve screen regions.
3. Use 9Router to design the visual direction and component objects from synchronized R2 references.
4. Get owner visual approval for generated designs before any production cutout.
5. Use PhotoRoom to remove backgrounds for every non-background UI object asset.
6. Place every approved object asset in Godot through SSOT geometry.
7. Audit object placement on portrait and landscape screenshots.
8. Only after object placement is approved, add or tune text.
9. Run the Text Layout Gate before claiming any UI scale or reskin pass is complete.

## B1. Responsive Frame

Define screen geometry for both vertical and horizontal screens.

Required outputs:

- Portrait safe area.
- Landscape safe area.
- Top region rect.
- Center gameplay/board rect.
- Bottom region rect.
- Modal usable rect.
- Minimum and maximum sizes for each region.
- Breakpoints for small phone, normal phone, tablet, desktop, and landscape.

SSOT:

- Store ratios, margins, min/max sizes, and safe-area rules in `ThemeConfig` or a canonical UI layout resource.
- Do not encode these numbers only in scene node offsets.

## B2. Owner Layout Gate

Ask owner which screen regions exist before asset generation.

Questions:

- Does gameplay screen have a top tray?
- Does gameplay screen have a bottom tray?
- What does top tray contain?
- What does bottom tray contain?
- Which controls are floating outside trays?
- Which modals are required: settings, leaderboard, pause, win, fail, shop, reward?
- Which regions must reserve monetization space?

Do not continue until owner confirms the region model.

## B3. Background Asset

Define background before UI asset generation.

Decisions:

- Theme mood.
- Contrast needed behind board.
- Depth style: flat, gradient, parallax, vignette, sky/space, room, surface, data grid.
- Visual quiet zones behind pipes/tiles.
- Export aspect ratios and crop rules.
- Portrait and landscape assets must both exist; do not stretch one orientation into the other.

Production:

- Use 9Router to generate the approved background.
- Use only approved model and no fallback.
- Store prompt, model, references, output path, and crop notes in docs.
- Store final asset path in theme SSOT.

## B4. Fake3D Layer Asset

Define the fake3D method before wiring UI.

Options:

- Transparent PNG layers.
- Spritesheet/atlas.
- Nine-slice-like panel pieces.
- Shader layer.
- Procedural base plus bitmap art.

Production:

- Use 9Router for art-directed UI layers when visual quality matters.
- Use PhotoRoom for transparent cutouts. Chroma key is not a production substitute.
- Generate top tray, bottom tray, stat capsule, floating buttons, modal frame, and special badges as separate assets when the shape needs depth.
- Store asset sizes, anchors, draw rects, padding, and slice rules in SSOT.

## B5. Component Object Generation

Generate usable game assets, not poster art.

Required process:

1. Use approved full-screen mockups only as style references.
2. Crop or prepare component references for each asset.
3. Upload reference images to R2.
4. Create a per-component checklist.
5. Generate one isolated object per image through 9Router.
6. Use the same style anchor and R2 reference pack for every related component.
7. Owner approves the object design before cleanup.
8. Run PhotoRoom on every non-background object that needs transparency.
9. QA the PhotoRoom cutout on dark, light, and checkerboard backgrounds.
10. Save raw output, PhotoRoom alpha output, prompt/request metadata, R2 URL, dimensions, and SHA256.
11. Record anchor, draw rect, padding, overdraw, and scale policy before integration.
12. Place all approved object assets in Godot through SSOT geometry.
13. Only after object placement is approved, add text or text layout.

Rules:

- `background_full` is the only full-screen generated production asset.
- Top tray, stats capsule, logo socket, floating buttons, bottom reserve, modal frame, and board backplate must be isolated objects.
- Do not generate posters, sample gameplay screenshots, or decorative full-screen compositions for components.
- Do not bake text, fake logos, characters, mascots, gameplay pipes, or board screenshots into UI components.
- Do not use demo crop pixels directly as production assets.
- Do not wire generated assets into Godot until owner approves each component visually.
- Do not use chroma-key cleanup as final production background removal for UI objects.
- Do not use a full-canvas alpha bbox as an excuse to reject PhotoRoom. Check on checkerboard first; if alpha exists, extraction must clone the PhotoRoom output and isolate objects by mask.
- For multi-object sprite sheets, never slice by a guessed grid. Clone the PhotoRoom sheet per object, mask out the other objects, trim the remaining object, and then build a canonical atlas from those object files.
- Do not add text before all object assets for that screen are placed and approved.

SSOT:

- Store the final production path, pixel size, anchor, draw rect, padding, and scale policy in `ThemeConfig` or a canonical UI asset resource.
- Keep component generation manifests in docs so future skins can repeat the process.

Current cyber references:

- `docs/9router_ui_generation_runbook.md`.
- `docs/ui_cyber_dark_light_component_design.md`.
- `docs/ui_cyber_component_generation_checklist.md`.
- `docs/ui_cyber_9router_component_call_queue.md`.
- `docs/ui_cyber_component_generation_manifest.json`.

## B5A. 9Router Component Call Queue

Use a queue before calling image generation so every UI part follows the same owner-approved style and geometry contract.

Queue source:

- `docs/ui_cyber_9router_component_call_queue.md`.

Each queue item must define:

- component key.
- mode.
- production exception status, if any.
- required R2 references.
- prompt additions.
- local raw path.
- local alpha/clean path.
- R2 key.
- expected SSOT geometry fields.
- visual audit gate.

Rules:

- One queue item equals one 9Router call, except grouped button states where each state is still recorded separately.
- Every call must include the base R2 reference pack plus the matching mode/component refs.
- Every prompt must repeat the object-only rule.
- Every output must be recorded in `docs/ui_cyber_component_generation_manifest.json`.
- Future agents must extend the queue rather than inventing ad hoc prompts.
- Every non-background object output must pass PhotoRoom cleanup before it can be marked production-ready.
- Godot integration happens only after the PhotoRoom output and owner-approved object placement exist.
- Text integration is a separate step after object placement approval.

## B6. Visual Audit Loop

Visual audit is mandatory.

Loop:

1. Open visible Godot debug.
2. Capture screenshot.
3. Compare with owner reference.
4. Check responsive framing.
5. Check overlap, scale, hierarchy, contrast, and touch targets.
6. Fix via SSOT tokens or regenerate assets.
7. Repeat until owner approves.

Never claim UI is done from tests alone.

## B7. Text Layout Gate

Text is the last production step, but it is not an eyeballing step. Every text node must pass through the canonical text layout gate before visual approval.

Required for every label, button text, readout, empty state, and dynamic row:

1. Define the owner rect before styling text. The owner rect can be an approved region such as `left_stats_readout`, `total_play_time_readout`, a modal content rect, or a list row rect.
2. Assign one canonical text role from `ThemeConfig.ui_text_roles`.
3. Apply text through `res://Scripts/ui_text_layout.gd`, not one-off `Label.new()` styling.
4. The text role must define font size, minimum font size, alignment, vertical alignment, padding, overflow behavior, max lines, and fit policy.
5. Runtime code must measure text with font metrics and shrink from max to min font size before allowing ellipsis or clipping.
6. Dynamic text states must be tested with normal, empty, long, numeric-growth, and translated-length samples.
7. Portrait, small portrait, landscape, and modal-open states must run through tests and visible debug review.

Forbidden:

- Text without an owner rect.
- Runtime labels or buttons that skip `UiTextLayout`.
- Manual offset fixes for text drift.
- Text that decides its own width from string length inside a layout container.
- Modal/popup text that is approved in one theme or orientation only.

## Completion Gate

UI pass is complete only when:

- Owner approved screenshot.
- Required responsive sizes are documented.
- Background asset and fake3D layer assets are in SSOT.
- Godot scene uses semantic nodes and theme-owned geometry.
- No fallback assets or hardcoded production dimensions.
- Visual QA screenshots are saved.
