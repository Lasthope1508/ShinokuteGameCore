# Blender MCP Discovery Runbook

Last updated: 2026-07-08

Use this before any Blender inspection, render, GLB cleanup, model authoring, texture projection, rigging, or 3D export work.

## Rule

Do not stop after Codex tool discovery says no `mcp__blender` tool is exposed. This machine has a Blender MCP configuration outside the current Codex tool surface. The agent must check the configured MCP files and known runtime paths before falling back to Blender CLI.

## Required Order

1. Run tool discovery for `mcp__blender` or `Blender`.
2. If exposed, use the MCP tool for Blender work and record that it was exposed in the current thread.
3. If not exposed, read the local Blender MCP guide:
   - `C:\Users\Admin\.gemini\config\skills\blender_mcp\SKILL.md`
4. Read the MCP config:
   - `C:\Users\Admin\.gemini\config\mcp_config.json`
5. Confirm the `mcpServers.blender` entry exists. Current known config:
   - command: `C:\Users\Admin\.local\bin\uv.exe`
   - args: `run --project C:\Users\Admin\.gemini\antigravity\mcp\blender-mcp blender-mcp`
6. Confirm these paths exist before any broad search:
   - Blender executable: `C:\Users\Admin\.gemini\antigravity\bin\Blender\blender-4.2.0-windows-x64\blender.exe`
   - MCP project: `C:\Users\Admin\.gemini\antigravity\mcp\blender-mcp`
   - MCP server entrypoint files: `main.py`, `pyproject.toml`, `src\`
   - Blender MCP addon copy: `C:\Users\Admin\Desktop\Game\blender_mcp_addon.py`
7. Check Blender MCP runtime model:
   - Blender addon listens inside Blender on TCP port `9876`.
   - The MCP server launched by `uv` talks to that addon.
   - If the addon is not running inside Blender, Codex can still use Blender CLI for deterministic render/export scripts, but must record that MCP was configured yet not exposed/running in the current thread.
8. Only after steps 1-7 fail, do a narrow search for config files. Do not broad-search all `.codex` sessions or Blender binary folders.

## Current Known Working Fallback

Do not jump here until the Blender MCP addon has been opened or checked.

## Opening Blender MCP

Preferred automated open from this project:

```powershell
$project = 'C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter'
$blender = 'C:\Users\Admin\.gemini\antigravity\bin\Blender\blender-4.2.0-windows-x64\blender.exe'
$script = Join-Path $project 'tools\start_blender_mcp_gui.py'
$args = "--python `"$script`""
Start-Process -FilePath $blender -ArgumentList $args -WorkingDirectory $project
Start-Sleep -Seconds 5
Test-NetConnection 127.0.0.1 -Port 9876
```

Expected result:

```text
TcpTestSucceeded: True
```

The project script `tools/start_blender_mcp_gui.py` loads `C:\Users\Admin\.gemini\antigravity\mcp\blender-mcp\addon.py` through `importlib` and registers it as a real module. Do not replace that script with a raw `exec()` loader: Blender `register_class()` evaluates type hints such as `BoolProperty`, and raw `exec()` can fail because the addon is not in `sys.modules`. Keep the `$args` quoting shown above; this project path contains spaces, and an unquoted `--python` script path can make Blender exit before the script runs.

Manual open if the script fails:

1. Launch `C:\Users\Admin\.gemini\antigravity\bin\Blender\blender-4.2.0-windows-x64\blender.exe`.
2. Install/enable addon from `C:\Users\Admin\.gemini\antigravity\mcp\blender-mcp\addon.py` or `C:\Users\Admin\Desktop\Game\blender_mcp_addon.py`.
3. In Blender viewport press `N`.
4. Open the `BlenderMCP` tab.
5. Set port `9876`.
6. Click `Connect to MCP server`.
7. Verify from PowerShell with `Test-NetConnection 127.0.0.1 -Port 9876`.

## CLI Fallback

When MCP is configured but unavailable in the current Codex tool surface or live addon socket, use Blender CLI:

```powershell
& 'C:\Users\Admin\.gemini\antigravity\bin\Blender\blender-4.2.0-windows-x64\blender.exe' --background --python '<script.py>' -- <args>
```

This fallback is valid for non-interactive inspection, render preview, import/export, mesh cleanup, and GLB authoring scripts.

## Failure Record Format

When Blender MCP is not available, record:

```text
Blender MCP discovery:
- Codex tool exposure: not exposed
- Gemini MCP config: found at C:\Users\Admin\.gemini\config\mcp_config.json
- MCP project: found at C:\Users\Admin\.gemini\antigravity\mcp\blender-mcp
- Addon: found at C:\Users\Admin\Desktop\Game\blender_mcp_addon.py
- Port model: addon listens on 9876 inside Blender
- Action: use Blender 4.2 CLI fallback for this thread, or ask owner to start Blender addon if live MCP interaction is required
```

## Forbidden

- Do not claim "no Blender MCP exists" when only the current Codex tool surface lacks `mcp__blender`.
- Do not broad-search all sessions, caches, or Blender installation files before checking the fixed config paths above.
- Do not replace MCP discovery with primitive-only Blender output. Production assets still must follow the reskin and 3D parity rules.
