#!/usr/bin/env python3
import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUTUPOST = Path(r"C:\Users\Admin\Desktop\Antigravity\AutoPost")
IMAGE_URL = os.environ.get("NINEROUTER_IMAGE_URL", "https://img.teelab247.com").rstrip("/")
MODEL = "cx/gpt-5.5-image"


def _auth_key() -> str:
    key = (
        os.environ.get("NINEROUTER_IMAGE_KEY")
        or os.environ.get("NINEROUTER_KEY")
        or os.environ.get("ROUTER_API_KEY")
    )
    if not key:
        raise RuntimeError(
            "No owner-approved image key found: set NINEROUTER_IMAGE_KEY, "
            "NINEROUTER_KEY, or ROUTER_API_KEY."
        )
    return key


def _request(url: str, data: bytes | None = None) -> bytes:
    headers = {"Authorization": f"Bearer {_auth_key()}"}
    if data is not None:
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(
        url,
        data=data,
        headers=headers,
        method="POST" if data is not None else "GET",
    )
    try:
        with urllib.request.urlopen(req, timeout=240) as response:
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


def _upload_ref(path_or_url: str, prefix: str) -> str:
    if path_or_url.startswith(("http://", "https://")):
        return path_or_url
    path = Path(path_or_url)
    if not path.exists():
        raise FileNotFoundError(path)
    if str(AUTUPOST) not in sys.path:
        sys.path.insert(0, str(AUTUPOST))
    from services.cloudflare_upload_service import get_cloudflare_upload_service

    svc = get_cloudflare_upload_service()
    if not svc.initialize():
        raise RuntimeError("Cloudflare R2 upload service failed to initialize.")
    key = f"{prefix}/{path.stem}{path.suffix}".replace("\\", "/")
    url = svc.upload_file_to_key(path, key)
    if not url:
        raise RuntimeError(f"Cloudflare R2 upload failed for {path}")
    return url


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--size", default="1792x1024")
    parser.add_argument("--refs", default="")
    parser.add_argument("--upload-prefix", default="images/codex/quantum_starter/shinokute")
    args = parser.parse_args()

    _ensure_model_available()

    ref_urls = [
        _upload_ref(item.strip(), args.upload_prefix)
        for item in args.refs.split(",")
        if item.strip()
    ]
    payload = {
        "model": MODEL,
        "prompt": args.prompt,
        "size": args.size,
        "output_format": "png",
        "image_detail": "high",
    }
    if len(ref_urls) == 1:
        payload["image"] = ref_urls[0]
    elif len(ref_urls) > 1:
        payload["images"] = ref_urls

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    body = _request(
        f"{IMAGE_URL}/v1/images/generations?response_format=binary",
        data=json.dumps(payload).encode("utf-8"),
    )
    output_path.write_bytes(body)
    print(f"saved={output_path}")
    print(f"bytes={len(body)}")
    print(f"refs={len(ref_urls)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
