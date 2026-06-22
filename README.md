# Block Puzzle Template

A clean, fully-commented **Godot 4.6** template for a block-puzzle game in
the Woodoku / sudoku-puzzle style:

* 9×9 grid divided into nine alternating 3×3 quadrants.
* Bottom tray with three slots that get refilled with random tetromino-like
  pieces (data-driven via `Resource` files).
* Drag-and-drop placement with translucent preview, clear-line hints and a
  pulsing shader highlight on the blocks that would be removed by a match.
* Two-stage scoring (placement → cascade → combo readout) with a dynamic
  combo multiplier.
* Score progress bar with milestone-driven level-ups (target → fill →
  drain → next target).
* On-boarding **tutorial** triggered on the first launch (two scripted
  placements, animated cursor + ghost piece, persisted completion flag).
* Animated row / column / quadrant clears with bump-elastic block removal.
* **Camera shake** that scales with the combo magnitude and triggers also
  on score-progress milestones, fully tunable from Inspector.
* Settings overlay (audio sliders, Restart Game, Main Menu).
* Game-over overlay with 10 s countdown, **Restart** and an **ADReward**
  stub (limited to 2 uses per game-over screen).
* Full session save: score, grid layout, slot pieces — resume the run after
  a refresh, app close, or trip back to the main menu.
* Project-wide `Theme.tres` so the buyer can recolor the whole UI from one
  resource (panels, buttons, labels, outlines, shadows).
* Fade scene transitions and **bump-elastic** overlays.
* Targeting Web (HTML5) but works on Desktop and Mobile too — viewport is
  responsive.

The template is intentionally minimal in code but **deeply Inspector-driven**:
almost every visual is exposed as a `Resource`, a `theme_override`, or an
`@export` so the buyer can re-skin the game without touching `.gd` files.

---

## Requirements

* Godot **4.6** (or later 4.x).
* GL Compatibility renderer (set in `project.godot`) for the broadest
  hardware support, including HTML5 export.

---

## Project layout

```
res://
├── Assets/
│   ├── Sprites/                 block, cell, quadrants, logo, slot, tutorial cursor
│   ├── Icons/                   menuList, trophy, cross, audio/music on-off, …
│   ├── Fonts/                   Alegreya-ExtraBold.ttf (project-wide font)
│   └── Shaders/
│       └── block_pulse.gdshader (white-flash pulse on potential clears)
├── Audio/
│   ├── SFX/                     sfx_pick, sfx_drop, sfx_invalid, sfx_clear,
│   │                            sfx_combo, sfx_button, sfx_popup,
│   │                            sfx_populateSlot, sfx_levelup,
│   │                            sfx_gameover, sfx_timeout (.wav)
│   └── Music/                   music_loop.ogg (looping)
├── Resources/
│   ├── Classes/                 Custom Resource scripts (PieceShape, ThemeConfig)
│   ├── Data/                    Static .tres data
│   │   ├── default_theme.tres   ThemeConfig — palette + tints
│   │   └── Pieces/              mono.tres, l_shape.tres, t_shape.tres, …
│   ├── Theme/
│   │   └── main_theme.tres      Project-wide UI Theme (panels + buttons + labels)
│   └── Globals/                 Autoload singletons
│       ├── SaveManager.gd       user://save.cfg (best, audio, run, tutorial)
│       ├── GameState.gd         current score, best, combo math, AD reward count
│       ├── AudioManager.gd      play_sfx, play_music, bus volume routing
│       └── SceneRouter.gd       fade-out → change_scene → fade-in
├── Scenes/
│   ├── Common/                  Cross-cutting overlays
│   │   ├── FadeTransition.tscn  Fullscreen black ColorRect on its own CanvasLayer
│   │   └── ElasticOverlay.tscn  Base for modal overlays (bump-elastic open/close)
│   ├── Main/Main.tscn           Entry point — splash with logo + studio name
│   ├── MainMenu/MainMenu.tscn   Title, Play, Settings, Best score, version label
│   └── Game/
│       ├── Game.tscn            Per-run coordinator
│       └── Component/
│           ├── Grid/            Cell, Quadrant, Grid (responsive 9×9)
│           ├── Piece/           Block, Piece (drag-and-drop)
│           ├── PieceTray/       PieceSlot, PieceTray
│           ├── HUD/             HUD, ScoreProgressBar, ScorePopup
│           └── Overlays/        SettingsOverlay, GameOverOverlay
└── Scripts/                     Stand-alone utilities
	├── PieceLibrary.gd          Loads / weighted-picks PieceShape resources
	└── GridSolver.gd            Static checks: is any move possible?
```

`Main.tscn` is the entry point (set as `run/main_scene` in `project.godot`).
It fades the screen in, holds for a beat on the studio logo, then routes
to `MainMenu.tscn`.

---

## How everything connects

* `GameState` (autoload) holds run-time state and emits signals (`score_changed`,
  `best_changed`, `game_over`, `game_reset`).
* `SaveManager` persists best score, audio volumes, the tutorial flag,
  **and the in-progress run** (score + grid + slots) to `user://save.cfg`.
  Works on HTML5 via IndexedDB.
* `AudioManager` exposes `play_sfx(name, pitch_variation)` and `play_music()`.
  SFX names live in `AudioManager.SFX_LIBRARY` — drop new files in
  `Audio/SFX/` and add an entry there. Missing files are skipped silently.
* `SceneRouter` performs `change_scene_to_file(path)` surrounded by a fade.
* `Game.gd` is the per-run coordinator: it owns `Grid`, `HUD`,
  `ScoreProgressBar` and `PieceTray`; on first launch it runs the tutorial,
  otherwise it either loads the saved run or starts a fresh refill.

---

## Score & combo rules

Tunable as constants at the top of `Resources/Globals/GameState.gd`:

| Constant                  | Default | Meaning                                          |
|---------------------------|---------|--------------------------------------------------|
| `POINTS_PER_CELL`         | 1       | Score gained per filled cell on placement        |
| `POINTS_PER_CLEARED_CELL` | 2       | Score gained per cleared cell (line / quadrant)  |
| `MAX_AD_REWARDS`          | 2       | ADReward uses available per game-over screen     |

**Combo formula** (`GameState.compute_combo`):
combo events = rows cleared + columns cleared + quadrants cleared. The
combo multiplier equals the event count if it's `≥ 2`, otherwise `1` (no
combo). The match score is then `cells_cleared × POINTS_PER_CLEARED_CELL × combo`.

Sequence shown to the player on a placement+match turn:
1. Placement popup `+N` floats from the placed piece (yellow).
2. Cascade of bump-spin-shrink animations clears the matched cells.
3. **Combo popup** "COMBO xN" — letter-by-letter reveal at center, only if
   combo ≥ 2.
4. **Match popup** `+N` — large red elastic pop at the screen center.

---

## Score progress bar

Sits under the HUD. Visualizes how close the player is to the next score
milestone. Targets follow `25 × n² + 75 × n` (`100, 250, 450, 700, 1000, …`).
On a milestone:

1. Bar fills to max (with a small pulse).
2. Bar **drains** visibly to zero in the current range.
3. Target label updates to the next goal.
4. Bar starts climbing again from the new floor.

Plays `sfx_levelup` at the moment the milestone is hit. The current level
is purely derived from the saved score, so saved runs always restore the
correct bar state.

---

## On-boarding tutorial

Plays only on the very first launch (gated by
`SaveManager.is_tutorial_completed()`). Two scripted placements:

1. Two near-complete center rows, a 2-block vertical piece in the central
   slot. The player drops it on column 4 to clear both rows at once.
2. Center 3×3 quadrant nearly full (one missing cell), a single block in
   the central slot. The player drops it on the empty cell to clear the
   quadrant.

A `tutorial_cursor.png` (mounted as a `TextureRect`) plus a translucent
ghost copy of the piece animate the suggested drag in a loop until the
player makes the move. Other slots are locked (`PieceSlot.set_locked`) and
only the scripted target origin is accepted on drop. After step 2 the flag
is persisted and the regular gameplay starts.

To force the tutorial again during development, run
`SaveManager.set_tutorial_completed(false)` from a debug action or just
delete `user://save.cfg`.

---

## Save system

`SaveManager` writes a `ConfigFile` to `user://save.cfg` with three
sections:

* `[progress]` — `best_score`, `tutorial_completed`.
* `[audio]` — per-bus volumes (Music, SFX, Master).
* `[game]` — full snapshot of the active run:
  * `score`
  * `grid` — list of `{x, y, color}` for every occupied cell.
  * `slots` — three entries (or `null`); each entry has `cells` (the
    shape) and `color`.

Save points:
* End of every settled turn (post placement + clears + refill).
* After an ADReward continuation.
* Cleared on Restart Game (Settings) or Restart (Game Over) or game over.

Resume points: `Game._ready()` calls `_load_saved_game()` if a snapshot
exists, restoring score, grid and slots without animation, then
`progress_bar_widget.refresh_from_state()` snaps the bar to its level.

---

## How to add a new piece

Pieces are pure data. Each one is a `.tres` of type **`PieceShape`**:

1. In the Godot FileSystem dock, right-click `Resources/Data/Pieces/` →
   *New Resource…* → choose **PieceShape**.
2. Fill in:
   * `cells` — a list of `Vector2i` offsets that compose the shape.
     Example for an `L`: `(0,0), (0,1), (0,2), (1,2)`.
   * `display_name` — used only in the editor.
   * `weight` — pick probability (higher = more frequent). Use `0` to
     temporarily disable a piece.
3. **Append the resource path to `PieceLibrary.PIECE_PATHS`** (top of
   `Scripts/PieceLibrary.gd`). On HTML5 builds Godot can't enumerate
   `res://` directories at runtime, so the explicit registry is what
   actually loads the pieces in the browser. The editor / desktop runs
   also fall back to a `DirAccess` scan for safety, but the registry is
   the authoritative source.
4. Save and run.

To add **rotated variants**, just create a new `.tres` with the cells
already rotated (no runtime rotation system is needed for a Woodoku-style
game).

---

## Theme & re-skinning

Two layers of restyling:

1. **`Resources/Theme/main_theme.tres`** — project-wide `Theme` registered
   in `project.godot` under `gui/theme/custom`. Edit it to restyle every
   `PanelContainer`, `Button`, and `Label` in one place:
   * `PanelContainer/styles/panel` — overlay panels (Settings, GameOver).
   * `Button/styles/{normal,hover,pressed,disabled,focus}` — all buttons
	 in menus / overlays. The disabled/focus styles are reused from
	 hover/disabled to keep the file compact.
   * `Button/colors/{font_color,font_outline_color,font_shadow_color}` and
	 constants — outline 8 px and a 2 px drop shadow are applied to
	 every Button.
   * `Label/colors/{font_color,font_outline_color,font_shadow_color}` and
	 constants — same outline + shadow defaults applied to every Label.

2. **`Resources/Data/default_theme.tres`** — gameplay-specific
   `ThemeConfig`:
   * `piece_colors` — palette used by the tray to tint freshly drawn
	 pieces.
   * `quadrant_dark_tint` / `quadrant_light_tint` — modulate applied to
	 the alternating 3×3 quadrant backgrounds.
   * `cell_empty_tint` — tint of empty cells.
   * `preview_valid_tint` — translucent ghost shown on a valid drag.
   * `preview_clear_highlight` — flash color used on cells that would be
	 cleared by the projected placement.

The `block.png` sprite is intentionally a white block, so changing
`piece_colors` recolors the whole game.

---

## Replacing assets

Every visible texture is referenced by a `TextureRect` / `TextureButton` /
`NinePatchRect` in a `.tscn`. Just replace the file in `Assets/` (or
`Audio/` for sounds) and Godot will reimport it. Path-based references —
no UID dependency, so swapping files is non-destructive.

The buyer will typically want to provide their own:

* `block.png`, `cell_empty.png`, `quadrant_bg_dark.png`, `quadrant_bg_light.png`
* `piece_slot.png` (NinePatch background of each tray slot)
* `logo.png` (rendered on the splash and in the menu)
* Icon set under `Assets/Icons/` (the template references `menuList.png`,
  `trophy.png` and `cross.png` in the HUD / overlays — feel free to swap).
* `tutorial_cursor.png` (the pointing-hand cursor used during the
  on-boarding tutorial).
* Audio (`Audio/SFX/*.wav`, `Audio/Music/music_loop.ogg`). Names expected
  by `AudioManager.SFX_LIBRARY`:
  `sfx_pick`, `sfx_drop`, `sfx_invalid`, `sfx_clear`, `sfx_combo`,
  `sfx_button`, `sfx_popup`, `sfx_populateSlot`, `sfx_levelup`,
  `sfx_gameover`, `sfx_timeout`.

If you also configure audio buses called `Music` and `SFX` (Project →
Audio Buses), the volume sliders in the Settings overlay will route to
them automatically; otherwise everything plays on `Master`.

---

## Integrating a real ad SDK

The Game-Over overlay's **Watch Ad** button is a stub. The integration
hook lives in `Scenes/Game/Component/Overlays/GameOverOverlay.gd` inside
`_on_ad_pressed()`:

```gdscript
# TODO: integrate AdMob / equivalent here. For now we simulate a reward
# after a short delay so the integration point is obvious.
```

Replace the `await get_tree().create_timer(0.5).timeout` with an actual ad
plugin call. On success, keep the existing
`GameState.consume_ad_reward()` + `ad_reward_granted.emit()` calls so the
rest of the game (limit-of-two-uses, single-block refill) keeps working.

The cap is `GameState.MAX_AD_REWARDS` — edit it there if you need a
different limit.

---

## Camera shake

The screen rumbles after a successful match and at every score-progress
milestone. The shake offsets the `Viewport.canvas_transform`, so all
in-game elements (grid, tray, HUD, placement popups) shake together,
while `CanvasLayer`-based UI (Settings overlay, GameOver overlay, the
match popup) stays still — perfect for keeping numbers readable.

Inspector knobs on `Game.tscn` (`Game.gd` script):

| Property              | Default | Effect                                                  |
|-----------------------|---------|---------------------------------------------------------|
| `shake_base_strength` | 12.0 px | Per-combo offset amplitude (set to 0 to disable shake)  |
| `shake_base_duration` | 0.40 s  | Total duration with linear decay                        |
| `shake_max_combo`     | 6       | Cap of the strength multiplier                          |
| `shake_levelup_combo` | 3       | Fixed "combo equivalent" used on score-bar level-ups    |

So a single-event clear feels like a 12 px / 0.40 s tap, a x2 combo gives
24 px, x3 → 36 px, and any score milestone fires the level-up shake at
the same intensity as a x3 combo (with the chosen default).

---

## Tutorial flow & lockouts

While the on-boarding tutorial is running:

* The `Settings` button on the HUD is disabled and dimmed (`hud.settings_button.disabled = true`)
  so the player can't open the menu mid-lesson. It's restored on tutorial
  completion.
* Drops on any cell other than the scripted target bounce back (with
  `sfx_invalid`).
* The viewport `size_changed` signal is wired so the cursor + ghost
  animation re-anchor themselves on resize/orientation change.
* Saves and stat updates are paused — the run-state snapshot only kicks
  in on the first real turn after the tutorial completes.

---

## HTML5 / iOS Safari notes

Two production-relevant browser quirks the template already handles, but
worth knowing if you extend the code:

1. **`DirAccess.open("res://...")` returns null** under HTML5 — the PCK
   filesystem is virtualized and not always listable. `PieceLibrary`
   loads its `.tres` from a hard-coded `PIECE_PATHS` list to work around
   this. **Add new pieces to that list** or they'll silently disappear
   on the web build.
2. **`tween.finished` is sometimes dropped on iOS Safari**, which would
   leave coroutines awaiting forever. Every awaited tween in the
   pipeline (`Grid.clear_cells`, `ScorePopup.play / play_match /
   play_combo`, `ElasticOverlay.open / close`, `FadeTransition.fade_to`)
   uses `await get_tree().create_timer(duration).timeout` instead.
   Animations still run via the tween, the timer is purely a safety
   `await`. Apply the same pattern if you add new awaited tweens.

---

## Debug shortcut

Pressing **`Q`** at any time **in a debug build** wipes the entire
`user://save.cfg` (best score, audio volumes, in-progress run, tutorial
flag) and returns to the splash so the player goes through the full
first-launch flow again. The shortcut is a no-op in release builds — see
`SaveManager._unhandled_key_input`. Useful while iterating on the
tutorial, the level curve, or save/load behavior.

---

## Exporting to HTML5

1. Install the Web export template (`Editor → Manage Export Templates`).
2. `Project → Export → Add… → Web`.
3. Tick **Embed PCK**, set **VRAM Compression / For Mobile** if targeting
   phones.
4. Hosting requires HTTPS + the `Cross-Origin-Opener-Policy` and
   `Cross-Origin-Embedder-Policy` headers set to `same-origin` and
   `require-corp` — itch.io and most modern hosts set these by default.

The `user://save.cfg` file is automatically backed by IndexedDB on Web,
so best score, tutorial flag and in-progress run all persist.

---

## License

The source code, scenes, scripts, shaders and project configuration of
this template are released under the **MIT License** — see
[`LICENSE`](LICENSE) for the full text. In short:

* ✅ Build commercial or free games on top of this template, ship them on
  any platform — no royalties, no attribution required.
* ✅ Modify, fork, share with your collaborators, version-control freely.
* ❌ You may NOT repackage and resell the template itself (or a fork of
  it) as a starter kit / asset pack. **One purchase = unlimited games
  you can ship**, not unlimited copies of the template you can resell.

The font **Alegreya** (in `Assets/Fonts/Alegreya-ExtraBold.ttf`) is
licensed under the [SIL Open Font License v1.1](OFL.txt). It can be
embedded in your exported games freely, including commercial ones — the
only constraint is that you don't rename the `.ttf` while changing its
"Reserved Font Name" tag.

Any third-party icons, audio or textures the buyer drops into the
project remain under their own licenses; please verify and credit them
in your own game's credits file.

A short third-party inventory is provided in [`CREDITS.md`](CREDITS.md).

---

## Known limitations / hand-offs for the buyer

* Audio buses `Music` and `SFX` must be created manually in the editor's
  Audio panel for the volume sliders to take effect (otherwise they fall
  back to `Master`). Save the layout as `default_bus_layout.tres` once
  done — this is a one-time setup.
* The ADReward callback is a stub — see *Integrating a real ad SDK* above.
* The studio name shown on the splash and the version string in the menu
  bottom-left are exposed via `@export var project_name` /
  `@export var version` on `MainMenu.gd`. Edit them from Inspector.

Have fun!
