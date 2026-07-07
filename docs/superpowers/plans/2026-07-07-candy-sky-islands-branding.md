# Candy Sky Islands Branding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the approved Candy Sky Islands branding set: app icon, splash image, and exact-text logo/wordmark.

**Architecture:** Keep branding assets isolated under `assets/themes/candy_sky_islands/branding/` until owner visual approval. Use 9Router `cx/gpt-5.5-image` for mascot icon, splash art, and exact-text wordmark/logo; local deterministic text rendering is only an emergency fallback if owner rejects the generated logo and explicitly approves fallback. Update project display name, root icon, and root splash only after approval. Add branding SSOT fields, manifest rows, QA scripts, and validation tests so reset context cannot skip the gate.

**Tech Stack:** Godot 4 GDScript, PNG assets, Python 3 with Pillow, 9Router image endpoint, Photoroom CDP port `9223` if alpha extraction is needed, PowerShell validation commands.

---

## File Structure

- Create `tests/test_branding_contract.gd`: verifies branding SSOT fields, manifest entries, checklist gate, and project settings after integration.
- Modify `Resources/QuantumThemeConfig.gd`: add branding asset paths.
- Modify `Resources/Data/Themes/candy_sky_islands/theme_config.tres`: store branding paths once assets exist.
- Create `tools/generate_candy_sky_branding.py`: calls 9Router for icon, splash, and logo drafts without printing secrets.
- Create `tools/render_candy_sky_logo.py`: emergency fallback only; renders exact `Candy Sky Islands` transparent PNG from local font if owner rejects the generated logo and approves fallback.
- Create `tools/qa_branding_assets.py`: verifies dimensions, modes, alpha where required, and small-icon readability proxy.
- Create `tools/make_branding_contact_sheet.py`: creates owner review sheet.
- Create assets under `assets/themes/candy_sky_islands/branding/`.
- Modify `project.godot`: only after owner approval, set `config/name="Candy Sky Islands"`, keep `config/icon="res://icon.png"` and `boot_splash/image="res://splash-screen.png"`, and replace root icon/splash files with approved themed versions.
- Modify `docs/asset_manifest.md`, `docs/reskin_checklist.md`, and `docs/reskin_state.md`: record gates and evidence.

## Task 1: Branding SSOT Contract

**Files:**
- Create: `tests/test_branding_contract.gd`
- Modify: `Resources/QuantumThemeConfig.gd`
- Modify: `Resources/Data/Themes/candy_sky_islands/theme_config.tres`

- [ ] **Step 1: Write the failing branding contract test**

Create `tests/test_branding_contract.gd`:

```gdscript
extends SceneTree

const THEME_PATH := "res://Resources/Data/Themes/candy_sky_islands/theme_config.tres"
const MANIFEST := "res://docs/asset_manifest.md"
const CHECKLIST := "res://docs/reskin_checklist.md"
const STATE := "res://docs/reskin_state.md"
const PROJECT := "res://project.godot"

func _init() -> void:
	var passed := true
	var theme := load(THEME_PATH)
	passed = passed and _assert_true(theme != null, "Candy theme should load")
	if theme != null:
		passed = passed and _assert_equal(theme.get("branding_icon_source_path"), "res://assets/themes/candy_sky_islands/branding/app_icon_source.png", "Branding icon source path should be explicit")
		passed = passed and _assert_equal(theme.get("branding_splash_path"), "res://assets/themes/candy_sky_islands/branding/splash_candy_sky_islands.png", "Branding splash path should be explicit")
		passed = passed and _assert_equal(theme.get("branding_logo_path"), "res://assets/themes/candy_sky_islands/branding/logo_candy_sky_islands.png", "Branding logo path should be explicit")
		passed = passed and _assert_equal(theme.get("branding_display_name"), "Candy Sky Islands", "Branding display name should match exact logo text")
	passed = passed and _assert_file_contains(MANIFEST, "app.icon", "Manifest should include app icon row")
	passed = passed and _assert_file_contains(MANIFEST, "app.splash", "Manifest should include splash row")
	passed = passed and _assert_file_contains(MANIFEST, "app.logo.main", "Manifest should include logo row")
	passed = passed and _assert_file_contains(CHECKLIST, "### Checkpoint 4: Branding", "Checklist should include branding checkpoint")
	passed = passed and _assert_file_contains(STATE, "Branding", "State should mention branding gate")
	passed = passed and _assert_file_contains(PROJECT, "config/icon=\"res://icon.png\"", "Project should keep root icon setting")
	passed = passed and _assert_file_contains(PROJECT, "boot_splash/image=\"res://splash-screen.png\"", "Project should keep root splash setting")
	if passed:
		print("test_branding_contract: PASS")
		quit(0)
	else:
		print("test_branding_contract: FAIL")
		quit(1)

func _assert_true(value: bool, message: String) -> bool:
	if not value:
		push_error(message)
		return false
	return true

func _assert_equal(actual, expected, message: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return false
	return true

func _assert_file_contains(path: String, needle: String, message: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("%s: missing %s" % [message, path])
		return false
	var text := FileAccess.get_file_as_string(path)
	if not text.contains(needle):
		push_error("%s: missing '%s'" % [message, needle])
		return false
	return true
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_branding_contract.gd"
```

Expected: FAIL because branding fields do not exist in `QuantumThemeConfig.gd` yet.

- [ ] **Step 3: Add branding fields to `QuantumThemeConfig.gd`**

Add this block after the Asset Family group and before the World group:

```gdscript
@export_group("Branding")
@export var branding_display_name := "Candy Sky Islands"
@export_file("*.png", "*.webp") var branding_icon_source_path := "res://assets/themes/candy_sky_islands/branding/app_icon_source.png"
@export_file("*.png", "*.webp") var branding_splash_path := "res://assets/themes/candy_sky_islands/branding/splash_candy_sky_islands.png"
@export_file("*.png", "*.webp") var branding_logo_path := "res://assets/themes/candy_sky_islands/branding/logo_candy_sky_islands.png"
```

Do not add these paths to `validate()` yet; the assets are not generated at this stage.

- [ ] **Step 4: Add branding values to `theme_config.tres`**

Add these values after `cloud_shadow_material_color`:

```ini
branding_display_name = "Candy Sky Islands"
branding_icon_source_path = "res://assets/themes/candy_sky_islands/branding/app_icon_source.png"
branding_splash_path = "res://assets/themes/candy_sky_islands/branding/splash_candy_sky_islands.png"
branding_logo_path = "res://assets/themes/candy_sky_islands/branding/logo_candy_sky_islands.png"
```

- [ ] **Step 5: Run the branding contract test**

Run the command from Step 2.

Expected: PASS with `test_branding_contract: PASS`.

- [ ] **Step 6: Commit Task 1**

Run:

```powershell
git add tests/test_branding_contract.gd Resources/QuantumThemeConfig.gd Resources/Data/Themes/candy_sky_islands/theme_config.tres
git -c user.name='Codex' -c user.email='codex@local' commit -m 'test: add candy branding contract'
```

Expected: commit succeeds. If unrelated files are staged, stop and unstage only unrelated paths with `git restore --staged <path>`.

## Task 2: Branding Asset Generation Tools

**Files:**
- Create: `tools/generate_candy_sky_branding.py`
- Create: `tools/render_candy_sky_logo.py`
- Create: `tools/qa_branding_assets.py`
- Create: `tools/make_branding_contact_sheet.py`

- [ ] **Step 1: Create the 9Router generation script**

Create `tools/generate_candy_sky_branding.py`:

```python
#!/usr/bin/env python3
import json
import os
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "themes" / "candy_sky_islands" / "branding"
IMAGE_URL = os.environ.get("NINEROUTER_IMAGE_URL", "https://img.teelab247.com").rstrip("/")
MODEL = "cx/gpt-5.5-image"

ICON_PROMPT = """Use case: stylized-concept
Asset type: mobile game app icon source
Primary request: Create a square Candy Sky Islands app icon featuring the approved Marshmallow Runner mascot head and upper body as the main read, with one small coral star-candy collectible cue.
Scene/backdrop: simple candy sky island color field, not a busy scene.
Subject: cheerful toy-like marshmallow runner mascot, cream body, coral and mint accents, friendly face, strong silhouette.
Style/medium: polished casual 3D mobile game icon, rounded candy materials, clean readable shapes.
Composition/framing: centered subject, fills most of the square, safe padding, readable at tiny launcher size.
Color palette: sky blue #79C7F2, cream #FFF2C7, coral #FF6F61, mint #7BE0AD, dark outline accent #273043.
Text (verbatim): no text.
Constraints: no logo, no letters, no watermark, no store badge, no UI, no cropped head, no extra characters.
"""

SPLASH_PROMPT = """Use case: stylized-concept
Asset type: 16:9 mobile game splash image
Primary request: Create a Candy Sky Islands splash screen with the approved Marshmallow Runner standing on a cream cake-cloud platform, with coral star-candy collectibles floating nearby.
Scene/backdrop: bright sky blue candy sky islands, soft clouds, cheerful readable mobile game world.
Subject: one marshmallow runner mascot, cake-cloud island platform, star-candy collectibles.
Style/medium: polished casual 3D game splash art, toy-like candy materials, clean shapes.
Composition/framing: 16:9 landscape, mascot in lower middle, clean upper center area reserved for separate logo overlay, no in-image title text.
Color palette: sky blue #79C7F2, cream #FFF2C7, coral #FF6F61, mint #7BE0AD, dark accent #273043.
Text (verbatim): no text.
Constraints: no logo, no words, no tutorial UI, no buttons, no store badge, no watermark, no photorealism, no dark cinematic lighting.
"""

LOGO_PROMPT = """Use case: logo-brand
Asset type: mobile game transparent logo source
Primary request: Create a compact Candy Sky Islands wordmark/logo with exact text.
Text (verbatim): "Candy Sky Islands"
Style/medium: polished casual 3D candy game wordmark, rounded candy-like lettering, clean vector-friendly shapes rendered as PNG.
Composition/framing: centered logo, transparent-friendly plain light background, generous padding, no mascot, no extra icons unless they are tiny candy highlights attached to letters.
Color palette: cream #FFF2C7, coral #FF6F61, mint #7BE0AD, dark outline #273043.
Constraints: text must be exactly Candy Sky Islands, no subtitle, no slogan, no extra words, no watermark, no store badge.
"""

def _auth_key() -> str:
	key = os.environ.get("NINEROUTER_IMAGE_KEY") or os.environ.get("NINEROUTER_KEY") or os.environ.get("ROUTER_API_KEY")
	if not key:
		raise RuntimeError("No owner-approved image key found: set NINEROUTER_IMAGE_KEY, NINEROUTER_KEY, or ROUTER_API_KEY.")
	return key

def _post_image(prompt: str, size: str, output_path: Path) -> None:
	payload = {
		"model": MODEL,
		"prompt": prompt,
		"size": size,
		"output_format": "png",
	}
	data = json.dumps(payload).encode("utf-8")
	req = urllib.request.Request(
		f"{IMAGE_URL}/v1/images/generations?response_format=binary",
		data=data,
		headers={
			"Authorization": f"Bearer {_auth_key()}",
			"Content-Type": "application/json",
		},
		method="POST",
	)
	try:
		with urllib.request.urlopen(req, timeout=180) as response:
			body = response.read()
	except urllib.error.HTTPError as exc:
		body = exc.read().decode("utf-8", errors="replace")
		raise RuntimeError(f"Image generation failed with HTTP {exc.code}: {body}") from exc
	output_path.parent.mkdir(parents=True, exist_ok=True)
	output_path.write_bytes(body)
	print(output_path)

def main() -> int:
	_post_image(ICON_PROMPT, "1024x1024", OUT_DIR / "app_icon_source.png")
	_post_image(SPLASH_PROMPT, "1792x1024", OUT_DIR / "splash_candy_sky_islands_raw.png")
	_post_image(LOGO_PROMPT, "1024x1024", OUT_DIR / "logo_candy_sky_islands_raw.png")
	return 0

if __name__ == "__main__":
	raise SystemExit(main())
```

- [ ] **Step 2: Create emergency deterministic logo renderer**

Create `tools/render_candy_sky_logo.py`. This script is not the primary logo path; it is an emergency fallback if the owner rejects generated logo text and approves local rendering:

```python
#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "themes" / "candy_sky_islands" / "branding" / "logo_candy_sky_islands.png"
FONT = ROOT / "fonts" / "lilita_one_regular.ttf"
TEXT = "Candy Sky Islands"

def main() -> int:
	font = ImageFont.truetype(str(FONT), 132)
	padding_x, padding_y = 56, 42
	dummy = Image.new("RGBA", (1, 1), (0, 0, 0, 0))
	draw = ImageDraw.Draw(dummy)
	box = draw.textbbox((0, 0), TEXT, font=font, stroke_width=10)
	width = box[2] - box[0] + padding_x * 2
	height = box[3] - box[1] + padding_y * 2
	image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
	shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
	shadow_draw = ImageDraw.Draw(shadow)
	position = (padding_x, padding_y - box[1])
	shadow_draw.text(position, TEXT, font=font, fill=(39, 48, 67, 180), stroke_width=14, stroke_fill=(39, 48, 67, 180))
	shadow = shadow.filter(ImageFilter.GaussianBlur(2.0))
	image.alpha_composite(shadow)
	draw = ImageDraw.Draw(image)
	draw.text(position, TEXT, font=font, fill=(255, 242, 199, 255), stroke_width=10, stroke_fill=(39, 48, 67, 255))
	draw.text((position[0], position[1] - 8), TEXT, font=font, fill=(255, 111, 97, 90), stroke_width=0)
	draw.line((padding_x + 18, height - 34, width - padding_x - 18, height - 34), fill=(123, 224, 173, 255), width=10)
	OUT.parent.mkdir(parents=True, exist_ok=True)
	image.save(OUT)
	print(OUT)
	return 0

if __name__ == "__main__":
	raise SystemExit(main())
```

- [ ] **Step 3: Create branding QA script**

Create `tools/qa_branding_assets.py`:

```python
#!/usr/bin/env python3
import json
from pathlib import Path

from PIL import Image, ImageStat

ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / "assets" / "themes" / "candy_sky_islands" / "branding"
OUT = BRANDING / "branding_qc.json"

ASSETS = {
	"app_icon_source": {"path": BRANDING / "app_icon_source.png", "size": (1024, 1024), "alpha": False},
	"splash_raw": {"path": BRANDING / "splash_candy_sky_islands_raw.png", "min_size": (1024, 576), "alpha": False},
	"logo": {"path": BRANDING / "logo_candy_sky_islands.png", "alpha": True},
}

def _alpha_extrema(image: Image.Image):
	if image.mode != "RGBA":
		return None
	return image.getchannel("A").getextrema()

def _is_nonblank(image: Image.Image) -> bool:
	rgb = image.convert("RGB")
	stat = ImageStat.Stat(rgb)
	return max(stat.var) > 8.0

def main() -> int:
	report = {"assets": {}, "bad": []}
	for key, rule in ASSETS.items():
		path = rule["path"]
		item = {"path": str(path.relative_to(ROOT))}
		if not path.exists():
			item["error"] = "missing"
			report["bad"].append(key)
			report["assets"][key] = item
			continue
		image = Image.open(path)
		item["mode"] = image.mode
		item["size"] = list(image.size)
		item["nonblank"] = _is_nonblank(image)
		if "size" in rule and image.size != rule["size"]:
			item["error"] = f"expected size {rule['size']}, got {image.size}"
			report["bad"].append(key)
		if "min_size" in rule and (image.width < rule["min_size"][0] or image.height < rule["min_size"][1]):
			item["error"] = f"expected min size {rule['min_size']}, got {image.size}"
			report["bad"].append(key)
		if rule["alpha"]:
			item["alpha_extrema"] = _alpha_extrema(image)
			if item["alpha_extrema"] != (0, 255):
				item["error"] = f"expected alpha extrema (0, 255), got {item['alpha_extrema']}"
				report["bad"].append(key)
		if not item["nonblank"]:
			item["error"] = "blank or nearly blank image"
			report["bad"].append(key)
		report["assets"][key] = item
	OUT.write_text(json.dumps(report, indent=2), encoding="utf-8")
	print(OUT)
	return 1 if report["bad"] else 0

if __name__ == "__main__":
	raise SystemExit(main())
```

- [ ] **Step 4: Create owner review contact sheet script**

Create `tools/make_branding_contact_sheet.py`:

```python
#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / "assets" / "themes" / "candy_sky_islands" / "branding"
OUT = ROOT / "docs" / "screenshots" / "candy_sky_islands_branding_contact_sheet.png"

ITEMS = [
	("App icon", BRANDING / "app_icon_source.png", (360, 360)),
	("Splash", BRANDING / "splash_candy_sky_islands.png", (720, 405)),
	("Logo", BRANDING / "logo_candy_sky_islands.png", (720, 180)),
]

def _fit(image: Image.Image, max_size: tuple[int, int]) -> Image.Image:
	image = image.convert("RGBA")
	scale = min(max_size[0] / image.width, max_size[1] / image.height, 1.0)
	size = (max(1, int(image.width * scale)), max(1, int(image.height * scale)))
	return image.resize(size, Image.LANCZOS)

def main() -> int:
	font = ImageFont.load_default()
	canvas = Image.new("RGB", (820, 1080), (24, 30, 38))
	draw = ImageDraw.Draw(canvas)
	y = 28
	for label, path, box in ITEMS:
		draw.text((32, y), label, fill=(233, 251, 255), font=font)
		y += 24
		draw.rectangle((32, y, 32 + box[0], y + box[1]), fill=(55, 64, 74), outline=(255, 242, 199))
		if path.exists():
			image = _fit(Image.open(path), box)
			x = 32 + (box[0] - image.width) // 2
			py = y + (box[1] - image.height) // 2
			if image.mode == "RGBA":
				canvas.paste(image, (x, py), image)
			else:
				canvas.paste(image, (x, py))
		else:
			draw.text((48, y + 24), f"Missing: {path.name}", fill=(255, 111, 97), font=font)
		y += box[1] + 42
	OUT.parent.mkdir(parents=True, exist_ok=True)
	canvas.save(OUT)
	print(OUT)
	return 0

if __name__ == "__main__":
	raise SystemExit(main())
```

- [ ] **Step 5: Commit Task 2**

Run:

```powershell
git add tools/generate_candy_sky_branding.py tools/render_candy_sky_logo.py tools/qa_branding_assets.py tools/make_branding_contact_sheet.py
git -c user.name='Codex' -c user.email='codex@local' commit -m 'tools: add candy branding asset pipeline'
```

Expected: commit succeeds with only tool files staged.

## Task 3: Generate Draft Branding Assets

**Files:**
- Create: `assets/themes/candy_sky_islands/branding/app_icon_source.png`
- Create: `assets/themes/candy_sky_islands/branding/splash_candy_sky_islands_raw.png`
- Create: `assets/themes/candy_sky_islands/branding/logo_candy_sky_islands.png`
- Create: `assets/themes/candy_sky_islands/branding/branding_qc.json`

- [ ] **Step 1: Confirm generation gate**

Before running paid generation, confirm the owner has approved generation for:

```text
app_icon_source.png
splash_candy_sky_islands_raw.png
logo_candy_sky_islands_raw.png
```

Expected: owner approval exists in chat. Logo is generated through 9Router as the primary path.

- [ ] **Step 2: Generate icon and splash through 9Router**

Run:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
$env:NINEROUTER_IMAGE_URL = 'https://img.teelab247.com'
python "$project\tools\generate_candy_sky_branding.py"
```

Expected output includes:

```text
assets\themes\candy_sky_islands\branding\app_icon_source.png
assets\themes\candy_sky_islands\branding\splash_candy_sky_islands_raw.png
assets\themes\candy_sky_islands\branding\logo_candy_sky_islands_raw.png
```

If key is missing, stop and report `No owner-approved image key found`. Do not print any key value.

- [ ] **Step 3: Prepare generated wordmark**

Run:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
Copy-Item -LiteralPath "$project\assets\themes\candy_sky_islands\branding\logo_candy_sky_islands_raw.png" -Destination "$project\assets\themes\candy_sky_islands\branding\logo_candy_sky_islands.png" -Force
```

Expected output:

```text
assets\themes\candy_sky_islands\branding\logo_candy_sky_islands.png
```

If the generated logo has a background that must be removed, run Photoroom on the full logo image first through CDP port `9223`, then save the output to `logo_candy_sky_islands.png`. Do not crop before Photoroom. If owner rejects generated text, stop and ask whether to use `tools/render_candy_sky_logo.py` fallback.

- [ ] **Step 4: Normalize splash to project ratio**

Run:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
python - <<'PY'
from pathlib import Path
from PIL import Image
project = Path(r'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter')
src = project / 'assets/themes/candy_sky_islands/branding/splash_candy_sky_islands_raw.png'
out = project / 'assets/themes/candy_sky_islands/branding/splash_candy_sky_islands.png'
img = Image.open(src).convert('RGB')
target = (2560, 1440)
ratio = target[0] / target[1]
if img.width / img.height > ratio:
    new_w = int(img.height * ratio)
    left = (img.width - new_w) // 2
    img = img.crop((left, 0, left + new_w, img.height))
else:
    new_h = int(img.width / ratio)
    top = (img.height - new_h) // 2
    img = img.crop((0, top, img.width, top + new_h))
img = img.resize(target, Image.LANCZOS)
out.parent.mkdir(parents=True, exist_ok=True)
img.save(out)
print(out)
PY
```

Expected output:

```text
assets\themes\candy_sky_islands\branding\splash_candy_sky_islands.png
```

- [ ] **Step 5: Run branding QA**

Run:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
python "$project\tools\qa_branding_assets.py"
```

Expected: exit code `0`; `assets/themes/candy_sky_islands/branding/branding_qc.json` has `"bad": []`.

- [ ] **Step 6: Create owner review contact sheet**

Run:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
python "$project\tools\make_branding_contact_sheet.py"
```

Expected output:

```text
docs\screenshots\candy_sky_islands_branding_contact_sheet.png
```

- [ ] **Step 7: Visual inspection**

Open and inspect:

```text
assets/themes/candy_sky_islands/branding/app_icon_source.png
assets/themes/candy_sky_islands/branding/splash_candy_sky_islands.png
assets/themes/candy_sky_islands/branding/logo_candy_sky_islands.png
docs/screenshots/candy_sky_islands_branding_contact_sheet.png
```

Reject before owner review if:

- Icon has text, cropped mascot, extra character, unreadable small silhouette, or busy background.
- Splash includes title text, gameplay UI, buttons, store badge, dark lighting, or covers the logo space.
- Logo text is not exactly `Candy Sky Islands`.
- Logo alpha is missing.

- [ ] **Step 8: Commit draft branding assets**

Run:

```powershell
git add assets/themes/candy_sky_islands/branding docs/screenshots/candy_sky_islands_branding_contact_sheet.png
git -c user.name='Codex' -c user.email='codex@local' commit -m 'art: add candy branding draft assets'
```

Expected: commit succeeds. This commit is draft assets only, not production integration.

## Task 4: Owner Visual Approval Gate

**Files:**
- Modify: `docs/reskin_state.md`
- Modify: `docs/reskin_checklist.md`
- Modify: `docs/asset_manifest.md`

- [ ] **Step 1: Present contact sheet to owner**

Show:

```text
docs/screenshots/candy_sky_islands_branding_contact_sheet.png
```

Ask:

```text
Duyệt bộ branding này để integrate vào project không? Icon, splash, logo đều phải duyệt trước khi thay `icon.png` và `splash-screen.png`.
```

Expected: continue only after owner approval.

- [ ] **Step 2: Update docs after owner approval**

In `docs/reskin_checklist.md`, set:

```markdown
- [x] App icon generation or creation approved before generation.
- [x] Splash generation or creation approved before generation.
- [x] Logo generation or creation approved before generation.
- [x] Generated or created branding PNGs visually inspected.
- [x] Branding PNGs owner approved.
- [x] Branding assets recorded in manifest before production integration.
```

In `docs/reskin_state.md`, set:

```markdown
## Current Gate

Branding integration after owner visual approval.
```

Add completed asset lines:

```markdown
- Branding app icon source owner approved: `assets/themes/candy_sky_islands/branding/app_icon_source.png`.
- Branding splash owner approved: `assets/themes/candy_sky_islands/branding/splash_candy_sky_islands.png`.
- Branding logo owner approved: `assets/themes/candy_sky_islands/branding/logo_candy_sky_islands.png`.
```

In `docs/asset_manifest.md`, update rows:

```markdown
| App icon | app.icon | `res://icon.png` and `res://assets/themes/candy_sky_islands/branding/app_icon_source.png` | 9Router `cx/gpt-5.5-image` after owner approval | generated, visually approved, pending production copy | N/A | square safe padding | 1024x1024 source, 256x256 production root icon | `res://docs/screenshots/candy_sky_islands_branding_contact_sheet.png` | Marshmallow Runner icon with star-candy cue |
| Splash image | app.splash | `res://splash-screen.png` and `res://assets/themes/candy_sky_islands/branding/splash_candy_sky_islands.png` | 9Router `cx/gpt-5.5-image` after owner approval | generated, visually approved, pending production copy | logo safe area in upper/center space | 16:9 crop | 2560x1440 startup splash | `res://docs/screenshots/candy_sky_islands_branding_contact_sheet.png` | Candy Sky Islands splash with mascot and collectibles |
| Logo | app.logo.main | `res://assets/themes/candy_sky_islands/branding/logo_candy_sky_islands.png` | 9Router `cx/gpt-5.5-image` after owner approval; Photoroom full-image alpha if needed | generated, visually approved | text bounds from alpha trim | transparent padding | transparent PNG | `res://docs/screenshots/candy_sky_islands_branding_contact_sheet.png` | Exact text: Candy Sky Islands |
```

- [ ] **Step 3: Commit approval docs**

Run:

```powershell
git add docs/reskin_state.md docs/reskin_checklist.md docs/asset_manifest.md
git -c user.name='Codex' -c user.email='codex@local' commit -m 'docs: approve candy branding assets'
```

Expected: commit succeeds after owner approval is recorded.

## Task 5: Production Integration

**Files:**
- Modify: `icon.png`
- Modify: `splash-screen.png`
- Modify: `project.godot`
- Modify: `Resources/Data/Themes/candy_sky_islands/theme_config.tres`
- Modify: `tests/test_branding_contract.gd`
- Modify: `docs/reskin_checklist.md`
- Modify: `docs/reskin_state.md`
- Modify: `docs/asset_manifest.md`

- [ ] **Step 1: Extend branding contract for production app name**

Add this assertion after the project icon and splash assertions in `tests/test_branding_contract.gd`:

```gdscript
passed = passed and _assert_file_contains(PROJECT, "config/name=\"Candy Sky Islands\"", "Project display name should use branding name after integration")
```

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_branding_contract.gd"
```

Expected: FAIL until `project.godot` is updated from `Starter Kit 3D Platformer` to `Candy Sky Islands`.

- [ ] **Step 2: Copy approved icon into production root**

Run:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
python - <<'PY'
from pathlib import Path
from PIL import Image
project = Path(r'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter')
src = project / 'assets/themes/candy_sky_islands/branding/app_icon_source.png'
out = project / 'icon.png'
img = Image.open(src).convert('RGBA').resize((256, 256), Image.LANCZOS)
img.save(out)
print(out)
PY
```

Expected: `icon.png` is `256x256`.

- [ ] **Step 3: Copy approved splash into production root**

Run:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
Copy-Item -LiteralPath "$project\assets\themes\candy_sky_islands\branding\splash_candy_sky_islands.png" -Destination "$project\splash-screen.png" -Force
```

Expected: `splash-screen.png` remains `2560x1440`.

- [ ] **Step 4: Update project display name**

In `project.godot`, change:

```ini
config/name="Starter Kit 3D Platformer"
```

to:

```ini
config/name="Candy Sky Islands"
```

Keep these paths unchanged:

```ini
boot_splash/image="res://splash-screen.png"
config/icon="res://icon.png"
```

- [ ] **Step 5: Confirm project settings**

Run:

```powershell
Select-String -LiteralPath 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter\project.godot' -Pattern 'config/icon|boot_splash/image|config/name'
```

Expected lines:

```text
config/name="Candy Sky Islands"
boot_splash/image="res://splash-screen.png"
config/icon="res://icon.png"
```

- [ ] **Step 6: Run branding contract**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --script "$project\tests\test_branding_contract.gd"
```

Expected: PASS with `test_branding_contract: PASS`.

- [ ] **Step 7: Update checklist, state, and manifest integration status**

In `docs/reskin_checklist.md`, set:

```markdown
- [x] Project icon and splash integrated only after owner visual approval.
```

In `docs/reskin_state.md`, set:

```markdown
## Current Gate

Branding validation.
```

In `docs/asset_manifest.md`, change app icon and splash status to:

```text
integrated, pending validation
```

- [ ] **Step 8: Commit production integration**

Run:

```powershell
git add icon.png splash-screen.png project.godot Resources/Data/Themes/candy_sky_islands/theme_config.tres tests/test_branding_contract.gd docs/reskin_checklist.md docs/reskin_state.md docs/asset_manifest.md
git -c user.name='Codex' -c user.email='codex@local' commit -m 'art: integrate candy app branding'
```

Expected: commit succeeds after production files are updated.

## Task 6: Validation And Final Evidence

**Files:**
- Modify: `docs/reskin_checklist.md`
- Modify: `docs/reskin_state.md`
- Modify: `docs/asset_manifest.md`

- [ ] **Step 1: Run branding QA**

Run:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
python "$project\tools\qa_branding_assets.py"
```

Expected: exit code `0`; `branding_qc.json` has `"bad": []`.

- [ ] **Step 2: Verify production image dimensions**

Run:

```powershell
Add-Type -AssemblyName System.Drawing
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
foreach ($name in @('icon.png','splash-screen.png')) {
  $path = Join-Path $project $name
  $img = [System.Drawing.Image]::FromFile($path)
  [pscustomobject]@{Path=$name;Width=$img.Width;Height=$img.Height}
  $img.Dispose()
}
```

Expected:

```text
icon.png            256  256
splash-screen.png  2560 1440
```

- [ ] **Step 3: Run all Godot script tests**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
Get-ChildItem "$project\tests" -Filter 'test_*.gd' | Sort-Object Name | ForEach-Object {
  & $godot --headless --path $project --script $_.FullName
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
```

Expected: all tests exit `0`, including `test_branding_contract: PASS`.

- [ ] **Step 4: Run Godot import**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --headless --path $project --import
```

Expected: exit code `0`. Existing invalid UID and Godot 3.x material remap warnings may remain; record them as warnings if exit code is `0`.

- [ ] **Step 5: Run visible smoke screenshot capture**

Run:

```powershell
$godot = 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe'
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
& $godot --path $project --script "$project\tools\capture_candy_sky_screenshots.gd"
```

Expected: `capture_candy_sky_screenshots: PASS`.

- [ ] **Step 6: Run whitespace check**

Run:

```powershell
git diff --check
```

Expected: no output and exit code `0`.

- [ ] **Step 7: Update final docs**

In `docs/reskin_checklist.md`, set:

```markdown
- [x] Branding validation passed.
```

In `docs/reskin_state.md`, set:

```markdown
## Current Gate

Branding complete pending owner final review.
```

Add validation evidence:

```markdown
- Branding QA passed on 2026-07-07: `assets/themes/candy_sky_islands/branding/branding_qc.json`.
- Production icon verified at 256x256.
- Production splash verified at 2560x1440.
- Existing Godot tests passed after branding integration.
- Godot import exited `0` after branding integration.
- Visible smoke screenshot run passed after branding integration.
- `git diff --check` passed after branding integration.
```

In `docs/asset_manifest.md`, change app icon, splash, and logo statuses to:

```text
accepted, integrated, validation pass
```

- [ ] **Step 8: Commit validation docs**

Run:

```powershell
git add docs/reskin_checklist.md docs/reskin_state.md docs/asset_manifest.md assets/themes/candy_sky_islands/branding/branding_qc.json
git -c user.name='Codex' -c user.email='codex@local' commit -m 'docs: record candy branding validation'
```

Expected: commit succeeds.

## Task 7: Final Audit

**Files:**
- Read: `AGENTS.md`
- Read: `docs/reskin_state.md`
- Read: `docs/reskin_checklist.md`
- Read: `docs/asset_manifest.md`
- Read: `docs/superpowers/specs/2026-07-07-candy-sky-islands-branding-design.md`

- [ ] **Step 1: Re-read reset guard files**

Run:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
Get-Content -Raw "$project\AGENTS.md"
Get-Content -Raw "$project\docs\reskin_state.md"
Get-Content -Raw "$project\docs\reskin_checklist.md"
Get-Content -Raw "$project\docs\asset_manifest.md"
Get-Content -Raw "$project\docs\superpowers\specs\2026-07-07-candy-sky-islands-branding-design.md"
git -C $project status --short
```

Expected: state, checklist, and manifest agree on branding status and no unapproved branding asset is marked accepted.

- [ ] **Step 2: Confirm no gameplay behavior changed**

Run:

```powershell
git diff HEAD~5..HEAD -- scripts/player.gd scripts/camera.gd scripts/coin.gd objects/platform_falling.tscn objects/coin.tscn objects/player.tscn scenes/main.tscn
```

Expected: no gameplay logic changes. Scene changes are allowed only if they are branding or import metadata, but this plan should not need scene edits.

- [ ] **Step 3: Report final result**

Report:

```text
Current gate:
Completed branding assets:
Pending assets:
Validation commands run:
Screenshots/contact sheets:
Known warnings:
```

Expected: do not call publish/mobile complete. Branding complete means only icon, splash, and logo for the current Godot project.
