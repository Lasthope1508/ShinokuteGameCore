#!/usr/bin/env python3
import json
import os
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "themes" / "candy_sky_islands" / "branding"
RAW_DIR = ROOT / "assets" / "themes" / "candy_sky_islands" / "source" / "branding_raw"
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


def _request(url: str, data: bytes | None = None) -> bytes:
	headers = {"Authorization": f"Bearer {_auth_key()}"}
	if data is not None:
		headers["Content-Type"] = "application/json"
	req = urllib.request.Request(url, data=data, headers=headers, method="POST" if data is not None else "GET")
	try:
		with urllib.request.urlopen(req, timeout=180) as response:
			return response.read()
	except urllib.error.HTTPError as exc:
		body = exc.read().decode("utf-8", errors="replace")
		raise RuntimeError(f"9Router image request failed with HTTP {exc.code}: {body}") from exc


def _ensure_model_available() -> None:
	body = _request(f"{IMAGE_URL}/v1/models/image")
	payload = json.loads(body.decode("utf-8"))
	model_ids = {item.get("id") for item in payload.get("data", [])}
	if MODEL not in model_ids:
		raise RuntimeError(f"Required image model {MODEL} is not listed by /v1/models/image.")


def _post_image(prompt: str, size: str, output_path: Path) -> None:
	payload = {
		"model": MODEL,
		"prompt": prompt,
		"size": size,
		"output_format": "png",
	}
	data = json.dumps(payload).encode("utf-8")
	body = _request(f"{IMAGE_URL}/v1/images/generations?response_format=binary", data=data)
	output_path.parent.mkdir(parents=True, exist_ok=True)
	output_path.write_bytes(body)
	print(output_path)


def main() -> int:
	_ensure_model_available()
	_post_image(ICON_PROMPT, "1024x1024", OUT_DIR / "app_icon_source.png")
	_post_image(SPLASH_PROMPT, "1792x1024", RAW_DIR / "splash_candy_sky_islands_raw.png")
	_post_image(LOGO_PROMPT, "1024x1024", RAW_DIR / "logo_candy_sky_islands_raw.png")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
