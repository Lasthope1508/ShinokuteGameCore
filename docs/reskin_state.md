# Quantum Starter Reskin State

Last updated: 2026-07-07

## Current Gate

Current game-skin scope passed and owner approved; optional branding scope opened by owner. Branding icon, splash, logo, and project display name are integrated; branding validation is the active gate.

## Completed Assets

- Theme direction: Candy Sky Islands, owner approved.
- Root Asset: player mascot, Marshmallow Runner direction, owner approved.
- Player application: safe runtime material pass applied to existing player rig/model.
- SSOT: `Resources/QuantumThemeConfig.gd` and `Resources/Data/Themes/candy_sky_islands/theme_config.tres`.
- Runtime theming: `scripts/theme_applier.gd` wired into `scenes/main.tscn`.
- Asset Family concept sheet generated and owner-approved: `assets/themes/candy_sky_islands/asset_family_concept_sheet.png`.
- Asset Family safe material routing implemented in `scripts/theme_applier.gd`; visual smoke screenshots captured.
- Rejected crop-edge audit kept as failure evidence; corrected QA now lives in `assets/themes/candy_sky_islands/asset_family_extraction_qc.json`.
- Crop edge audit failed for most cloned regions: `assets/themes/candy_sky_islands/source/asset_family_crop_edge_audit.json`.
- Owner finalized polygon outline data: `assets/themes/candy_sky_islands/source/asset_family_outline_regions_candidate.json`.
- Photoroom full-sheet background removal completed through CDP port 9223: `assets/themes/candy_sky_islands/source/asset_family_concept_sheet_photoroom.png`.
- Production extraction redone from the Photoroom alpha sheet using owner polygon data; 15 assets passed alpha/edge QA in `assets/themes/candy_sky_islands/asset_family_extraction_qc.json`.
- Corrected asset contact sheet owner approved on 2026-07-07: `docs/screenshots/candy_sky_islands_corrected_asset_contact_sheet.png`.
- Branding app icon source owner approved: `assets/themes/candy_sky_islands/branding/app_icon_source.png`.
- Branding splash owner approved: `assets/themes/candy_sky_islands/branding/splash_candy_sky_islands.png`.
- Branding logo owner approved: `assets/themes/candy_sky_islands/branding/logo_candy_sky_islands.png`.
- Branding contact sheet owner approved: `docs/screenshots/candy_sky_islands_branding_contact_sheet.png`.
- Asset family screenshots captured:
  - `docs/screenshots/candy_sky_islands_asset_family_gameplay.png`
  - `docs/screenshots/candy_sky_islands_asset_family_hud.png`
- Evidence screenshots:
  - `docs/screenshots/candy_sky_islands_desktop_gameplay.png`
  - `docs/screenshots/candy_sky_islands_player_marshmallow_runner.png`
  - `docs/screenshots/candy_sky_islands_coin_pickup.png`
  - `docs/screenshots/candy_sky_islands_hud.png`

## Pending Assets

- Deeper GLB replacement for obstacle/brick/flag only if separately approved.
- Splash/icon/logo branding assets are pending validation.

## Validation Evidence

- Tests passed on 2026-07-07 with Godot 4.3 after corrected extraction:
  - `test_asset_family_manifest_contract.gd`
  - `test_asset_family_theme_contract.gd`
  - `test_candy_theme_config.gd`
  - `test_reskin_static_contract.gd`
  - `test_theme_applier_contract.gd`
- Godot import exited `0` on 2026-07-07 with Godot 4.3 after corrected extraction.
- Visible smoke screenshot run passed on 2026-07-07 after corrected extraction.
- Do not claim current validation pass without rerunning commands.

## Known Warnings

- README names Godot 4.6, local validation used Godot 4.3.
- Godot import produced existing invalid UID warnings and material remap warnings.
- Worktree is dirty with generated/import metadata and new reskin files.
- Concept sheet generation was owner-approved on 2026-07-07.
- Owner approved using system-key fallback for 9Router image generation on 2026-07-07: prefer `NINEROUTER_IMAGE_KEY`; if missing, use `NINEROUTER_KEY`, then `ROUTER_API_KEY`, without printing secrets.

## Next Required Gate

Branding validation.

Recommended next sequence:

1. Run branding QA, dimensions check, Godot tests/import/smoke, and `git diff --check`.
2. Record validation evidence.
3. Complete final owner review report.
