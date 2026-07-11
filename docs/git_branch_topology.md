# Shinokute Git Branch Topology

Canonical remote:

- `https://github.com/Lasthope1508/ShinokuteGameCore.git`

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

Legacy branch policy:

- Branches under `legacy/` are read-only archive pointers.
- Do not continue gameplay, reskin, core migration, publish, or Firebase work
  from a legacy branch.
- If a legacy branch still exists in an old source repo, copy its commit to
  a canonical `game/<game-id>` branch before doing new work.
- Do not delete an old branch name until a `legacy/...` alias points to the
  same commit.
- Do not force-push canonical or legacy branches.

Legacy aliases already reserved:

| Old repo | Old branch | Legacy alias |
|---|---|---|
| `Lasthope1508/bloxchain` | `bloxchain` | `legacy/bloxchain/bloxchain` |
| `Lasthope1508/bloxchain` | `codex/bloxchain-shinokute-core` | `legacy/bloxchain/codex-bloxchain-shinokute-core` |
| `Lasthope1508/bloxchain` | `codex/bloxchain-core-contract` | `legacy/bloxchain/codex-bloxchain-core-contract` |
| `Lasthope1508/Godot-Casual-Games` | `codex/water-canonical-names` | `legacy/glyph-arrows/codex-water-canonical-names` |

Before pushing:

1. Inspect the local game repo/worktree branch and remote.
2. Confirm the branch target is a `game/<game-id>` branch.
3. Push core changes only to `ShinokuteGameCore/main`.
4. Push game changes only to the matching `game/<game-id>` branch.
5. Never push Candy Sky Islands to `KenneyNL/Starter-Kit-3D-Platformer`.
