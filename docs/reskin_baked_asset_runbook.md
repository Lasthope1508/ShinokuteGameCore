# Baked Asset Cleanup Runbook

Use this before cleaning any approved asset that contains baked sample data such as numbers, placeholder text, watermarks, guide marks, labels, or demo UI values.

## Rule

The baked source is the strongest visual reference. Do not redraw, paint over, or locally fake cleanup first.

Required order:

1. Keep the original baked asset unchanged as source evidence.
2. Use that exact baked asset as the 9Router image/reference input.
3. Prompt for a minimal edit: remove only the baked sample content and preserve shape, star/icon marks, frame, material, lighting, color, padding, and transparent-safe edges.
4. Save the raw 9Router output under `assets/themes/<theme>/source/`.
5. Run Photoroom on the full 9Router output through Chrome CDP port `9223` before any crop or trim if background/alpha is needed.
6. Trim only from the Photoroom alpha output, with small padding.
7. QA mode, alpha extrema, edge foreground ratio, dimensions, and visual readability.
8. Integrate only after manifest/checklist/state record source, raw output, Photoroom output, final output, QA path, and validation proof.

## Forbidden

- Do not do local Pillow/paint/chroma-key cleanup first.
- Do not crop the baked source before 9Router or Photoroom.
- Do not grid-slice baked sheets.
- Do not treat a locally cleaned fallback as production unless the owner explicitly approves fallback because 9Router or Photoroom is unavailable.
- Do not delete the baked original; keep it as reference evidence.

## Prompt Shape

Use direct edit language:

```text
Use the provided image as the exact reference. Remove only the baked sample numbers/text/marks from the clear content area. Preserve the original frame silhouette, icon/star marks, material style, lighting, color palette, padding, and proportions. Do not redesign the asset. Do not add new text.
```

For text-bearing production assets, include the exact final text only when the owner has approved that text.

## QA Checklist

- Original baked source exists.
- 9Router raw output exists.
- Photoroom full-image/full-sheet output exists when alpha is needed.
- Final output is `RGBA` if transparency is expected.
- Alpha extrema include `0` and `255`.
- Edge foreground ratio is low enough that foreground is not cut off.
- Baked sample content is gone.
- Desired design content is still preserved.
- Manifest names this as `9Router reference edit from baked source, then Photoroom full-image alpha, then trim/QA`.

## Current Example

HUD frame cleanup:

- Source: `assets/themes/candy_sky_islands/hud_score_frame.png`
- 9Router raw: `assets/themes/candy_sky_islands/source/hud_score_frame_clean_9router_raw.png`
- Photoroom output: `assets/themes/candy_sky_islands/source/hud_score_frame_clean_9router_photoroom.png`
- Final: `assets/themes/candy_sky_islands/hud_score_frame_clean_9router.png`
- QA: `assets/themes/candy_sky_islands/hud_score_frame_clean_9router_qc.json`
