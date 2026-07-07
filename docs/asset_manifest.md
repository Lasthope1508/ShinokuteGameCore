# Quantum Starter Asset Manifest

Every reused, generated, edited, or imported asset in the reskin must be listed here before it is placed in production scenes.

## Current Asset Inventory

| Role | Asset Key | Path | Source | Status | Owner Rect | Padding | In-game Size | Proof Screenshot | Notes |
|---|---|---|---|---|---|---|---|---|---|
| App icon | app.icon | `res://icon.png` and `res://assets/themes/candy_sky_islands/branding/app_icon_source.png` | 9Router `cx/gpt-5.5-image` after owner approval | generated, visually approved, pending production copy | N/A | square safe padding | 1024x1024 source, 256x256 production root icon | `res://docs/screenshots/candy_sky_islands_branding_contact_sheet.png` | Marshmallow Runner icon with star-candy cue |
| Splash image | app.splash | `res://splash-screen.png` and `res://assets/themes/candy_sky_islands/branding/splash_candy_sky_islands.png` | 9Router `cx/gpt-5.5-image` after owner approval | generated, visually approved, pending production copy | logo safe area in upper/center space | 16:9 crop | 2560x1440 startup splash | `res://docs/screenshots/candy_sky_islands_branding_contact_sheet.png` | Candy Sky Islands splash with mascot and collectibles |
| Skybox | env.skybox | `res://sprites/skybox.png` | Kenney package | current | N/A | N/A | world environment background | none yet | Referenced by `res://scenes/main-environment.tres` |
| HUD coin icon | hud.coin.icon | `res://sprites/coin.png` | Kenney package | current | N/A | N/A | HUD icon scaled to `0.2` in `main.tscn` | none yet | Text owner rect is separate |
| HUD coin text | hud.coin.text | `res://scenes/main.tscn` node `HUD/Coins` + `res://Resources/Data/Themes/candy_sky_islands/theme_config.tres` | scene label | themed via SSOT | `x=144,y=64,w=224,h=59` | `Vector4(0,0,0,0)` | top-left HUD text | `res://docs/screenshots/candy_sky_islands_hud.png` | Owner rect, font path, font size, and text color stored in theme config |
| HUD font | hud.font.main | `res://fonts/lilita_one_regular.ttf` | package font | current | N/A | N/A | 48 px label setting | none yet | Font license file exists under `res://fonts/license.txt` |
| Player model | player.model | `res://models/character.glb` | Kenney package | current | N/A | N/A | 3D playable character | none yet | Instanced through `res://objects/character.tscn` |
| Player scene | player.scene | `res://objects/player.tscn` + `res://Resources/Data/Themes/candy_sky_islands/theme_config.tres` | Kenney package | themed via runtime material | N/A | N/A | `CharacterBody3D` player | `res://docs/screenshots/candy_sky_islands_player_marshmallow_runner.png` | Contains collider, shadow, trail particles, footsteps; source rig/model unchanged |
| Player shadow | player.shadow | `res://sprites/blob_shadow.png` | Kenney package | current | N/A | N/A | Decal shadow `Vector3(1,2,1)` | none yet | Reuse unless theme needs new shadow |
| Trail particle | player.trail.dust | `res://meshes/dust.res` + `res://Resources/Data/Themes/candy_sky_islands/theme_config.tres` | imported mesh | themed via runtime material | N/A | N/A | player run particles | `res://docs/screenshots/candy_sky_islands_coin_pickup.png` | Trail color token stored in theme config; source mesh unchanged |
| Coin model | collectible.coin.model | `res://models/coin.glb` | Kenney package | current | N/A | N/A | 3D pickup | none yet | Root asset candidate for style anchor |
| Coin scene | collectible.coin.scene | `res://objects/coin.tscn` + `res://Resources/Data/Themes/candy_sky_islands/theme_config.tres` | Kenney package | themed via runtime material | N/A | N/A | `Area3D` pickup | `res://docs/screenshots/candy_sky_islands_coin_pickup.png` | Coin material and particle color tokens stored in theme config; source scene unchanged |
| Coin particle texture | collectible.coin.particle | `res://sprites/particle.png` | Kenney package | current | N/A | N/A | pickup sparkle particle | none yet | Recolor through SSOT if changed |
| Platform small | platform.small | `res://models/platform.glb` + `res://Resources/Data/Themes/candy_sky_islands/theme_config.tres` | Kenney package | themed via runtime material | N/A | N/A | 3D platform | `res://docs/screenshots/candy_sky_islands_desktop_gameplay.png` | Scene wrapper: `res://objects/platform.tscn`; source model unchanged |
| Platform medium | platform.medium | `res://models/platform-medium.glb` + `res://Resources/Data/Themes/candy_sky_islands/theme_config.tres` | Kenney package | themed via runtime material | N/A | N/A | 3D platform | `res://docs/screenshots/candy_sky_islands_coin_pickup.png` | Scene wrapper: `res://objects/platform_medium.tscn`; source model unchanged |
| Platform large round | platform.round.large | `res://models/platform-grass-large-round.glb` | Kenney package | current | N/A | N/A | 3D platform | none yet | Scene wrapper: `res://objects/platform_grass_large_round.tscn` |
| Falling platform | platform.falling | `res://models/platform-falling.glb` + `res://Resources/Data/Themes/candy_sky_islands/theme_config.tres` | Kenney package | themed via runtime material | N/A | N/A | 3D falling platform | `res://docs/screenshots/candy_sky_islands_coin_pickup.png` | Scene wrapper: `res://objects/platform_falling.tscn`; source model unchanged |
| Grass prop | prop.grass | `res://models/grass.glb` | Kenney package | current | N/A | N/A | 3D prop | none yet | Used by round platform scene |
| Grass small prop | prop.grass.small | `res://models/grass-small.glb` | Kenney package | current | N/A | N/A | 3D prop | none yet | Used by round platform scene |
| Brick block | obstacle.brick | `res://models/brick.glb` | Kenney package | current | N/A | N/A | 3D block | none yet | Scene wrapper: `res://objects/brick.tscn` |
| Brick particle | obstacle.brick.particle | `res://models/brick-particle.glb` | Kenney package | current | N/A | N/A | break particles | none yet | Used by brick behavior |
| Cloud prop | prop.cloud | `res://models/cloud.glb` + `res://Resources/Data/Themes/candy_sky_islands/theme_config.tres` | Kenney package | themed via runtime material | N/A | N/A | 3D background prop | `res://docs/screenshots/candy_sky_islands_desktop_gameplay.png` | Cloud color token stored in theme config; source model unchanged |
| Flag goal | goal.flag | `res://models/flag.glb` | Kenney package | current | N/A | N/A | 3D finish marker | none yet | Instanced directly in main scene |
| Shared colormap | material.colormap | `res://models/Textures/colormap.png` | Kenney package | current | N/A | N/A | model palette texture | none yet | Keep or replace only through theme SSOT |
| Jump SFX | audio.jump | `res://sounds/jump.ogg` | Kenney package | current | N/A | N/A | player jump event | none yet | Referenced in `player.gd` |
| Land SFX | audio.land | `res://sounds/land.ogg` | Kenney package | current | N/A | N/A | player land event | none yet | Referenced in `player.gd` |
| Coin SFX | audio.coin | `res://sounds/coin.ogg` | Kenney package | current | N/A | N/A | coin pickup event | none yet | Referenced in `coin.gd` |
| Footstep SFX | audio.walking | `res://sounds/walking.ogg` | Kenney package | current | N/A | N/A | looping footsteps | none yet | Referenced in `player.tscn` |

## Block Kit For Reskin

Fill only after Checkpoint 1 approval.

| Role | Asset Key | Path | Source | Status | Owner Rect | Padding | In-game Size | Proof Screenshot | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Logo | app.logo.main | `res://assets/themes/candy_sky_islands/branding/logo_candy_sky_islands.png` | 9Router `cx/gpt-5.5-image` after owner approval; Photoroom full-image alpha | generated, visually approved | text bounds from alpha trim | transparent padding | 1338x780 transparent PNG | `res://docs/screenshots/candy_sky_islands_branding_contact_sheet.png` | Exact text: Candy Sky Islands |
| Main button shell | ui.button.main | `res://assets/themes/<theme>/button_main.png` | pending owner approval | blocked | not approved | not approved | not approved | none | Only needed if menu UI is added |
| Panel shell | ui.panel.popup | `res://assets/themes/<theme>/panel_popup.png` | pending owner approval | blocked | not approved | not approved | not approved | none | Only needed if popups are added |
| HUD score owner | hud.score.owner | `res://assets/themes/<theme>/hud_score_owner.png` | pending owner approval | blocked | not approved | not approved | not approved | none | Needed if HUD frame changes |
| Player style anchor | player.root_asset | `res://assets/themes/candy_sky_islands/root_asset_marshmallow_runner_concept.png` | image generation via `cx/gpt-5.5-image` | generated, owner-approved | N/A | N/A | 1024x1024 concept/reference PNG | `res://docs/screenshots/candy_sky_islands_player_marshmallow_runner.png` | Root Asset: Marshmallow Runner player; applied as safe runtime material pass |
| Coin style anchor | collectible.root_asset | `res://assets/themes/<theme>/coin_root.png` or `res://models/<theme>/coin.glb` | pending owner approval | blocked | N/A | N/A | not approved | none | Root asset candidate if collectible-led reskin |
| Platform material swatch | material.platform.swatch | `res://assets/themes/<theme>/platform_material.png` | pending owner approval | blocked | N/A | N/A | not approved | none | Use for material consistency |
| Background test swatch | bg.main.swatch | `res://assets/themes/<theme>/skybox_test.png` | pending owner approval | blocked | N/A | N/A | not approved | none | Replace skybox only after approval |
| VFX placeholder | vfx.pickup | `res://assets/themes/<theme>/pickup_particle.png` | pending owner approval | blocked | N/A | N/A | not approved | none | Optional particle replacement |
| Asset family concept sheet | asset_family.concept_sheet | `res://assets/themes/candy_sky_islands/asset_family_concept_sheet.png` | image generation after owner approval | generated, owner-approved | N/A | N/A | 1024x1024 concept/reference PNG | none | Shows collectible, platform kit, HUD, props/background, obstacle, and goal style anchors |
| Star-candy collectible | collectible.star_candy | `res://assets/themes/candy_sky_islands/star_collectible.png` + `res://Resources/Data/Themes/candy_sky_islands/theme_config.tres` | Photoroom full sheet CDP 9223, then owner polygon clone/cut | extracted, alpha/edge QA pass, applied as HUD icon | `computed_rect_px=38,39,318,285` | polygon mask + trim padding 8 | 305x272 PNG alpha | `res://docs/screenshots/candy_sky_islands_asset_family_hud.png` | Output redone from Photoroom alpha sheet; QA in `asset_family_extraction_qc.json` |
| Cake/cloud platform kit | platform.cake_cloud_kit | `res://assets/themes/candy_sky_islands/platform_large.png`, `platform_medium.png`, `platform_small.png`, `platform_long.png` + theme tokens | Photoroom full sheet CDP 9223, then owner polygon clone/cut | extracted, alpha/edge QA pass, material pass applied | owner polygon rects in approved outline manifest | polygon mask + trim padding 8 | 590x371, 358x291, 280x221, 386x233 PNG alpha refs | `res://docs/screenshots/candy_sky_islands_asset_family_gameplay.png` | Existing platform material pass remains; refs redone from Photoroom alpha sheet |
| Star-candy HUD frame | hud.score.frame | `res://assets/themes/candy_sky_islands/hud_score_frame.png` | Photoroom full sheet CDP 9223, then owner polygon clone/cut | extracted, alpha/edge QA pass | `computed_rect_px=382,73,496,216` | polygon mask + trim padding 8 | 482x196 PNG alpha | `res://docs/screenshots/candy_sky_islands_asset_family_hud.png` | Concept frame includes sample digits; output redone from Photoroom alpha sheet |
| Star-candy HUD icon | hud.star_candy.icon | `res://assets/themes/candy_sky_islands/star_collectible.png` | Photoroom full sheet CDP 9223, then owner polygon clone/cut | extracted, alpha/edge QA pass, applied | `computed_rect_px=38,39,318,285` | polygon mask + trim padding 8 | existing HUD icon rect | `res://docs/screenshots/candy_sky_islands_asset_family_hud.png` | Production HUD icon uses corrected star collectible |
| Candy skybox | env.candy_skybox | `res://assets/themes/candy_sky_islands/sky_panel_islands.png` | Photoroom full sheet CDP 9223, then owner polygon clone/cut | extracted, alpha/edge QA pass | `computed_rect_px=924,909,311,200` | polygon mask + trim padding 8 | 307x170 PNG alpha | `res://docs/screenshots/candy_sky_islands_asset_family_gameplay.png` | Panel redone from Photoroom alpha sheet |
| Candy clouds | prop.cloud.sheet_refs | `res://assets/themes/candy_sky_islands/cloud_large.png`, `cloud_mid.png`, `cloud_bottom.png`, `cloud_bottom_small.png` | Photoroom full sheet CDP 9223, then owner polygon clone/cut | extracted, alpha/edge QA pass, material pass applied | owner polygon rects in approved outline manifest | polygon mask + trim padding 8 | 332x227, 166x113, 233x108, 177x108 PNG alpha refs | `res://docs/screenshots/candy_sky_islands_asset_family_gameplay.png` | Existing cloud GLB remains in game; refs guide material pass |
| Candy wafer obstacle | obstacle.wafer.ref | `res://assets/themes/candy_sky_islands/wafer_obstacle.png` | Photoroom full sheet CDP 9223, then owner polygon clone/cut | extracted, alpha/edge QA pass | `computed_rect_px=26,879,496,294` | polygon mask + trim padding 8 | 474x289 PNG alpha | none | Existing brick GLB remains unless later model replacement is approved |
| Candy goal flag | goal.candy_pennant.ref | `res://assets/themes/candy_sky_islands/goal_flag.png` | Photoroom full sheet CDP 9223, then owner polygon clone/cut | extracted, alpha/edge QA pass | `computed_rect_px=940,412,303,471` | polygon mask + trim padding 8 | 277x443 PNG alpha | none | Existing flag GLB remains unless later model replacement is approved |

## Generated Asset Log

| Date | Prompt/Source | Cost Approval | Output Path | Reviewed PNG | Accepted | Notes |
|---|---|---|---|---|---|---|
| 2026-07-07 | Marshmallow Runner player root asset prompt via `cx/gpt-5.5-image` | owner approved in chat for Checkpoint 2 concept only | `res://assets/themes/candy_sky_islands/root_asset_marshmallow_runner_concept.png` | yes | yes | Full-body 3D mascot concept; not yet applied to game |
| 2026-07-07 | Asset Family concept sheet prompt via `cx/gpt-5.5-image` and owner-approved system-key fallback | owner approved in chat for Checkpoint 3 concept sheet | `res://assets/themes/candy_sky_islands/asset_family_concept_sheet.png` | yes | yes | Concept sheet includes star collectible, HUD frame, cake/cloud platforms, clouds, wafer obstacle, and goal flag |
| 2026-07-07 | Cloned sheet regions processed through Photoroom CDP port 9223 | owner approved sheet extraction in chat | `res://assets/themes/candy_sky_islands/*_photoroom.png` and final trimmed PNGs | yes | no | Rejected after crop edge audit found risky sheet boundaries; redo requires visual custom rect approval before Photoroom |
| 2026-07-07 | Full concept sheet processed through Photoroom CDP port 9223, then owner polygon clone/cut and alpha trim | owner finalized polygon data and approved contact sheet in chat | `res://assets/themes/candy_sky_islands/source/asset_family_concept_sheet_photoroom.png` and corrected final PNGs | yes | yes | 15 assets passed alpha extrema and edge QA; owner approved `docs/screenshots/candy_sky_islands_corrected_asset_contact_sheet.png` |

## Runtime Theme SSOT

| Token Key | Resource | Runtime Consumer | Proof Screenshot | Notes |
|---|---|---|---|---|
| palette.sky | `res://Resources/Data/Themes/candy_sky_islands/theme_config.tres` | `res://scripts/theme_applier.gd` | `res://docs/screenshots/candy_sky_islands_desktop_gameplay.png` | Approved `#79C7F2`; used as trail backlight token |
| palette.surface | `res://Resources/Data/Themes/candy_sky_islands/theme_config.tres` | `res://scripts/theme_applier.gd` | `res://docs/screenshots/candy_sky_islands_desktop_gameplay.png` | Approved `#FFF2C7`; used for platform material pass |
| palette.primary | `res://Resources/Data/Themes/candy_sky_islands/theme_config.tres` | `res://scripts/theme_applier.gd` | `res://docs/screenshots/candy_sky_islands_coin_pickup.png` | Approved `#FF6F61`; used for coin material pass |
| palette.accent | `res://Resources/Data/Themes/candy_sky_islands/theme_config.tres` | `res://scripts/theme_applier.gd` | `res://docs/screenshots/candy_sky_islands_coin_pickup.png` | Approved `#7BE0AD`; used for rim/trail tokens |
| hud.coin.text.owner | `res://Resources/Data/Themes/candy_sky_islands/theme_config.tres` | `res://scripts/theme_applier.gd` | `res://docs/screenshots/candy_sky_islands_hud.png` | Owner rect and padding controlled by theme config |

## Asset Test Scene Evidence

- Scene path: not created yet.
- Desktop screenshot: none.
- Mobile screenshot: none.
- [ ] All Block Kit assets render in intended roles.
- [ ] Text-bearing blocks have owner rect and padding.
- [ ] In-game Size is recorded for every accepted block.
- [ ] Screen still reads as a 3D platformer.

## Manifest Validation Rules

- Every changed asset must have one row in this file before scene integration.
- Every text-bearing asset must have owner rect and padding before text placement.
- Every generated asset must have cost approval and visual review recorded.
- Every runtime path used by new reskin code must map to an asset key in this file or to a theme SSOT key.
- No asset may be marked accepted without proof screenshot after placement.
