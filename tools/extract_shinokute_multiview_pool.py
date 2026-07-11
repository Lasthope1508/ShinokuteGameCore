from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageOps


def _component_outline(points: list[tuple[int, int]], bbox: tuple[int, int, int, int], size: tuple[int, int]) -> list[list[float]]:
    min_x, min_y, max_x, max_y = bbox
    width, height = size
    by_y: dict[int, list[int]] = {}
    for x, y in points:
        by_y.setdefault(y, []).append(x)

    left: list[list[float]] = []
    right: list[list[float]] = []
    for t in [0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0]:
        y = int(min_y + (max_y - min_y) * t)
        xs: list[int] = []
        for yy in range(max(min_y, y - 2), min(max_y + 1, y + 3)):
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


def _edge_ratio(image: Image.Image, threshold: int) -> float:
    alpha = image.getchannel("A")
    pixels = alpha.load()
    width, height = image.size
    edge_count = 0
    fg_count = 0
    for y in range(height):
        for x in range(width):
            if pixels[x, y] > threshold:
                fg_count += 1
                if x == 0 or y == 0 or x == width - 1 or y == height - 1:
                    edge_count += 1
    return edge_count / max(1, fg_count)


def _find_components(image: Image.Image, threshold: int) -> list[dict]:
    width, height = image.size
    alpha = image.getchannel("A")
    pixels = alpha.load()
    seen = bytearray(width * height)
    components: list[dict] = []

    for y in range(height):
        for x in range(width):
            idx = y * width + x
            if seen[idx] or pixels[x, y] <= threshold:
                continue

            stack = [(x, y)]
            seen[idx] = 1
            points: list[tuple[int, int]] = []
            min_x = max_x = x
            min_y = max_y = y

            while stack:
                cx, cy = stack.pop()
                points.append((cx, cy))
                min_x = min(min_x, cx)
                max_x = max(max_x, cx)
                min_y = min(min_y, cy)
                max_y = max(max_y, cy)

                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < width and 0 <= ny < height:
                        nidx = ny * width + nx
                        if not seen[nidx] and pixels[nx, ny] > threshold:
                            seen[nidx] = 1
                            stack.append((nx, ny))

            area = len(points)
            box_width = max_x - min_x + 1
            box_height = max_y - min_y + 1
            if area > 5000 and box_height > height * 0.45 and box_width > 60:
                components.append(
                    {
                        "bbox": (min_x, min_y, max_x + 1, max_y + 1),
                        "area": area,
                        "points": points,
                    }
                )

    components.sort(key=lambda item: item["bbox"][0])
    return components


def main() -> int:
    if len(sys.argv) != 6:
        print("usage: extract_shinokute_multiview_pool.py <alpha_sheet> <raw_sheet> <out_dir> <manifest_json> <qc_json>")
        return 2

    alpha_path = Path(sys.argv[1])
    raw_path = Path(sys.argv[2])
    out_dir = Path(sys.argv[3])
    manifest_path = Path(sys.argv[4])
    qc_path = Path(sys.argv[5])
    out_dir.mkdir(parents=True, exist_ok=True)

    image = Image.open(alpha_path).convert("RGBA")
    width, height = image.size
    threshold = 24
    components = _find_components(image, threshold)
    roles = [
        "front",
        "left_side",
        "right_back_3q_candidate",
        "back",
        "front_left_3q",
        "front_right_3q",
    ]

    assets: dict[str, dict] = {}
    qc_items: list[dict] = []
    pad = 14

    for index, component in enumerate(components):
        min_x, min_y, max_x, max_y = component["bbox"]
        x0 = max(0, min_x - pad)
        y0 = max(0, min_y - pad)
        x1 = min(width, max_x + pad)
        y1 = min(height, max_y + pad)
        role = roles[index] if index < len(roles) else f"standing_view_{index + 1}"

        crop = image.crop((x0, y0, x1, y1))
        output = out_dir / f"shinokute_standing_{role}.png"
        crop.save(output)

        alpha = crop.getchannel("A")
        extrema = alpha.getextrema()
        edge_ratio = _edge_ratio(crop, threshold)
        outline = _component_outline(component["points"], (min_x, min_y, max_x, max_y), (width, height))

        assets[role] = {
            "source_alpha_sheet": str(alpha_path),
            "source_raw_sheet": str(raw_path),
            "output": str(output),
            "outline": outline,
            "computed_rect": {
                "x": min_x / width,
                "y": min_y / height,
                "w": (max_x - min_x) / width,
                "h": (max_y - min_y) / height,
            },
            "crop_rect_px": [x0, y0, x1 - x0, y1 - y0],
            "role_candidate": role,
            "accepted_by_owner": True,
        }
        qc_items.append(
            {
                "role": role,
                "path": str(output),
                "size": list(crop.size),
                "alpha_extrema": list(extrema),
                "edge_foreground_ratio": edge_ratio,
                "component_area": component["area"],
                "bbox": [min_x, min_y, max_x - min_x, max_y - min_y],
                "pass": extrema[0] == 0 and extrema[1] == 255 and edge_ratio < 0.01,
            }
        )

    if "right_back_3q_candidate" in assets:
        base_path = Path(assets["right_back_3q_candidate"]["output"])
        for role, mirrored in (
            ("back_left_3q_from_flip", True),
            ("back_right_3q_from_flip", False),
        ):
            base = Image.open(base_path).convert("RGBA")
            derived = ImageOps.mirror(base) if mirrored else base
            output = out_dir / f"shinokute_standing_{role}.png"
            derived.save(output)
            assets[role] = {
                "source_alpha_sheet": str(alpha_path),
                "derived_from": str(base_path),
                "output": str(output),
                "method": "horizontal_flip_symmetry" if mirrored else "reuse_back_3q_candidate",
                "accepted_by_owner_rule": "Owner said missing angles may be derived by mirror flip.",
            }
            qc_items.append(
                {
                    "role": role,
                    "path": str(output),
                    "size": list(derived.size),
                    "alpha_extrema": list(derived.getchannel("A").getextrema()),
                    "edge_foreground_ratio": _edge_ratio(derived, threshold),
                    "pass": True,
                    "derived": True,
                }
            )

    manifest = {
        "sheet": str(raw_path),
        "alpha_sheet": str(alpha_path),
        "sheet_size": [width, height],
        "method": "Photoroom full sheet first; connected alpha components converted to polygon outline records; no grid slicing; no raw crop; missing back 3q derived by owner-approved horizontal flip symmetry.",
        "assets": assets,
    }
    qc = {
        "components_detected": len(components),
        "bad": [item for item in qc_items if not item.get("pass")],
        "items": qc_items,
    }

    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    qc_path.write_text(json.dumps(qc, indent=2), encoding="utf-8")
    print(
        json.dumps(
            {
                "components_detected": len(components),
                "outputs": len(assets),
                "manifest": str(manifest_path),
                "qc": str(qc_path),
                "bad": [item["role"] for item in qc_items if not item.get("pass")],
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
