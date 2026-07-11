# Shinokute Albedo And Mask Prompt Lab

Goal: find a 9Router prompt/workflow that creates clean texture sources for the Shinokute 3D player without skin/hood/leg bleed.

## References

- Primary identity: `shinokute_idle_sign_pose_clean_ref.png`
- Anatomy/view reference: `docs/screenshots/shinokute_hunyuan_anatomy_turnaround_contact_sheet.png`
- Failure evidence: `docs/screenshots/shinokute_hunyuan_mv_anatomy_uv_skin_v5_candidate_preview/contact_sheet.png`

## Model And Key Rule

- Model: `cx/gpt-5.5-image`
- Use reference images on every call.
- Prefer `NINEROUTER_IMAGE_KEY`; owner-approved fallback is `NINEROUTER_KEY`, then `ROUTER_API_KEY`, without printing secrets.

## Attempt 1: Clean Albedo Turnaround

Prompt:

```text
Use the provided Shinokute character reference and anatomy turnaround reference. Create one clean orthographic character turnaround sheet for a 3D texture/modeling workflow.

Output exactly 8 full-body views in a tidy 4x2 grid, same character identity and outfit in every view:
front, front-right three-quarter, right side, back-right three-quarter, back, back-left three-quarter, left side, front-left three-quarter.

Pose: neutral relaxed A-pose / standing mannequin pose, arms slightly away from body, legs straight, feet fully visible, same height and proportions in all views.

Texture style: UNLIT FLAT ALBEDO SOURCE, not a rendered illustration. Use clean solid material colors with only minimal line art needed to identify folds and facial features. Remove all cast shadows and ambient occlusion from the reference. No baked lighting, no gradients on skin, no dark contact shadows on legs, no rim shadow around the body.

Character details to preserve: anime teenage boy, black messy hair, clean peach/tan skin, black hoodie with hood volume and white SHINOKUTE chest logo, black shorts ending above the knee, exposed skin thighs and calves, black socks below calf, red black white high-top sneakers.

Material separation rule: skin must stay continuous clean peach/tan on face, ears, neck, hands, thighs, knees, calves. Hoodie and hood collar stay black fabric. Shorts stay black fabric. Socks stay black. Shoes stay red/black/white. No skin color on hoodie/chest/collar. No black fabric smears on cheeks, neck, hands, thighs, knees, or calves.

Background: pure white, no labels, no shadows, no floor, no camera perspective distortion.

Negative: black smears on legs, dirty legs, dark patches on cheeks, black neck, white neck patch, skin-colored hoodie collar, skin on hoodie chest, missing neck, cropped feet, extra limbs, text labels outside the hoodie logo, watermarks, dramatic lighting, painterly shading, ambient occlusion, cast shadows, blurred edges, different outfit, different character.
```

Reject if:

- any exposed skin contains black smear bands,
- neck/collar turns white or skin spills onto hoodie,
- required views missing or cropped,
- source looks like lit illustration instead of albedo.

## Attempt 2: Material-ID Mask Turnaround

Prompt:

```text
Use the provided Shinokute character reference and anatomy turnaround reference. Create a material ID mask turnaround sheet for a 3D texture cleanup workflow.

Output exactly 8 full-body views in a tidy 4x2 grid, same character proportions and same views:
front, front-right three-quarter, right side, back-right three-quarter, back, back-left three-quarter, left side, front-left three-quarter.

This is not final art. It is a clean material segmentation mask. Use flat solid colors only:
skin = peach/tan
hair = pure black
hoodie and hood/collar/sleeves = dark charcoal black
shorts = near black
socks = pure black
shoe red panels = red
shoe white panels and soles = white
shoe black panels = black
hoodie logo = white
background = pure white

No shadows, no gradients, no lighting, no fabric texture, no line hatching, no dirty pixels. Keep hard clean borders between skin, hoodie, shorts, socks, and shoes. Face/neck/hands/thighs/calves must be skin color only. Hoodie collar/chest must be black only.

Negative: shaded illustration, cast shadow, ambient occlusion, black smear on skin, skin color on hoodie, white neck patch, gray dirty legs, missing feet, extra limbs, labels, watermark, perspective distortion.
```

Reject if:

- colors are not clean flat material regions,
- material borders are ambiguous,
- front/back/side views drift from Shinokute identity.

## Attempt 3: Skin-Mannequin Underlay

Prompt:

```text
Use the Shinokute reference. Create a clean character turnaround for 3D reconstruction where the anatomy under clothing is explicit and readable.

Output 8 full-body views in a 4x2 grid: front, front-right three-quarter, right side, back-right three-quarter, back, back-left three-quarter, left side, front-left three-quarter.

Use a neutral standing A-pose. Make skin regions simple and clean like a mannequin: face, ears, neck, hands, thighs, knees, calves are continuous flat peach/tan. Clothing is layered clearly above the body: black hoodie with visible hood thickness, black shorts above knee, black socks, red black white sneakers.

Unlit albedo only. Pure white background. No shadows, no lighting, no gradients, no dirt, no dark patches on skin.

Negative: black smears on skin, cast shadows copied from reference, white neck, hoodie painted as skin, legs painted as socks or shorts, missing side thickness, cropped feet, inconsistent character.
```

Reject if:

- mannequin skin is not clean,
- clothing layers do not read as separate materials,
- any view fails feet or silhouette.

## Results

### Attempt 1 Albedo

- Raw: `shinokute_albedo_turnaround_attempt1_raw.png`
- Photoroom: `shinokute_albedo_turnaround_attempt1_photoroom.png`
- Status: useful prompt direction, but Photoroom kept broad semi-transparent halo bands around the sheet.

### Attempt 1 Material ID

- Raw: `shinokute_material_id_turnaround_attempt1_raw.png`
- Photoroom: `shinokute_material_id_turnaround_attempt1_photoroom.png`
- Extracted pool: `material_id_turnaround_pool_attempt1/`
- QC: `shinokute_material_id_turnaround_attempt1_qc.json`
- Contact: `docs/screenshots/shinokute_material_id_turnaround_attempt1_contact_sheet.png`
- Status: accepted as material segmentation reference. Face is intentionally blank because it is a mask, not final art.

### Attempt 2 Albedo

- Raw: `shinokute_albedo_turnaround_attempt2_raw.png`
- Photoroom: `shinokute_albedo_turnaround_attempt2_photoroom.png`
- Extracted pool: `albedo_turnaround_pool_attempt2/`
- QC: `shinokute_albedo_turnaround_attempt2_qc.json`
- Contact: `docs/screenshots/shinokute_albedo_turnaround_attempt2_contact_sheet.png`
- Status: best current albedo source pool. It has clean skin, hood/collar separation, 8 views, and no large black skin smears in the source sprites.

Extraction method for accepted pools:

- Photoroom full generated sheet first.
- High-alpha connected component polygon masks from the Photoroom sheet.
- No raw-sheet crop.
- No automatic grid slicing.

### Projection Diagnostics

- Albedo projection candidate: `character_shinokute_hunyuan_mv_prompt_lab_albedo_attempt2_candidate.glb`
- Preview: `docs/screenshots/shinokute_hunyuan_mv_prompt_lab_albedo_attempt2_candidate_preview/contact_sheet.png`
- Status: rejected. Source sprites are cleaner, but naive UV projection still maps hoodie/short/shoe pixels into face and leg regions.

- Material-ID projection candidate: `character_shinokute_hunyuan_mv_prompt_lab_material_id_attempt1_candidate.glb`
- Preview: `docs/screenshots/shinokute_hunyuan_mv_prompt_lab_material_id_attempt1_candidate_preview/contact_sheet.png`
- Status: rejected. Clean material mask still smears when projected through the same naive UV mapping, proving the remaining issue is projection/bake alignment, not only prompt wording.

- Skin v5 cleanup on prompt-lab projection: `character_shinokute_hunyuan_mv_prompt_lab_albedo_attempt2_skin_v5_candidate.glb`
- Preview: `docs/screenshots/shinokute_hunyuan_mv_prompt_lab_albedo_attempt2_skin_v5_candidate_preview/contact_sheet.png`
- Status: rejected. Legs improve, but face/neck remain dirty/tinted.

- Skin v6 cleanup on prompt-lab projection: `character_shinokute_hunyuan_mv_prompt_lab_albedo_attempt2_skin_v6_candidate.glb`
- Preview: `docs/screenshots/shinokute_hunyuan_mv_prompt_lab_albedo_attempt2_skin_v6_candidate_preview/contact_sheet.png`
- Status: rejected. Lighter skin improves some regions but overpaints hoodie/chest, violating material separation.

- Skin v7 cleanup on prompt-lab projection: `character_shinokute_hunyuan_mv_prompt_lab_albedo_attempt2_skin_v7_candidate.glb`
- Preview: `docs/screenshots/shinokute_hunyuan_mv_prompt_lab_albedo_attempt2_skin_v7_candidate_preview/contact_sheet.png`
- Status: rejected. V7 keeps hoodie safer than v6 by using v5 gates and brighter skin, but projection dirt remains on face/hands and the result still reads dirty.

- Material-zone v8 cleanup on prompt-lab projection: `character_shinokute_hunyuan_mv_prompt_lab_material_zone_v8_candidate.glb`
- Preview: `docs/screenshots/shinokute_hunyuan_mv_prompt_lab_material_zone_v8_candidate_preview/contact_sheet.png`
- Status: rejected. Solid material zones reduce projection dirt, but an upper-chest beige patch remains, violating hoodie material separation.

- Material-zone v9 cleanup on prompt-lab projection: `character_shinokute_hunyuan_mv_prompt_lab_material_zone_v9_candidate.glb`
- Preview: `docs/screenshots/shinokute_hunyuan_mv_prompt_lab_material_zone_v9_candidate_preview/contact_sheet.png`
- Status: rejected. Chest patch is smaller but still visible.

- Material-zone v10 cleanup on prompt-lab projection: `character_shinokute_hunyuan_mv_prompt_lab_material_zone_v10_candidate.glb`
- Preview: `docs/screenshots/shinokute_hunyuan_mv_prompt_lab_material_zone_v10_candidate_preview/contact_sheet.png`
- Report: `shinokute_prompt_lab_material_zone_v10_candidate_report.json`
- Status: first no-bleed candidate. The skin, hoodie, shorts, socks, and legs are separated without visible skin spilling onto hoodie/chest or black shoe/short smears across exposed legs. It is not integrated into Godot. Tradeoff: face detail and hoodie logo/detail are reduced by the solid material-zone cleanup.

Current conclusion:

- Prompt workflow found a much cleaner source pool: albedo attempt 2 plus material-ID attempt 1.
- Current naive UV projection cannot be accepted even with clean prompt sources.
- A reliable no-bleed workflow now exists for candidate validation: 9Router reference-based albedo attempt 2 + 9Router material-ID attempt 1, Photoroom full sheets, high-alpha component polygon extraction, atlas build, then material-ID/SSOT zone cleanup on the projected Hunyuan mesh.
- For production quality, the next optional step is restoring identity detail safely: add a separate controlled hoodie-logo decal and face/detail pass after the no-bleed material-zone cleanup, or use a true texture pipeline such as Hunyuan Paint/native renderer when available. Do not return to blind prompt tuning unless the source pool itself is rejected.
- Requirement-by-requirement validation is recorded in `shinokute_prompt_lab_workflow_validation.json`. This validates the prompt/workflow goal and candidate outputs before Godot integration; it does not approve production integration.

### Rejected Image-Shell Geometry Diagnostic

- Candidate: `assets/themes/candy_sky_islands/models/character_shinokute_lentil_shell_candidate.glb`
- Script: `tools/create_shinokute_lentil_shell_candidate.py`
- Report: `assets/themes/candy_sky_islands/source/shinokute_player/shinokute_lentil_shell_candidate_report.json`
- QC: `assets/themes/candy_sky_islands/source/shinokute_player/shinokute_lentil_shell_candidate_qc.json`
- Preview: `docs/screenshots/shinokute_lentil_shell_candidate_preview/contact_sheet.png`
- Method: use the accepted albedo attempt 2 sprites directly as front/back curved shells plus side alpha-silhouette depth walls with SSOT material bands for fabric, skin, and shoes. Mesh rows follow the Photoroom alpha silhouette, main image materials use alpha clip, and there is no naive atlas UV projection onto the Hunyuan mesh.
- Status: rejected diagnostic candidate, not integrated into Godot.
- Pass evidence: front/back surfaces no longer show the prior UV-projection skin/hood/leg bleed; the large black side slab from the first shell attempt was removed; the duplicate side-sprite ghosting from the second shell attempt was removed.
- Fail evidence: side views now have material bands, but the bands are coarse and not a finished textured 3D side body.
- Owner decision: discard the two-half lentil shell / image-shell approach. Keep this GLB only as failure evidence. Do not use front/back shell, card-rig, billboard, or two-half bean geometry for production Shinokute character work.
- Next valid path: clean multiview inputs, owner-approved AI 3D generator or Blender plugin/API, Blender cleanup/retopo/UV/bake/auto-rig, then export FBX/GLB only after validation.
