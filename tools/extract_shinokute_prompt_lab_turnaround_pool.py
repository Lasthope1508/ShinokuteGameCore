from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROLES = [
    "front",
    "front_right_3q",
    "right_side",
    "back_right_3q",
    "back",
    "back_left_3q",
    "left_side",
    "front_left_3q",
]


def edge_ratio(image: Image.Image, threshold: int = 24) -> float:
    alpha = image.getchannel("A")
    pixels = alpha.load()
    width, height = image.size
    fg = 0
    edge = 0
    for y in range(height):
        for x in range(width):
            if pixels[x, y] > threshold:
                fg += 1
                if x == 0 or y == 0 or x == width - 1 or y == height - 1:
                    edge += 1
    return edge / max(1, fg)


def find_components(image: Image.Image, threshold: int) -> list[dict]:
    width, height = image.size
    alpha = image.getchannel("A")
    pixels = alpha.load()
    seen = bytearray(width * height)
    comps: list[dict] = []
    for y in range(height):
        for x in range(width):
            idx = y * width + x
            if seen[idx] or pixels[x, y] <= threshold:
                continue
            stack = [(x, y)]
            seen[idx] = 1
            min_x = max_x = x
            min_y = max_y = y
            area = 0
            by_y: dict[int, list[int]] = {}
            while stack:
                cx, cy = stack.pop()
                area += 1
                min_x = min(min_x, cx)
                max_x = max(max_x, cx)
                min_y = min(min_y, cy)
                max_y = max(max_y, cy)
                by_y.setdefault(cy, []).append(cx)
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < width and 0 <= ny < height:
                        nidx = ny * width + nx
                        if not seen[nidx] and pixels[nx, ny] > threshold:
                            seen[nidx] = 1
                            stack.append((nx, ny))
            box_w = max_x - min_x + 1
            box_h = max_y - min_y + 1
            if area > 2000 and box_h > height * 0.20 and box_w > 35:
                comps.append(
                    {
                        "bbox": (min_x, min_y, max_x + 1, max_y + 1),
                        "area": area,
                        "by_y": by_y,
                    }
                )
    comps.sort(key=lambda c: ((c["bbox"][1] + c["bbox"][3]) * 0.5, c["bbox"][0]))
    if len(comps) >= 8:
        top = sorted(comps[:4], key=lambda c: c["bbox"][0])
        bottom = sorted(comps[4:8], key=lambda c: c["bbox"][0])
        comps = top + bottom + comps[8:]
    return comps


def outline_for_component(comp: dict, size: tuple[int, int]) -> list[list[float]]:
    min_x, min_y, max_x, max_y = comp["bbox"]
    width, height = size
    left: list[list[float]] = []
    right: list[list[float]] = []
    by_y = comp["by_y"]
    for t in [i / 20 for i in range(21)]:
        y = int(min_y + (max_y - min_y) * t)
        xs: list[int] = []
        for yy in range(max(min_y, y - 2), min(max_y, y + 3)):
            xs.extend(by_y.get(yy, []))
        if xs:
            left.append([min(xs) / width, y / height])
            right.append([max(xs) / width, y / height])
    outline = left + list(reversed(right))
    if len(outline) < 3:
        outline = [
            [min_x / width, min_y / height],
            [max_x / width, min_y / height],
            [max_x / width, max_y / height],
            [min_x / width, max_y / height],
        ]
    return outline


def masked_component_crop(image: Image.Image, comp: dict, crop_box: tuple[int, int, int, int]) -> Image.Image:
    x0, y0, x1, y1 = crop_box
    crop = image.crop(crop_box).convert("RGBA")
    mask = Image.new("L", crop.size, 0)
    pixels = mask.load()
    for yy, xs in comp["by_y"].items():
        cy = yy - y0
        if cy < 0 or cy >= crop.height:
            continue
        for xx in xs:
            cx = xx - x0
            if 0 <= cx < crop.width:
                pixels[cx, cy] = 255
    mask = mask.filter(ImageFilter.MaxFilter(5))
    alpha = crop.getchannel("A")
    crop.putalpha(Image.composite(alpha, Image.new("L", crop.size, 0), mask))
    return crop


def make_contact(items: list[dict], output: Path) -> None:
    thumbs = []
    for item in items:
        img = Image.open(item["path"]).convert("RGBA")
        img.thumbnail((220, 320), Image.Resampling.LANCZOS)
        thumbs.append((item["role"], img))
    sheet = Image.new("RGB", (220 * 4, 360 * 2), "white")
    draw = ImageDraw.Draw(sheet)
    for i, (role, img) in enumerate(thumbs):
        x = (i % 4) * 220 + (220 - img.width) // 2
        y = (i // 4) * 360 + 28 + (320 - img.height) // 2
        draw.text(((i % 4) * 220 + 8, (i // 4) * 360 + 8), role, fill=(0, 0, 0))
        sheet.paste(img.convert("RGB"), (x, y), img)
    sheet.save(output)


def main() -> int:
    if len(sys.argv) != 9:
        print(
            "usage: extract_shinokute_prompt_lab_turnaround_pool.py "
            "<alpha_sheet> <raw_sheet> <out_dir> <prefix> <manifest_json> <qc_json> "
            "<contact_sheet> <threshold>"
        )
        return 2
    alpha_path = Path(sys.argv[1])
    raw_path = Path(sys.argv[2])
    out_dir = Path(sys.argv[3])
    prefix = sys.argv[4]
    manifest_path = Path(sys.argv[5])
    qc_path = Path(sys.argv[6])
    contact_path = Path(sys.argv[7])
    threshold = int(sys.argv[8])
    out_dir.mkdir(parents=True, exist_ok=True)
    contact_path.parent.mkdir(parents=True, exist_ok=True)

    image = Image.open(alpha_path).convert("RGBA")
    width, height = image.size
    comps = find_components(image, threshold)
    assets = {}
    qc_items = []
    pad = 18
    for index, comp in enumerate(comps[:8]):
        role = ROLES[index]
        min_x, min_y, max_x, max_y = comp["bbox"]
        x0, y0 = max(0, min_x - pad), max(0, min_y - pad)
        x1, y1 = min(width, max_x + pad), min(height, max_y + pad)
        crop = masked_component_crop(image, comp, (x0, y0, x1, y1))
        output = out_dir / f"{prefix}_{role}.png"
        crop.save(output)
        extrema = crop.getchannel("A").getextrema()
        edge = edge_ratio(crop)
        item = {
            "role": role,
            "path": str(output),
            "size": list(crop.size),
            "alpha_extrema": list(extrema),
            "edge_foreground_ratio": edge,
            "component_area": comp["area"],
            "pass": extrema == (0, 255) and edge < 0.01,
        }
        qc_items.append(item)
        assets[role] = {
            "source_alpha_sheet": str(alpha_path),
            "source_raw_sheet": str(raw_path),
            "output": str(output),
            "outline": outline_for_component(comp, (width, height)),
            "computed_rect": {
                "x": min_x / width,
                "y": min_y / height,
                "w": (max_x - min_x) / width,
                "h": (max_y - min_y) / height,
            },
            "crop_rect_px": [x0, y0, x1 - x0, y1 - y0],
            "method": "Photoroom full sheet first; high-alpha connected component polygon mask; no grid slicing; no raw crop.",
        }
    manifest = {
        "sheet": str(raw_path),
        "alpha_sheet": str(alpha_path),
        "sheet_size": [width, height],
        "threshold": threshold,
        "method": "Photoroom full sheet first; high-alpha connected components converted to polygon outline records; no grid slicing; no raw crop.",
        "assets": assets,
    }
    qc = {
        "components_detected": len(comps),
        "outputs": len(assets),
        "bad": [i for i in qc_items if not i["pass"]],
        "items": qc_items,
    }
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    qc_path.write_text(json.dumps(qc, indent=2), encoding="utf-8")
    make_contact(qc_items, contact_path)
    print(
        json.dumps(
            {
                "components_detected": len(comps),
                "outputs": len(assets),
                "bad": [i["role"] for i in qc_items if not i["pass"]],
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
