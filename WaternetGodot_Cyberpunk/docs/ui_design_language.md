# UI Design Language

Purpose: keep every gameplay UI pass professional, consistent, and SSOT-driven before polishing individual screens.

## Core Direction

Cyber gameplay UI uses a single cockpit tray language:

- The board stays primary.
- The top HUD is a top tray layer that appears to sit above the gameplay area.
- The top tray layer can overflow the screen edges or visual bounds; it must not read as a closed rectangular frame.
- The readout can use a transparent layout capsule, but only one generated top tray shell is rendered.
- no loose tile-like cards.
- The center brand element is a raised logo core using the real project logo as a separate runtime `TextureRect`.
- Stats are embedded readouts inside the inner capsule.
- Primary side actions are floating buttons outside the inner capsule.
- Modals use one framed panel with a corner utility close button.
- ThemeConfig is SSOT for sizes, spacing, color, glow, shadow, and control scale.

## Reference Ratio

The reference image uses these proportions:

- Top tray width is narrower than the screen, roughly three quarters of mobile width.
- Side buttons sit outside or slightly proud of the main tray.
- Center logo/avatar breaks the tray silhouette upward.
- Stats use big numbers and compact labels.
- Board starts below the tray with enough breathing room.

Cyber adaptation:

- Use `TopTrayLayer` as the overflow layer behind the inner capsule.
- Use `ui_top_tray_width_ratio` for tray width.
- Use `ui_top_tray_regions` to place utility pods, stat readouts, and logo from one normalized SSOT.
- Use `ui_top_tray_logo_size` and `ui_top_tray_height` to keep the logo raised.
- Use `ui_top_tray_stat_height` for readout band.

## Top Tray Anatomy

Canonical gameplay top tray:

- `TopTrayLayer`: wide overflow layer that creates fake3D separation above the board.
- `LeftFloatingMenu`: purple floating menu button outside the inner capsule.
- `RightFloatingReplay`: yellow floating replay button outside the inner capsule.
- `StatsCapsule`: transparent structure only. It must not own gameplay text.
- `LogoCore`: raised real project logo, direct child of `TopTrayLayer`, not part of a generated socket image.
- Optional secondary actions such as leaderboard/settings/mute must not destroy this silhouette; place them inside menus or as small secondary pods only after the main read is stable.

## Modal Rules

- Close is never an action row.
- Close belongs to the modal corner as a utility close button.
- Main modal actions remain stacked content buttons.
- Modal button height, content gap, and close size come from ThemeConfig.
- Opening a modal blocks board rotation.

## Forbidden Patterns

- No placeholder logo text in gameplay tray.
- No second generated top tray shell inside `StatsCapsule`.
- No generated logo socket replacing the real project logo.
- No full-row X close button.
- No loose tile-like stat cards spread across the top.
- No per-screen hardcoded button sizes when ThemeConfig has a token.
- No runtime fallback assets.

## Required Tokens

ThemeConfig owns:

- `ui_top_tray_height`
- `ui_top_tray_layer_height`
- `ui_top_tray_width_ratio`
- `ui_top_tray_capsule_width_ratio`
- `ui_top_tray_logo_size`
- `ui_top_tray_logo_center_y_ratio`
- `ui_top_tray_icon_button_size`
- `ui_top_tray_regions`
- `ui_top_tray_region_source_size`
- `ui_top_tray_region_pixel_rects`
- `ui_top_tray_stat_height`
- `ui_top_tray_stat_font_size`
- `ui_top_tray_stat_min_font_size`
- `ui_top_tray_stat_line_height_ratio`
- `ui_top_tray_stat_fit_width_ratio`
- `ui_top_tray_board_gap`
- `ui_top_tray_bg_color`
- `ui_top_tray_border_color`
- `ui_top_tray_shadow_color`
- `ui_top_tray_glow_color`
- `ui_modal_close_button_size`
- `ui_modal_action_button_height`
- `ui_modal_content_gap`
- `ui_modal_content_margin_x`
- `ui_modal_content_margin_top`
- `ui_modal_content_margin_bottom`
- `ui_result_modal_width_ratio`
- `ui_result_modal_height_ratio`
- `ui_result_modal_landscape_width_ratio`
- `ui_result_modal_landscape_height_ratio`
- `ui_result_modal_action_button_width`
- `ui_result_modal_action_button_height`
- `ui_result_modal_content_gap`
- `ui_result_modal_content_margin_x`
- `ui_result_modal_content_margin_top`
- `ui_result_modal_content_margin_bottom`
- `ui_result_modal_title_font_size`
- `ui_result_modal_moves_font_size`
- `ui_result_modal_button_font_size`
- `ui_result_modal_outline_size_by_mode`
- `ui_result_modal_text_color_by_mode`
- `ui_result_modal_outline_color_by_mode`
- `ui_result_modal_button_text_color_by_mode`
- `ui_result_modal_button_bg_by_mode`

## Implementation Contract

- Scene nodes may define semantic structure.
- Runtime sizing and styling must read ThemeConfig.
- Tests must guard node structure and token presence before visual polish begins.
- Settings modal option buttons are text-only centered rows. Icons belong to floating controls or generated art, not option rows.
- Modal dimensions and styles are role contracts, not a shared bucket. Settings/profile/leaderboard may use generic modal tokens, but solved/result panels must use `ui_result_modal_*` compact tokens and centered, non-fill action buttons.
- Modal code paths are also SSOT. `_style_modal_action_buttons()` owns generic settings/modal rows only; `_style_result_modal_action_buttons()` owns solved/result text, width, font size, and mode-specific button colors. Generic modal functions must not reference `ui_result_modal_*`.
- Result modal regressions must be checked at runtime, not only by source text. `Tests/test_result_modal_runtime_style.gd` verifies actual `NextBtn` stylebox and font color against active `ui_generated_asset_mode`.

## Asset Region SSOT

Generated UI art can be beautiful but still fail in Godot if runtime controls are placed by eyeballing offsets. Every generated component that contains intended sub-zones must store those zones in SSOT before integration.

Top tray region contract:

- `ThemeConfig.ui_top_tray_regions` owns normalized `Vector4(x, y, w, h)` rectangles.
- Coordinates are relative to the full generated top tray source canvas after responsive fit, not to the full viewport and not to `top_tray_layer.alpha_bbox`.
- `ThemeConfig.ui_top_tray_region_source_size` and `ThemeConfig.ui_top_tray_region_pixel_rects` keep owner-approved pixel dimensions auditable.
- Required regions: `left_stats_readout`, `right_stats_readout`, `logo_core`, `left_floating_menu`, `right_floating_replay`.
- `LogoCore`, stat readouts, and floating buttons must be placed from those regions only.
- Gameplay top tray text has one owner path: `TopLeftStatLabel` and `TopRightStatLabel`, both direct children of `TopTrayLayer`.
- Legacy `LevelLabel`, `MovesLabel`, and `BestLabel` nodes under `StatsReadout` are forbidden.
- `res://Assets/Icons/logo.png` must be physically trimmed, with `ui_project_logo_alpha_bbox` covering the full file.
- Do not copy coordinates from scene node offsets into production logic.
- Do not tune logo/menu/replay/stat positions by manual per-node offsets.
- If a new skin changes top tray art, update only `ui_top_tray_regions` and generated asset geometry metadata.

Coordinate workflow:

1. Inspect generated top tray source canvas and real visual sub-zones.
2. Record sub-zone rectangles as normalized `Vector4` values in theme SSOT, plus matching pixel rects for audit.
3. Add/extend tests that compare runtime node rects against SSOT regions.
4. Capture dark/light portrait/landscape and visually audit against the asset zones.
5. Adjust SSOT coordinates only, never scene offsets.

## Production Workflow

Use `docs/ui_production_workflow.md` before implementing any UI. The workflow is canonical for this game and future mobile game skins.

## Professional Mobile Game UI Checklist

Use this checklist before implementing or approving any gameplay UI screen.

### Composition

- visual hierarchy: player reads primary gameplay state first, secondary counters second, utility actions last.
- responsive proportions: tray, board, modal, and bottom reserve scale by viewport ratio, not fixed pixels only.
- safe area: layout avoids notches, rounded phone corners, desktop window edges, and future ad/banner zones.
- monetization reserve: top, bottom, and modal layouts keep explicit space for future ads, rewarded prompts, or shop links without redesign.

### Mobile Ergonomics

- touch target: primary controls remain large enough for thumb use on small phones.
- Utility buttons use icons; labels only when text is the clearest command.
- Close/cancel buttons sit in corners or utility zones, not as full-width action rows.
- Controls never overlap gameplay board input.

### Visual Language

- Cyber gameplay uses one cockpit-style fake3D system: raised logo core, embedded readouts, attached utility pods.
- Repeated UI pieces must share bevel, glow, shadow, radius, border, and spacing tokens.
- Empty decorative cards are forbidden.
- no loose tile-like cards.

### State Coverage

- state coverage: every interactive UI element needs default, hover/focus, pressed, disabled, and modal-blocked states.
- Counters need normal, changed, best/new-best, warning, and solved states when relevant.
- Settings and leaderboard need loading, empty, error, and populated states.
- Modal open state must block board rotation.

### Motion And Feedback

- motion budget: tray idle effects, modal transitions, button feedback, and VFX must stay inside 60 FPS budget.
- Motion should clarify state, not compete with pipe VFX.
- Audio feedback must use canonical SFX events from theme SSOT.
- Future haptic feedback must route through a single manager, not per-button code.

### Accessibility

- accessibility: text must be readable at small mobile size and pass contrast against cyber background.
- Avoid relying on color alone for critical state.

## Responsive QA Matrix

Every gameplay UI pass must verify these screen families before approval:

- small portrait phone: narrow safe area, tall board-first layout.
- normal portrait phone: primary production target.
- portrait tablet: wider margins, same tray hierarchy.
- landscape phone: shorter height, board remains playable, trays compress.
- landscape tablet/desktop: wider background asset, center board zone stays calm.
- browser/desktop window: responsive layout uses semantic breakpoints, not device names.

Background rule:

- Use `background_full_portrait` for portrait aspect families.
- Use `background_full_landscape` for landscape and desktop aspect families.
- Never stretch one background orientation into the other.
- Icons need tooltips or accessible labels where engine support allows.
- Motion intensity should be tunable if later settings add reduced motion.

### Localization

- localization: gameplay UI text must fit longer translated strings or use canonical icons.
- Avoid hardcoded copy inside logic when it belongs in a UI text table later.
- Numeric readouts should keep stable width when values grow.

### Technical SSOT

- ThemeConfig is SSOT for gameplay UI sizes, spacing, colors, glow, shadow, and motion values.
- Scene files define semantic hierarchy; scripts bind state and apply theme values.
- No runtime fallback assets.
- No one-off style constants in gameplay logic when a token exists.

### Visual QA

- visual QA requires screenshots at mobile portrait, small mobile portrait, tablet/desktop, and modal-open states.
- Compare against current reference ratio before saying a screen is approved.
- Check no text overflow, no board/UI overlap, no accidental one-row icon buttons, and no stale placeholder text.
- Owner visual approval happens in visible Godot debug, not headless tests only.
