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

## Build Command Shape

- Trim each BGM WAV with trailing silence removal.
- Resample BGM to 44.1kHz mono for publish.
- Concatenate deterministic sorted sources.
- Encode final BGM as Vorbis quality 0, 44.1kHz mono. This keeps the nonstop loop under the mobile BGM budget without shortening the owner-approved arrangement.
- Encode SFX as Vorbis quality 4, 44.1kHz stereo, one file per canonical event.

## Verification

- Run `test_theme_audio_ssot.gd`.
- Run `test_audio_no_fallback_contract.gd`.
- Run `test_no_runtime_fallback_contract.gd`.
- Use `ffprobe` on `Audio/Music/cyberpunk_theme/Gameplay.ogg` and verify `vorbis`, `44100`, `1 channel`, and size under `AssetBudgetConfig.bgm_mb`.
- Use `ffprobe` on every `Audio/Sfx/cyberpunk_theme/*.ogg` and verify `vorbis`, `44100`, `2 channels`.
- Open visible Godot debug with `res://Scenes/Gameplay/GameScene.tscn` and listen for BGM loop plus rotate/target SFX.

## Closed Cyber Audio Checklist

- [x] Owner chose BGM source folder and Cyber SFX folder.
- [x] Owner chose deterministic BGM assembly: filename sort, trim trailing silence per source file, concatenate nonstop.
- [x] Publish optimization pass set BGM encode: OGG Vorbis, 44.1kHz, mono, quality 0; current output is 2.58 MB for the 479.78s nonstop loop.
- [x] BGM generated at `res://Audio/Music/cyberpunk_theme/Gameplay.ogg`.
- [x] BGM manifest generated at `res://Audio/Music/cyberpunk_theme/manifest.json`.
- [x] SFX generated at `res://Audio/Sfx/cyberpunk_theme`, one OGG per canonical event.
- [x] Audio paths, mobile encode metadata, per-event volume offsets, and per-event pitch variation live in `ThemeConfig` plus `cyberpunk_theme.tres`.
- [x] `AudioManager` and `ThemeManager` use theme SSOT only.
- [x] No runtime fallback to default SFX or root BGM.
- [x] Gameplay rotate event uses `pipe_rotate`.
- [x] Gameplay solved target event uses `target_reached`.
- [x] Godot import completed after audio generation.
- [x] Contract tests passed: `test_theme_audio_ssot.gd`, `test_audio_no_fallback_contract.gd`, `test_no_runtime_fallback_contract.gd`, `test_gameplay_interaction_contract.gd`, `test_game_scene_vfx_polish_hooks.gd`.
- [x] Visible Godot debug opened for owner audio check.
