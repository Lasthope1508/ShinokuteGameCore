import hashlib
import importlib.util
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

from PIL import Image


PROJECT = Path(__file__).resolve().parents[1]
MODEL_ID = "cx/gpt-5.5-image"
MANIFEST_PATH = PROJECT / "docs" / "ui_cyber_component_generation_manifest.json"
UPLOADER_PATH = Path(r"C:\Users\Admin\Desktop\Game\reskin_dashboard\upload_server.py")
PHOTOROOM_SCRIPT = Path(r"C:\Users\Admin\.gemini\config\skills\photoroom-cdp-background-removal\scripts\photoroom_cdp_fetch_segment.js")
PUBLIC_PREFIX = "images/glyph-arrows-cyber-ui-production"

MODES = {
    "dark": "dark cyber. Purple floating settings button, yellow floating replay button, black/deep-green gameplay tone, cyan electric bevel glow.",
    "light": "bright cyber light. Pale graphite/white-lit material, purple floating settings button, yellow floating replay button, cyan electric bevel glow.",
}

BUTTONS = {
    "floating_menu_button_default": {
        "role": "settings",
        "symbol": "centered gear/settings icon, readable at small mobile size, no hamburger/menu text",
        "icon_path": PROJECT / "Assets" / "Icons" / "menuList.png",
    },
    "floating_replay_button_default": {
        "role": "replay",
        "symbol": "centered clockwise replay arrow icon, readable at small mobile size",
        "icon_path": PROJECT / "Assets" / "Icons" / "return.png",
    },
}


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def gateway() -> tuple[str, str, str]:
    base = os.environ.get("NINEROUTER_IMAGE_URL") or "https://img.teelab247.com"
    key = os.environ.get("NINEROUTER_IMAGE_KEY") or os.environ.get("NINEROUTER_KEY")
    key_source = "NINEROUTER_IMAGE_KEY" if os.environ.get("NINEROUTER_IMAGE_KEY") else "NINEROUTER_KEY"
    if not key:
        raise RuntimeError("No approved 9Router key found in NINEROUTER_IMAGE_KEY or NINEROUTER_KEY")
    return base.rstrip("/"), key, key_source


def request_json(url: str, key: str) -> dict:
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {key}"})
    with urllib.request.urlopen(req, timeout=30) as response:
        return json.loads(response.read().decode("utf-8"))


def verify_model(base: str, key: str) -> None:
    health = json.loads(urllib.request.urlopen(f"{base}/api/health", timeout=20).read().decode("utf-8"))
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


def manifest_item(manifest: dict, mode: str, component_key: str) -> dict:
    for item in manifest.get("items", []):
        if item.get("mode") == mode and item.get("component_key") == component_key:
            return item
    return {}


def upsert_manifest_item(manifest: dict, item: dict) -> None:
    items = manifest.setdefault("items", [])
    for index, existing in enumerate(items):
        if existing.get("mode") == item.get("mode") and existing.get("component_key") == item.get("component_key"):
            items[index] = item
            return
    items.append(item)


def reference_urls(manifest: dict, upload_mod, mode: str, component_key: str, icon_path: Path) -> list[str]:
    refs: list[str] = []
    for key in ("top_tray_layer", component_key, "board_backplate"):
        item = manifest_item(manifest, mode, key)
        url = item.get("production_r2_url") or item.get("r2_url")
        if url and url not in refs:
            refs.append(url)
    current_button = PROJECT / "Assets" / "UI" / "cyberpunk_theme" / "generated" / "production" / mode / f"{component_key}_photoroom.png"
    for local_path in (current_button, icon_path):
        if local_path.exists():
            r2_key = f"{PUBLIC_PREFIX}/refs/{mode}/{local_path.stem}.png"
            url = upload_file(upload_mod, local_path, r2_key)
            if url not in refs:
                refs.append(url)
    return refs


def build_prompt(mode: str, component_key: str, refs: list[str]) -> str:
    button = BUTTONS[component_key]
    return "\n".join([
        "Create one isolated production mobile game UI button asset object, not poster art and not a full screen mockup.",
        f"Asset: {component_key}.",
        f"Mode: {MODES[mode]}",
        f"Button action: {button['role']}.",
        f"Required symbol: {button['symbol']}.",
        "The icon must be baked into the button art and optically centered in the button body.",
        "Keep the button shell style, bevel depth, material, glow, and silhouette synchronized with the reference button and top tray.",
        "Object only. No text, no logo, no character, no gameplay pipe, no board screenshot, no extra UI pieces.",
        "Centered single button, fully visible, square canvas, generous empty margin.",
        "Output PNG on flat pure #ff00ff removable background for PhotoRoom cleanup.",
        "Reference image URLs for style synchronization:",
        "\n".join(refs),
    ])


def generate_raw(base: str, key: str, prompt: str, refs: list[str], raw_path: Path) -> None:
    raw_path.parent.mkdir(parents=True, exist_ok=True)
    body = {
        "model": MODEL_ID,
        "prompt": prompt,
        "size": "1024x1024",
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
            headers={
                "Authorization": f"Bearer {key}",
                "Content-Type": "application/json",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=260) as response:
                raw_path.write_bytes(response.read())
            return
        except urllib.error.HTTPError as exc:
            last_error = exc.read().decode("utf-8", errors="replace")
            if exc.code not in (408, 429, 500, 502, 503, 504):
                break
        except Exception as exc:
            last_error = str(exc)
        time.sleep(5 + attempt * 5)
    raise RuntimeError(last_error or "9Router image generation failed")


def run_photoroom(raw_path: Path, output_path: Path, ports: list[int]) -> int:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.setdefault("PHOTOROOM_TURNSTILE_TIMEOUT_MS", "60000")
    last_error = ""
    for port in ports:
        cmd = ["node", str(PHOTOROOM_SCRIPT), str(port), str(raw_path), str(output_path)]
        result = subprocess.run(cmd, cwd=str(PROJECT), env=env, text=True, capture_output=True, timeout=180)
        if result.returncode == 0 and output_path.exists() and output_path.stat().st_size > 0:
            return port
        last_error = (result.stderr or result.stdout)[-2000:]
    raise RuntimeError(f"PhotoRoom failed for {raw_path}: {last_error}")


def trim_alpha(input_path: Path, output_path: Path, padding: int = 36) -> tuple[tuple[int, int], tuple[int, int, int, int], tuple[int, int]]:
    image = Image.open(input_path).convert("RGBA")
    alpha = image.getchannel("A")
    extrema = alpha.getextrema()
    bbox = image.getbbox()
    if bbox is None:
        raise RuntimeError(f"Blank alpha after PhotoRoom: {input_path}")
    left = max(0, bbox[0] - padding)
    top = max(0, bbox[1] - padding)
    right = min(image.width, bbox[2] + padding)
    bottom = min(image.height, bbox[3] + padding)
    trimmed = image.crop((left, top, right, bottom))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    trimmed.save(output_path)
    return trimmed.size, (bbox[0] - left, bbox[1] - top, bbox[2] - left, bbox[3] - top), extrema


def create_preview(paths: dict[tuple[str, str], Path]) -> Path:
    cells = []
    for mode in ("dark", "light"):
        for component_key in BUTTONS.keys():
            path = paths[(mode, component_key)]
            cells.append((mode, component_key, Image.open(path).convert("RGBA")))
    cell = 360
    preview = Image.new("RGBA", (cell * 2, cell * 2), (28, 32, 36, 255))
    for index, (mode, component_key, image) in enumerate(cells):
        x0 = (index % 2) * cell
        y0 = (index // 2) * cell
        bg = Image.new("RGBA", (cell, cell), (38, 42, 48, 255))
        for y in range(0, cell, 32):
            for x in range(0, cell, 32):
                if ((x // 32) + (y // 32)) % 2 == 0:
                    for yy in range(y, min(y + 32, cell)):
                        for xx in range(x, min(x + 32, cell)):
                            bg.putpixel((xx, yy), (52, 58, 66, 255))
        scale = min(260 / image.width, 260 / image.height)
        resized = image.resize((int(image.width * scale), int(image.height * scale)), Image.Resampling.LANCZOS)
        bg.alpha_composite(resized, ((cell - resized.width) // 2, 60 + (260 - resized.height) // 2))
        preview.alpha_composite(bg, (x0, y0))
    out = PROJECT / "debug" / "top_tray_icon_baked_buttons_preview.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    preview.save(out)
    return out


def main() -> int:
    base, key, key_source = gateway()
    verify_model(base, key)
    upload_mod = uploader()
    manifest = load_json(MANIFEST_PATH)
    generated: dict[tuple[str, str], Path] = {}
    ports = [int(value) for value in os.environ.get("PHOTOROOM_PORTS", "9904,9223").split(",") if value.strip()]

    print(json.dumps({"model": MODEL_ID, "key_source": key_source, "photoroom_ports": ports}, ensure_ascii=False))
    for mode in MODES.keys():
        for component_key in BUTTONS.keys():
            out_dir = PROJECT / "Assets" / "UI" / "cyberpunk_theme" / "generated" / "production" / mode
            raw_path = out_dir / f"{component_key}_icon_raw.png"
            photoroom_path = out_dir / f"{component_key}_icon_photoroom_untrimmed.png"
            final_path = out_dir / f"{component_key}_icon_photoroom.png"
            refs = reference_urls(manifest, upload_mod, mode, component_key, BUTTONS[component_key]["icon_path"])
            prompt = build_prompt(mode, component_key, refs)
            generate_raw(base, key, prompt, refs, raw_path)
            used_port = run_photoroom(raw_path, photoroom_path, ports)
            pixel_size, alpha_bbox, alpha_extrema = trim_alpha(photoroom_path, final_path)
            r2_key = f"{PUBLIC_PREFIX}/{mode}/{component_key}_icon_photoroom.png"
            r2_url = upload_file(upload_mod, final_path, r2_key)
            item = {
                "mode": mode,
                "component_key": component_key,
                "local_path": str(final_path),
                "raw_local_path": str(raw_path),
                "photoroom_untrimmed_path": str(photoroom_path),
                "r2_key": r2_key,
                "r2_url": r2_url,
                "production_r2_url": r2_url,
                "content_type": "image/png",
                "bytes": final_path.stat().st_size,
                "sha256": sha256(final_path),
                "pixel_size": list(pixel_size),
                "asset_stage": "photoroom_production_cutout_candidate",
                "acceptance_status": "pending_owner_visual_approval",
                "background_removal_method": "photoroom",
                "production_background_removal_method": "photoroom",
                "photoroom_port": used_port,
                "alpha_extrema": list(alpha_extrema),
                "alpha_bbox": list(alpha_bbox),
                "anchor": f"top_tray.{component_key}.icon_baked",
                "runtime_region": "alpha_bbox",
                "scale_policy": "fit_inside_canonical_floating_button_rect_preserve_aspect_centered",
                "icon_policy": "icon_baked_into_button_texture; no runtime GeneratedButtonIcon overlay",
                "source_refs": [
                    "docs/ui_cyber_component_generation_manifest.json",
                    "docs/9router_ui_generation_runbook.md",
                ],
                "reference_urls": refs,
                "prompt": prompt,
            }
            upsert_manifest_item(manifest, item)
            generated[(mode, component_key)] = final_path
            write_json(MANIFEST_PATH, manifest)
            print(json.dumps({"mode": mode, "component_key": component_key, "path": str(final_path), "pixel_size": pixel_size, "r2_url": r2_url}, ensure_ascii=False))

    preview = create_preview(generated)
    preview_key = f"{PUBLIC_PREFIX}/debug/{preview.name}"
    preview_url = upload_file(upload_mod, preview, preview_key)
    upsert_manifest_item(manifest, {
        "mode": "debug",
        "component_key": "top_tray_icon_baked_buttons_preview",
        "local_path": str(preview),
        "r2_key": preview_key,
        "r2_url": preview_url,
        "content_type": "image/png",
        "bytes": preview.stat().st_size,
        "sha256": sha256(preview),
        "asset_stage": "preview",
        "acceptance_status": "debug_preview",
    })
    manifest["updated_at"] = "2026-07-03"
    write_json(MANIFEST_PATH, manifest)
    print(json.dumps({"preview": str(preview), "preview_url": preview_url}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
