from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

import bpy

ADDON = Path(r"C:\Users\Admin\.gemini\antigravity\mcp\blender-mcp\addon.py")
LOG = Path(r"C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter\debug\blender_mcp_start.log")

def log(message: str) -> None:
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with LOG.open("a", encoding="utf-8") as handle:
        handle.write(message + "\n")

log("start_blender_mcp_gui.py: begin")

spec = importlib.util.spec_from_file_location("blender_mcp_addon", ADDON)
if spec is None or spec.loader is None:
    raise RuntimeError(f"Cannot load Blender MCP addon from {ADDON}")

module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)
module.register()
log("addon registered")

bpy.context.scene.blendermcp_port = 9876
bpy.context.scene.blendermcp_auto_start_server = True
if not getattr(bpy.context.scene, "blendermcp_server_running", False):
    bpy.ops.blendermcp.start_server()
log(f"server_running={getattr(bpy.context.scene, 'blendermcp_server_running', None)}")

print("Codex: Blender MCP addon loaded and server requested on port 9876")
log("start_blender_mcp_gui.py: done")
