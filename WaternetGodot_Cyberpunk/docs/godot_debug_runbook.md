# Godot Debug Runbook

Purpose: exact local workflow for opening and inspecting this Godot project without repeating MCP/debug setup mistakes.

## Tools Installed

- GoPeak MCP is installed globally as `gopeak@2.3.8`.
- Codex config points `[mcp_servers.godot]` to `C:\Users\Admin\AppData\Roaming\npm\node_modules\gopeak\build\cli.js`.
- Project addons are installed in `addons/auto_reload`, `addons/godot_mcp_editor`, and `addons/godot_mcp_runtime`.
- Runtime ports:
  - `9090`: legacy `McpInteractionServer` from `Scripts/mcp_interaction_server.gd`.
  - `7777`: GoPeak runtime addon from `addons/godot_mcp_runtime/mcp_runtime_autoload.gd`.
  - `6505`: GoPeak editor bridge.

## Visible Debug

Use visible debug when the human needs to see and test the game window.

Command:

```powershell
& 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe' --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' 'res://Scenes/Gameplay/GameScene.tscn'
```

Expected:

- Window title: `Glyphflow Arrays (DEBUG)`.
- Console logs show `McpInteractionServer: Listening on 127.0.0.1:9090`.
- Console logs show `[MCP Runtime] Server listening on port 7777`.

Bring the window forward if needed:

```powershell
$p = Get-Process *Godot* | Where-Object { $_.MainWindowTitle -like '*DEBUG*' } | Select-Object -First 1
Add-Type 'using System; using System.Runtime.InteropServices; public class Win32Focus { [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow); [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd); }'
[Win32Focus]::ShowWindow($p.MainWindowHandle, 9) | Out-Null
[Win32Focus]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
```

## GoPeak Caveat

GoPeak `run-project` is useful for logs and headless validation, but it launches this project with `--headless`. Do not use `run-project` when the user asks to see the Godot window.

Use `run-project` only for non-visual MCP checks:

```json
{
  "name": "run-project",
  "arguments": {
    "projectPath": "C:/Users/Admin/Desktop/Godot Casual Games/WaternetGodot_Cyberpunk",
    "scene": "res://Scenes/Gameplay/GameScene.tscn"
  }
}
```

If the task says visible debug, use the visible debug command above.

## Health Checks

```powershell
Get-Process *Godot* | Select-Object Id,ProcessName,MainWindowTitle,MainWindowHandle
Test-NetConnection 127.0.0.1 -Port 9090
Test-NetConnection 127.0.0.1 -Port 7777
```

Passing state:

- `MainWindowTitle` contains `Glyphflow Arrays (DEBUG)`.
- `MainWindowHandle` is not `0`.
- Both ports return `TcpTestSucceeded = True`.

## Headless Tests

Headless tests must not bind runtime debug ports. Both runtime servers guard against headless mode:

- `Scripts/mcp_interaction_server.gd`
- `addons/godot_mcp_runtime/mcp_runtime_autoload.gd`

Use headless only for automated tests:

```powershell
& 'C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe' --headless --path 'C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot_Cyberpunk' -s res://Tests/test_pipe_vfx_lightning_arcs.gd
```
