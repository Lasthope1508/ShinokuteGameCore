# Cyber UI Style Trials

Purpose: define 9Router style trials for the cyber gameplay UI before production asset slicing. Use the same reference pack for all trials so background, fake3D tray, playboard, pipe energy, buttons, and modal frames stay visually synchronized.

Operational runbook:

- `docs/9router_ui_generation_runbook.md`

## Reference Pack

R2 manifest:

- `docs/ui_cyber_reference_pack_r2.json`

Reference URLs:

- Current gameplay/playboard: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-ref/current_cyber_gameplay.png`
- Cell tile: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-ref/cyber_cell_bg.png`
- Lightning/VFX tone: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-ref/cyber_lightning_preview.png`
- Pipe I: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-ref/cyber_pipe_i.png`
- Pipe L: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-ref/cyber_pipe_l.png`
- Pipe T: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-ref/cyber_pipe_t.png`
- Pipe X: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-ref/cyber_pipe_x.png`
- Source: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-ref/cyber_source.png`
- Target: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-ref/cyber_target.png`
- Owner layout ratio reference: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-ref/owner_reference_layout.jpg`
- Project logo: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-ref/project_logo.png`

## Shared Style Anchor

Use this exact anchor in every 9Router generation prompt:

`cyber pipe puzzle, fake3D cockpit layer, black and deep green gameplay tone, cyan electric accent, glossy beveled sci-fi material, readable premium mobile game UI, coherent scale with existing pipe sprites, no placeholder text, no fake logo, no extra gameplay pieces`

## Trial Output

Each trial generates one full-screen concept mockup, not production slices.

Canvas:

- Portrait: `720x1280` design intent.
- 9Router request size: `1024x1792` if available; otherwise closest portrait size supported by `cx/gpt-5.5-image`.

Mockup layout requirements:

- Top tray at 16% to 19% viewport height.
- Top tray reads as one fake3D layer floating over the gameplay area, not a closed rectangle.
- Purple floating menu button on the left.
- Yellow floating replay button on the right.
- Small inner capsule for score/readout/avatar/logo.
- Real project logo used only as visual reference; do not invent text.
- 5x5 to 10x10 board area kept quiet and readable.
- Bottom reserve exists but stays visually secondary.

Negative requirements:

- No text labels except tiny abstract unreadable UI marks.
- No waternet placeholder.
- No characters.
- No pipes drawn into UI tray/background.
- No loose tile-like stat cards.
- No bright green background fighting gameplay energy.
- No one-note purple-only palette.

## Trial A. Neon Circuit Cockpit

Intent:

- Strongest fit for current cyber pipe art.
- UI feels like a floating circuit console above a dark tech board.
- Background: subtle black/deep-green circuit depth, quiet behind board.
- Accents: cyan electric edges, tiny lime energy glints, purple/yellow utility buttons.

Prompt:

`Using the reference images, create a premium mobile puzzle game UI concept mockup. Style anchor: cyber pipe puzzle, fake3D cockpit layer, black and deep green gameplay tone, cyan electric accent, glossy beveled sci-fi material, readable premium mobile game UI, coherent scale with existing pipe sprites, no placeholder text, no fake logo, no extra gameplay pieces. Portrait gameplay screen. Top HUD is a single floating fake3D cockpit tray layer, overflowing edges slightly, with a smaller inner capsule for stats and centered logo socket. Purple floating menu button left, yellow floating replay button right. Center gameplay board area is quiet and readable for a square pipe grid with existing black-green cyber tiles and cyan-green energy. Bottom area reserves space but stays secondary. Background is subtle deep cyber circuitry with soft parallax depth, not busy. No characters, no readable text, no random pipes in UI, no tile-like stat cards.`

Risk:

- Can become too tech-grid flat if bevel/depth is weak.

## Trial B. Industrial Reactor Bay

Intent:

- More physical fake3D depth.
- UI feels like metal panels around a reactor board.
- Good if owner wants stronger object/material feeling.

Prompt:

`Using the reference images, create a premium mobile puzzle game UI concept mockup. Style anchor: cyber pipe puzzle, fake3D cockpit layer, black and deep green gameplay tone, cyan electric accent, glossy beveled sci-fi material, readable premium mobile game UI, coherent scale with existing pipe sprites, no placeholder text, no fake logo, no extra gameplay pieces. Portrait gameplay screen inside a dark futuristic reactor bay. Top HUD is a floating beveled metal console layer with cyan edge light and soft shadow, not a closed rectangle. Purple floating menu button left, yellow floating replay button right. Center logo socket rises above the tray. Gameplay board zone is clean, dark, and readable, with enough breathing room for glow and lightning VFX. Bottom reserve is a shallow metallic ledge. No characters, no readable text, no extra pipes in background, no bulky frame around the board.`

Risk:

- Can look too heavy and reduce board primacy.

## Trial C. Holographic Terminal

Intent:

- Lightest UI, best readability.
- Top tray feels like transparent holographic glass, less physical.
- Good if VFX should dominate.

Prompt:

`Using the reference images, create a premium mobile puzzle game UI concept mockup. Style anchor: cyber pipe puzzle, fake3D cockpit layer, black and deep green gameplay tone, cyan electric accent, glossy beveled sci-fi material, readable premium mobile game UI, coherent scale with existing pipe sprites, no placeholder text, no fake logo, no extra gameplay pieces. Portrait gameplay screen. Top HUD is a semi-transparent holographic cockpit layer floating above the board, with beveled glass rim, cyan glow, and deep shadow to preserve fake3D depth. Purple floating menu button left, yellow floating replay button right. Center logo socket breaks the silhouette upward. Board region remains dark and quiet for a cyber pipe puzzle. Bottom reserve is subtle glass/metal. No characters, no readable text, no random UI cards, no bright clutter.`

Risk:

- Can become too flat/transparent if shadow and material are weak.

## Trial D. Bright Cyber Lab

Intent:

- Test a brighter cyber theme while preserving the existing black/dark graphite pipe sprites.
- Make background, tray, board tiles, and bottom reserve feel like a clean luminous sci-fi lab.
- Let VFX shift toward icy cyan, white-blue, and tiny lime glints because most live VFX colors are theme-driven.

VFX color constraint:

- Existing pipe sprites cannot change color without regenerating the pipe assets.
- Procedural live VFX colors can change through `ThemeConfig` fields consumed by `Scripts/pipe_vfx_layer.gd`.
- Changeable live VFX includes contact spark, trail, path wave, energy stream, target pulse, source emission, idle hum, disconnect decay, error spark, rotation spark, win burst, and lightning modulation.
- Static energy overlay sheets are PNG/atlas based; they are not a clean hue-change target unless regenerated or routed through a future shader.
- Current cyber pipe-body static overlay is disabled, but target energy overlay can still use baked sheet pixels.
- Bright cyber should therefore use cyan/icy-white procedural VFX and avoid depending on recolored pipe sprites.

Prompt:

`Using the reference images, create a premium mobile puzzle game UI concept mockup for a BRIGHT cyber theme variant. Important constraint: do not change the existing pipe sprite colors or material; the pipes stay black/dark graphite with silver metal rims exactly like the reference pipe sprites. Only the background, UI panels, tray material, playboard surface, and procedural VFX color treatment may become brighter. Style anchor: bright cyber pipe puzzle, fake3D cockpit layer, clean luminous sci-fi lab, pearl white and pale mint surfaces, deep graphite pipe sprites unchanged, icy cyan electric accent, small lime energy accents, glossy beveled sci-fi material, readable premium mobile game UI, coherent scale with existing pipe sprites, no placeholder text, no fake logo, no extra gameplay pieces. Portrait gameplay screen. Top HUD is a single floating fake3D cockpit tray layer, overflowing edges slightly, with a smaller inner capsule for stats and a centered logo socket. Center logo socket must be empty or use the uploaded project logo shape only. No mascot, no robot, no face, no character, no avatar. Purple floating menu button on the left, yellow floating replay button on the right. Center gameplay board area is quiet and readable for a square pipe grid; keep the black cyber pipe sprites visually unchanged and high-contrast. VFX may read as icy cyan, white-blue, and tiny lime glints because the implementation has procedural VFX colors, but do not recolor the pipe sprites. Bottom area reserves space but stays secondary. Background is bright cyber lab glass and soft circuit depth, not flat white, not busy. No readable text, no random pipes in UI, no tile-like stat cards.`

Risk:

- Bright tile surfaces may reduce contrast if final Godot board uses lighter cell assets without enough border/shadow.
- VFX can be recolored, but baked energy sheets and target overlay require regeneration if exact hue matching is needed.

## Recommended First Trial

Start with Trial A.

Reason:

- It matches current black/green pipe board and cyan lightning best.
- It keeps the board readable while giving enough fake3D cockpit language for the top tray.
- It has the least risk of redesigning the pipe art direction.

## 9Router Request Shape

Use only `cx/gpt-5.5-image`. No fallback model.

Owner-approved key policy:

- Owner approved using `NINEROUTER_KEY` for image generation in this project on 2026-07-01.
- If `NINEROUTER_IMAGE_KEY` is missing, use `NINEROUTER_KEY` as the image authorization key.
- Keep `NINEROUTER_IMAGE_URL=https://img.teelab247.com`.
- This is an explicit project exception to the default 9Router image skill preference.
- Still use only `cx/gpt-5.5-image`.
- Still no fallback model or provider.
- Before generation, verify `/v1/models/image` lists `cx/gpt-5.5-image` with the approved key.

Binary output target:

- `Assets/UI/cyberpunk_theme/generated/style_trial_a_full_mockup.png`
- `Assets/UI/cyberpunk_theme/generated/style_trial_b_full_mockup.png`
- `Assets/UI/cyberpunk_theme/generated/style_trial_c_full_mockup.png`

After owner approves one trial:

1. Record approved style in this doc.
2. Generate production slices from the approved mockup plus the same reference pack.
3. Run PhotoRoom for every non-background transparent object; chroma-key cleanup is preview-only.
4. Record each asset path, pixel size, anchor, draw rect, padding, and slice rule in SSOT.

## Generated Trials

### Trial A. Neon Circuit Cockpit

Generated on 2026-07-01.

Request:

- Model: `cx/gpt-5.5-image`.
- Key policy: owner-approved `NINEROUTER_KEY` project exception.
- Size requested: `1024x1792`.
- Output format: `png`.
- Reference count: 11 R2 images from `docs/ui_cyber_reference_pack_r2.json`.
- No fallback model or provider used.

Output:

- Local path: `Assets/UI/cyberpunk_theme/generated/style_trial_a_full_mockup.png`.
- R2 URL: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-trials/style_trial_a_full_mockup.png`.
- Pixel size: `941x1672`.
- Bytes: `2047293`.
- SHA256: `F8FDAF4752C337C1DC8B36BD18D69CFF95DCFBCF2CEAE07A03B1B989EB5F37C5`.

Visual audit:

- Strong match: cyber material language, glossy bevels, cyan accents, purple menu button, yellow replay button, readable board zone, bottom reserve.
- Risk: center logo socket contains a generated robot mascot. This violates the no-character and real-logo requirement.
- Risk: board and pipes are too literal in the full-screen concept; production slices must not replace canonical gameplay sprites.
- Owner decision needed: accept Trial A as style direction with logo-core regeneration, or regenerate Trial A with stricter no-character/logo-socket instruction.

### Trial D. Bright Cyber Lab

Generated on 2026-07-01.

Request:

- Model: `cx/gpt-5.5-image`.
- Key policy: owner-approved `NINEROUTER_KEY` project exception.
- Size requested: `1024x1792`.
- Output format: `png`.
- Reference count: 11 R2 images from `docs/ui_cyber_reference_pack_r2.json`.
- No fallback model or provider used.

Output:

- Local path: `Assets/UI/cyberpunk_theme/generated/style_trial_d_bright_cyber_lab.png`.
- R2 URL: `https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-trials/style_trial_d_bright_cyber_lab.png`.
- Pixel size: `941x1672`.
- Bytes: `2347801`.
- SHA256: `F332869464B092D8D1A8F6EC689741CBC661B29F82BE614A2B565333DE0077F5`.

Visual audit:

- Strong match: bright cyber lab tone, fake3D white tray, black pipes preserved, cyan/white VFX readable, purple menu, yellow replay, bottom reserve.
- Strong match: no generated character or mascot in the center logo socket.
- Risk: board and pipes are literal in the concept; production must keep canonical gameplay sprites and use generated art only for background/UI layers.
- Risk: if final board tiles become this bright, pipe shadows and tile borders need stronger SSOT contrast tokens.
- Owner decision needed: choose Trial D as bright cyber direction, or use it only as a secondary skin direction after dark cyber is finished.
