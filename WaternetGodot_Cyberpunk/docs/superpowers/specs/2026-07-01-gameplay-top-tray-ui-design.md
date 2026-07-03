# Gameplay Top Tray UI Design

Date: 2026-07-01

## Goal

Redesign the in-game top tray for the cyber theme so it feels like a premium fake3D cockpit console, not a row of loose stat cards or tile-like boxes.

Owner-selected direction: `P` from the visual companion. This means option A structure with extra cyber detail: fake3D depth, angled trims, glow, and subtle scanline/pulse polish.

## Reference Read

- Flow Free: board-first connection puzzle, HUD should not compete with the path board.
- Two Dots: clean mobile puzzle hierarchy, relaxed readable state, low visual noise.
- Candy Crush Saga: persistent gameplay counters/actions remain visible and easy to read.

Applied rule for this game: keep board as the main play surface, but make the tray feel authored and premium because the cyber skin already has strong fake3D/VFX.

## Visual Direction

The tray is one connected cyber console:

- Center logo as raised core, not plain text.
- Left and right utility pods attach to the tray body.
- Stats are embedded readouts inside the same tray body.
- No separated rectangular cards that look like a second tile grid.
- No visible tutorial text or feature explanation in gameplay.
- Use cyan/green cyber glow already established by pipe energy and lightning.
- Keep dark metal base, inner glow, beveled edges, and restrained scanline/pulse motion.

## Top Tray Contents

Required visible controls:

- Back
- Reset
- Settings
- Leaderboard
- Mute

Required info readouts:

- Level
- Moves
- Best or target metric if current mode defines one

Required center element:

- Game logo from `res://Assets/Icons/logo.png`, centered in the tray.
- The gameplay tray must show the logo asset, not placeholder title text such as `WATERNET`.

## Layout

Desktop and mobile use the same semantic structure:

- `TopTrayRoot`: one full-width HUD container.
- `TrayShell`: fake3D background panel.
- `LogoCore`: centered raised logo area.
- `LeftUtilityPod`: back and reset.
- `RightUtilityPod`: settings, leaderboard, mute.
- `StatsReadout`: transparent layout root only. Level/moves live in `left_stats_readout`; best lives in `right_stats_readout`. Logo socket stays independent in the center.

The tray height must be theme-configured and responsive. It must not hardcode one fixed phone size.

## Settings

Settings opens an overlay, not a scene change.

Initial settings scope:

- Music on/off
- SFX on/off
- Restart level
- Back to level select
- Close

The overlay should reuse existing audio controls and route through existing managers. It must not duplicate audio state.

## Leaderboard

Leaderboard opens an overlay from gameplay.

Initial leaderboard scope:

- Reuse existing `ProfilePopup`/`LeaderboardManager` behavior where possible.
- Show current player/profile entry if available.
- Show world leaderboard list.
- Close back to gameplay.

No new leaderboard backend work in this pass.

## SSOT

All dimensions, colors, motion durations, icon labels, and tray spacing belong in theme/UI config, not scattered through `GameScene.gd`.

Expected source of truth:

- Keep gameplay state in `GameScene.gd`.
- Add a bounded UI component script for the tray if needed.
- Add theme-driven constants through `ThemeConfig` or a UI-specific config resource if the project already has a better pattern.
- Keep paths canonical. No fallback assets.

## Interaction

- Buttons need mobile touch size at least matching current utility button height.
- Settings and leaderboard pause only UI interaction if overlay is open; gameplay board should not rotate under modal overlays.
- Back/reset/mute retain current behavior.
- New overlay buttons play canonical SFX events from theme audio SSOT.

## Testing

Add focused tests before implementation:

- Top tray scene/node contract: logo core exists, utility pods exist, stats readout exists.
- Gameplay hook contract: settings and leaderboard buttons connect to overlay handlers.
- No hardcoded fallback paths for logo/audio/leaderboard.
- Responsive contract: tray config exposes height/spacing and `GameScene` uses it for board top margin.
- Modal input contract: board rotation does not trigger while settings or leaderboard overlay is visible.

## Acceptance

- Visible Godot debug shows premium fake3D cyber tray.
- Logo sits centered and reads as the dominant tray element.
- Logo is the existing project logo asset, not a text substitute.
- Stats are readable but visually attached to the console.
- Controls are reachable and not spread like board tiles.
- Board remains visually primary.
- Settings and leaderboard open from gameplay.
- Tests pass with no fallback warnings.
