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
	OUT.parent.mkdir(parents=True, exist_ok=True)
	OUT.write_text(json.dumps(report, indent=2), encoding="utf-8")
	print(OUT)
	return 1 if report["bad"] else 0


if __name__ == "__main__":
	raise SystemExit(main())
