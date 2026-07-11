from __future__ import annotations

import json
import socket
import sys
from pathlib import Path


def send_execute_code(code: str, host: str = "127.0.0.1", port: int = 9876) -> dict:
    payload = json.dumps({"type": "execute_code", "params": {"code": code}}).encode("utf-8")
    with socket.create_connection((host, port), timeout=20) as client:
        client.settimeout(None)
        client.sendall(payload)
        chunks: list[bytes] = []
        while True:
            chunk = client.recv(65536)
            if not chunk:
                break
            chunks.append(chunk)
            try:
                return json.loads(b"".join(chunks).decode("utf-8"))
            except json.JSONDecodeError:
                continue
    raise RuntimeError("Blender MCP closed without JSON response")


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: run_blender_script_via_mcp.py <script.py> [args...]")
        return 2
    script = Path(sys.argv[1]).resolve()
    script_args = [str(script), *sys.argv[2:]]
    if not script.exists():
        raise FileNotFoundError(script)

    code = f"""
import runpy
import sys
sys.argv = {script_args!r}
runpy.run_path({str(script)!r}, run_name="__main__")
"""
    response = send_execute_code(code)
    print(json.dumps(response, indent=2))
    if response.get("status") != "success":
        return 1
    result = response.get("result", {})
    if isinstance(result, dict) and result.get("executed") is not True:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
