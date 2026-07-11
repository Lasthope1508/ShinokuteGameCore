from __future__ import annotations

import json
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw


PROJECT = Path(__file__).resolve().parents[1]
ALPHA_SHEET = PROJECT / "assets/themes/candy_sky_islands/source/candy_function_ui_sheet_photoroom.png"
OUT_DIR = PROJECT / "assets/themes/candy_sky_islands/ui"
WORK_DIR = PROJECT / "assets/themes/candy_sky_islands/source/candy_function_ui_extraction"
QC_PATH = PROJECT / "assets/themes/candy_sky_islands/source/candy_function_ui_extraction_qc.json"
OUTLINES_PATH = PROJECT / "assets/themes/candy_sky_islands/source/candy_function_ui_component_outlines.json"
CONTACT_SHEET = PROJECT / "docs/screenshots/candy_function_ui_contact_sheet.png"

ALPHA_THRESHOLD = 24
MIN_COMPONENT_PIXELS = 1000
TRIM_PADDING = 12

SLOT_NAMES = {
	"top_left": "ui_leaderboard_button",
	"top_middle": "ui_leaderboard_tab",
	"top_right": "ui_leaderboard_close",
	"middle_left": "ui_leaderboard_panel",
	"middle_right": "ui_leaderboard_row",
	"bottom_left": "ui_username_panel",
	"bottom_middle": "ui_username_input",
	"bottom_middle_right": "ui_button_primary",
	"bottom_right": "ui_button_secondary",
}


def main() -> None:
	OUT_DIR.mkdir(parents=True, exist_ok=True)
	WORK_DIR.mkdir(parents=True, exist_ok=True)
	CONTACT_SHEET.parent.mkdir(parents=True, exist_ok=True)

	sheet = Image.open(ALPHA_SHEET).convert("RGBA")
	components = find_components(sheet)
	if len(components) != 9:
		raise SystemExit(f"Expected 9 UI components, found {len(components)}")

	assigned = assign_slots(components, sheet.size)
	qc = {
		"source": str(ALPHA_SHEET.relative_to(PROJECT)).replace("\\", "/"),
		"method": "Photoroom full sheet first, then alpha connected-component masks; no raw crop, no grid slicing",
		"outputs": {},
	}
	outlines = {
		"sheet": str(ALPHA_SHEET.relative_to(PROJECT)).replace("\\", "/"),
		"sheet_size": list(sheet.size),
		"method": "auto alpha component polygon from full Photoroom sheet",
		"assets": {},
	}

	contact_entries = []
	for slot, component in assigned.items():
		name = SLOT_NAMES[slot]
		output_path = OUT_DIR / f"{name}.png"
		clone_path = WORK_DIR / f"{name}_clone_from_photoroom_sheet.png"
		mask_path = WORK_DIR / f"{name}_component_mask.png"
		crop, mask, bbox = crop_component(sheet, component)
		crop.save(output_path)
		crop.save(clone_path)
		mask.save(mask_path)

		edge_ratio = edge_foreground_ratio(crop)
		alpha_extrema = crop.getchannel("A").getextrema()
		qc["outputs"][name] = {
			"path": str(output_path.relative_to(PROJECT)).replace("\\", "/"),
			"slot": slot,
			"component_bbox_px": list(component["bbox"]),
			"trim_bbox_px": list(bbox),
			"size": list(crop.size),
			"mode": crop.mode,
			"alpha_extrema": list(alpha_extrema),
			"edge_foreground_ratio": edge_ratio,
			"status": "pass" if crop.mode == "RGBA" and alpha_extrema[0] == 0 and alpha_extrema[1] == 255 and edge_ratio < 0.04 else "fail",
		}
		outlines["assets"][name] = {
			"outline": component_outline(component, sheet.size),
			"computed_rect": normalized_rect(component["bbox"], sheet.size),
			"source": "computed from alpha component after Photoroom full-sheet background removal",
		}
		contact_entries.append((name, crop))

	if any(item["status"] != "pass" for item in qc["outputs"].values()):
		QC_PATH.write_text(json.dumps(qc, indent=2), encoding="utf-8")
		raise SystemExit("One or more UI asset crops failed QC")

	QC_PATH.write_text(json.dumps(qc, indent=2), encoding="utf-8")
	OUTLINES_PATH.write_text(json.dumps(outlines, indent=2), encoding="utf-8")
	write_contact_sheet(contact_entries)


def find_components(image: Image.Image) -> list[dict]:
	alpha = image.getchannel("A")
	w, h = image.size
	pix = alpha.load()
	seen = bytearray(w * h)
	components: list[dict] = []
	for y in range(h):
		for x in range(w):
			idx = y * w + x
			if seen[idx] or pix[x, y] <= ALPHA_THRESHOLD:
				seen[idx] = 1
				continue
			queue = deque([(x, y)])
			seen[idx] = 1
			points = []
			min_x = max_x = x
			min_y = max_y = y
			while queue:
				cx, cy = queue.pop()
				points.append((cx, cy))
				min_x = min(min_x, cx)
				max_x = max(max_x, cx)
				min_y = min(min_y, cy)
				max_y = max(max_y, cy)
				for ny in (cy - 1, cy, cy + 1):
					if ny < 0 or ny >= h:
						continue
					for nx in (cx - 1, cx, cx + 1):
						if nx < 0 or nx >= w or (nx == cx and ny == cy):
							continue
						next_idx = ny * w + nx
						if seen[next_idx]:
							continue
						seen[next_idx] = 1
						if pix[nx, ny] > ALPHA_THRESHOLD:
							queue.append((nx, ny))
			if len(points) >= MIN_COMPONENT_PIXELS:
				components.append({"bbox": (min_x, min_y, max_x, max_y), "points": points})
	return components


def assign_slots(components: list[dict], size: tuple[int, int]) -> dict[str, dict]:
	w, h = size
	slots = {
		"top_left": (0.22 * w, 0.16 * h),
		"top_middle": (0.60 * w, 0.16 * h),
		"top_right": (0.85 * w, 0.16 * h),
		"middle_left": (0.28 * w, 0.47 * h),
		"middle_right": (0.75 * w, 0.49 * h),
		"bottom_left": (0.15 * w, 0.82 * h),
		"bottom_middle": (0.38 * w, 0.82 * h),
		"bottom_middle_right": (0.62 * w, 0.82 * h),
		"bottom_right": (0.86 * w, 0.82 * h),
	}
	remaining = components[:]
	assigned: dict[str, dict] = {}
	for slot, target in slots.items():
		component = min(remaining, key=lambda item: distance(center(item["bbox"]), target))
		assigned[slot] = component
		remaining.remove(component)
	return assigned


def crop_component(sheet: Image.Image, component: dict) -> tuple[Image.Image, Image.Image, tuple[int, int, int, int]]:
	w, h = sheet.size
	points = set(component["points"])
	min_x, min_y, max_x, max_y = component["bbox"]
	min_x = max(0, min_x - TRIM_PADDING)
	min_y = max(0, min_y - TRIM_PADDING)
	max_x = min(w - 1, max_x + TRIM_PADDING)
	max_y = min(h - 1, max_y + TRIM_PADDING)
	crop = sheet.crop((min_x, min_y, max_x + 1, max_y + 1)).convert("RGBA")
	mask = Image.new("L", crop.size, 0)
	mask_pix = mask.load()
	for x, y in points:
		if min_x <= x <= max_x and min_y <= y <= max_y:
			mask_pix[x - min_x, y - min_y] = 255
	alpha = crop.getchannel("A")
	crop.putalpha(Image.composite(alpha, Image.new("L", crop.size, 0), mask))
	return crop, mask, (min_x, min_y, max_x, max_y)


def edge_foreground_ratio(image: Image.Image) -> float:
	alpha = image.getchannel("A")
	w, h = image.size
	pix = alpha.load()
	edge_pixels = []
	for x in range(w):
		edge_pixels.append(pix[x, 0])
		edge_pixels.append(pix[x, h - 1])
	for y in range(1, h - 1):
		edge_pixels.append(pix[0, y])
		edge_pixels.append(pix[w - 1, y])
	if not edge_pixels:
		return 1.0
	return sum(1 for value in edge_pixels if value > ALPHA_THRESHOLD) / float(len(edge_pixels))


def component_outline(component: dict, size: tuple[int, int]) -> list[list[float]]:
	min_x, min_y, max_x, max_y = component["bbox"]
	w, h = size
	cx = (min_x + max_x) / 2.0
	cy = (min_y + max_y) / 2.0
	return [
		[(min_x + cx) / 2.0 / w, min_y / h],
		[max_x / w, (min_y + cy) / 2.0 / h],
		[max_x / w, (max_y + cy) / 2.0 / h],
		[(max_x + cx) / 2.0 / w, max_y / h],
		[(min_x + cx) / 2.0 / w, max_y / h],
		[min_x / w, (max_y + cy) / 2.0 / h],
		[min_x / w, (min_y + cy) / 2.0 / h],
		[(min_x + cx) / 2.0 / w, min_y / h],
	]


def normalized_rect(bbox: tuple[int, int, int, int], size: tuple[int, int]) -> dict:
	min_x, min_y, max_x, max_y = bbox
	w, h = size
	return {
		"x": min_x / w,
		"y": min_y / h,
		"w": (max_x - min_x + 1) / w,
		"h": (max_y - min_y + 1) / h,
	}


def center(bbox: tuple[int, int, int, int]) -> tuple[float, float]:
	min_x, min_y, max_x, max_y = bbox
	return ((min_x + max_x) / 2.0, (min_y + max_y) / 2.0)


def distance(a: tuple[float, float], b: tuple[float, float]) -> float:
	return ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2) ** 0.5


def write_contact_sheet(entries: list[tuple[str, Image.Image]]) -> None:
	thumb_w, thumb_h = 360, 180
	label_h = 34
	cols = 3
	rows = 3
	canvas = Image.new("RGBA", (cols * thumb_w, rows * (thumb_h + label_h)), (121, 199, 242, 255))
	draw = ImageDraw.Draw(canvas)
	for index, (name, image) in enumerate(entries):
		col = index % cols
		row = index // cols
		x0 = col * thumb_w
		y0 = row * (thumb_h + label_h)
		bg = Image.new("RGBA", (thumb_w, thumb_h), (255, 242, 199, 255))
		thumb = image.copy()
		thumb.thumbnail((thumb_w - 36, thumb_h - 24), Image.Resampling.LANCZOS)
		tx = x0 + (thumb_w - thumb.width) // 2
		ty = y0 + (thumb_h - thumb.height) // 2
		canvas.alpha_composite(bg, (x0, y0))
		canvas.alpha_composite(thumb, (tx, ty))
		draw.text((x0 + 12, y0 + thumb_h + 8), name, fill=(39, 48, 67, 255))
	canvas.convert("RGB").save(CONTACT_SHEET)


if __name__ == "__main__":
	main()
