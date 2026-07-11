# Shinokute Git Branch Topology

Canonical rule:

- `ShinokuteGameCore/main` is the shared core trunk.
- Each shipped/reskinned game owns one game branch.
- Game branches may have different project roots or unrelated histories.
- Do not push a game branch to an upstream template remote.
- Do not mix multiple games into one game branch.

Current game branches:

| Game | Canonical branch | Source path |
|---|---|---|
| BloxChain | `game/bloxchain` | `C:\Users\Admin\Desktop\Godot Casual Games\BloxChain_GitHub_Final` |
| Glyph Arrows / Glyphflow Arrays | `game/glyph-arrows` | `C:\Users\Admin\Desktop\Godot Casual Games\WaternetGodot` and `WaternetGodot_Cyberpunk` in the casual-games repo |
| Candy Sky Islands | `game/candy-sky-islands` | `C:\Users\Admin\Desktop\Godot Casual Games\Html5_SourceGames\Godot\quantum_starter` |

Before pushing:

1. Inspect the local game repo/worktree branch and remote.
2. Confirm the branch target is a `game/<game-id>` branch.
3. Push core changes only to `ShinokuteGameCore/main`.
4. Push game changes only to the matching `game/<game-id>` branch.
5. Never push Candy Sky Islands to `KenneyNL/Starter-Kit-3D-Platformer`.

