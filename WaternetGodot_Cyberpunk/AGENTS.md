# Glyphflow Arrays Agent Gate

Mandatory for every agent working on this Godot project.

## Read First

Before touching source, scenes, exports, Firebase deploys, Android builds, HTML5 builds, audio, UI, VFX, or packaging, read these files in order:

1. `docs/godot_working_guide.md`
2. `docs/release_packaging_checklist.md`
3. `docs/mobile_html5_asset_optimization_checklist.md`
4. `docs/audio_pipeline.md`
5. `shared/ShinokuteGameCore/docs/godot_web_publish_runbook.md`

For reskin/core work, also read:

```text
shared/ShinokuteGameCore/docs/reskin_core_skin_boundary.md
```

## Canonical Source Gate

Never assume `main` is the latest playable source.

Before export or deploy:

1. Ask or verify which branch and commit the owner wants published.
2. Run `git ls-remote` or equivalent remote verification.
3. Build from that branch and commit.
4. Report the exact repo, branch, and commit in the final answer.

Current known latest Glyphflow checkpoint at the time this file was added:

```text
repo: https://github.com/Lasthope1508/Godot-Casual-Games.git
branch: codex/water-canonical-names
commit: e087eda
```

If the owner says "latest", refresh remote state before using this checkpoint.

## Audio Gate

Do not look for original desktop source audio folders during publish. Runtime audio is already inside the Godot project and must come from Git:

```text
Audio/Music/cyberpunk_theme/Gameplay.ogg
Audio/Music/cyberpunk_theme/manifest.json
Audio/Sfx/cyberpunk_theme/*.ogg
```

`export_presets.cfg` must include the runtime audio files in selected resources for Web and Android exports.

If audio is missing in a build:

1. Check the Git branch and commit first.
2. Check `export_presets.cfg` selected resources.
3. Check `docs/audio_pipeline.md`.
4. Check browser audio unlock using the publish runbook.
5. Do not reconvert audio or invent fallback paths unless the owner explicitly approves.

## Publish Gate

For any owner test URL or official web publish:

1. Export with Godot, not a hand-built HTML wrapper.
2. Use a fresh or verified checkout.
3. Use a web-only public deploy directory.
4. Serve `.html`, `.pck`, `.js`, and `.wasm` with no-store cache headers, or export a versioned basename.
5. Smoke test the deployed URL through real gameplay and one real input.
6. Verify audio unlock after user gesture.
7. Report URL, commit, artifact names, and smoke result.

No success claim without fresh verification.

