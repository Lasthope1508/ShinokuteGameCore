# 9Router UI Generation Runbook

Purpose: give future agents the exact project workflow for UI image generation, reference upload, and documentation. No fallback is allowed in this project.

## Policy

- Use only `cx/gpt-5.5-image` for image generation.
- Do not use any fallback model or provider.
- Use `NINEROUTER_IMAGE_URL` if it exists; otherwise use `https://img.teelab247.com`.
- Owner approved using `NINEROUTER_KEY` for image generation in this project on 2026-07-01.
- Key selection order:
  - `NINEROUTER_IMAGE_KEY`
  - `NINEROUTER_KEY`
- Never print or write API keys to docs, logs, screenshots, or final replies.
- Stop if `/v1/models/image` does not list `cx/gpt-5.5-image`.

## Required Reference Pack

Before generation, build or update:

- `Assets/UI/cyberpunk_theme/reference_pack/`
- `docs/ui_cyber_reference_pack_r2.json`

Current reference pack must include:

- owner layout ratio reference
- current gameplay/playboard screenshot
- project logo
- cyber cell tile
- cyber source
- cyber target
- cyber I/L/T/X pipe sprites
- lightning/VFX tone preview

## R2 Upload

Use the existing uploader from:

- `C:\Users\Admin\Desktop\Game\reskin_dashboard\upload_server.py`

Do not copy secrets into this project. Import the old uploader and call `upload_to_r2`.

Example:

```powershell
$code = @'
import json, mimetypes, importlib.util
from pathlib import Path

server_path = r"C:\Users\Admin\Desktop\Game\reskin_dashboard\upload_server.py"
spec = importlib.util.spec_from_file_location("old_upload_server", server_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

ref_dir = Path(r"C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk\Assets\UI\cyberpunk_theme\reference_pack")
out_path = Path(r"C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk\docs\ui_cyber_reference_pack_r2.json")

items = []
for path in sorted(ref_dir.iterdir()):
    if not path.is_file():
        continue
    content_type = mimetypes.guess_type(str(path))[0] or "application/octet-stream"
    key = f"images/glyph-arrows-cyber-ui-ref/{path.name}"
    url = mod.upload_to_r2(path.read_bytes(), key, content_type)
    items.append({
        "name": path.name,
        "local_path": str(path),
        "r2_key": key,
        "url": url,
        "content_type": content_type,
        "bytes": path.stat().st_size
    })

out_path.write_text(json.dumps({
    "purpose": "Cyber gameplay UI 9Router reference pack for style synchronization.",
    "uploaded_at": "2026-07-01",
    "style_anchor": "cyber pipe puzzle, fake3D cockpit layer, black and deep green gameplay tone, cyan electric accent, glossy beveled sci-fi material, readable premium mobile game UI",
    "items": items
}, indent=2, ensure_ascii=False), encoding="utf-8")

print(json.dumps({"uploaded": len(items), "manifest": str(out_path)}, indent=2))
'@
$py = Join-Path $env:TEMP 'upload_cyber_ui_refs.py'
Set-Content -Path $py -Value $code -Encoding UTF8
python $py
```

Verify public refs:

```powershell
$manifest = Get-Content -Raw 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk\docs\ui_cyber_reference_pack_r2.json' | ConvertFrom-Json
foreach($item in $manifest.items | Select-Object -First 3){
  curl.exe -I --max-time 20 $item.url
}
```

Expected:

- `HTTP/1.1 200 OK`
- correct `Content-Type`

## Model Check

Run before every generation session:

```powershell
$ErrorActionPreference='Stop'
$base = if ($env:NINEROUTER_IMAGE_URL) { $env:NINEROUTER_IMAGE_URL } else { 'https://img.teelab247.com' }
$key = if ($env:NINEROUTER_IMAGE_KEY) { $env:NINEROUTER_IMAGE_KEY } else { $env:NINEROUTER_KEY }
if (-not $key) { throw 'No approved 9Router key found in NINEROUTER_IMAGE_KEY or NINEROUTER_KEY' }

$headers = @{ Authorization = "Bearer $key" }
$health = Invoke-RestMethod -Uri "$base/api/health" -Method Get -TimeoutSec 20
$models = Invoke-RestMethod -Uri "$base/v1/models/image" -Headers $headers -Method Get -TimeoutSec 30
$ids = @($models.data | ForEach-Object { $_.id })

[pscustomobject]@{
  base = $base
  health_ok = [bool]$health.ok
  key_source = if ($env:NINEROUTER_IMAGE_KEY) { 'NINEROUTER_IMAGE_KEY' } else { 'NINEROUTER_KEY' }
  image_model_count = $ids.Count
  has_cx_gpt_55_image = $ids -contains 'cx/gpt-5.5-image'
} | ConvertTo-Json -Compress
```

Expected:

- `health_ok=true`
- `has_cx_gpt_55_image=true`

Optional model info:

```powershell
$info = Invoke-RestMethod -Uri "$base/v1/models/info?id=cx/gpt-5.5-image" -Headers $headers -Method Get -TimeoutSec 30
$info | ConvertTo-Json -Depth 10
```

Current known capability:

- endpoint: `/v1/images/generations`
- capabilities: `text2img`, `edit`
- params: `size`, `quality`, `background`, `image_detail`, `output_format`

## Generate Full-Screen Style Trial

Use the style prompts from:

- `docs/ui_cyber_style_trials.md`

Example for Trial A:

```powershell
$ErrorActionPreference='Stop'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk'
$base = if ($env:NINEROUTER_IMAGE_URL) { $env:NINEROUTER_IMAGE_URL } else { 'https://img.teelab247.com' }
$key = if ($env:NINEROUTER_IMAGE_KEY) { $env:NINEROUTER_IMAGE_KEY } else { $env:NINEROUTER_KEY }
if (-not $key) { throw 'No approved 9Router key found' }

$out = Join-Path $project 'Assets\UI\cyberpunk_theme\generated\style_trial_a_full_mockup.png'
$manifest = Get-Content -Raw (Join-Path $project 'docs\ui_cyber_reference_pack_r2.json') | ConvertFrom-Json
$urls = @($manifest.items | ForEach-Object { $_.url })

$prompt = @"
Using the reference images, create a premium mobile puzzle game UI concept mockup. Style anchor: cyber pipe puzzle, fake3D cockpit layer, black and deep green gameplay tone, cyan electric accent, glossy beveled sci-fi material, readable premium mobile game UI, coherent scale with existing pipe sprites, no placeholder text, no fake logo, no extra gameplay pieces. Portrait gameplay screen. Top HUD is a single floating fake3D cockpit tray layer, overflowing edges slightly, with a smaller inner capsule for stats and centered logo socket. Purple floating menu button left, yellow floating replay button right. Center gameplay board area is quiet and readable for a square pipe grid with existing black-green cyber tiles and cyan-green energy. Bottom area reserves space but stays secondary. Background is subtle deep cyber circuitry with soft parallax depth, not busy. No characters, no readable text, no random pipes in UI, no tile-like stat cards.

Reference image URLs for style synchronization:
$($urls -join "`n")
"@

$bodyObj = [ordered]@{
  model = 'cx/gpt-5.5-image'
  prompt = $prompt
  size = '1024x1792'
  output_format = 'png'
  image_detail = 'high'
  images = $urls
}

$bodyPath = Join-Path $env:TEMP 'style_trial_a_9router_request.json'
($bodyObj | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath $bodyPath -Encoding UTF8

curl.exe -sS --fail-with-body -w '%{http_code}' `
  -X POST "$base/v1/images/generations?response_format=binary" `
  -H "Authorization: Bearer $key" `
  -H "Content-Type: application/json" `
  --data-binary "@$bodyPath" `
  --output "$out"
```

After generation:

- verify pixel size
- compute SHA256
- inspect visually
- upload trial to R2
- write output path, R2 URL, dimensions, bytes, SHA256, model, prompt/ref count, and visual audit notes into `docs/ui_cyber_style_trials.md`
- update `docs/ui_gameplay_layout_checklist.md`

## Generate Production Component Asset

Production component generation is different from style trials.

Canonical queue:

- `docs/ui_cyber_9router_component_call_queue.md`

Use that queue for component order, required refs, prompt additions, output paths, and audit gates. Do not call 9Router for random UI parts outside the queue. If a new UI part is needed, add it to the queue first with refs and SSOT geometry fields.

Rules:

- Generate one isolated object per image.
- Do not generate poster art, full-screen mockups, sample gameplay screenshots, or decorative compositions.
- Use transparent PNG when possible.
- If transparent PNG is not clean, generate on a flat removable background and run PhotoRoom.
- PhotoRoom is mandatory for every non-background transparent production object.
- Do not blame PhotoRoom when a cutout has a full-canvas alpha bbox. Full bbox can come from valid glow/edge alpha touching the canvas. Inspect the cutout on checkerboard and verify alpha, then fix extraction geometry if needed.
- Chroma-key cleanup is debug-only preview work and must not be recorded as production alpha.
- Production asset paths must point to PhotoRoom cutouts, not chroma-key outputs.
- Object must be centered, fully visible, uncropped, and easy to slice/place in Godot.
- No baked text, fake logos, characters, mascots, extra icons, pipes, board screenshots, or sample UI labels.
- Background-full is the only component allowed to be a full-screen image.
- Text work starts only after all object assets for that screen are placed through SSOT and approved from screenshots.

Prompt shape:

```text
Create one isolated production game UI asset object, not a poster and not a full-screen mockup.
Asset: <component name>.
Mode: <dark or light>.
Use reference images only for material, bevel, glow, and proportion.
Output only the object on transparent background or a flat removable background.
No text, no fake logo, no characters, no gameplay pipes, no board screenshot.
Keep the object fully visible with clean alpha-friendly edges.
```

After generation:

- inspect alpha/background
- run PhotoRoom for every non-background object that needs transparency
- QA PhotoRoom edges on dark, light, and checkerboard backgrounds
- record local PhotoRoom path, R2 URL, pixel size, anchor, draw rect, padding, SSOT key, `background_removal_method = photoroom`, and `edge_qa_status`
- reject if output reads as poster/mockup instead of object asset

Sprite-sheet extraction rule:

- If 9Router produces an approved multi-object sheet, run PhotoRoom on the full approved sheet first.
- Then clone the PhotoRoom sheet once per wanted object/glyph, mask every other object out from that clone, and trim the remaining object.
- Compose a canonical atlas only from the trimmed PhotoRoom-derived object files.
- Do not slice by equal grid guesses, fixed cell counts, or hand-counted columns. Object bounds must come from the PhotoRoom sheet alpha/object mask and be recorded in SSOT.
- Do not regenerate each glyph/object independently unless the owner rejects the sheet style; independent regeneration can drift style and scale.

Minimal call loop for queued components:

```powershell
$ErrorActionPreference='Stop'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk'
$base = if ($env:NINEROUTER_IMAGE_URL) { $env:NINEROUTER_IMAGE_URL } else { 'https://img.teelab247.com' }
$key = if ($env:NINEROUTER_IMAGE_KEY) { $env:NINEROUTER_IMAGE_KEY } else { $env:NINEROUTER_KEY }
if (-not $key) { throw 'No approved 9Router key found in NINEROUTER_IMAGE_KEY or NINEROUTER_KEY' }

$headers = @{ Authorization = "Bearer $key" }
$models = Invoke-RestMethod -Uri "$base/v1/models/image" -Headers $headers -Method Get -TimeoutSec 30
if (@($models.data | ForEach-Object { $_.id }) -notcontains 'cx/gpt-5.5-image') {
  throw 'cx/gpt-5.5-image missing. Stop; no fallback allowed.'
}

$fullRefs = Get-Content -Raw (Join-Path $project 'docs\ui_cyber_reference_pack_r2.json') | ConvertFrom-Json
$componentRefs = Get-Content -Raw (Join-Path $project 'docs\ui_cyber_dark_light_component_refs_r2.json') | ConvertFrom-Json

# Pick refs from docs/ui_cyber_9router_component_call_queue.md.
# Build prompt from base block plus component prompt additions.
# Save raw to Assets/UI/cyberpunk_theme/generated/production/<mode>/<component>_raw.png.
# Save temporary preview alpha only if needed; chroma-key preview is not production.
# Clean production alpha through PhotoRoom to Assets/UI/cyberpunk_theme/generated/production/<mode>/<component>_photoroom.png.
# Upload PhotoRoom production alpha to R2 through C:\Users\Admin\Desktop\Game\reskin_dashboard\upload_server.py.
# Append/update docs/ui_cyber_component_generation_manifest.json.
```

## Visual Audit Rules

Reject or regenerate if any of these appear:

- generated character, mascot, fake avatar, or fake logo
- poster composition or full-screen mockup generated for a production component
- readable placeholder text
- Waternet or unrelated brand text
- extra gameplay pieces in the UI tray/background
- tile-like stat cards spread across the top
- board area too busy for pipe/VFX readability
- color drift away from black/deep-green, cyan electric accent, purple menu, yellow replay
- material drift between generated parts

Trial A generated on 2026-07-01 passed material direction but contained a robot mascot in the logo socket. Use it as style direction only if owner accepts regenerating/replacing the logo core.

## Production Slice Rule

Full-screen mockups are not production assets.

After owner picks a style:

1. Generate background and fake3D layer assets from the approved mockup plus the same R2 reference pack.
2. Use PhotoRoom for every non-background alpha cutout; chroma-key cleanup is preview-only.
3. Store final asset paths and geometry in SSOT.
4. Do not replace canonical pipe/cell gameplay sprites with mockup pixels.
5. Do not hand-tune production dimensions in scene node offsets.
6. Place all object assets first; only then add or tune text.

## Required Tests

Run after doc updates:

```powershell
& 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe' --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' --script 'res://Tests/test_ui_gameplay_layout_checklist_contract.gd'
& 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe' --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' --script 'res://Tests/test_ui_production_workflow_contract.gd'
```
