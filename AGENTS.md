# Codex Reskin Guard

Before any Quantum Starter reskin work, Codex must read these files first:

1. `docs/reskin_state.md`
2. `docs/reskin_checklist.md`
3. `docs/asset_manifest.md`
4. `docs/default_skin_size_ssot.md`
5. `docs/reskin_visual_ssot_runbook.md`
6. `docs/reskin_baked_asset_runbook.md`
7. `docs/reskin_2d_character_to_3d_runbook.md`
8. `docs/blender_mcp_discovery_runbook.md`
9. `../../../Doc/Art Design Document â€” 2D & Giáº£ 3D Game Mobile (Godot 4).md`, especially section `3.5 Quy trÃ¬nh AI Art Pipeline (9Router & Photoroom) & Quy táº¯c Cáº¯t Sprite Sheet`
10. latest `docs/superpowers/specs/*reskin*.md`
11. latest `docs/superpowers/plans/*reskin*.md`
12. `git status --short`

Before any level progression, completion, fail/retry, or difficulty-scaling work,
Codex must also read `docs/gameplay_progression_ssot.md`.

Before any packaging, Web export, Android export, Firebase deploy, Play Store
handoff, payload-size audit, or
package-ready claim, Codex must also read `docs/packaging_handoff.md` and
`docs/validation_runbook.md` Gate 4B. For Android export, AAB signing,
Google Play upload, Android device smoke, or Android-ready claims, Codex must
also read `docs/android_packaging_runbook.md` and `docs/validation_runbook.md`
Gate 4C. Do not infer output folders, deploy targets, export filters,
Firebase project, preview channel, runtime resources, Android package id,
signing profile, Play Store target, or cache policy from memory.
Candy Sky Islands has Web and Android source handoffs.
Package-ready claims are still blocked until fresh Web export, Android AAB
export, payload scans, size tables, and device/browser smoke evidence exist in
the current pass.

Before finishing, committing, or pushing source changes that can affect build,
export, hosting, runtime payload, assets, audio, input, scene loading, Firebase,
Android, or Play Store behavior, Codex must update `docs/packaging_handoff.md`
in the same source pass. If no handoff update is needed, Codex must explicitly
verify that the existing handoff still matches the changed source. Run
`tests/test_packaging_handoff_contract.gd` before the commit. This rule exists
for contextless packaging agents: they must be able to package from repository
docs alone, without chat history.

Android packaging reset rule: before Android export, AAB, signing, or Play
Store work, read `docs/android_packaging_runbook.md` section
`Android Packaging Reset Rule` and the Android pointer in
`docs/packaging_handoff.md`. Do not install Java/JDK, Android SDK, Gradle,
create keystores, change package id, or invent Play settings during source
handoff. First compare BloxChain and Glyph Arrows Android preset/signing
patterns, then use Candy's documented Android preset and signing handoff. Use
`tools/patch_android_template_for_play.ps1` before Android export, keep
`android/build/.gdignore`, never commit or print passwords, and restore
`keystore/release_password=""` after temporary export injection. If a release
tool or secret is missing during packaging, report the exact blocker instead of
creating a replacement.

Candy Sky Islands Web transition rule: win/death/fall gameplay transitions must not call
`get_tree().reload_current_scene()`, `tree.reload_current_scene()`, or scene changes from
physics/signal callbacks. Use `GameProgression` in-place reset: guard duplicate
transitions, defer out of the callback, rebuild the generated stage from the progression
SSOT, and call `Player.reset_for_level(...)`.

After reading, Codex must report:

- Current gate
- Completed assets
- Pending assets
- Next required gate

No implementation, asset generation, validation claim, merge, or finish report may happen before this report.

## Reskin Gate Rules

- Root Asset approval is only style anchor approval, not full reskin completion.
- If any asset group remains pending, Codex must not describe the reskin as complete or ready.
- Asset Family / Block Kit groups include player, collectible, platform/block kit, HUD, props/background, obstacle/goal, and optional splash/icon when branding scope is approved.
- Every creative asset group must pass: design options, owner approval, asset creation or generation, game application, manifest update, checklist update, validation, screenshot evidence.
- Before design options or asset creation, read `docs/default_skin_size_ssot.md` and preserve the default runtime size, collider envelope, or UI rect unless the owner approves a size change. Wrapper passes must be marked as wrappers, not full replacements.
- Before any reskin edit, read `docs/reskin_visual_ssot_runbook.md`. Every visible on-screen asset must have a canonical role key, SSOT/theme ownership, manifest coverage, and contract-test coverage before it is treated as production. Do not scatter skin-specific hardcoded paths through scenes/scripts.
- Before any player character replacement, define and obey `player.visual_target_height`, `player.visual_allowed_height`, and `player.visual_scale_policy` in `docs/default_skin_size_ssot.md`. Raw imported character size is not production truth. Scale through a stable parent slot so `AnimationPlayer` cannot overwrite the base scale.
- Do not use goal token budgets unless the owner gives an explicit number.
- For 9Router image generation in this workspace, use `NINEROUTER_IMAGE_KEY` when available. Owner approved system-key fallback on 2026-07-07: if image-specific key is missing, use existing system key env vars in this order without printing secrets: `NINEROUTER_KEY`, then `ROUTER_API_KEY`.
- When extracting production assets from a generated sheet, follow the existing global art pipeline in this order: remove the background from the full approved sheet through Photoroom CDP on Chrome debugging port 9223, then clone/cut each object from that Photoroom alpha sheet using owner-approved custom rect/polygon data, then trim and inspect alpha/edge quality, then record outputs in the manifest. Do not crop the raw sheet first. Do not use automatic grid slicing. Do not substitute local chroma-key/Pillow removal unless Photoroom is unavailable and owner approves fallback.
- For outline-based object extraction, use the local Codex skill `photoroom-polygon-sheet-extraction`. It creates polygon-only drawing editors and extracts from the Photoroom alpha sheet; do not use square/rectangle-only selection as the owner approval surface when objects are close or overlapping.
- For baked asset cleanup, follow `docs/reskin_baked_asset_runbook.md`: use the baked source itself as the 9Router reference, request a minimal edit that removes only baked numbers/text/watermark/sample marks, then run Photoroom on the full edited image before trim/QA. Do not replace this with local paint/Pillow cleanup unless owner explicitly approves that fallback.
- Do not use dummy primitive meshes, rough placeholder geometry, or primitive-only Blender scripts as production reskin replacements. Local primitives are allowed only as temporary wrappers/prototypes and must be documented as such. A production visual replacement must be based on an approved real reference asset, owner-approved generated asset, Photoroom/outline extraction, or a model whose silhouette/material cues are explicitly derived from those references.
- If Godot warnings or errors reveal a missing production asset, mesh surface material, import material, texture, or other visual resource, produce or attach the real asset/material at the source and record it in the manifest. Do not silence the warning by skipping the object, hiding the visual, using a dummy replacement, or treating the missing resource as acceptable.
- 3D parity rule: before replacing any default 3D asset, record whether the default role has volume/depth in `docs/default_skin_size_ssot.md`. If the default asset is a 3D model or 3D scene with nonzero depth, the production replacement must also be a real 3D model/wrapper with comparable volume/depth unless the owner explicitly approves a flat 2D downgrade. A `Sprite3D`, flat billboard, screenshot, or reference PNG may be temporary evidence or reference art, but it cannot be marked as a full 3D production replacement for a volumetric default role.
- 3D character-from-2D rule: when the owner provides a 2D character/sprite-sheet and asks to make that character into the 3D player, read `docs/reskin_2d_character_to_3d_runbook.md` first. Required pipeline: preserve owner source, Photoroom full source first, polygon extract clean source pose/sprite, use 9Router with that character reference to generate full turnaround/multiview sprites, Photoroom full generated sheet, polygon extract each view/sprite, then start 3D reconstruction/render. The production 3D replacement must use that exact 2D character identity as the visual source and must preserve real 3D volume/depth unless the owner explicitly approves a downgrade. Do not replace the character with a Blender piece-built approximation, mascot, primitive kitbash, single flat extrusion, or manually reinterpreted look unless the owner explicitly approves that as a separate redesign.
- Shinokute lentil/two-shell rejection rule: owner rejected the two-half "lentil shell" / image-shell character approach on 2026-07-08. Keep `character_shinokute_lentil_shell_candidate.glb` only as diagnostic failure evidence. Do not return to front/back shell, card-rig, billboard, or two-half bean geometry for production Shinokute player work unless the owner explicitly reopens that method.
- AI 3D reconstruction ladder rule: for 2D-character-to-3D work, prefer real image-to-3D reconstruction before manual Blender modeling. Current approved ladder is `Unique3D` as the primary free/quality path, `TripoSR` as the fast draft fallback, `SculptMate` only as a Blender convenience wrapper/draft path, and `blender-2d-to-3d-plugin` only for flat/extruded icons, tiles, cutouts, or diagnostic meshes. Every path still requires the source 2D character reference, Photoroom/polygon-clean inputs, Blender cleanup/retopo/UV/bake/rig/export, Godot validation, and owner approval before integration.
- Shinokute character 3D coordinate SSOT rule: before any Shinokute material assignment, texture projection, decal placement, retopo cleanup, rigging, or Godot player integration, read `docs/shinokute_character_3d_ssot.md` and update `assets/themes/candy_sky_islands/source/shinokute_player/shinokute_character_3d_ssot.json`. Do not guess material zones from one render or one mesh axis pass.
- Blender access reset rule: before any 3D inspection, render, GLB cleanup, or model authoring, read `docs/blender_mcp_discovery_runbook.md`. Run tool discovery for Blender MCP (`mcp__blender`/Blender) first. If Blender MCP is not exposed in the current Codex thread, do not claim Blender MCP is missing. Check `C:\Users\Admin\.gemini\config\mcp_config.json`, read `C:\Users\Admin\.gemini\config\skills\blender_mcp\SKILL.md`, confirm the configured `blender` server (`C:\Users\Admin\.local\bin\uv.exe run --project C:\Users\Admin\.gemini\antigravity\mcp\blender-mcp blender-mcp`), confirm the addon path `C:\Users\Admin\Desktop\Game\blender_mcp_addon.py`, then use the known local Blender 4.2 CLI fallback at `C:\Users\Admin\.gemini\antigravity\bin\Blender\blender-4.2.0-windows-x64\blender.exe` only when MCP is configured but not exposed/running in the current thread. Do not waste time with broad filesystem searches until these fixed config paths have been checked.
- Core learning reset rule: after a reskin exposes reusable behavior, move reusable logic/schema into `addons/shinokute_game_core` and leave only game-owned skin/config/assets/adapters in the game. Before and after core changes, run `tests/test_shinokute_reskin_core_audit_contract.gd` and use `ShinokuteReskinBoundaryAudit` to catch hardcoded game names, skin asset paths, stale JS globals, duplicate game-local schema classes, and export stale markers. Record the result in `docs/reskin_checklist.md`, `docs/validation_runbook.md`, and `docs/asset_manifest.md`.
