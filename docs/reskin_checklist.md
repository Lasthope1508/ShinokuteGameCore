# Quantum Starter Reskin Checklist

Use this checklist before editing production scenes, generating assets, or claiming the reskin is ready.

## Project

- Game name: Candy Sky Islands
- Repo path: `C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter`
- Reskin goal: Candy Sky Islands visual reskin for the existing 3D platformer template
- Owner-approved scope: game-skin first pass for theme palette, SSOT, HUD visual tokens, environment/material direction, root asset planning, asset family extraction, and app branding
- Target platforms: desktop smoke first; HTML5 mobile controls opened by owner on 2026-07-10 for cross-device testing
- License status: code MIT; included 2D sprites, 3D models, and sounds are CC0 per `README.md`
- Main scene: `res://scenes/main.tscn`
- Current gameplay core: 3D platformer controller, double jump, collectible coins, falling platforms, camera rotate/zoom, keyboard/mouse, gamepad, and Roblox-like HTML5 touch input
- Current engine note: README names Godot 4.6; local available console binary found at `C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe`

## Canonical Core/Asset Standard

This project follows the single Shinokute reskin standard:

- Reusable function behavior lives in `ShinokuteGameCore`.
- Candy Sky Islands keeps only game adapters/wrappers, gameplay-specific rules/application, and Candy-owned UI/function skin.
- UI skin/layout SSOT and asset checklist must exist before UI, HUD, function skin, or platform work.
- Asset manifest must map every old/default role to a canonical Candy Sky Islands asset key, status, in-game size, source, proof, and platform usage.
- iOS, Android, HTML5, and Roblox must consume the same canonical asset keys and art/audio/source assets.
- Platform-specific code may adapt input, safe area, export shell, renderer, storage bridge, or API glue only inside the platform layer/branch/shim.
- Platform-specific generated files are derivatives of canonical asset keys, not separate design branches.
- No reusable function code may be copied into game scenes or platform branches when core owns the behavior.

Current Candy layer split:

| Layer | Owner | Candy status |
|---|---|---|
| Profile, username, settings, leaderboard, input router, 3D player controller, follow camera, mobile touch controller, function overlay grouping | `res://addons/shinokute_game_core` | Core-owned; Candy uses thin wrappers/config |
| Candy UI/function skin, HUD, username prompt, settings panel, leaderboard panel, mobile visual controls | Candy game repo | Game-owned presentation, theme assets, layout |
| Candy asset keys, text owner rects, fonts, audio routes, HUD metrics, model paths | `Resources/Data/Themes/candy_sky_islands/theme_config.tres`, `docs/asset_manifest.md`, `docs/default_skin_size_ssot.md` | Canonical SSOT |
| HTML5 shell/export/iOS Web pointer bridge | HTML5 platform layer plus core mobile controller hooks | Platform-specific code path; must still read canonical assets |
| iOS, Android, Roblox | Future platform layers | Must reuse canonical Candy asset keys; no new art branch without owner approval |

## Required Reading

- [x] `Doc/Art Design Document â€” 2D & Giáº£ 3D Game Mobile (Godot 4).md` read.
- [x] `Shared/ShinokuteGameCore/AGENTS.md` read.
- [x] `Shared/ShinokuteGameCore/docs/reskin_core_skin_boundary.md` read.
- [x] `Shared/ShinokuteGameCore/docs/reskin_runbook.md` read.
- [x] `Shared/ShinokuteGameCore/docs/asset_generation_guardrails.md` read.
- [x] `Shared/ShinokuteGameCore/docs/reskin_checklist_template.md` read.
- [x] `Shared/ShinokuteGameCore/templates/new_game/docs/asset_manifest.md` read.
- [x] `Html5_SourceGames/Godot/quantum_starter/docs/reskin_baked_asset_runbook.md` read.
- [x] `Html5_SourceGames/Godot/quantum_starter/docs/reskin_2d_character_to_3d_runbook.md` read before any owner-supplied 2D character to 3D player work.
- [x] `Html5_SourceGames/Godot/quantum_starter/docs/blender_mcp_discovery_runbook.md` read before any Blender/MCP/GLB work.
- [x] `Html5_SourceGames/Godot/quantum_starter/README.md` read.
- [x] `Html5_SourceGames/Godot/quantum_starter/LICENSE.md` read.
- [ ] Game-local publish checklist read if web/mobile publish enters scope.

## Scope Classification

- [x] Game skin only for first pass.
- [x] Function skin only.
- [ ] Rules adapter work.
- [ ] Shared core work.
- [ ] Publish/release work.

Notes:
- First pass must keep movement, camera, collision, coin collection, and falling platform behavior unchanged.
- ShinokuteGameCore username/profile/leaderboard wiring is approved for this source as of 2026-07-10.
- Ads/publish flow still needs separate owner approval and checklist before wiring.

## Approval Gates

### Checkpoint 0: Default Skin Size SSOT

- [x] Default skin size SSOT exists: `docs/default_skin_size_ssot.md`.
- [x] Default image pixel sizes recorded.
- [x] Default 3D AABB sizes recorded.
- [x] Default HUD runtime rects recorded.
- [x] Every default visual/audio role maps to a Candy Sky Islands asset, wrapper state, pending state, unused candidate, or audio replacement state.
- [x] Wrapper roles are not marked as full model replacements.
- [x] Default size SSOT contract exists: `tests/test_default_skin_size_ssot_contract.gd`.

Hard gate:
- Do not present visual design options, generate images, run Photoroom, extract sheets, create wrappers, or replace models before this SSOT is read and updated for the target role.
- Do not resize generated outputs blindly to match bounding boxes. Preserve role scale, collider envelope, or UI rect based on this SSOT unless the owner approves a size change.
- Do not use dummy primitive meshes, rough placeholder geometry, or primitive-only Blender output as production reskin replacements. Production visuals must derive from approved reference art, Photoroom/outline extraction, owner-approved generated art, or a model whose silhouette/material cues are traceable to those references.
- For default 3D assets with nonzero volume/depth, do not mark a flat `Sprite3D`, billboard, screenshot, or reference PNG as a full 3D replacement unless the owner explicitly approves a flat 2D downgrade. A volumetric default role needs a real 3D replacement or a clearly marked temporary/interim state.
- For owner-supplied 2D player characters, `docs/reskin_2d_character_to_3d_runbook.md` is mandatory. Use the supplied character as reference, run Photoroom on the full source image/sheet, polygon-extract the clean source pose, use 9Router with that reference to generate full turnaround/multiview sprites, run Photoroom on the full generated sheet, polygon-extract every view/sprite, then start 3D reconstruction/render. The final 3D player must preserve the supplied character image identity and real 3D volume. Do not substitute a Blender piece-built approximation, primitive kitbash, single flat extrusion, or redesigned character unless the owner explicitly approves that downgrade/redesign.
- Before Blender/MCP/GLB work, `docs/blender_mcp_discovery_runbook.md` is mandatory. If the current Codex tool surface has no `mcp__blender`, check `C:\Users\Admin\.gemini\config\mcp_config.json` and `C:\Users\Admin\.gemini\config\skills\blender_mcp\SKILL.md` before using CLI fallback. Do not claim Blender MCP is missing just because it is not exposed as a current Codex tool.

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

### Checkpoint 5: Deep Reskin

- [x] Owner approved Approach A: deep-but-safe visual reskin.
- [x] Owner previously approved stopping before SFX replacement for the deep visual gate.
- [x] Deep Reskin design spec written: `docs/superpowers/specs/2026-07-07-candy-sky-islands-deep-reskin-design.md`.
- [x] Owner reviewed written Deep Reskin spec.
- [x] Deep Reskin implementation plan written: `docs/superpowers/plans/2026-07-07-candy-sky-islands-deep-reskin.md`.
- [x] Deep visual roles represented in SSOT.
- [x] Deep manifest contract passes.
- [x] Audio inventory includes `break` and `fall`.
- [x] Existing SFX paths are routed through SSOT without replacing `.ogg` files.
- [x] Collectible visual replacement group owner approved.
- [x] Platform visual replacement group owner approved.
- [x] Obstacle visual replacement group owner approved.
- [x] Goal visual replacement group owner approved.
- [x] Props/background visual replacement group owner approved.
- [x] Dust/particle/colormap cleanup owner approved.
- [x] Dust/particle/colormap cleanup validation passed.
- [x] Player model wrapper group owner approved if attempted.
- [x] Deep visual validation passed.
- [x] Original stop before SFX replacement confirmed for deep visual scope.
- [x] Candy Island BGM/SFX replacement applied after separate owner instruction on 2026-07-10.
- [x] Full HUD design source cleanup completed.
- [x] Deeper legacy GLB model replacement completed for active production scenes; audio-only roles now route to Candy Island processed OGG assets.
- [x] Platform kit GLB replacement completed for small, medium, falling, round platform, grass, and small grass visuals.
- [x] Cloud reference-art replacement validation completed.
- [x] Obstacle and goal GLB replacement validation completed.
- [x] Collectible GLB replacement validation completed.
- [x] Legacy player shadow replacement completed.
- [x] Legacy colormap dependency removed or fully justified.

Note:
- Collectible option C selected. Owner explicitly approved AI generation and system-key fallback on 2026-07-08.
- First multi-view generated sheet was rejected after visual review; it must not be extracted or integrated: `assets/themes/candy_sky_islands/source/deep_collectible_star_candy_reference_sheet.png`.
- Second generated single-object reference: `assets/themes/candy_sky_islands/source/deep_collectible_star_candy_reference_attempt2.png`.
- Deep collectible Photoroom full-image pass completed before trim: `assets/themes/candy_sky_islands/source/deep_collectible_star_candy_reference_attempt2_photoroom.png`; alpha QA: `assets/themes/candy_sky_islands/source/deep_collectible_star_candy_attempt2_photoroom_qc.json`.
- Owner approved skipping manual polygon for the one isolated object. Trimmed reference created from the Photoroom alpha output only: `assets/themes/candy_sky_islands/deep_star_candy_model_reference.png`; QA: `assets/themes/candy_sky_islands/deep_star_candy_model_reference_qc.json`.
- Collectible wrapper applied to `objects/coin.tscn` as a `Sprite3D` visual child while preserving `Area3D`, collision, pickup signal, score increment, and `Audio.play_event("coin")`.
- Collectible wrapper validation passed on 2026-07-08: `test_deep_collectible_wrapper_contract.gd`, full Godot script test suite, Godot import, and visible smoke screenshot capture.
- Collectible role moved from Sprite3D wrapper/legacy coin internals to Candy GLB visual on 2026-07-08; `Area3D`, collision, pickup signal, score increment, particles, and `Audio.play_event("coin")` remain unchanged. Focused contracts, full tests, Godot import, visible smoke screenshot capture, and visual proof inspection passed.
- Platform option B selected and owner approved on 2026-07-08: local cake/cloud wrapper meshes around existing platform scenes, with colliders, layout, and falling behavior preserved.
- Platform wrapper validation passed on 2026-07-08: `test_deep_platform_wrapper_contract.gd`, full Godot script test suite, Godot import, and visible smoke screenshot capture. Proof: `docs/screenshots/candy_sky_islands_platform_wrapper.png`.
- Platform GLB replacement applied on 2026-07-08 with Blender 4.2 CLI authored Candy GLBs. Small, medium, falling, round platform, grass, and small grass scene visuals now reference `res://assets/themes/candy_sky_islands/models/*.glb`; colliders, falling Area3D, signal, script, layout, and SFX routing remain unchanged. Focused contracts, full tests, import, and visible smoke screenshot capture passed in this subgate.
- Obstacle/goal option B covered by owner broad approval on 2026-07-08: local wrapper visual meshes around existing brick and flag nodes, with brick collision/break behavior and flag world placement preserved. Validation passed on 2026-07-08 with `test_deep_obstacle_goal_wrapper_contract.gd`, full Godot script test suite, Godot import, visible smoke screenshot capture, and `git diff --check`. Proof: `docs/screenshots/candy_sky_islands_obstacle_goal_wrapper.png`.
- Obstacle and goal roles moved from wrapper/legacy visual refs to Candy GLB visual refs on 2026-07-08; brick collider, bottom detector, break particles, `Audio.play_event("break")`, and `World/flag` transform remain unchanged. Focused contracts, full tests, Godot import, visible smoke screenshot capture, and visual proof inspection passed.
- Props/background option B covered by owner broad approval on 2026-07-08: local candy cloud wrapper, round platform/grass wrapper, and skybox SSOT routing. Validation passed on 2026-07-08 with `test_deep_props_background_wrapper_contract.gd`, full Godot script test suite, Godot import, visible smoke screenshot capture, visual proof inspection, and `git diff --check`. Proof: `docs/screenshots/candy_sky_islands_props_background_wrapper.png`.
- Round platform and grass roles moved from wrapper/legacy visual refs to Candy GLB visual refs on 2026-07-08. Cloud production visual now uses reference-derived volumetric `cloud_candy_volume.glb` built from the approved Photoroom `cloud_large.png` alpha silhouette after primitive-only `cloud_candy.glb` was demoted as dummy evidence.
- Dust/particle/colormap option B selected by owner on 2026-07-08: local Godot VFX/material cleanup, no new image generation, no `.ogg` replacement. Validation passed on 2026-07-08 with `test_deep_vfx_material_cleanup_contract.gd`, full Godot script test suite, Godot import, visible smoke screenshot capture, and proof inspection. Proof: `docs/screenshots/candy_sky_islands_vfx_material_cleanup.png`.
- Collectible halo artifact fix applied on 2026-07-08: `CandyPickupHalo` uses `assets/themes/candy_sky_islands/meshes/star_candy_halo_mesh.tres`, based on the real `star_candy_collectible.glb` star proportions, not a square `QuadMesh`; the halo mesh owns a real surface material and is excluded from coin body recolor passes.
- Optional player wrapper group approved by owner on 2026-07-08 after B cleanup. It must preserve player controller, rig, animation, collider, camera target, movement, jump, double jump, footsteps, and in-place fall retry behavior.
- Optional player wrapper validation passed on 2026-07-08 with `test_deep_player_wrapper_contract.gd`, full Godot script test suite, Godot import, visible smoke screenshot capture, and proof inspection. Proof: `docs/screenshots/candy_sky_islands_player_wrapper.png`.
- Player full GLB replacement applied and validated on 2026-07-08 with Blender 4.2 CLI authored Candy marshmallow GLB. `objects/character.tscn` now references `assets/themes/candy_sky_islands/models/character_candy_marshmallow.glb` instead of legacy `models/character.glb`; `objects/player.tscn` preserves `CharacterBody3D`, script, collider, `Character/AnimationPlayer`, trail particles, footsteps, shadow, movement, jump, double jump, and in-place fall retry behavior. Proof: `docs/screenshots/candy_sky_islands_player_glb_replacement.png`.
- Shinokute human player replacement subgate completed after owner selected option C on 2026-07-08. Source order followed: owner sheet, Photoroom full sheet first, polygon hand-sign pose extraction, 9Router cleanup from the extracted pose to remove baked sheet/grid artifacts, Photoroom full-image alpha, Blender 4.2 CLI volumetric GLB, and `objects/character.tscn` integration. `AnimationPlayer` still exposes `idle`, `walk`, and `jump`, plus future `run`; animation step is 1/60s; idle uses hand-sign/aura motion instead of a static stance. Validation passed.
- CHR077 Skeleton Mage player replacement applied and focused-validation passed on 2026-07-09 from KayKit Skeletons character pack, catalog ID CHR077, CC0 1.0 commercial use allowed with no attribution required. `objects/character.tscn` now references `assets/themes/candy_sky_islands/models/character_chr077_skeleton_mage.glb`; Shinokute-only aura animation target removed; `AnimationPlayer` still exposes `idle`, `walk`, `jump`, and future `run`; animation step is 1/60s.
- Player scale-envelope correction applied on 2026-07-10 after the SSOT gap was found: `player.visual_target_height = 1.30 u`, `player.visual_allowed_height = 1.10..1.35 u`, and `player.visual_scale_policy` now live in `docs/default_skin_size_ssot.md`; CHR077 is under `CHR077SkeletonMageSlot` scale `0.5`, with animation tracks kept off the parent scale so base scale is not overwritten.
- Deep visual validation passed for all approved/applied visual groups on 2026-07-08.
- Final SFX stop confirmed on 2026-07-08: no `.ogg` replacement, `git diff -- sounds` clean, and `git status --short -- sounds` clean.
- Historical SFX stop confirmed on 2026-07-08: no `.ogg` replacement during the visual deep-reskin gate.
- Candy Island BGM/SFX replacement applied on 2026-07-10 from owner-provided `Audio/Candy Island`; BGM Loop_1 + Loop_2 were silence-trimmed before concat and encoded OGG Vorbis for mobile size.
- Roblox-like mobile controls applied on 2026-07-10: core `ShinokuteInputRouter` owns canonical move/look/jump/zoom and last-input scheme detection; Candy owns the visual touch overlay with left dynamic thumbstick, right jump button, right-side look drag, iOS Web pointer bridge, mouse fallback, and two-finger pinch zoom. HTML5 export must keep an iOS-safe dynamic viewport head include so canvas resizes on portrait/landscape rotation. Move/jump guard zones must reject look capture first, so slipped joystick thumbs and missed jump taps cannot become camera spin input. While touch controls are active, raw `InputEventMouseMotion` must not rotate `View`; mobile look must come only from routed touch look delta. Mouse fallback is move/jump-only and must never emit look, because mobile Web can merge multiple fingers into one mouse stream. Right-hand look on Web uses the JS pointer bridge with `pointerId` ownership.
- Future mobile/camera edits must be checked against Roblox-style references first: cross-platform input, `PreferredInput`, mobile gestures, and CoreScripts camera module split. Required architecture: one canonical input router, pointer ownership per touch, and no duplicate camera-look path for the same physical gesture.
- Shinokute core central 3D controller extraction is active as of 2026-07-11. Reusable 3D player control, follow camera, Shift Lock, routed desktop/mobile input, guard zones, pinch zoom, and Web pointer-id bridge live under `addons/shinokute_game_core/controllers/`. Candy scripts `player.gd`, `view.gd`, and `candy_mobile_touch_controls.gd` must stay thin wrappers unless a future game needs skin-only overrides.
- Shinokute core must not hardcode game names, game-node paths, JS globals, DOM ids, theme folders, or skin asset names from Candy Sky Islands or any future reskin. Core controller defaults stay generic/empty; each game scene or wrapper wires its own `GameCore`, `ShinokuteInputRouter`, theme config, UI skin, and asset paths. `test_shinokute_3d_controller_core_contract.gd` is the boundary guard.
- `ShinokuteReskinBoundaryAudit` is the reusable core helper for next-game audits. Run it or the matching contract before and after moving behavior into core; it catches game-name leaks, game asset paths, stale JS globals, and duplicate game-local schema names inside reusable modules.
- Shinokute core owns reusable progression schema as `ShinokuteProgressionCatalog` and `ShinokuteProgressionLevel`. Candy Sky Islands may own `Resources/Data/Progression/candy_sky_islands_obby_progression.tres` data and the `scripts/obby_stage_builder.gd` adapter that maps abstract segment keys to Candy scenes, but must not keep duplicate game-local progression schema scripts.
- Shinokute core owns reusable dynamic progression through `ShinokuteDynamicProgressionResolver`; Candy Sky Islands owns only `dynamic_progression_profile` curve data. Infinite 3D obby difficulty must be deterministic per visible level number, fair across retries/devices, capped by the measured jump envelope, and scaled through route length, platform count, route width, turn cycles, ascent/descent, platform mix, hazard density, and timing instead of impossible jump gaps.
- Unikey/IME safety is part of Shinokute input core as of 2026-07-11. Web keyboard movement must clear stale action state on router ready and on Web `keyup`/`blur`/`visibilitychange`/`compositionstart`; `move_left`/A must not stay pressed if Vietnamese IME loses the keyup event.
- Function overlay safety is part of Shinokute UI core as of 2026-07-11. Any HUD function panel that appears over gameplay must join `ShinokuteFunctionOverlayGroup`, keep only one same-group panel visible at a time, set gameplay-adjacent buttons to `Control.FOCUS_NONE`, and release UI focus after clicks so Space/gameplay keys cannot retrigger Settings, Leaderboard, tabs, close buttons, or toggles.
- Web selected-resource export must include every runtime helper preloaded by exported scripts. After adding a core/helper script, update `export_presets.cfg` `export_files`, then extend `test_web_export_preset_contract.gd` before exporting. Do not trust editor/headless tests alone; Firebase/Web PCK can miss a helper and make UI scripts parse-fail only on device.

Core Learning Gate:
- Before leaving a reskin, list each reusable behavior discovered from the game and decide whether it belongs in Shinokute core, game-owned skin/config, or platform-owned adapter code.
- If a behavior is reusable, add it to `addons/shinokute_game_core` or create a core-facing schema/interface. If it stays game-owned, document why in the manifest/checklist.
- Add or update a boundary contract so the next reskin cannot regress into duplicated managers, copied schema classes, or hardcoded game names inside core.

Platform Input Matrix:
- Record PC keyboard/mouse, mobile touch, iOS Web, Android Web/native, HTML5 desktop, and Roblox parity expectations before changing controls.
- Input behavior must route through one core input path where possible; platform adapters may translate gestures, but must not create a second camera/movement path.
- HTML5 desktop and HTML5 mobile are separate runtime profiles. Desktop Web uses keyboard/mouse/gamepad and must not show the mobile thumbstick/jump overlay on load. Web mobile enables touch overlay only through Godot mobile Web feature tags such as `web_android`/`web_ios`, native mobile tags, or explicit test/owner force; do not auto-enable it from generic browser touch capability such as `navigator.maxTouchPoints` or CSS coarse pointer, because Windows touch laptops and browser emulation can report those on desktop.

Export Audit:
- After core/schema/export edits, scan `export_presets.cfg` and the generated PCK for stale game-local schema names, authoring-only files, debug/source paths, old JS globals, and missing selected runtime helpers.
- Do not publish or hand off a test link if stale markers remain in selected export resources or PCK content.

Hard gate:
- Do not generate, replace, or approve new SFX in this checkpoint.
- Do not create visual replacements for a group until that group has owner approval.
- Do not use grid slicing.
- Run Photoroom on the full approved sheet before polygon/outline object extraction.
- If an approved asset has baked sample content, read `docs/reskin_baked_asset_runbook.md` and use the baked asset as the 9Router reference before Photoroom/trim/QA. Do not do local paint/Pillow cleanup first unless owner approves fallback.
- Do not accept dummy primitive meshes, rough placeholder geometry, or primitive-only Blender scripts as production visual replacements.
- When converting an owner-supplied 2D character sheet into a 3D player, the production visual must follow the 2D character to 3D runbook: 9Router reference-based multiview sprites, Photoroom full generated sheet, polygon extraction for each sprite/view, and only then 3D reconstruction/render. Piece-built Blender approximations, primitive kitbashes, and single flat extrusions are rejected unless separately owner-approved as redesign/downgrade.

## Existing Asset Inventory

Asset manifest:

- Path: `res://docs/asset_manifest.md`
- Default size SSOT: `res://docs/default_skin_size_ssot.md`
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
| HUD score text | `res://scenes/main.tscn` label `Coins` | `offset_left=144, offset_top=64, offset_right=368, offset_bottom=123` | `hud_text_owner_rect` in `theme_config.tres`; frame rect in `hud_score_frame_rect` | fixed HUD rect | Scene defaults mirror SSOT; runtime applier owns final rects |
| Font | `res://fonts/lilita_one_regular.ttf` | N/A | N/A | font asset | Reuse unless theme requires change |
| Player model | `res://models/character.glb` legacy via `res://objects/character.tscn`; replacement `res://assets/themes/candy_sky_islands/models/character_chr077_skeleton_mage.glb` | N/A | N/A | 3D rig/model | CHR077 Skeleton Mage GLB replacement applied; scale slot `0.5` enforces target visual height near `1.30 u`; controller/collider/animation names preserved; `idle`/`walk`/`jump`/`run` use 1/60s animation step |
| Platform set | `res://models/platform*.glb` via `res://objects/platform*.tscn` | N/A | N/A | 3D environment kit | Reskin material/model only after approval |
| Coin collectible | `res://objects/coin.tscn`, `res://models/coin.glb` legacy + `res://assets/themes/candy_sky_islands/models/star_candy_collectible.glb` replacement | N/A | N/A | 3D model + particle | Candy GLB replacement applied |
| Brick block | `res://objects/brick.tscn`, `res://models/brick.glb` legacy + `res://assets/themes/candy_sky_islands/models/brick_candy_wafer.glb` replacement | N/A | N/A | 3D block | Candy GLB replacement applied |
| Cloud prop | `res://objects/cloud.tscn`, `res://models/cloud.glb` legacy + `res://assets/themes/candy_sky_islands/cloud_large.png` reference + `res://assets/themes/candy_sky_islands/models/cloud_candy_volume.glb` production GLB | N/A | N/A | 3D prop | Reference-derived volumetric GLB replacement applied; primitive-only `cloud_candy.glb` demoted; flat `Sprite3D` interim visual removed |
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
- [x] Audio event names and BGM path stored in SSOT if changed.
- [x] VFX/particle color and density values stored in SSOT if changed.
- [x] `QuantumThemeConfig.gd` fallback defaults point to Candy HUD star, Candy skybox, Candy Island BGM, and full Candy Island audio event routes; old HUD coin and skybox remain only as `legacy_path` source evidence.

Hardcoded values to remove or wrap before final:
- `res://sprites/coin.png` direct HUD reference in `res://scenes/main.tscn` removed on 2026-07-08; scene source now uses approved star collectible.
- HUD label offsets and `CandyScoreFrame` runtime rect are routed through `theme_config.tres`; scene defaults mirror SSOT for editor readability.
- Coin material colors in `res://objects/coin.tscn`.
- Trail particle material color in `res://objects/player.tscn`.
- Skybox texture path in `res://scenes/main-environment.tres` if background is changed.

Final visual notes:
- HUD source cleanup added `CandyScoreFrame` from `hud_score_frame_clean_9router.png`, removed the old coin icon source reference, removed hidden legacy `Icon`/`x` nodes, and routes frame/text rects through SSOT.
- Player now uses the CHR077 Skeleton Mage GLB replacement while preserving controller, collider, `Character/AnimationPlayer`, movement, jump, double jump, footsteps, and in-place fall retry behavior. The prior Candy marshmallow and Shinokute human GLBs remain source/history evidence only unless owner reverts direction.
- Coin pickup uses a star-candy GLB visual; `CandyPickupHalo` uses the real star-shaped halo mesh with a real surface material; legacy colormap resource no longer exists in the scene. Legacy particle texture still exists for pickup sparkle compatibility.
- Platform kit, brick, goal, and cloud visuals use Candy GLBs while preserving collider/layout/script contracts. Cloud uses `cloud_candy_volume.glb`, generated from the approved Photoroom `cloud_large.png` alpha silhouette, while preserving scene movement script and transforms.
- Player shadow now uses `res://assets/themes/candy_sky_islands/player_shadow_soft.png` while preserving the default `Vector3(1,2,1)` Decal scale.
- Residual non-production assets: `platform.large` and `block-coin` are inventoried unused candidates, not redesigned production assets; `models/Textures/colormap.png` remains source evidence only.

## Core Wiring

- [x] Owner approval exists for profile/username/leaderboard wiring.
- [x] Candy uses `res://addons/shinokute_game_core/core/game_core.gd`, `PlayerProfile`, and `LeaderboardClient` through `scripts/candy_game_core_bridge.gd`.
- [x] Candy owns `Resources/Data/Core/candy_sky_islands_game_core_config.tres` as the SSOT for Firebase, leaderboard collection, score label, username policy, theme, and progression references.
- [x] Candy HUD owns `LeaderboardButton` and `LeaderboardPanel`; UI reads rows only from `CandyGameCore.leaderboard_loaded` and fetches only through `CandyGameCore.fetch_leaderboard`.
- [x] Candy HUD Settings and Leaderboard panels use Shinokute core function overlay grouping; Settings and Leaderboard cannot stay open together, and their buttons cannot keep keyboard focus or steal Space jump.
- [x] Core wiring is treated as logic/service only; Candy-owned function-skin UI is required before username/profile/leaderboard can be marked production done.
- [x] Enabled Candy shared-feature UI uses Candy-owned scene nodes plus Candy SSOT/config, not generic core demo UI.
- [x] Candy username overlay now points to `res://scenes/ui/candy_username_prompt_overlay.tscn`, not Shinokute core demo UI.
- [x] No copied Shinokute managers added in this reskin pass.
- [ ] Separate owner approval exists before adding ads or publish flow.
- [ ] No game-specific skin files moved into `Shared/ShinokuteGameCore`.

## Text Fit And Game Context

- [x] HUD coin label fits desktop viewport.
- [x] HUD frame uses an explicit compact rect and must ignore natural texture size for generated/trimmed PNGs.
- [x] HUD score text is centered horizontally/vertically inside the cleaned frame, starts after the star icon, uses 44 px font size, and uses dark Candy text instead of default white.
- [ ] HUD coin label fits mobile viewport if mobile scope is approved.
- [x] Text does not overlap icon, safe area padding, or gameplay.
- [x] Text hierarchy remains compact HUD text, not hero text.
- [x] Screen still reads as a 3D platformer, not a generic app overlay.
- [x] Screenshots captured for changed screens.

Screenshot paths:
- Desktop: `docs/screenshots/candy_sky_islands_desktop_gameplay.png`
- Player: `docs/screenshots/candy_sky_islands_player_marshmallow_runner.png`
- Player GLB replacement: `docs/screenshots/candy_sky_islands_player_glb_replacement.png`
- Cloud 3D parity close-up: `docs/screenshots/candy_sky_islands_cloud_3d_parity.png`
- Coin pickup: `docs/screenshots/candy_sky_islands_coin_pickup.png` (deep star-candy wrapper visible)
- Coin halo close-up: `docs/screenshots/candy_sky_islands_star_halo_closeup.png`
- HUD: `docs/screenshots/candy_sky_islands_hud.png`
- Function UI contact sheet: `docs/screenshots/candy_function_ui_contact_sheet.png`
- Function UI leaderboard: `docs/screenshots/candy_function_ui_leaderboard.png`
- Function UI username prompt: `docs/screenshots/candy_function_ui_username.png`
- Function UI text-fit correction: `test_candy_function_skin_text_fit_contract.gd` validates content margins, row text owner margins, and compact font sizes after owner reported text overlapping UI art.
- Asset family gameplay: `docs/screenshots/candy_sky_islands_asset_family_gameplay.png`
- Asset family HUD: `docs/screenshots/candy_sky_islands_asset_family_hud.png`
- Corrected asset contact sheet: `docs/screenshots/candy_sky_islands_corrected_asset_contact_sheet.png`
- Mobile: not captured; mobile scope is not approved.

## Function Skin Gates

- [x] Existing assets were inventoried before new visual shells were created.
- [x] Candy-owned leaderboard UI exists for the enabled leaderboard feature.
- [x] Candy-owned username prompt UI exists for the enabled username/profile feature.
- [x] Candy-owned settings UI exists for BGM, SFX, and Shift Lock settings.
- [x] Candy-owned mobile touch control UI exists for HTML5 phones.
- [x] Enabled shared-feature UI uses Candy SSOT/config and game-owned nodes.
- [x] Function-skin UI assets were generated as a no-text 9Router sheet, then Photoroom full-sheet processed before extraction.
- [x] Function-skin UI extraction used alpha component masks from the Photoroom sheet; no raw crop and no grid slicing.
- [x] Function-skin text is constrained to cream-center owner regions with content margins and smaller font sizes; text no longer uses full decorative texture bounds as its layout box.
- [x] Every reused asset has matching role, ratio, crop, padding, and owner rect.
- [x] Every new generated asset has owner approval.
- [x] Function-skin visuals live in the game repo, not Shinokute core.
- [x] Contract check proves chosen controls use SSOT asset keys/owner rects once SSOT exists.
- [x] Screenshot validation exists for leaderboard and username prompt function UI.
- [ ] Screenshot validation exists for settings panel function UI.

## Validation Matrix

Run the detailed commands in `res://docs/validation_runbook.md`.

### Phase 0: Pre-Edit Gate

- [x] Required reading complete.
- [x] Game-local checklist exists.
- [x] Game-local asset manifest exists.
- [x] Default skin size SSOT exists and was read.
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
- [x] Falling below world retries current level in-place without SceneTree reload.
- [x] Console reviewed for missing resources and parse errors.

### Phase 5: Screenshot Evidence

- [x] Desktop gameplay screenshot captured.
- [x] HUD close-up screenshot captured after coin pickup.
- [ ] Mobile or narrow viewport screenshot captured if mobile scope is approved.
- [x] Screenshot notes confirm no overlap and no blank/missing assets.
- [x] HUD layout contract validates `CandyScoreFrame` size behavior after scene instantiate.
- [x] Default skin size SSOT contract validates baseline coverage before further reskin.

## Tests And Evidence

Static validation:
- Command: `Get-ChildItem <project>\tests -Filter 'test_*.gd' | Sort-Object Name | ForEach-Object { Godot_v4.3-stable_win64_console.exe --headless --path <project> --script $_.FullName }`
- Result: PASS on 2026-07-07 with Godot 4.3 for `test_asset_family_manifest_contract.gd`, `test_asset_family_theme_contract.gd`, `test_candy_theme_config.gd`, `test_reskin_static_contract.gd`, and `test_theme_applier_contract.gd`.
- Branding result: PASS on 2026-07-07 with Godot 4.3 for all tests, including `test_branding_contract.gd`.
- HUD layout result: PASS on 2026-07-08 with Godot 4.3 for `test_hud_layout_contract.gd`; full `tests/test_*.gd` suite passed after the HUD frame size fix.
- Default size SSOT result: PASS on 2026-07-08 with Godot 4.3 for `test_default_skin_size_ssot_contract.gd`; full `tests/test_*.gd` suite passed after adding the baseline size gate.
- Final audit result: PASS on 2026-07-08 with Godot 4.3 for `test_reskin_final_audit_contract.gd`; full `tests/test_*.gd` suite passed after removing stale player-wrapper docs and Candy fallback defaults.
- Settings/audio/shift-lock result: PASS on 2026-07-10 with Godot 4.3 for `test_candy_settings_audio_shift_lock_contract.gd` and `test_candy_settings_runtime_contract.gd`; Candy Island audio is processed to mobile-sized OGG routes. Shift Lock default changed to OFF on 2026-07-11 through core settings while remaining user-toggleable in Settings.
- Shift Lock face-axis result: PASS on 2026-07-10 with Godot 4.3 for `test_camera_mouse_input_contract.gd`; camera must snap behind the actual visual face direction on enable, use `shift_lock_pitch_degrees` for over-back framing, avoid OS mouse capture on scene load/settings toggle, capture only while the active game window has Shift Lock ON and right mouse is held, warp the pointer to the exact game viewport center immediately on capture start, release capture on right mouse up/focus out/Shift Lock off, let horizontal mouse movement rotate character yaw and locked camera yaw, keep scroll wheel zoom active, follow input-driven character facing in the same physics frame without yaw lerp lag, keep `move_back` as backpedal, and make `move_left`/`move_right` turn character facing plus camera in the player-facing camera view without strafing sideways or using camera lerp yaw as the movement basis. Roblox-style lesson: preserve raw local input vector separately from camera lock/free-camera visual interpolation; Candy then applies the owner-approved lock-behind-character turn/backpedal semantics with pointer capture scoped only to active in-window right-mouse hold and centered before lock. Right mouse button in free-camera mode remains camera drag only. Use `character_face_yaw_offset_degrees` when a replacement GLB face axis differs. Current CHR077 visual face axis is Godot local `+Z`, so camera-behind offset is `180`; for that axis, `move_right` subtracts yaw and `move_left` adds yaw. Tests assert `View.is_os_mouse_capture_active()` is false after Shift Lock enable, true during Shift Lock right-mouse hold, `View.get_last_mouse_capture_center_position()` equals the viewport center, and capture is false after release/focus out.
- Roblox-like mobile controls result: PASS on 2026-07-10 with Godot 4.3 for `test_shinokute_input_router_contract.gd`, `test_candy_mobile_touch_controls_contract.gd`, `test_camera_mouse_input_contract.gd`, and `test_web_export_preset_contract.gd`; core input router detects touch/keyboard/mouse/gamepad scheme, keeps keyboard/gamepad support, consumes touch look/jump/zoom once, and Candy HUD routes a left thumbstick, right jump button, right-side look drag, two-finger pinch zoom, and iOS Web pointer-id bridge into that router. Web export contract requires `viewport-fit=cover`, `100dvh`, `visualViewport`, `orientationchange`, and `touch-action:none` for mobile rotation/stretch behavior. The contracts also cover joystick slip, jump miss guard zones, held-right-then-left-stick multi-touch, raw `MouseMotion` suppression while touch controls are active, move/jump-only mouse fallback, and JS pointer bridge right-look plus left-move, proving those paths do not bypass router capture and spin the camera.
- iOS Web pointer coordinate normalization result: PASS on 2026-07-11 with Godot 4.3 for `test_candy_mobile_touch_controls_contract.gd` after RED failure. The JS pointer bridge must send canvas CSS width/height, and core `MobileTouchControls` must convert CSS pointer coordinates into current Godot viewport coordinates before hit-testing move/jump/look/pinch. This prevents orientation/visualViewport stretch from making the drawn controls and actual hit regions diverge on iPhone/iPad.
- iOS right-swipe Touch Events fallback result: PASS on 2026-07-11 with Godot 4.3 for `test_candy_mobile_touch_controls_contract.gd` after RED failure. Core `MobileTouchControls` must expose `handle_web_touch_event`, install `touchstart/touchmove/touchend/touchcancel`, route `changedTouches` by `Touch.identifier`, normalize CSS coordinates to viewport coordinates, and keep a single active JS bridge owner so Pointer Events and Touch Events cannot both drive one physical gesture.
- iOS JavaScriptBridge payload unwrap result: PASS on 2026-07-11 with Godot 4.3 for `test_candy_mobile_touch_controls_contract.gd` after RED failure. Owner device diagnostic log showed JS pointer events but no Godot routing lines, proving the break was between JS callback and GDScript parsing. `MobileTouchControls` must unwrap a single nested JavaScriptBridge callback payload before parsing pointer/touch events.
- Shift Lock OFF routed mobile look result: PASS on 2026-07-11 with Godot 4.3 for `test_camera_mouse_input_contract.gd` after RED failure. Owner clarified the remaining iOS right-swipe bug occurs with Shift Lock OFF. Core `follow_camera_3d.gd` must consume routed look before camera rig interpolation so right-side mobile look changes the visible free camera in the same physics frame, while character yaw remains unchanged until movement rules rotate it.
- iOS JavaScriptBridge flat-argument result: PASS on 2026-07-11 with Godot 4.3 for `test_candy_mobile_touch_controls_contract.gd` after RED failure. Owner iPhone log showed JS pointer events but no `gd pointer`/camera lines. Official Godot docs define `create_callback` callbacks as one GDScript Array containing JavaScript `arguments`; therefore JS must call `window.candySkyPointerEvent(type, id, x, y, w, h)` and `window.candySkyTouchEvent(type, id, x, y, w, h)`, not pass one nested array. The old unwrap remains only as compatibility guard.
- iOS/mobile correction result: PASS on 2026-07-10 with Godot 4.3 for full `tests/test_*.gd` suite, 36 contracts total. Fresh staged Web export generated `Export_web_test/candy_sky_islands.html`, `.pck`, `.wasm`, and runtime files. PCK forbidden marker scan passed with no matches. Local in-app browser smoke passed at portrait `390x844` and landscape `844x390`; canvas client size matched viewport, mobile shell was present, and console warnings/errors were empty. Firebase preview redeployed: `https://foodapp-7ff6b--candy-sky-islands-test-8a6pe9td.web.app/candy_sky_islands.html`; remote headers returned `200`, `no-cache`, HTML content type, WASM content type, and PCK octet-stream content type. Remote browser smoke also passed at `390x844` and `844x390` with empty warning/error logs.
- Win/death transition result: PASS on 2026-07-10 with Godot 4.3 for `test_game_progression_ssot_contract.gd`, `test_game_progression_runtime_reset.gd`, and full `tests/test_*.gd` suite, 37 contracts total. `GameProgression` now defers win/death out of callbacks, guards `_transition_in_progress`, and restarts the current/next level in-place by rebuilding `World/GeneratedStage` and resetting `Player`; `Player` emits `fell_out_of_bounds` only and exposes `reset_for_level(...)`. Contract forbids `reload_current_scene`/scene changes in player/progression gameplay transitions because SceneTree reload from Web death can hang HTML5. Fresh local Web export rebuilt and local Playwright death smoke kept the page responsive through 4 fall loops with zero console errors. PCK forbidden marker scan on the default `Export/` preset still finds artifact markers and must not be reported clean until export filtering is fixed.

Godot import:
- Command: see Validation Matrix Phase 2.
- Result: PASS on 2026-07-07 with Godot 4.3, exit code `0`; existing source warnings remain for invalid UIDs and remapped material parameters.
- Branding result: PASS on 2026-07-07 with Godot 4.3, exit code `0`; same existing invalid UID and material remap warnings remain.

Smoke run:
- Command/URL: `Godot_v4.3-stable_win64_console.exe --path <project> --script tools/capture_candy_sky_screenshots.gd`
- Result: PASS on 2026-07-07 with visible Vulkan Forward+ window. Automated smoke covered scene load, movement, jump, double-jump, camera rotate/zoom, coin HUD update, falling platform state, extracted HUD icon load, and screenshots. Headless screenshot capture was not usable because dummy rendering returned null viewport textures.
- HUD layout result: PASS on 2026-07-08 with compact HUD frame assertion enabled; `CandyScoreFrame` must stay within 360x160 and ignore natural texture size.
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
- Firebase project: `foodapp-7ff6b`, preview channel `candy-sky-islands-test`.
- Hosting target: preview only, expires `2026-07-17T13:00:59.018072046Z`.
- Export preset: Web.
- Output directory: `Export_web_test`.
- Artifact sizes: HTML 6036 bytes, PCK 13,316,880 bytes, WASM 35,376,909 bytes.
- Latest deferred-reload export sizes: HTML 6036 bytes, PCK 13,317,344 bytes, WASM 35,376,909 bytes.
- URL: `https://foodapp-7ff6b--candy-sky-islands-test-8a6pe9td.web.app/candy_sky_islands.html`.
- Browser smoke result: PASS local and Firebase at `390x844` and `844x390`; canvas matched viewport and logs were empty.
- Header/cache result: PASS for HTML/WASM/PCK; all `200`, `Cache-Control: no-cache`; WASM served as `application/wasm`, PCK as `application/octet-stream`.
- Screenshot paths: none.

### Web Publish Evidence 2026-07-12 13:19

- Mode: Official publish.
- Source repo/branch/commit: `https://github.com/Lasthope1508/ShinokuteGameCore.git`, `game/candy-sky-islands`, `f43c907`.
- Godot project: `C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter`.
- Firebase preview project/target/channel: `foodapp-7ff6b`, `candy-preview`, `candy-sky-islands-test`.
- Firebase production project/target/site: `shinokute-studio`, `shinokute-play`, `https://play.shinokute.com`.
- Public dir: `Export_web_test`, rebuilt from runtime whitelist only.
- Web export command: `Godot_v4.3-stable_win64_console.exe --headless --path <project> --export-release "Web" "<project>\Export\candy_sky_islands.html"`.
- Artifact sizes: HTML 6036 bytes, JS 331495 bytes, PCK 12892080 bytes, WASM 35376909 bytes, BGM 1136942 bytes, SFX total 45882 bytes.
- Tests: PASS full `tests/test_*.gd` sweep, 42 contracts.
- PCK forbidden scan: PASS, `path_count=356`.
- Public dir clean gate: PASS, 8 runtime files, no `.import`, `.gdignore`, logs, docs, tests, or Android artifacts.
- Preview deploy: PASS, `firebase hosting:channel:deploy candy-sky-islands-test --only candy-preview --project foodapp-7ff6b --expires 7d`.
- Preview URL: `https://foodapp-7ff6b--candy-sky-islands-test-8a6pe9td.web.app/?codex_preview=1783836965`.
- Production precheck: PASS, `shinokute-play` site exists and `play.shinokute.com` resolves through `shinokute-play.web.app`.
- Production deploy: PASS, `firebase deploy --only hosting:shinokute-play --project shinokute-studio`.
- Production URL: `https://play.shinokute.com/?codex_prod=1783837116`.
- Header check: PASS for `.html`, `.pck`, `.js`, `.wasm`; all `200` with `Cache-Control: no-cache, no-store, must-revalidate`; WASM served as `application/wasm`.
- Smoke path: desktop and iPhone 13 Playwright loaded canvas, skipped username prompt, moved/jumped/double-jumped, exercised mobile controls and portrait/landscape rotation.
- Console result: PASS; production desktop and iPhone 13 logs contain only Godot/WebGL startup logs, no errors.
- Screenshot paths: `output/playwright/production-desktop-*.png`, `output/playwright/production-iphone13-*.png`.
- Android blocker at source commit `f43c907`: `Android blocked: no Android preset or signing handoff in source`. Superseded by the Android source handoff entry below.

### Android Source Handoff Evidence 2026-07-12

- Android procedure SSOT is `docs/android_packaging_runbook.md`; this section is
  historical evidence only and must not be used as the packaging runbook.
- Mode: Source handoff standardization, not Play release.
- Source owner action: added Android preset and signing handoff so packaging/release agents no longer guess package id, version, AAB path, or keystore policy.
- Android preset: `Android`.
- Package id: `com.shinokutestudio.candyskyislands`.
- Version policy: current Candy Android upload version is `version/code=7`,
  `version/name="1.0.6"` because Play Console consumed version codes 1, 2, and
  3 during rejected upload attempts, version code 4 for the first accepted
  internal testing release, and version code 5 for the 2026-07-12 upload before
  the desktop Web mobile-overlay smoke fix, then version code 6 for the
  2026-07-13 upload before the HUD contrast fix. Bump code for every Play
  upload attempt that reaches Google.
- AAB path: `Export/candy_sky_islands.aab`.
- Target SDK policy: `version/target_sdk=35`; Play Console rejected the first
  Candy upload attempt because the old AAB targeted API 34.
- Keystore path: `C:/Users/Admin/.gemini/antigravity/secrets/candy_sky_islands.keystore`.
- Password source: `C:/Users/Admin/.gemini/antigravity/secrets/candy_sky_islands_keystore_secrets.json`; never commit passwords or Play credentials.
- Required contracts: `tests/test_android_export_preset_contract.gd`, `tests/test_packaging_handoff_contract.gd`, `tests/test_web_export_preset_contract.gd`.
- Required Android release gates before any Play upload: fresh AAB export, Gate 4C AAB marker scan, AAB size table, signing evidence, native Android device smoke.

### Android Packaging Evidence 2026-07-12

- Mode: Local release AAB packaging, not Play upload.
- Source repo/branch/commit before packaging evidence: `game/candy-sky-islands`, `6c079e0`.
- Root cause fixed for local export: manual Android template expansion needs `android/.build_version` beside `android/build/`; Candy now uses `android/.build_version` content `4.3.stable`, matching the Godot 4.3 template. Without this marker Godot reports: "Trying to build from a gradle built template, but no version info for it exists."
- Android template import guard: `android/build/.gdignore` is required so Godot
  does not create `.import` sidecars in `android/build/res/mipmap*`, which
  Android Gradle rejects as invalid resource filenames.
- Android export command: `Godot_v4.3-stable_win64_console.exe --headless --path <project> --export-release "Android" "<project>\Export\candy_sky_islands.aab"`.
- Password handling: `keystore_password` read from local-only `C:/Users/Admin/.gemini/antigravity/secrets/candy_sky_islands_keystore_secrets.json`, injected temporarily for export, and `export_presets.cfg` restored to `keystore/release_password=""`.
- Android preset contract: PASS.
- Godot import: PASS.
- AAB export: PASS, `Export/candy_sky_islands.aab`, 58719413 bytes. First
  Play upload attempt blocked because this AAB targeted API 34; source policy
  updated to `version/target_sdk=35` before rebuilding.
- Play upload version code correction: version code `1` became unavailable
  after the rejected Play upload attempt, and version codes `2` and `3` became
  unavailable after Play still read target API 34. Source moved to
  `version/code=4`, `version/name="1.0.3"` before the accepted internal test
  build; source moved to `version/code=5`, `version/name="1.0.4"` for the next
  upload attempt; source then moved to `version/code=6`,
  `version/name="1.0.5"` after Play consumed code 5 before the desktop Web
  mobile-overlay smoke fix; source then moved to `version/code=7`,
  `version/name="1.0.6"` after Play consumed code 6 before the HUD contrast
  fix.
- Target SDK correction: for Godot 4.3 custom Gradle builds,
  `version/target_sdk=35` in `export_presets.cfg` was not enough; local
  `android/build/config.gradle` must also use `compileSdk: 35`,
  `targetSdk: 35`, `buildTools: '35.0.0'`, and return the maximum of the
  Godot-provided `export_version_target_sdk` property and `versions.targetSdk`.
  The canonical local patch command is
  `tools/patch_android_template_for_play.ps1`.
- AAB signing marker: PASS, `META-INF/CANDY_SK.RSA`, `META-INF/CANDY_SK.SF`, and `META-INF/MANIFEST.MF` present.
- Gate 4C outer marker scan: PASS, `path_count=0`; outer scan alone is not enough for compressed AAB contents.
- Gate 4C deep scan: PASS, `entry_count=315`, `content_path_count=112`.
- Fresh final size table for Play internal testing upload: HTML 6036 bytes, JS 331495 bytes, PCK 12892032 bytes, WASM 35376909 bytes, AAB 58719395 bytes, BGM 1136942 bytes, SFX total 45882 bytes.
- Play Console internal testing result: PASS on 2026-07-12. App `Candy Sky Islands`, package `com.shinokutestudio.candyskyislands`, release `4 (1.0.3)`, API levels `24+`, target SDK `35`, ABIs `2`, new install size `36 MB`, status `Available to internal testers`.
- Tester list: `Shinokute testers`, 5 users.
- Tester join link: `https://play.google.com/apps/internaltest/4701018407986590939`.
- Remaining Android release blockers: no native Android device smoke yet, no deobfuscation file uploaded, and no native debug symbols uploaded.

### Web Publish Evidence 2026-07-12 17:27

- Mode: Official publish to `play.shinokute.com` after Android/Google Play handoff.
- Source repo/branch/commit before publish: `game/candy-sky-islands`, `32e9077`.
- Production Firebase project/target: `shinokute-studio`, `shinokute-play`.
- Production precheck: PASS; Firebase site `shinokute-play` exists and `play.shinokute.com` resolves through `shinokute-play.web.app`.
- Full test sweep: PASS, `CANDY_FULL_TEST_SWEEP_PASS count=43`.
- Godot import/export: PASS, `Godot_v4.3-stable_win64_console.exe --headless --path <project> --export-release "Web" "<project>\Export\candy_sky_islands.html"`.
- PCK forbidden scan: PASS, `PCK_PATH_MARKER_SCAN_PASS path_count=360`.
- Public dir sync: PASS, `PUBLIC_WHITELIST_SYNC_PASS count=8`.
- Artifact sizes: HTML 6036 bytes, JS 331495 bytes, PCK 12892208 bytes, WASM 35376909 bytes, AAB 58719395 bytes, BGM 1136942 bytes, SFX total 45882 bytes.
- Production deploy: PASS, `firebase deploy --only hosting:shinokute-play --project shinokute-studio`.
- Production smoke URL: `https://play.shinokute.com/?codex_prod=1783850852`.
- Header check: PASS for `.html`, `.pck`, `.js`, `.wasm`; all `200` with `Cache-Control: no-cache, no-store, must-revalidate`; WASM served as `application/wasm`.
- Smoke path: desktop and iPhone 13 Playwright loaded canvas, skipped username prompt, moved/jumped/double-jumped, exercised mobile controls and portrait/landscape rotation.
- Console result: PASS; production desktop and iPhone 13 logs contain only Godot/WebGL startup logs, no errors.
- Screenshot paths: `output/playwright/production-latest-desktop-*.png`, `output/playwright/production-latest-iphone13-*.png`.
- Android status: Google Play internal testing evidence exists above; native Android device smoke remains a separate blocker for full package-ready claims.

### Android + HTML5 Packaging Evidence 2026-07-13

- Mode: HTML5 package rebuild and Google Play internal testing publish after HUD contrast fix.
- Source repo/branch before package evidence: `game/candy-sky-islands`.
- Version policy update: source package version moved to `version/code=7`, `version/name="1.0.6"` because Play had already consumed `6 (1.0.5)`. Google Play then consumed version code 7 for this publish; next Play upload attempt must bump to version code 8.
- Target SDK requirement check: official Android Developers target SDK page was checked on 2026-07-13; Candy remains on Android 15 / API 35 via `version/target_sdk=35` plus local Gradle template SDK 35 patch.
- Shipped pattern check: BloxChain and Glyph Arrows Android presets both use dedicated `Android` preset, `export_filter="resources"`, canonical `Export/<game>.aab`, per-game package id, per-game keystore path under local secrets, and empty committed `keystore/release_password=""`; Candy follows the same pattern.
- Preflight contracts: PASS, `test_packaging_handoff_contract.gd`, `test_android_export_preset_contract.gd`, and `test_web_export_preset_contract.gd`.
- Android template patch: PASS, `ANDROID_TEMPLATE_PLAY_PATCH_PASS target_sdk=35 removed_res_import=0`.
- Godot import: PASS, `GODOT_IMPORT_EXIT code=0`.
- Full test sweep: PASS, `CANDY_FULL_TEST_SWEEP_PASS count=45`.
- Web export: PASS, `Godot_v4.3-stable_win64_console.exe --headless --path <project> --export-release "Web" "<project>\Export\candy_sky_islands.html"`.
- Public dir sync: PASS, `PUBLIC_WHITELIST_SYNC_PASS count=8`; `Export_web_test/` rebuilt from runtime whitelist only.
- PCK forbidden marker scan: PASS, `PCK_PATH_MARKER_SCAN_PASS path_count=369`.
- Local Web smoke: PASS from `Export_web_test` on `http://127.0.0.1:65347/candy_sky_islands.html` with cache-busted query. Smoke skipped username prompt, reached gameplay, moved, jumped, double-jumped, zoomed, and console had no errors. Browser only logged Web Audio autoplay warnings before user gesture.
- Android export command: `Godot_v4.3-stable_win64_console.exe --headless --path <project> --export-release "Android" "<project>\Export\candy_sky_islands.aab"`.
- Android export note: Godot printed `export: end` and wrote `Export/candy_sky_islands.aab`, then the export process hung and was terminated manually. The generated AAB was accepted only after bundletool validation, manifest verification, signing marker verification, and Play Console upload/processing all passed.
- Password handling: local `keystore_password` was read from `C:/Users/Admin/.gemini/antigravity/secrets/candy_sky_islands_keystore_secrets.json`, injected only for export, and `export_presets.cfg` was restored to `keystore/release_password=""`.
- AAB zip/signing markers: PASS, `entry_count=319`, `base/manifest/AndroidManifest.xml`, `META-INF/CANDY_SK.RSA`, `META-INF/CANDY_SK.SF`, and `META-INF/MANIFEST.MF` present.
- AAB outer marker scan: PASS, `AAB_PATH_MARKER_SCAN_PASS path_count=0`; deep scan required because compressed contents hide paths from outer scan.
- AAB deep scan: PASS, `AAB_DEEP_SCAN_PASS entry_count=319 content_path_count=114`.
- Bundletool validate: PASS, `BUNDLETOOL_VALIDATE_PASS`.
- AAB manifest evidence: `package=com.shinokutestudio.candyskyislands`, `versionCode=7`, `versionName=1.0.6`, `targetSdk=35`.
- Jarsigner verification: PASS, `jar verified`; expected self-signed/no-timestamp warnings remain non-blocking for this internal testing upload.
- Fresh size table: HTML 6036 bytes, JS 331495 bytes, PCK 12908464 bytes, WASM 35376909 bytes, AAB 58733028 bytes, BGM 1136942 bytes, SFX total 45882 bytes.
- Google Play upload method: Chrome remote debugging session on port 9222, not in-app browser. Normal Playwright file upload was blocked by the 50 MB transport limit, so the documented CDP `DOM.setFileInputFiles` path was used.
- Play Console preview evidence: uploaded bundle `7 (1.0.6)`, API levels `24+`, target SDK `35`, screen layouts `4`, ABIs `2`, required features `2`, new install size `36 MB`, update size `1.93 MB`, no supported-device loss.
- Play Console warnings: non-blocking deobfuscation file warning and native debug symbols warning. No target SDK, signing, package id, or version-code errors.
- Play Console internal testing result: PASS on 2026-07-13. Latest release `7 (1.0.6)`, status `Available to internal testers`, released Jul 13 11:32 AM, tester join link unchanged: `https://play.google.com/apps/internaltest/4701018407986590939`.
- Remaining Android release blocker for full package-ready claim: native Android device smoke was not run in this pass.

## Completion

- Commit hash: not committed.
- Known warnings:
  - `quantum_starter` is currently untracked in the parent repository.
  - Local available Godot binary is 4.3, while the source README says Godot 4.6.
- Known gaps:
  - Real iOS device retest remains pending after the mobile contract/export pass.
- Legacy colormap file remains on disk as source evidence, but active production scenes no longer reference it.
- `platform.large` and `block-coin` are unused candidates, not production scene assets.
- `prop.cloud` reference-derived 3D volume parity is applied through `cloud_candy_volume.glb`; flat `Sprite3D` reference art is no longer production.
- Owner follow-up needed:
  - Choose next separate gate: mobile viewport screenshot/browser smoke, publish, or Shinokute integration.
