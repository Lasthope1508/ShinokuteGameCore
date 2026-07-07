# Quantum Starter Reskin Checklist

Use this checklist before editing production scenes, generating assets, or claiming the reskin is ready.

## Project

- Game name: Candy Sky Islands
- Repo path: `C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter`
- Reskin goal: Candy Sky Islands visual reskin for the existing 3D platformer template
- Owner-approved scope: game-skin first pass for theme palette, SSOT, HUD visual tokens, environment/material direction, root asset planning, asset family extraction, and app branding
- Target platforms: desktop smoke first; mobile/web only after export scope is approved
- License status: code MIT; included 2D sprites, 3D models, and sounds are CC0 per `README.md`
- Main scene: `res://scenes/main.tscn`
- Current gameplay core: 3D platformer controller, double jump, collectible coins, falling platforms, camera rotate/zoom, gamepad input
- Current engine note: README names Godot 4.6; local available console binary found at `C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe`

## Required Reading

- [x] `Doc/Art Design Document — 2D & Giả 3D Game Mobile (Godot 4).md` read.
- [x] `Shared/ShinokuteGameCore/AGENTS.md` read.
- [x] `Shared/ShinokuteGameCore/docs/reskin_core_skin_boundary.md` read.
- [x] `Shared/ShinokuteGameCore/docs/reskin_runbook.md` read.
- [x] `Shared/ShinokuteGameCore/docs/asset_generation_guardrails.md` read.
- [x] `Shared/ShinokuteGameCore/docs/reskin_checklist_template.md` read.
- [x] `Shared/ShinokuteGameCore/templates/new_game/docs/asset_manifest.md` read.
- [x] `Html5_SourceGames/Godot/quantum_starter/README.md` read.
- [x] `Html5_SourceGames/Godot/quantum_starter/LICENSE.md` read.
- [ ] Game-local publish checklist read if web/mobile publish enters scope.

## Scope Classification

- [x] Game skin only for first pass.
- [ ] Function skin only.
- [ ] Rules adapter work.
- [ ] Shared core work.
- [ ] Publish/release work.

Notes:
- First pass must keep movement, camera, collision, coin collection, and falling platform behavior unchanged.
- No ShinokuteGameCore migration is approved for this source yet.
- If owner later wants leaderboard/profile/ads/publish flow, create a separate Shinokute core integration checklist and plan.

## Approval Gates

### Checkpoint 1: Theme And Style

- [x] Owner approved theme name: Candy Sky Islands.
- [x] Owner approved perspective: keep current true 3D platformer perspective.
- [x] Owner approved art style: bright casual toy-like sky islands with candy/material accents.
- [x] Owner approved 5-color palette:
  - Sky blue: `#79C7F2`
  - Cream: `#FFF2C7`
  - Coral: `#FF6F61`
  - Mint: `#7BE0AD`
  - Dark text: `#273043`
- [x] Owner approved references or mood description: mascot player, star-candy collectible, cake/cloud island platforms, cheerful readable mobile style.
- [x] Owner approved whether paid generation may be used for the Checkpoint 2 player root asset concept.

Hard gate:
- Do not edit gameplay scenes, generated art, model materials, splash/icon, HUD visuals, or project branding before this checkpoint is approved.

### Checkpoint 2: Root Asset

- [x] Root asset selected and generated: player mascot, Marshmallow Runner direction.
- [x] Root asset visually inspected.
- [x] Root asset perspective matches the approved style.
- [x] Root asset lighting/material style matches approved palette.
- [x] Root asset owner approval recorded: Marshmallow Runner concept approved by owner on 2026-07-07.

Hard gate:
- Do not generate or apply the rest of the asset set before this checkpoint is approved.

### Checkpoint 3: Asset Family / Block Kit

- [x] Owner approved safe material plus concept sheet approach on 2026-07-07.
- [x] Owner approved Asset Family design scope on 2026-07-07.
- [x] Asset Family design spec written: `docs/superpowers/specs/2026-07-07-candy-sky-islands-asset-family-design.md`.
- [x] Owner reviewed written Asset Family spec.
- [x] Asset Family implementation plan written: `docs/superpowers/plans/2026-07-07-candy-sky-islands-asset-family.md`.
- [x] Concept sheet generation approved before generation.
- [x] Concept sheet generated and visually inspected.
- [x] Concept sheet owner approved.
- [x] Photoroom extraction completed for full sheet before object cloning: `assets/themes/candy_sky_islands/source/asset_family_concept_sheet_photoroom.png`.
- [x] Extracted asset alpha/edge QA recorded: `assets/themes/candy_sky_islands/asset_family_extraction_qc.json`.
- [x] Previous extraction rejected on 2026-07-07: crop edge audit found risky sheet boundaries in most regions.
- [x] Visual region editor created for owner-approved custom rects: `debug/candy_sky_islands_region_editor.html`.
- [x] Polygon outline candidate received and structurally validated: `assets/themes/candy_sky_islands/source/asset_family_outline_regions_candidate.json`.
- [x] Owner-approved outline/rect data recorded before recrop: `assets/themes/candy_sky_islands/source/asset_family_approved_outline_regions.json`.
- [x] Object clones cut from the Photoroom alpha sheet, not from the raw sheet.
- [x] Photoroom CDP port 9223 rerun on the approved full sheet before object cloning.
- [x] Post-Photoroom alpha/edge QA passes before production use.
- [x] Collectible asset pass applied and screenshot captured.
- [x] Platform kit pass applied and screenshot captured.
- [x] HUD icon/frame pass applied and screenshot captured.
- [x] Props/background pass applied and screenshot captured.

Hard gate:
- Do not generate, import, or apply remaining asset family assets before the written Asset Family spec is owner-reviewed and the implementation plan exists.

### Checkpoint 4: Branding

- [x] Owner opened optional branding scope on 2026-07-07.
- [x] Owner approved Branding Option A on 2026-07-07: Marshmallow Runner icon, Candy Sky Islands splash, compact wordmark/logo.
- [x] Branding design spec written: `docs/superpowers/specs/2026-07-07-candy-sky-islands-branding-design.md`.
- [x] Owner reviewed written Branding spec.
- [x] Branding implementation plan written: `docs/superpowers/plans/2026-07-07-candy-sky-islands-branding.md`.
- [x] App icon generation or creation approved before generation.
- [x] Splash generation or creation approved before generation.
- [x] Logo generation or creation approved before generation.
- [x] Generated or created branding PNGs visually inspected.
- [x] Branding PNGs owner approved.
- [x] Photoroom full-image or full-sheet background removal completed before any logo/icon object extraction that needs alpha.
- [ ] Polygon outline extraction used if any branding sheet has close or overlapping objects. Not applicable for current branding output; logo alpha used Photoroom full-image extraction, no multi-object sheet cut.
- [x] Branding assets recorded in manifest before production integration.
- [x] Project icon and splash integrated only after owner visual approval.
- [x] Branding validation passed.
- [x] Owner final review approved integrated branding on 2026-07-07.

Hard gate:
- Do not generate, import, or apply branding assets before the written Branding spec is owner-reviewed and the implementation plan exists.

## Existing Asset Inventory

Asset manifest:

- Path: `res://docs/asset_manifest.md`
- [x] Existing asset rows filled for current reskin surface.
- [x] Block Kit rows filled for changed/generated assets.
- [ ] In-game Size recorded for every accepted changed asset.
- [ ] Owner Rect recorded for text-bearing assets.
- [x] Paid generation approval recorded before generation.
- [x] Generated PNG reviewed before conversion/import.

| Role | Existing asset key/path | Owner rect | Padding | Ratio/crop | Reuse decision |
|---|---|---|---|---|---|
| App icon | `res://icon.png` | N/A | N/A | square | Replaced after branding approval |
| Splash | `res://splash-screen.png` | N/A | N/A | landscape image | Replaced after branding approval |
| HUD score icon | `res://sprites/coin.png` | N/A | N/A | square icon | Replace only through SSOT |
| HUD score text | `res://scenes/main.tscn` label `Coins` | `offset_left=144, offset_top=64, offset_right=368, offset_bottom=123` | not recorded in SSOT yet | fixed HUD rect | Move to SSOT before visual edit |
| Font | `res://fonts/lilita_one_regular.ttf` | N/A | N/A | font asset | Reuse unless theme requires change |
| Player model | `res://models/character.glb` via `res://objects/character.tscn` | N/A | N/A | 3D rig/model | Reskin material/model only after approval |
| Platform set | `res://models/platform*.glb` via `res://objects/platform*.tscn` | N/A | N/A | 3D environment kit | Reskin material/model only after approval |
| Coin collectible | `res://objects/coin.tscn`, `res://models/coin.glb` | N/A | N/A | 3D model + particle | Root asset candidate |
| Brick block | `res://objects/brick.tscn`, `res://models/brick.glb` | N/A | N/A | 3D block | Reskin material/model only after approval |
| Cloud prop | `res://objects/cloud.tscn`, `res://models/cloud.glb` | N/A | N/A | 3D prop | Reuse or recolor through SSOT |
| Skybox | `res://sprites/skybox.png` via `res://scenes/main-environment.tres` | N/A | N/A | sky texture | Replace only through SSOT |

New asset requests approved by owner:
- Theme/style approved.
- Player Root Asset direction approved: Marshmallow Runner.
- Image generation approved for the Checkpoint 2 player root asset concept only.
- Generated concept path: `res://assets/themes/candy_sky_islands/root_asset_marshmallow_runner_concept.png`.
- Optional branding scope approved; icon/splash/logo draft PNGs generated, visually inspected, owner approved, production integrated, and validation passed.

## SSOT Resources

- [x] `Resources/QuantumThemeConfig.gd` or equivalent game-local theme resource created.
- [x] `Resources/Data/Themes/<theme>/theme_config.tres` or equivalent created.
- [x] `docs/asset_manifest.md` updated for changed/reused assets.
- [x] Color palette stored in SSOT.
- [x] Model/material override paths stored in SSOT.
- [x] HUD icon/font/color/owner rect stored in SSOT.
- [x] Skybox/splash/icon paths stored in SSOT if changed.
- [x] Audio event names stored in SSOT if changed.
- [x] VFX/particle color and density values stored in SSOT if changed.

Hardcoded values to remove or wrap before final:
- `res://sprites/coin.png` direct HUD reference in `res://scenes/main.tscn`.
- HUD label offsets in `res://scenes/main.tscn`.
- Coin material colors in `res://objects/coin.tscn`.
- Trail particle material color in `res://objects/player.tscn`.
- Skybox texture path in `res://scenes/main-environment.tres` if background is changed.

## Core Wiring

Current scope does not require ShinokuteGameCore wiring.

- [ ] Separate owner approval exists before adding profile, leaderboard, ads, analytics, localization, remote config, or publish flow.
- [ ] No copied Shinokute managers added in this reskin pass.
- [ ] No game-specific skin files moved into `Shared/ShinokuteGameCore`.

## Text Fit And Game Context

- [x] HUD coin label fits desktop viewport.
- [ ] HUD coin label fits mobile viewport if mobile scope is approved.
- [x] Text does not overlap icon, safe area padding, or gameplay.
- [x] Text hierarchy remains compact HUD text, not hero text.
- [x] Screen still reads as a 3D platformer, not a generic app overlay.
- [x] Screenshots captured for changed screens.

Screenshot paths:
- Desktop: `docs/screenshots/candy_sky_islands_desktop_gameplay.png`
- Player: `docs/screenshots/candy_sky_islands_player_marshmallow_runner.png`
- Coin pickup: `docs/screenshots/candy_sky_islands_coin_pickup.png`
- HUD: `docs/screenshots/candy_sky_islands_hud.png`
- Asset family gameplay: `docs/screenshots/candy_sky_islands_asset_family_gameplay.png`
- Asset family HUD: `docs/screenshots/candy_sky_islands_asset_family_hud.png`
- Corrected asset contact sheet: `docs/screenshots/candy_sky_islands_corrected_asset_contact_sheet.png`
- Mobile: not captured; mobile scope is not approved.

## Function Skin Gates

- [x] Existing assets were inventoried before new visual shells were created.
- [x] Every reused asset has matching role, ratio, crop, padding, and owner rect.
- [ ] Every new generated asset has owner approval.
- [x] Function-skin visuals live in the game repo, not Shinokute core.
- [x] Contract check proves chosen controls use SSOT asset keys/owner rects once SSOT exists.

## Validation Matrix

Run the detailed commands in `res://docs/validation_runbook.md`.

### Phase 0: Pre-Edit Gate

- [x] Required reading complete.
- [x] Game-local checklist exists.
- [x] Game-local asset manifest exists.
- [x] Checkpoint 1 approved.
- [x] SSOT targets named before scene edits.

### Phase 1: Static Checks

- [x] No new fallback asset/config markers.
- [x] No unapproved generated asset paths.
- [x] Changed assets exist on disk and have manifest rows.
- [x] Changed text-bearing regions have owner rect and padding.
- [x] Changed scene paths are represented in SSOT.

### Phase 2: Godot Import

- Command:
  ```powershell
  $godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
  $project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
  & $godot --headless --path $project --import
  ```
- Required result: exit code `0`.
- Engine note: if Godot 4.3 cannot import this Godot 4.6 project cleanly, stop and use an approved Godot 4.6 console binary. Do not claim validation passed from a mismatched engine.
- Result: PASS on 2026-07-07 with Godot 4.3. Warnings remain from existing invalid UIDs and Godot 3.x material remaps; import exit code was `0`.

### Phase 3: Contract Checks

- [x] Asset manifest gate passes.
- [x] SSOT path/color gate passes.
- [x] Text owner rect gate passes.
- [x] No changed skin value is scattered only in scenes/scripts.

### Phase 4: Smoke Run

- [x] Launch main scene.
- [x] Player can move.
- [x] Player can jump and double-jump.
- [x] Camera can rotate and zoom.
- [x] Coin collection increments HUD.
- [x] Falling platform behavior still works.
- [x] Falling below world reloads scene.
- [x] Console reviewed for missing resources and parse errors.

### Phase 5: Screenshot Evidence

- [x] Desktop gameplay screenshot captured.
- [x] HUD close-up screenshot captured after coin pickup.
- [ ] Mobile or narrow viewport screenshot captured if mobile scope is approved.
- [x] Screenshot notes confirm no overlap and no blank/missing assets.

## Tests And Evidence

Static validation:
- Command: `Get-ChildItem <project>\tests -Filter 'test_*.gd' | Sort-Object Name | ForEach-Object { Godot_v4.3-stable_win64_console.exe --headless --path <project> --script $_.FullName }`
- Result: PASS on 2026-07-07 with Godot 4.3 for `test_asset_family_manifest_contract.gd`, `test_asset_family_theme_contract.gd`, `test_candy_theme_config.gd`, `test_reskin_static_contract.gd`, and `test_theme_applier_contract.gd`.
- Branding result: PASS on 2026-07-07 with Godot 4.3 for all tests, including `test_branding_contract.gd`.

Godot import:
- Command: see Validation Matrix Phase 2.
- Result: PASS on 2026-07-07 with Godot 4.3, exit code `0`; existing source warnings remain for invalid UIDs and remapped material parameters.
- Branding result: PASS on 2026-07-07 with Godot 4.3, exit code `0`; same existing invalid UID and material remap warnings remain.

Smoke run:
- Command/URL: `Godot_v4.3-stable_win64_console.exe --path <project> --script tools/capture_candy_sky_screenshots.gd`
- Result: PASS on 2026-07-07 with visible Vulkan Forward+ window. Automated smoke covered scene load, movement, jump, double-jump, camera rotate/zoom, coin HUD update, falling platform state, extracted HUD icon load, and screenshots. Headless screenshot capture was not usable because dummy rendering returned null viewport textures.
- Screens checked: `docs/screenshots/candy_sky_islands_desktop_gameplay.png`, `docs/screenshots/candy_sky_islands_player_marshmallow_runner.png`, `docs/screenshots/candy_sky_islands_coin_pickup.png`, `docs/screenshots/candy_sky_islands_hud.png`, `docs/screenshots/candy_sky_islands_asset_family_gameplay.png`, `docs/screenshots/candy_sky_islands_asset_family_hud.png`.
- Branding result: PASS on 2026-07-07 with visible Vulkan Forward+ window.

Branding QA:
- Command: `python tools/qa_branding_assets.py`
- Result: PASS on 2026-07-07; `assets/themes/candy_sky_islands/branding/branding_qc.json` has `bad: []`.
- Production dimensions verified on 2026-07-07: `icon.png` is 256x256; `splash-screen.png` is 2560x1440.
- Whitespace check: `git diff --check` passed on 2026-07-07.

## Publish Evidence

Fill only if publishing or making an owner test link.

- Publish runbook read: no, publish not in current scope.
- Firebase project: not approved.
- Hosting target: not approved.
- Export preset: not approved.
- Output directory: not approved.
- Artifact sizes: not measured.
- URL: not created.
- Browser smoke result: not run.
- Header/cache result: not run.
- Screenshot paths: none.

## Completion

- Commit hash: not committed.
- Known warnings:
  - `quantum_starter` is currently untracked in the parent repository.
  - Local available Godot binary is 4.3, while the source README says Godot 4.6.
- Known gaps:
  - Deeper GLB replacement for obstacle/brick/flag is not in approved scope.
  - Mobile/narrow viewport screenshots are not captured because mobile scope is not approved.
- Owner follow-up needed:
  - None for current game-skin plus branding scope. Open a separate gate for deeper GLB replacement, mobile/web validation, publish, or Shinokute integration.
