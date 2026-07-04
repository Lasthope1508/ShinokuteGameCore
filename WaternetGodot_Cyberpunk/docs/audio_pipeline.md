# Audio Pipeline

Purpose: keep BGM and SFX theme-driven, mobile-ready, and no-fallback.

## Owner Decisions

- BGM source: `C:\Users\Admin\Desktop\Godot Casual Games\Audio\Music\Neon_Surge_Loop_*.wav`.
- BGM assembly: sort by filename, trim trailing silence from each file, concatenate into one nonstop loop.
- BGM mobile encode for publish: OGG Vorbis, mono, 44.1kHz, quality 0. This is the package-size profile for mobile and HTML5.
- BGM output: `res://Audio/Music/cyberpunk_theme/Gameplay.ogg`.
- BGM manifest: `res://Audio/Music/cyberpunk_theme/manifest.json`.
- SFX source: `C:\Users\Admin\Desktop\Godot Casual Games\Audio\SFX\Arrows\Cyber`.
- SFX output root: `res://Audio/Sfx/cyberpunk_theme`.

## SSOT

- `ThemeConfig.bgm_path`: active theme BGM path.
- `ThemeConfig.bgm_manifest_path`: BGM build manifest path.
- `ThemeConfig.bgm_mobile_sample_rate`, `bgm_mobile_channels`, `bgm_vorbis_quality`: mobile publish encode contract.
- `ThemeConfig.sfx_event_paths`: canonical event name to concrete audio file.
- `ThemeConfig.sfx_event_volume_offsets`: per-event mix offset in dB.
- `ThemeConfig.sfx_event_pitch_variation`: per-event default pitch variation.

## Canonical Events

- `ui_button`: generic UI button.
- `ui_popup`: modal/profile popup.
- `pipe_rotate`: valid pipe or endpoint rotation.
- `invalid_rotate`: invalid input.
- `energy_enter_tile`: energy first enters a tile.
- `energy_connect_segment`: powered path extends or connects a segment.
- `disconnect`: powered path breaks.
- `target_reached`: target receives energy.
- `win`: solved celebration.
- `reset`: level reset.
- `timeout`: timed mode timeout, if enabled later.
- `gameover`: fail state, if enabled later.

## No Fallback

- `AudioManager` resolves BGM only through `ThemeConfig.bgm_path`.
- `ThemeManager.get_sfx(...)` resolves SFX only through `ThemeConfig.sfx_event_paths`.
- Missing audio should return null and warn. Do not fall back to `Audio/Sfx/default` or root `Audio/Music/Gameplay.ogg`.
- `AudioManager` owns canonical runtime buses `Music` and `SFX`; music and SFX players must route directly to those buses, not silently fall back to `Master`.
- Settings Music/SFX toggles must change the real `Music`/`SFX` bus state and update button labels in the same click path.
- Settings Master Audio toggles `Music` and `SFX` together. `Master` must not be used as a hidden mute gate because stale saved `Master = 0` can make the game silent while Music/SFX labels show ON.

## Build Command Shape

- Trim each BGM WAV with trailing silence removal.
- Resample BGM to 44.1kHz mono for publish.
- Concatenate deterministic sorted sources.
- Encode final BGM as Vorbis quality 0, 44.1kHz mono. This keeps the nonstop loop under the mobile BGM budget without shortening the owner-approved arrangement.
- Encode SFX as Vorbis quality 4, 44.1kHz stereo, one file per canonical event.

## Web Audio Runtime

- `default_bus_layout.tres` is the canonical runtime bus SSOT. It must define `Music` and `SFX`, and `project.godot` must point `[audio] buses/default_bus_layout` at it.
- Selected-resource exports must include `res://default_bus_layout.tres`. Do not rely on `AudioServer.add_bus()` as the only way to create production Web buses.
- Web export must use the Godot default HTML shell: `html/custom_html_shell=""`.
- Web export must not inject custom audio JavaScript: `html/head_include=""`.
- do not wrap AudioContext, webkitAudioContext, or Godot WebAudio internals. The working Bloxchain export uses the default Godot shell with no AudioContext wrapper; wrapping it can make Godot report `AudioStreamPlayer.playing == true` while browser output stays silent.
- Do not add click-to-start overlays, delayed `setTimeout(startGame)`, or manual WebAudio gates before `engine.startGame(...)`.
- `Resources/Web/glyphflow_web_shell.html` is archived reference only unless a future owner-approved browser issue requires a new shell. It must not be wired into export presets without a failing browser-audio reproduction and a passing audible verification.
- Settings labels and `AudioStreamPlayer.playing` are not proof of audible output. Web verification must include a cache-busted HTML run, one real pointer click after load, and owner audible confirmation.
- `default_bus_layout.tres` must stay wired in `project.godot` under `[audio] buses/default_bus_layout="res://default_bus_layout.tres"` and must be included in selected-resource Web/Android exports.
- Do not reuse archived bad DTS BGM builds. The broken file had non-monotonic DTS warnings and could show waveform while staying silent in Web/Godot. Regenerate from WAV sources with the canonical ffmpeg command shape instead.
- Web builds must unlock audio inside Godot, not with custom JS. `AudioManager._input()` handles the first mouse/touch/key event on Web and restarts the BGM stream from its current playback position. This covers the browser case where Godot reports `AudioStreamPlayer.playing == true` before audible output is actually unlocked.
- Web debug state in `document.documentElement.dataset.glyphflowAudioDebug` must expose `web_audio_unlock_attempted` and `web_audio_unlock_input_count` so packaging agents can verify that a real user gesture reached `AudioManager`.

## Web Audio Incident 2026-07-03

Symptom:

- Standalone browser probe could play the regenerated `Gameplay.ogg`.
- Exported Godot Web game showed `AudioStreamPlayer.playing == true`, `AudioStreamOggVorbis`, valid `Music/SFX/Master` buses, and unmuted volumes, but owner heard no audio.
- Reopening `glyphflow_arrays.html?v=...` still served stale behavior because the HTML query string did not force a new fixed-name `.pck`.

Root causes:

- Old BGM encode had non-monotonic DTS warnings and was unsafe for browser/Godot Web playback. It was archived outside the project and replaced by a clean Vorbis q0 44.1kHz mono build.
- Godot Web could mark BGM as playing before browser audible output was unlocked by a user gesture.
- Firebase cache policy did not prevent stale fixed-name Godot Web runtime files from being reused.

Required fix pattern:

- Keep `AudioManager._input()` web-only first-gesture unlock. On first mouse/touch/key event it restarts the BGM stream from the current playback position inside Godot.
- Keep `default_bus_layout.tres` wired from `project.godot` and included in selected-resource exports.
- Keep Firebase `Cache-Control: no-cache, no-store, must-revalidate` for `.html`, `.pck`, `.js`, and `.wasm`, or export with a new basename when sending an owner test link.
- Do not add custom `AudioContext` wrappers, custom HTML shells, click-to-start overlays, or fallback audio paths to work around this.

Verification evidence required after any Web audio/export change:

- Run `test_web_audio_unlock_contract.gd`, `test_audio_debug_state_contract.gd`, `test_audio_bus_layout_contract.gd`, `test_theme_audio_ssot.gd`, and `test_export_packaging_contract.gd`.
- Export with Godot, not by hand-editing exported files.
- Scan `.pck` for forbidden debug/raw/fallback markers.
- Deploy or serve with fresh/no-store runtime files.
- Open Web game, make one real click/touch/key input, and verify `document.documentElement.dataset.glyphflowAudioDebug` changes from `web_audio_unlock_attempted=false` to `true` with `web_audio_unlock_input_count=1`.
- Owner audible confirmation is the final proof. Debug state alone is not enough.

## Verification

- Run `test_theme_audio_ssot.gd`.
- Run `test_audio_no_fallback_contract.gd`.
- Run `test_no_runtime_fallback_contract.gd`.
- Run `test_web_audio_unlock_contract.gd`.
- Use `ffprobe` on `Audio/Music/cyberpunk_theme/Gameplay.ogg` and verify `vorbis`, `44100`, `1 channel`, and size under `AssetBudgetConfig.bgm_mb`.
- Use `ffprobe` on every `Audio/Sfx/cyberpunk_theme/*.ogg` and verify `vorbis`, `44100`, `2 channels`.
- Open visible Godot debug with `res://Scenes/Gameplay/GameScene.tscn` and listen for BGM loop plus rotate/target SFX.

## Closed Cyber Audio Checklist

- [x] Owner chose BGM source folder and Cyber SFX folder.
- [x] Owner chose deterministic BGM assembly: filename sort, trim trailing silence per source file, concatenate nonstop.
- [x] Publish optimization pass set BGM encode: OGG Vorbis, 44.1kHz, mono, quality 0; current clean output is 2.96 MiB / 3,102,013 bytes for the 479.78s nonstop loop.
- [x] BGM generated at `res://Audio/Music/cyberpunk_theme/Gameplay.ogg`.
- [x] BGM manifest generated at `res://Audio/Music/cyberpunk_theme/manifest.json`.
- [x] SFX generated at `res://Audio/Sfx/cyberpunk_theme`, one OGG per canonical event.
- [x] Audio paths, mobile encode metadata, per-event volume offsets, and per-event pitch variation live in `ThemeConfig` plus `cyberpunk_theme.tres`.
- [x] `AudioManager` and `ThemeManager` use theme SSOT only.
- [x] No runtime fallback to default SFX or root BGM.
- [x] `Music` and `SFX` buses are canonical runtime buses from `default_bus_layout.tres`, loaded by `project.godot`, and settings toggles are covered by `test_settings_modal_audio_contract.gd`.
- [x] Settings exposes `MASTER AUDIO ON/OFF`; it toggles both canonical buses and clears legacy hidden Master mute state.
- [x] Web first-gesture audio unlock lives in `AudioManager._input()` and restarts BGM without custom AudioContext wrappers.
- [x] Gameplay rotate event uses `pipe_rotate`.
- [x] Gameplay solved target event uses `target_reached`.
- [x] Godot import completed after audio generation.
- [x] Contract tests passed: `test_theme_audio_ssot.gd`, `test_audio_no_fallback_contract.gd`, `test_no_runtime_fallback_contract.gd`, `test_gameplay_interaction_contract.gd`, `test_game_scene_vfx_polish_hooks.gd`.
- [x] Visible Godot debug opened for owner audio check.
