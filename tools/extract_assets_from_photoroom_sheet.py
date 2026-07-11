#!/usr/bin/env python3
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw


PROJECT = Path(__file__).resolve().parents[1]
THEME_DIR = PROJECT / "assets" / "themes" / "candy_sky_islands"
SOURCE_DIR = THEME_DIR / "source"
ALPHA_SHEET = SOURCE_DIR / "asset_family_concept_sheet_photoroom.png"
OUTLINES = SOURCE_DIR / "asset_family_outline_regions_candidate.json"
WORK_DIR = SOURCE_DIR / "approved_outline_extraction"
QC_PATH = THEME_DIR / "asset_family_extraction_qc.json"
MANIFEST_PATH = SOURCE_DIR / "asset_family_approved_outline_regions.json"


def px_rect(rect, width, height):
    x = max(0, round(rect["x"] * width))
    y = max(0, round(rect["y"] * height))
    w = max(1, round(rect["w"] * width))
    h = max(1, round(rect["h"] * height))
    return x, y, min(width, x + w), min(height, y + h)


def px_points(points, width, height):
    return [
        (
            max(0, min(width, round(point[0] * width))),
            max(0, min(height, round(point[1] * height))),
        )
        for point in points
    ]


def edge_alpha_ratio(image):
    alpha = image.getchannel("A")
    width, height = alpha.size
    if width == 0 or height == 0:
        return {"left": 0, "right": 0, "top": 0, "bottom": 0}
    left = sum(1 for y in range(height) if alpha.getpixel((0, y)) > 0) / height
    right = sum(1 for y in range(height) if alpha.getpixel((width - 1, y)) > 0) / height
    top = sum(1 for x in range(width) if alpha.getpixel((x, 0)) > 0) / width
    bottom = sum(1 for x in range(width) if alpha.getpixel((x, height - 1)) > 0) / width
    return {"left": left, "right": right, "top": top, "bottom": bottom}


def trim_alpha(image, padding=8):
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if not bbox:
        return image, None
    left = max(0, bbox[0] - padding)
    top = max(0, bbox[1] - padding)
    right = min(image.size[0], bbox[2] + padding)
    bottom = min(image.size[1], bbox[3] + padding)
    return image.crop((left, top, right, bottom)), [left, top, right, bottom]


def main():
    data = json.loads(OUTLINES.read_text(encoding="utf-8"))
    sheet = Image.open(ALPHA_SHEET).convert("RGBA")
    width, height = sheet.size
    if data["sheet_size"] != [width, height]:
        raise SystemExit(f"Outline sheet_size {data['sheet_size']} != alpha sheet {sheet.size}")

    WORK_DIR.mkdir(parents=True, exist_ok=True)
    qc = {
        "pipeline": [
            "Photoroom full sheet via CDP 9223",
            "Clone/crop each object from alpha sheet",
            "Apply owner polygon mask",
            "Trim by alpha with padding",
            "QA alpha and edge ratios",
        ],
        "alpha_sheet": str(ALPHA_SHEET.relative_to(PROJECT)).replace("\\", "/"),
        "outline_source": str(OUTLINES.relative_to(PROJECT)).replace("\\", "/"),
        "assets": {},
    }
    approved_manifest = {
        "sheet": str(ALPHA_SHEET.relative_to(PROJECT)).replace("\\", "/"),
        "sheet_size": [width, height],
        "assets": {},
    }

    for key, item in data["assets"].items():
        outline = item.get("outline") or []
        rect = item.get("computed_rect")
        if len(outline) < 3 or not rect:
            raise SystemExit(f"{key}: outline and computed_rect required")

        left, top, right, bottom = px_rect(rect, width, height)

        # Clone step: every asset starts from the Photoroom alpha sheet, then crops its own rect.
        clone_region = sheet.crop((left, top, right, bottom))
        clone_path = WORK_DIR / f"{key}_clone_from_photoroom_sheet.png"
        clone_region.save(clone_path)

        full_mask = Image.new("L", (width, height), 0)
        draw = ImageDraw.Draw(full_mask)
        draw.polygon(px_points(outline, width, height), fill=255)
        mask_region = full_mask.crop((left, top, right, bottom))
        mask_path = WORK_DIR / f"{key}_owner_polygon_mask.png"
        mask_region.save(mask_path)

        masked = clone_region.copy()
        alpha = ImageChops.multiply(masked.getchannel("A"), mask_region)
        masked.putalpha(alpha)
        masked_path = WORK_DIR / f"{key}_masked_before_trim.png"
        masked.save(masked_path)

        trimmed, trim_bbox = trim_alpha(masked)
        output_path = THEME_DIR / f"{key}.png"
        trimmed.save(output_path)

        alpha_extrema = trimmed.getchannel("A").getextrema()
        edge_ratio = edge_alpha_ratio(trimmed)
        risky_edges = {edge: ratio for edge, ratio in edge_ratio.items() if ratio > 0.02}
        alpha_ok = alpha_extrema == (0, 255)
        qc["assets"][key] = {
            "source_alpha_sheet": str(ALPHA_SHEET.relative_to(PROJECT)).replace("\\", "/"),
            "clone_region": str(clone_path.relative_to(PROJECT)).replace("\\", "/"),
            "polygon_mask": str(mask_path.relative_to(PROJECT)).replace("\\", "/"),
            "masked_before_trim": str(masked_path.relative_to(PROJECT)).replace("\\", "/"),
            "output": str(output_path.relative_to(PROJECT)).replace("\\", "/"),
            "owner_outline_points": len(outline),
            "computed_rect_norm": rect,
            "computed_rect_px": [left, top, right - left, bottom - top],
            "trim_bbox_in_clone": trim_bbox,
            "output_size": list(trimmed.size),
            "mode": trimmed.mode,
            "alpha_extrema": list(alpha_extrema),
            "alpha_ok": alpha_ok,
            "edge_alpha_ratio": edge_ratio,
            "risky_edges": risky_edges,
            "edge_ok": not risky_edges,
        }
        approved_manifest["assets"][key] = {
            "outline": outline,
            "computed_rect": rect,
            "computed_rect_px": [left, top, right - left, bottom - top],
            "output": str(output_path.relative_to(PROJECT)).replace("\\", "/"),
        }

    QC_PATH.write_text(json.dumps(qc, indent=2), encoding="utf-8")
    MANIFEST_PATH.write_text(json.dumps(approved_manifest, indent=2), encoding="utf-8")
    print(json.dumps({"assets": len(qc["assets"]), "qc": str(QC_PATH), "manifest": str(MANIFEST_PATH)}, indent=2))


if __name__ == "__main__":
    main()
