# BloxChain Mobile HTML5 Asset Optimization Checklist

- Runtime exports must use explicit resources from `docs/runtime_asset_manifest.json`.
- `export_filter="all_resources"` is forbidden.
- Broad include filters like `*.png`, `*.webp`, `*.wav`, `*.ogg`, `*.tres`, and `Assets/**` are forbidden.
- Non-runtime folders such as `Export/`, `scratch/`, `debug/`, `.claude/`, `.agents/`, and generated Android payload folders must not enter release payloads.
- Runtime raw/source files such as `*_raw.png`, backup files, debug captures, and workbench media must not ship.
- Runtime texture policy: mobile-friendly imported textures with ETC2/ASTC available for Android and Web-safe compressed texture output.
- BGM publish policy: Ogg Vorbis looped music, no backup/source audio in release payload.
- Default budgets live in `docs/runtime_asset_manifest.json`.
