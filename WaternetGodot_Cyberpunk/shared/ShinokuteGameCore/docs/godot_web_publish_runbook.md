# Godot Web Publish Runbook

This is the canonical Shinokute procedure for putting a Godot HTML5 build on the web.

Every agent must read this document before giving the owner a playable web link or publishing a production web build. Do not improvise Firebase deploy steps from memory.

## Publish Modes

| Mode | Purpose | Allowed Shortcut | Required Result |
|---|---|---|---|
| Owner test link | Give the owner a fresh web URL to review gameplay, UI, audio, or VFX. | Android export can be skipped only when the owner asked for a web test link, not package readiness. | Fresh web export deployed to a preview or test URL, real gameplay smoke passed, console clean. |
| Official publish | Replace or update the public production web game. | No shortcut. | Full package gate passed, owner test approved, production URL smoke passed, docs updated. |

Loading the HTML shell, splash, menu, or level select is never enough. A valid web check reaches real gameplay and performs one real interaction.

## Per-Game Publish SSOT

Each game repo must document these fields in its local release checklist before any deploy:

| Field | Meaning |
|---|---|
| `game_id` | Stable internal game id. |
| `project_root` | Absolute local Godot project path. |
| `web_preset` | Godot Web export preset name. |
| `web_export_basename` | Export base name, for example `glyphflow_arrays`. |
| `web_entry_file` | Main HTML file, for example `Export/glyphflow_arrays.html`. |
| `firebase_project` | Firebase project id from `.firebaserc`. |
| `firebase_hosting_target` | Firebase hosting target or blank when the project has a single default hosting site. |
| `firebase_public_dir` | Hosting public dir from `firebase.json`. |
| `owner_test_url_policy` | Preview channel, staging site, or explicitly approved production test URL. |
| `production_url` | Official URL shown to players. |
| `smoke_path` | Exact click path from load to gameplay interaction. |
| `web_audio_gate` | Audio unlock/debug check when the game has web audio. |
| `forbidden_deploy_files` | Files that must not be in the Firebase public dir. |

No agent may invent missing Firebase project ids, hosting targets, production URLs, or fallback publish paths. If a required field is missing, stop and add it to the game checklist from existing repo config or ask the owner.

## Git Source Gate

When the owner says "lay tren Git", "lay tren GitHub", "source moi nhat", "dua source moi nhat cua web len", or similar, Git is the source of truth.

Required steps:

1. Resolve the exact repo URL, branch, and remote SHA with `git ls-remote` or the Git provider.
2. Clone into a short temporary directory such as `C:\sgd-YYYYMMDD-HHMMSS`.
3. Export, stage, smoke, and deploy from that fresh clone or from artifacts built from that fresh clone.
4. Record repo URL, branch, and SHA in the publish evidence.
5. Do not treat an existing local checkout as canonical unless its remote and SHA have been verified in the current pass.
6. Do not download the live site HTML and call it source.
7. Do not copy from another game repo or project root to fill missing files.

If a required web wrapper, portal, or Firebase config is not present in Git, say so explicitly. Use only a minimal temporary wrapper when the owner has asked for a live replacement and the wrapper's behavior is clear. Record that exception in the evidence.

## Temporary Workspace Gate

Use a short temp root for publish work that should not modify the user's project checkout:

```powershell
$root = "C:\sgd-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $root
```

Keep generated deploy staging files, `node_modules`, screenshots, smoke scripts, and Firebase public dirs inside that temp root unless the repo intentionally owns them. Before deleting temp output, verify the resolved path starts with `C:\sgd-`. Remove the temp root after deploy and final verification.

Never leave staging folders, Playwright installs, smoke screenshots, or copied export files in a game repo unless the owner explicitly asked to commit those files.

## Required Firebase Headers

Godot Web loads fixed runtime filenames unless the export basename changes. A cache-busted HTML URL alone does not guarantee a fresh `.pck`, `.js`, or `.wasm`.

For owner test links, Firebase Hosting must serve these with no-store:

```json
{
  "source": "**/*.@(html|pck|js|wasm)",
  "headers": [
    {
      "key": "Cache-Control",
      "value": "no-cache, no-store, must-revalidate"
    }
  ]
}
```

For Godot exports that require cross-origin isolation, also keep these headers on all files:

```json
{
  "source": "**",
  "headers": [
    {
      "key": "Cross-Origin-Opener-Policy",
      "value": "same-origin"
    },
    {
      "key": "Cross-Origin-Embedder-Policy",
      "value": "require-corp"
    }
  ]
}
```

Official production may use versioned export basenames plus stronger asset caching only when the game checklist says so and the production smoke proves the new `.pck` loaded. Otherwise keep no-store for `.html`, `.pck`, `.js`, and `.wasm`.

## Owner Test Link Workflow

Use this when the owner says "dua html len web", "cho link web test", "dua ban html5 cho tao test", or similar.

1. Read the project release checklist, asset optimization checklist, audio pipeline if present, and this runbook.
2. Use Godot MCP `get_project_info` for the target project when available. Confirm the project name and path.
3. Inspect `firebase.json`, `.firebaserc`, and the per-game publish SSOT.
4. Run the required web/package contract tests for the game. If the change could affect runtime loading, run the full Godot test sweep.
5. Clear stale Godot import/export cache when assets or import settings changed.
6. Reimport with Godot.
7. Export Web with the documented preset and basename.
8. Audit the generated `.pck` for forbidden markers.
9. Prepare the Firebase public dir. It must contain only web runtime files needed by Godot Web and allowed static assets.
10. Deploy to an owner test destination.
11. Open the deployed URL with a fresh query string and perform the game-specific smoke path.
12. Check browser console after interaction. Any error blocks the link.
13. If the game has audio, perform one real user input and verify the game's web audio unlock/debug state when available.
14. Send the owner the URL only after the deployed URL smoke passes.
15. Record evidence in the game release checklist: command, URL, commit, artifact sizes, console result, smoke path.

Recommended owner test deploy command:

```powershell
$channel = "owner-test-$(Get-Date -Format 'yyyyMMdd-HHmm')"
firebase hosting:channel:deploy $channel --expires 7d
```

When the project uses hosting targets:

```powershell
$channel = "owner-test-$(Get-Date -Format 'yyyyMMdd-HHmm')"
firebase hosting:channel:deploy $channel --only hosting:<target> --expires 7d
```

Use `firebase deploy --only hosting` for an owner test only when the owner explicitly asked to replace the live test site or the game checklist names production hosting as the approved test URL.

## Shinokute Play Multi-Game Site

`play.shinokute.com` is a shared production web site, not one game's default Firebase root.

Known live Firebase target:

- Firebase project: `shinokute-studio`
- Hosting site/target: `shinokute-play`
- Public domain: `https://play.shinokute.com`

Current route contract:

| Game | Route | Godot runtime route |
|---|---|---|
| BloxChain | `/bloxchain/` | `/bloxchain/game/index.html` |
| Glyphflow Arrays | `/glyph-arrows/` | `/glyph-arrows/game/index.html` |

When replacing this site:

1. Build each game from its own verified Git source and SHA.
2. Export each game with basename `index` when it will live under a wrapper's `game/index.html`.
3. Stage only the web runtime files for each game under that game's `game/` directory.
4. Preserve route ownership. Do not overwrite one game's route with another game's artifacts.
5. Use a Firebase config with site/target `shinokute-play`, no-store headers for `.html`, `.pck`, `.js`, `.wasm`, and COOP/COEP headers when required.
6. Deploy with:

```powershell
firebase deploy --project shinokute-studio --only hosting:shinokute-play
```

Wrapper and portal ownership:

- If Git contains the portal or wrapper HTML, use the Git version.
- If Git does not contain the portal or wrapper HTML, do not pull live HTML down as source. Create only a minimal temp wrapper that loads `game/index.html`, and record that Git lacked wrapper source.
- Do not add marketing pages, layout redesigns, analytics, or extra assets during a runtime replacement.

Smoke checks for wrapper routes must interact with the Godot canvas inside the `game/` frame. A console-clean run that leaves the screenshot on menu, splash, or level select is not a pass. Capture screenshots after each major click when validating a wrapped route.

## Official Web Publish Workflow

Use this only when the owner asks to publish, release, replace the old public build, update the live site, or publish official web.

1. Complete the owner test workflow first and get owner approval for the tested URL.
2. Confirm the repo branch and commit that will be published.
3. Run full Godot test sweep.
4. Run fresh Web export.
5. Run fresh Android export if the task claims package readiness or includes mobile release.
6. Run PCK/AAB forbidden scans.
7. Verify Android signing when an AAB is produced.
8. Compare size table to the game budget SSOT.
9. Confirm `firebase.json` public dir and headers.
10. Confirm the Firebase public dir has no Android artifacts, logs, `.import` files, screenshots, raw refs, docs, tests, or audit outputs.
11. Deploy production:

```powershell
firebase deploy --only hosting
```

With target:

```powershell
firebase deploy --only hosting:<target>
```

12. Open the production URL with a fresh query string.
13. Perform the production smoke path through gameplay and one interaction.
14. Check browser console after interaction.
15. Verify response headers for `.html`, `.pck`, `.js`, and `.wasm`.
16. Update the game release checklist with production URL, deploy time, commit hash, artifact sizes, smoke result, header result, and any approved exceptions.
17. Commit and push the updated checklist.

Do not say official publish is done until the production URL itself passes smoke. Localhost success is not production evidence.

## Clean Public Dir Gate

Before deploy, run an equivalent check against the Firebase public dir:

```powershell
$public = "Export"
$bad = Get-ChildItem $public -Recurse -File | Where-Object {
  $_.Name -match '\.(aab|apk|zip|log|import|tmp)$' -or
  $_.FullName -match '\\(docs|Tests|debug|scratch|component_refs|raw|reference)\\' -or
  $_.Name -like 'godot_*'
}
if ($bad) {
  $bad | Select-Object FullName
  throw "Firebase public dir contains non-web release files."
}
```

Preferred structure for future games is a dedicated web-only public dir such as `ExportWebPublic`. Copy only the generated Godot Web runtime files into it, then point `firebase.json` hosting public to that folder. This prevents AAB files from sharing the deploy root with Web files.

## Header Verification

After deploy, verify headers from the deployed URL:

```powershell
$base = "https://example.web.app"
curl.exe -I "$base/glyphflow_arrays.html"
curl.exe -I "$base/glyphflow_arrays.pck"
curl.exe -I "$base/glyphflow_arrays.js"
curl.exe -I "$base/glyphflow_arrays.wasm"
```

Required for owner test:

- `Cache-Control: no-cache, no-store, must-revalidate` on `.html`, `.pck`, `.js`, and `.wasm`.
- `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` when the Godot build needs cross-origin isolation.

If headers are wrong, fix `firebase.json`, redeploy, and re-run smoke. Do not ask the owner to hard refresh as the publish solution.

## Evidence Template

Append this to the game release checklist after every owner test link or official publish:

```markdown
## Web Publish Evidence YYYY-MM-DD HH:mm

- Mode: Owner test link | Official publish
- Source repos/branches/commits:
- Godot project:
- Firebase project:
- Hosting target/site:
- Public dir:
- URL:
- Routes:
- Web export command:
- Artifact sizes:
  - HTML:
  - JS:
  - WASM:
  - PCK:
- Live PCK byte size:
- Tests:
- PCK forbidden scan:
- Public dir clean gate:
- Header check:
- Smoke path:
- Console result:
- Web audio unlock result:
- Owner approval:
- Wrapper/portal source:
- Temp cleanup:
- Blockers:
```

## Common Failure Map

| Symptom | Cause | Fix |
|---|---|---|
| Owner sees old game after new deploy | `.pck`, `.js`, or `.wasm` cached under fixed filename. | Add no-store headers or export versioned basename; redeploy and smoke. |
| Localhost works, web is black | Firebase public dir missing `.pck`, `.wasm`, `.js`, worklet, or headers. | Clean/copy web runtime files, verify network and console. |
| Link loads menu but gameplay crashes | Export selected resources omitted runtime preload script or asset. | Fix export preset and add/repair contract test. |
| No sound on web | Audio context not unlocked or wrong exported audio file. | Use real user input, check web audio debug state, then inspect exported audio. |
| Firebase deploy uploads AAB/log/import files | `Export/` used as mixed Web/Android dump. | Use web-only public dir or strict ignore/clean gate. |
| Agent cannot find target | Publish SSOT missing. | Read `.firebaserc`/`firebase.json`, update release checklist, then continue. |
| Wrong game route changed | Shared site staged artifacts without route ownership. | Rebuild per game from its own Git SHA and stage under the documented route. |
| Wrapped route smoke says pass but screenshot is still menu | Clicks hit wrapper page or wrong canvas coordinates. | Select the `game/` frame, click the Godot canvas, capture each step, and require gameplay screenshot. |
| Source was taken from local or live site after owner asked for Git | Canonical source gate skipped. | Fresh clone verified remote SHA, rebuild, redeploy, and record repo URL/branch/SHA. |
