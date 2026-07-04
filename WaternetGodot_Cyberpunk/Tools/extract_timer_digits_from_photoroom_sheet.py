import json
from pathlib import Path

from PIL import Image, ImageDraw

PROJECT = Path(__file__).resolve().parents[1]
SHEET_PATH = PROJECT / "Assets" / "UI" / "cyberpunk_theme" / "generated" / "candidates" / "bottom_timer_digits" / "bottom_timer_digits_dark_photoroom_untrimmed.png"
OUT_DIR = PROJECT / "Assets" / "UI" / "cyberpunk_theme" / "generated" / "candidates" / "bottom_timer_digits" / "objects_from_sheet"
PREVIEW_PATH = PROJECT / "debug" / "bottom_timer_digits_dark_objects_from_sheet_preview.png"
MANIFEST_PATH = PROJECT / "docs" / "ui_cyber_bottom_timer_digit_candidates.json"
GLYPHS = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", "."]


def alpha_column_runs(image: Image.Image, threshold: int = 8, max_gap: int = 8) -> list[tuple[int, int]]:
    alpha = image.getchannel("A")
    columns = []
    for x in range(image.width):
        hit = False
        for y in range(image.height):
            if alpha.getpixel((x, y)) > threshold:
                hit = True
                break
        columns.append(hit)
    runs = []
    start = None
    gap = 0
    for x, hit in enumerate(columns):
        if hit:
            if start is None:
                start = x
            gap = 0
        elif start is not None:
            gap += 1
            if gap > max_gap:
                runs.append((start, x - gap + 1))
                start = None
                gap = 0
    if start is not None:
        runs.append((start, image.width))
    return [(left, right) for left, right in runs if right - left >= 18]


def object_bbox_for_run(image: Image.Image, left: int, right: int, threshold: int = 8, padding: int = 18) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    top = image.height
    bottom = 0
    for y in range(image.height):
        for x in range(left, right):
            if alpha.getpixel((x, y)) > threshold:
                top = min(top, y)
                bottom = max(bottom, y + 1)
    if bottom <= top:
        raise RuntimeError(f"Empty object run: {(left, right)}")
    return (
        max(0, left - padding),
        max(0, top - padding),
        min(image.width, right + padding),
        min(image.height, bottom + padding),
    )


def clone_mask_trim(image: Image.Image, bbox: tuple[int, int, int, int], output_path: Path) -> dict:
    clone = image.copy()
    alpha = clone.getchannel("A")
    mask = Image.new("L", clone.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rectangle([bbox[0], bbox[1], bbox[2] - 1, bbox[3] - 1], fill=255)
    kept_alpha = Image.composite(alpha, Image.new("L", clone.size, 0), mask)
    clone.putalpha(kept_alpha)
    actual = clone.getbbox()
    if actual is None:
        raise RuntimeError(f"Masked clone is blank: {output_path}")
    trimmed = clone.crop(actual)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    trimmed.save(output_path)
    return {
        "mask_rect": [bbox[0], bbox[1], bbox[2] - bbox[0], bbox[3] - bbox[1]],
        "trim_rect": [actual[0], actual[1], actual[2] - actual[0], actual[3] - actual[1]],
        "size": [trimmed.width, trimmed.height],
        "path": str(output_path),
    }


def write_preview(objects: list[dict]) -> None:
    cols = 6
    cell_w = 210
    cell_h = 210
    preview = Image.new("RGBA", (cols * cell_w, 2 * cell_h), (14, 18, 20, 255))
    draw = ImageDraw.Draw(preview)
    for index, item in enumerate(objects):
        x0 = (index % cols) * cell_w
        y0 = (index // cols) * cell_h
        for yy in range(0, cell_h, 18):
            for xx in range(0, cell_w, 18):
                color = (42, 48, 56, 255) if ((xx // 18 + yy // 18) % 2 == 0) else (20, 25, 30, 255)
                draw.rectangle([x0 + xx, y0 + yy, x0 + xx + 17, y0 + yy + 17], fill=color)
        glyph_img = Image.open(item["path"]).convert("RGBA")
        thumb = glyph_img.copy()
        thumb.thumbnail((cell_w - 34, cell_h - 54), Image.Resampling.LANCZOS)
        preview.alpha_composite(thumb, (x0 + (cell_w - thumb.width) // 2, y0 + 22 + (cell_h - 64 - thumb.height) // 2))
        draw.text((x0 + 10, y0 + cell_h - 30), item["glyph"], fill=(185, 238, 232, 255))
    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    preview.save(PREVIEW_PATH)


def main() -> int:
    image = Image.open(SHEET_PATH).convert("RGBA")
    runs = alpha_column_runs(image)
    if len(runs) != len(GLYPHS):
        raise RuntimeError(f"Expected {len(GLYPHS)} glyph runs, got {len(runs)}: {runs}")
    objects = []
    for glyph, (left, right) in zip(GLYPHS, runs):
        safe = glyph.replace(":", "colon").replace(".", "dot")
        bbox = object_bbox_for_run(image, left, right)
        item = clone_mask_trim(image, bbox, OUT_DIR / f"timer_digit_{safe}.png")
        item["glyph"] = glyph
        item["column_run"] = [left, right]
        objects.append(item)
    write_preview(objects)
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8")) if MANIFEST_PATH.exists() else {}
    manifest["object_extraction"] = {
        "status": "pending_owner_visual_approval",
        "source_sheet": str(SHEET_PATH),
        "method": "clone_photoroom_sheet_per_glyph_mask_other_objects_then_trim",
        "grid_slicing": "forbidden",
        "preview_path": str(PREVIEW_PATH),
        "glyphs": objects,
    }
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({
        "source_sheet": str(SHEET_PATH),
        "preview": str(PREVIEW_PATH),
        "count": len(objects),
        "objects": objects,
    }, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
