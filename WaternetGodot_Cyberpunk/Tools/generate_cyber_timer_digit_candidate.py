import hashlib
import importlib.util
import json
import os
import sys
import subprocess
import time
import urllib.error
import urllib.request
from pathlib import Path

from PIL import Image, ImageDraw

PROJECT = Path(__file__).resolve().parents[1]
MODEL_ID = "cx/gpt-5.5-image"
UPLOADER_PATH = Path(r"C:\Users\Admin\Desktop\Game\reskin_dashboard\upload_server.py")
PHOTOROOM_SCRIPT = Path(r"C:\Users\Admin\.gemini\config\skills\photoroom-cdp-background-removal\scripts\photoroom_cdp_fetch_segment.js")
OUT_DIR = PROJECT / "Assets" / "UI" / "cyberpunk_theme" / "generated" / "candidates" / "bottom_timer_digits"
MANIFEST_PATH = PROJECT / "docs" / "ui_cyber_bottom_timer_digit_candidates.json"
PUBLIC_PREFIX = "images/glyph-arrows-cyber-ui-candidates/bottom_timer_digits"


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def gateway() -> tuple[str, str, str]:
    base = (os.environ.get("NINEROUTER_IMAGE_URL") or "https://img.teelab247.com").rstrip("/")
    key = os.environ.get("NINEROUTER_IMAGE_KEY") or os.environ.get("NINEROUTER_KEY")
    key_source = "NINEROUTER_IMAGE_KEY" if os.environ.get("NINEROUTER_IMAGE_KEY") else "NINEROUTER_KEY"
    if not key:
        raise RuntimeError("No approved 9Router key found in NINEROUTER_IMAGE_KEY or NINEROUTER_KEY")
    return base, key, key_source


def request_json(url: str, key: str | None = None) -> dict:
    headers = {"Authorization": f"Bearer {key}"} if key else {}
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=30) as response:
        return json.loads(response.read().decode("utf-8"))


def verify_model(base: str, key: str) -> None:
    health = request_json(f"{base}/api/health")
    models = request_json(f"{base}/v1/models/image", key)
    ids = [item.get("id") for item in models.get("data", [])]
    if not health.get("ok"):
        raise RuntimeError("9Router health check failed")
    if MODEL_ID not in ids:
        raise RuntimeError(f"{MODEL_ID} missing. Stop; no fallback allowed.")


def uploader():
    spec = importlib.util.spec_from_file_location("old_upload_server", UPLOADER_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot import uploader: {UPLOADER_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def upload_file(module, path: Path, key: str) -> str:
    return module.upload_to_r2(path.read_bytes(), key, "image/png")


def load_component_refs() -> list[str]:
    manifest_path = PROJECT / "docs" / "ui_cyber_dark_light_component_refs_r2.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    wanted = {"dark": {"bottom_reserve", "full_demo", "top_tray", "board_region"}}
    refs: list[str] = []
    for item in manifest.get("items", []):
        mode = item.get("mode")
        component = item.get("component")
        if mode in wanted and component in wanted[mode]:
            url = item.get("url")
            if url:
                refs.append(url)
    return refs


def prompt(refs: list[str]) -> str:
    return "\n".join([
        "Create one isolated production game UI sprite sheet object, not poster art and not a full screen mockup.",
        "Asset: bottom tray 3D digital timer numerals for a cyber pipe puzzle game.",
        "Mode: dark cyber. Black and deep green material, cyan electric edge glow, glossy beveled sci-fi fake3D digits, premium mobile game readability.",
        "Required sprite sheet contents: exact glyphs 0 1 2 3 4 5 6 7 8 9 : .",
        "Arrange the glyphs in one straight horizontal row, evenly spaced, same baseline, same height, same style, no rotation, no perspective distortion between glyphs.",
        "Each glyph must be a standalone raised 3D number object with cyan inner glow and dark metallic side depth.",
        "The glyphs must be readable at small mobile size on a dark bottom tray.",
        "No words, no labels, no logo, no fake timer value, no extra UI panel, no pipes, no icons, no background scene.",
        "Output only the sprite sheet on a flat pure white #ffffff studio background for PhotoRoom cleanup.",
        "Leave enough space between glyphs so a script can slice them into equal cells.",
        "Reference image URLs for style synchronization:",
        "\n".join(refs),
    ])


def generate_raw(base: str, key: str, body_prompt: str, refs: list[str], out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    body = {
        "model": MODEL_ID,
        "prompt": body_prompt,
        "size": "1792x1024",
        "quality": "hd",
        "output_format": "png",
        "image_detail": "high",
        "images": refs,
    }
    payload = json.dumps(body).encode("utf-8")
    last_error = ""
    for attempt in range(3):
        req = urllib.request.Request(
            f"{base}/v1/images/generations?response_format=binary",
            data=payload,
            method="POST",
            headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(req, timeout=300) as response:
                out_path.write_bytes(response.read())
            return
        except urllib.error.HTTPError as exc:
            last_error = exc.read().decode("utf-8", errors="replace")
            if exc.code not in (408, 429, 500, 502, 503, 504):
                break
        except Exception as exc:
            last_error = str(exc)
        time.sleep(5 + attempt * 5)
    raise RuntimeError(last_error or "9Router image generation failed")


def run_photoroom(raw_path: Path, output_path: Path) -> int:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.setdefault("PHOTOROOM_TURNSTILE_TIMEOUT_MS", "60000")
    ports = [int(value) for value in os.environ.get("PHOTOROOM_PORTS", "9904,9223").split(",") if value.strip()]
    last_error = ""
    for port in ports:
        cmd = ["node", str(PHOTOROOM_SCRIPT), str(port), str(raw_path), str(output_path)]
        result = subprocess.run(cmd, cwd=str(PROJECT), env=env, text=True, capture_output=True, timeout=240)
        if result.returncode == 0 and output_path.exists() and output_path.stat().st_size > 0:
            return port
        last_error = (result.stderr or result.stdout)[-2400:]
    raise RuntimeError(f"PhotoRoom failed: {last_error}")


def trim_alpha(input_path: Path, output_path: Path, padding: int = 24) -> dict:
    image = Image.open(input_path).convert("RGBA")
    bbox = image.getbbox()
    if bbox is None:
        raise RuntimeError(f"Blank alpha: {input_path}")
    left = max(0, bbox[0] - padding)
    top = max(0, bbox[1] - padding)
    right = min(image.width, bbox[2] + padding)
    bottom = min(image.height, bbox[3] + padding)
    cropped = image.crop((left, top, right, bottom))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    cropped.save(output_path)
    return {
        "source_size": [image.width, image.height],
        "trim_rect": [left, top, right - left, bottom - top],
        "alpha_bbox_in_trimmed": [bbox[0] - left, bbox[1] - top, bbox[2] - left, bbox[3] - top],
        "trimmed_size": [cropped.width, cropped.height],
    }


def create_approval_preview(trimmed_path: Path, preview_path: Path) -> None:
    sheet = Image.open(trimmed_path).convert("RGBA")
    cell_w = 220
    cell_h = 220
    canvas = Image.new("RGBA", (cell_w * 3, cell_h + sheet.height + 80), (14, 18, 20, 255))
    draw = ImageDraw.Draw(canvas)
    backgrounds = [
        ((10, 16, 18, 255), "dark"),
        ((215, 236, 232, 255), "light"),
        ((34, 38, 44, 255), "checker"),
    ]
    scaled = sheet.resize((min(620, sheet.width), int(sheet.height * min(620, sheet.width) / sheet.width)), Image.Resampling.LANCZOS)
    for idx, (color, label) in enumerate(backgrounds):
        x = idx * cell_w
        panel = Image.new("RGBA", (cell_w, cell_h), color)
        if label == "checker":
            px = panel.load()
            for yy in range(cell_h):
                for xx in range(cell_w):
                    if ((xx // 18) + (yy // 18)) % 2 == 0:
                        px[xx, yy] = (58, 64, 72, 255)
        thumb = sheet.copy()
        thumb.thumbnail((cell_w - 28, cell_h - 50), Image.Resampling.LANCZOS)
        panel.alpha_composite(thumb, ((cell_w - thumb.width) // 2, 24 + (cell_h - 70 - thumb.height) // 2))
        canvas.alpha_composite(panel, (x, 0))
        draw.text((x + 12, cell_h - 28), label, fill=(180, 230, 220, 255))
    canvas.alpha_composite(scaled, ((canvas.width - scaled.width) // 2, cell_h + 34))
    preview_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(preview_path)


def _column_runs(image: Image.Image) -> list[tuple[int, int]]:
    alpha = image.getchannel("A")
    columns = []
    for x in range(image.width):
        hit = False
        for y in range(image.height):
            if alpha.getpixel((x, y)) > 16:
                hit = True
                break
        columns.append(hit)
    runs: list[tuple[int, int]] = []
    start = None
    gap = 0
    max_internal_gap = 5
    for x, hit in enumerate(columns):
        if hit:
            if start is None:
                start = x
            gap = 0
        elif start is not None:
            gap += 1
            if gap > max_internal_gap:
                runs.append((start, x - gap + 1))
                start = None
                gap = 0
    if start is not None:
        runs.append((start, image.width))
    return [(a, b) for a, b in runs if b - a > 3]


def _magenta_column_runs(image: Image.Image) -> list[tuple[int, int]]:
    rgb = image.convert("RGB")
    columns = []
    for x in range(rgb.width):
        hit = False
        for y in range(rgb.height):
            r, g, b = rgb.getpixel((x, y))
            is_magenta = r > 210 and g < 70 and b > 190
            if not is_magenta:
                hit = True
                break
        columns.append(hit)
    runs: list[tuple[int, int]] = []
    start = None
    gap = 0
    max_internal_gap = 5
    for x, hit in enumerate(columns):
        if hit:
            if start is None:
                start = x
            gap = 0
        elif start is not None:
            gap += 1
            if gap > max_internal_gap:
                runs.append((start, x - gap + 1))
                start = None
                gap = 0
    if start is not None:
        runs.append((start, image.width))
    return [(a, b) for a, b in runs if b - a > 10]


def _alpha_bbox(path: Path) -> tuple[int, int, int, int] | None:
    image = Image.open(path).convert("RGBA")
    return image.getbbox()


def _assert_clean_alpha(path: Path) -> None:
    image = Image.open(path).convert("RGBA")
    bbox = image.getbbox()
    if bbox is None:
        raise RuntimeError(f"Blank PhotoRoom glyph output: {path}")
    full_area = image.width * image.height
    bbox_area = (bbox[2] - bbox[0]) * (bbox[3] - bbox[1])
    if bbox_area > full_area * 0.92:
        raise RuntimeError(f"PhotoRoom did not remove background for {path}: bbox={bbox} size={image.size}")


def create_photoroom_glyph_atlas_from_raw(raw_path: Path, atlas_path: Path, glyph_preview_path: Path) -> dict:
    glyphs = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", "."]
    raw = Image.open(raw_path).convert("RGBA")
    runs = _magenta_column_runs(raw)
    if len(runs) != len(glyphs):
        raise RuntimeError(f"Expected {len(glyphs)} raw glyph column runs, got {len(runs)}: {runs}")
    raw_glyph_dir = OUT_DIR / "raw_glyphs"
    clean_glyph_dir = OUT_DIR / "photoroom_glyphs"
    raw_glyph_dir.mkdir(parents=True, exist_ok=True)
    clean_glyph_dir.mkdir(parents=True, exist_ok=True)
    clean_crops = []
    for glyph, (left, right) in zip(glyphs, runs):
        top = raw.height
        bottom = 0
        rgb = raw.convert("RGB")
        for y in range(raw.height):
            for x in range(left, right):
                r, g, b = rgb.getpixel((x, y))
                if not (r > 210 and g < 70 and b > 190):
                    top = min(top, y)
                    bottom = max(bottom, y + 1)
        pad = 64
        crop_box = (
            max(0, left - pad),
            max(0, top - pad),
            min(raw.width, right + pad),
            min(raw.height, bottom + pad),
        )
        raw_glyph_path = raw_glyph_dir / f"glyph_{glyph.replace(':', 'colon').replace('.', 'dot')}_raw.png"
        clean_glyph_path = clean_glyph_dir / f"glyph_{glyph.replace(':', 'colon').replace('.', 'dot')}_photoroom.png"
        raw.crop(crop_box).save(raw_glyph_path)
        run_photoroom(raw_glyph_path, clean_glyph_path)
        _assert_clean_alpha(clean_glyph_path)
        clean = Image.open(clean_glyph_path).convert("RGBA")
        bbox = clean.getbbox()
        if bbox is None:
            raise RuntimeError(f"Blank glyph after PhotoRoom: {glyph}")
        clean_crops.append((glyph, crop_box, bbox, clean.crop(bbox)))

    cell_w = max(crop.width for _, _, _, crop in clean_crops) + 22
    cell_h = max(crop.height for _, _, _, crop in clean_crops) + 22
    atlas = Image.new("RGBA", (cell_w * len(glyphs), cell_h), (0, 0, 0, 0))
    frames = {}
    for index, (glyph, source_crop, clean_bbox, crop) in enumerate(clean_crops):
        x = index * cell_w + (cell_w - crop.width) // 2
        y = (cell_h - crop.height) // 2
        atlas.alpha_composite(crop, (x, y))
        frames[glyph] = {
            "cell": [index * cell_w, 0, cell_w, cell_h],
            "source_crop": list(source_crop),
            "photoroom_bbox": list(clean_bbox),
            "draw_offset": [x - index * cell_w, y],
            "draw_size": [crop.width, crop.height],
        }
    atlas_path.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(atlas_path)
    _write_glyph_grid_preview(clean_crops, glyph_preview_path)
    return {
        "glyphs": glyphs,
        "cell_size": [cell_w, cell_h],
        "frames": frames,
        "atlas_size": [atlas.width, atlas.height],
        "source": "per_glyph_photoroom_cutouts",
    }


def _write_glyph_grid_preview(crops: list[tuple], glyph_preview_path: Path) -> None:
    cols = 6
    preview_cell = 170
    preview = Image.new("RGBA", (cols * preview_cell, 2 * preview_cell), (12, 17, 19, 255))
    draw = ImageDraw.Draw(preview)
    for index, item in enumerate(crops):
        glyph = item[0]
        crop = item[-1]
        x0 = (index % cols) * preview_cell
        y0 = (index // cols) * preview_cell
        for yy in range(0, preview_cell, 18):
            for xx in range(0, preview_cell, 18):
                color = (35, 40, 47, 255) if ((xx // 18 + yy // 18) % 2 == 0) else (22, 27, 32, 255)
                draw.rectangle([x0 + xx, y0 + yy, x0 + xx + 17, y0 + yy + 17], fill=color)
        thumb = crop.copy()
        thumb.thumbnail((preview_cell - 38, preview_cell - 52), Image.Resampling.LANCZOS)
        preview.alpha_composite(thumb, (x0 + (preview_cell - thumb.width) // 2, y0 + 22 + (preview_cell - 62 - thumb.height) // 2))
        draw.text((x0 + 10, y0 + preview_cell - 28), glyph, fill=(180, 236, 230, 255))
    glyph_preview_path.parent.mkdir(parents=True, exist_ok=True)
    preview.save(glyph_preview_path)


def create_glyph_atlas(trimmed_path: Path, atlas_path: Path, glyph_preview_path: Path) -> dict:
    glyphs = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", "."]
    image = Image.open(trimmed_path).convert("RGBA")
    runs = _column_runs(image)
    if len(runs) != len(glyphs):
        raise RuntimeError(f"Expected {len(glyphs)} glyph column runs, got {len(runs)}: {runs}")
    alpha = image.getchannel("A")
    crops = []
    for glyph, (left, right) in zip(glyphs, runs):
        top = image.height
        bottom = 0
        for y in range(image.height):
            for x in range(left, right):
                if alpha.getpixel((x, y)) > 16:
                    top = min(top, y)
                    bottom = max(bottom, y + 1)
        pad = 10
        crop_box = (
            max(0, left - pad),
            max(0, top - pad),
            min(image.width, right + pad),
            min(image.height, bottom + pad),
        )
        crops.append((glyph, crop_box, image.crop(crop_box)))

    cell_w = max(crop.width for _, _, crop in crops)
    cell_h = max(crop.height for _, _, crop in crops)
    cell_w = max(96, cell_w + 18)
    cell_h = max(128, cell_h + 18)
    atlas = Image.new("RGBA", (cell_w * len(glyphs), cell_h), (0, 0, 0, 0))
    frames = {}
    for index, (glyph, crop_box, crop) in enumerate(crops):
        x = index * cell_w + (cell_w - crop.width) // 2
        y = (cell_h - crop.height) // 2
        atlas.alpha_composite(crop, (x, y))
        frames[glyph] = {
            "cell": [index * cell_w, 0, cell_w, cell_h],
            "source_crop": list(crop_box),
            "draw_offset": [x - index * cell_w, y],
            "draw_size": [crop.width, crop.height],
        }
    atlas_path.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(atlas_path)

    _write_glyph_grid_preview(crops, glyph_preview_path)
    return {
        "glyphs": glyphs,
        "cell_size": [cell_w, cell_h],
        "frames": frames,
        "atlas_size": [atlas.width, atlas.height],
    }


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    trimmed_path = OUT_DIR / "bottom_timer_digits_dark_photoroom_trimmed.png"
    atlas_path = OUT_DIR / "bottom_timer_digits_dark_atlas_equal_cells.png"
    glyph_preview_path = PROJECT / "debug" / "bottom_timer_digits_dark_glyph_grid_preview.png"
    if "--slice-only" in sys.argv:
        raw_path = OUT_DIR / "bottom_timer_digits_dark_raw.png"
        atlas_data = create_photoroom_glyph_atlas_from_raw(raw_path, atlas_path, glyph_preview_path)
        upload_mod = uploader()
        atlas_r2 = upload_file(upload_mod, atlas_path, f"{PUBLIC_PREFIX}/bottom_timer_digits_dark_atlas_equal_cells.png")
        glyph_preview_r2 = upload_file(upload_mod, glyph_preview_path, f"{PUBLIC_PREFIX}/bottom_timer_digits_dark_glyph_grid_preview.png")
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8")) if MANIFEST_PATH.exists() else {}
        manifest["atlas_path"] = str(atlas_path)
        manifest["glyph_preview_path"] = str(glyph_preview_path)
        manifest["atlas_r2_url"] = atlas_r2
        manifest["glyph_preview_r2_url"] = glyph_preview_r2
        manifest["atlas"] = atlas_data
        manifest.setdefault("sha256", {})
        manifest["sha256"]["atlas"] = sha256(atlas_path)
        manifest["sha256"]["glyph_preview"] = sha256(glyph_preview_path)
        MANIFEST_PATH.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(json.dumps({
            "atlas": str(atlas_path),
            "glyph_preview": str(glyph_preview_path),
            "atlas_r2_url": atlas_r2,
            "glyph_preview_r2_url": glyph_preview_r2,
            "atlas_data": atlas_data,
        }, indent=2, ensure_ascii=False))
        return 0
    base, key, key_source = gateway()
    verify_model(base, key)
    refs = load_component_refs()
    raw_path = OUT_DIR / "bottom_timer_digits_dark_raw.png"
    photoroom_path = OUT_DIR / "bottom_timer_digits_dark_photoroom_untrimmed.png"
    preview_path = PROJECT / "debug" / "bottom_timer_digits_dark_approval_preview.png"
    atlas_path = OUT_DIR / "bottom_timer_digits_dark_atlas_equal_cells.png"
    glyph_preview_path = PROJECT / "debug" / "bottom_timer_digits_dark_glyph_grid_preview.png"
    body_prompt = prompt(refs)
    generate_raw(base, key, body_prompt, refs, raw_path)
    photoroom_port = run_photoroom(raw_path, photoroom_path)
    trim_data = trim_alpha(photoroom_path, trimmed_path)
    create_approval_preview(trimmed_path, preview_path)
    atlas_data = create_glyph_atlas(trimmed_path, atlas_path, glyph_preview_path)

    upload_mod = uploader()
    raw_r2 = upload_file(upload_mod, raw_path, f"{PUBLIC_PREFIX}/bottom_timer_digits_dark_raw.png")
    final_r2 = upload_file(upload_mod, trimmed_path, f"{PUBLIC_PREFIX}/bottom_timer_digits_dark_photoroom_trimmed.png")
    preview_r2 = upload_file(upload_mod, preview_path, f"{PUBLIC_PREFIX}/bottom_timer_digits_dark_approval_preview.png")
    atlas_r2 = upload_file(upload_mod, atlas_path, f"{PUBLIC_PREFIX}/bottom_timer_digits_dark_atlas_equal_cells.png")
    glyph_preview_r2 = upload_file(upload_mod, glyph_preview_path, f"{PUBLIC_PREFIX}/bottom_timer_digits_dark_glyph_grid_preview.png")
    manifest = {
        "purpose": "Owner-review candidate for cyber bottom tray 3D timer digit sprite sheet.",
        "status": "pending_owner_visual_approval",
        "pipeline": "9Router design -> PhotoRoom cutout -> alpha trim -> owner sprite approval -> SSOT/runtime integration",
        "model": MODEL_ID,
        "key_source": key_source,
        "mode": "dark",
        "glyphs_requested": ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", "."],
        "reference_urls": refs,
        "raw_path": str(raw_path),
        "photoroom_untrimmed_path": str(photoroom_path),
        "trimmed_path": str(trimmed_path),
        "atlas_path": str(atlas_path),
        "approval_preview_path": str(preview_path),
        "glyph_preview_path": str(glyph_preview_path),
        "raw_r2_url": raw_r2,
        "trimmed_r2_url": final_r2,
        "approval_preview_r2_url": preview_r2,
        "atlas_r2_url": atlas_r2,
        "glyph_preview_r2_url": glyph_preview_r2,
        "trim": trim_data,
        "atlas": atlas_data,
        "photoroom_port": photoroom_port,
        "sha256": {
            "raw": sha256(raw_path),
            "trimmed": sha256(trimmed_path),
            "atlas": sha256(atlas_path),
            "preview": sha256(preview_path),
            "glyph_preview": sha256(glyph_preview_path),
        },
        "notes": [
            "Preview only; do not wire into Godot before owner approves the glyph design.",
            "If approved, next pass must create canonical equal-cell atlas or per-glyph cutouts and store slice geometry in ThemeConfig SSOT.",
        ],
    }
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({
        "raw": str(raw_path),
        "trimmed": str(trimmed_path),
        "atlas": str(atlas_path),
        "preview": str(preview_path),
        "glyph_preview": str(glyph_preview_path),
        "manifest": str(MANIFEST_PATH),
        "photoroom_port": photoroom_port,
        "preview_r2_url": preview_r2,
        "glyph_preview_r2_url": glyph_preview_r2,
    }, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
