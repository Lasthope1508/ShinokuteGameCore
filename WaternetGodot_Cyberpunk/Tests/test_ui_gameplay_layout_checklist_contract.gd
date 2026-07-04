extends SceneTree

func _init() -> void:
	var passed := true
	var checklist := FileAccess.get_file_as_string("res://docs/ui_gameplay_layout_checklist.md")
	var style_trials := FileAccess.get_file_as_string("res://docs/ui_cyber_style_trials.md")
	var r2_manifest := FileAccess.get_file_as_string("res://docs/ui_cyber_reference_pack_r2.json")
	var runbook := FileAccess.get_file_as_string("res://docs/9router_ui_generation_runbook.md")
	var component_design := FileAccess.get_file_as_string("res://docs/ui_cyber_dark_light_component_design.md")
	var component_refs := FileAccess.get_file_as_string("res://docs/ui_cyber_dark_light_component_refs_r2.json")
	var component_queue := FileAccess.get_file_as_string("res://docs/ui_cyber_9router_component_call_queue.md")
	var generation_manifest := FileAccess.get_file_as_string("res://docs/ui_cyber_component_generation_manifest.json")

	passed = passed and _assert_true(not checklist.is_empty(), "Gameplay UI layout checklist should exist")
	passed = passed and _assert_true(not style_trials.is_empty(), "Cyber UI style trial doc should exist")
	passed = passed and _assert_true(not r2_manifest.is_empty(), "Cyber UI R2 reference manifest should exist")
	passed = passed and _assert_true(not runbook.is_empty(), "9Router UI generation runbook should exist")
	passed = passed and _assert_true(not component_design.is_empty(), "Dark/light component design should exist")
	passed = passed and _assert_true(not component_refs.is_empty(), "Dark/light component R2 manifest should exist")
	passed = passed and _assert_true(not component_queue.is_empty(), "9Router component call queue should exist")
	passed = passed and _assert_true(not generation_manifest.is_empty(), "Component generation manifest should exist")

	for required_text in [
		"Owner approved B1 on 2026-07-01.",
		"Owner approved B2 on 2026-07-01.",
		"Board overdraw guard: proportional to cell size, not fixed pixels.",
		"Required B1 SSOT fields",
		"Approved B2 region model",
		"Top tray exists as a fake3D layer above gameplay.",
		"Bottom tray keeps an empty reserve",
		"Floating controls: purple menu on the left, yellow replay on the right.",
		"Do not start B3 asset generation until background direction is approved.",
		"Build a reference pack before generation.",
		"Upload reference pack to R2 for 9Router reference usage.",
		"Draft style trials for owner to choose the main style.",
		"Generate Trial A full-screen style mockup through 9Router.",
		"Upload Trial A mockup to R2.",
		"Record Trial A metadata and visual audit notes.",
		"Generate Trial D bright cyber mockup through 9Router.",
		"Upload Trial D mockup to R2.",
		"Record VFX color constraints for bright cyber.",
		"Accept both dark and light cyber directions as mode references.",
		"Crop dark/light component references from demo mockups.",
		"Upload dark/light component references to R2.",
		"Write dark/light component design and production order.",
		"Lock production component rule: object assets only, no poster/mockup output.",
		"Style sync requirements",
		"Reference pack must include owner reference image, current cyber pipe/cell screenshot, project logo, final pipe/cell sprites, and any approved mockup.",
		"Every 9Router prompt must repeat the same art direction anchor",
		"Production assets must be generated from the approved full-screen mockup or shared references, not isolated prompts.",
		"Current R2 reference manifest: `docs/ui_cyber_reference_pack_r2.json`.",
		"Current style trial doc: `docs/ui_cyber_style_trials.md`.",
		"9Router UI generation runbook: `docs/9router_ui_generation_runbook.md`.",
		"Dark/light component design: `docs/ui_cyber_dark_light_component_design.md`.",
		"Dark/light component R2 manifest: `docs/ui_cyber_dark_light_component_refs_r2.json`.",
		"Owner approved using `NINEROUTER_KEY` for image generation in this project on 2026-07-01.",
		"If `NINEROUTER_IMAGE_KEY` is missing, use `NINEROUTER_KEY` as the image authorization key.",
		"Before generation, verify `/v1/models/image` lists `cx/gpt-5.5-image` with the approved key.",
		"Generate through 9Router only after approval.",
		"Store asset sizes, anchors, draw rects, padding, and slice rules in SSOT.",
		"Write canonical 9Router component call queue for dark/light GUI assets.",
		"Lock rule: every production GUI component call must use R2 refs for style sync.",
		"Lock rule: future agents must extend the queue before generating new GUI parts.",
		"Lock rule: background assets require both portrait and landscape outputs.",
		"Generate dark/light `background_full_portrait` candidates.",
		"Generate dark/light `background_full_landscape` candidates.",
		"Upload background candidates to R2 and record generation manifest.",
		"Create dark/light portrait/landscape background preview sheet for owner approval.",
		"Generate dark/light `logo_socket` candidates.",
		"Create temporary magenta alpha candidates for `logo_socket`; production replacement must go through PhotoRoom before final approval.",
		"Upload `logo_socket` candidates to R2 and record generation manifest.",
		"Generate dark/light `stats_capsule` candidates.",
		"Create temporary magenta alpha candidates for `stats_capsule`; production replacement must go through PhotoRoom before final approval.",
		"Upload `stats_capsule` candidates to R2 and record generation manifest.",
		"Generate dark/light `floating_menu_button` state candidates.",
		"Create temporary magenta alpha candidates for `floating_menu_button`; production replacement must go through PhotoRoom before final approval.",
		"Upload `floating_menu_button` states to R2 and record generation manifest.",
		"Generate dark/light `floating_replay_button` state candidates.",
		"Create temporary magenta alpha candidates for `floating_replay_button`; production replacement must go through PhotoRoom before final approval.",
		"Upload `floating_replay_button` states to R2 and record generation manifest.",
		"Generate dark/light `bottom_reserve_layer` candidates.",
		"Create temporary magenta alpha candidates for `bottom_reserve_layer`; production replacement must go through PhotoRoom before final approval.",
		"Upload `bottom_reserve_layer` candidates to R2 and record generation manifest.",
		"Generated UI object assets are the primary visuals; legacy Godot panel/button styleboxes are transparent hitboxes only when matching generated assets exist.",
		"Store generated UI object alpha bounding boxes in `ThemeConfig.ui_generated_asset_geometry[*].alpha_bbox` so runtime places the real object area, not transparent canvas padding.",
		"GameScene wraps generated object PNGs in `AtlasTexture` regions from SSOT `alpha_bbox`; full-source exceptions are explicitly marked by `runtime_region = \"full_source\"`.",
		"Owner-approved floating menu/replay button placement uses icon-baked PhotoRoom PNGs in runtime; visual draw source is the per-mode `alpha_bbox` crop so PhotoRoom padding cannot shift optical center.",
		"Wire `bottom_reserve_layer` as a semantic HUD node and place it from SSOT bottom reserve ratios.",
		"Render only one generated top tray shell; `StatsCapsule` is a transparent layout control, and `LogoCore` renders the real project logo from the owner-approved `logo_core` region.",
		"Store optional `GeneratedStatsCapsule` and `GeneratedLogoSocket` as library assets, but keep them inactive in current cyber top tray stack.",
		"Store normalized top tray sub-regions in `ThemeConfig.ui_top_tray_regions`; use them only for controls/readouts, not full-tray art stack components.",
		"Runtime top tray region placement uses the settled control size when available and falls back to `TopTrayRoot.custom_minimum_size` so SSOT placement works before Godot containers finish layout.",
		"Top tray region coordinate SSOT: `docs/ui_top_tray_region_ssot.md`.",
		"Settings modal uses generated `modal_frame` as the visual shell; `SettingsOverlay` is a non-container `Panel` so anchored close/content controls cannot expand into a full-row or full-panel icon.",
		"Store modal portrait/landscape size ratios in ThemeConfig and place modal rect from viewport ratios.",
		"Modal frame currently uses SSOT `runtime_stretch_mode = \"scale\"` until a real 9-slice/sliced modal frame pass is implemented.",
		"Leaderboard/Profile popup uses generated `modal_frame`, non-container root, corner close button, and GameScene injects active theme/mode before display.",
		"Solved/win popup uses generated `modal_frame`, non-container root, and modal rect from the same ThemeConfig portrait/landscape ratios as settings and leaderboard.",
		"Store top tray stat slot ratios and font size in ThemeConfig so logo clearance and readout typography scale without per-scene magic numbers.",
		"Capture dark/light portrait/landscape settings modal screenshots.",
		"Capture dark/light portrait/landscape leaderboard modal screenshots.",
		"Capture dark/light portrait/landscape solved/win modal screenshots.",
		"Capture dark portrait, dark landscape, light portrait, and light landscape generated UI layout screenshots.",
		"9Router component call queue: `docs/ui_cyber_9router_component_call_queue.md`."
	]:
		passed = passed and _assert_true(checklist.contains(required_text), "Checklist should document %s" % required_text)

	for required_text in [
		"Lock rule: UI asset pipeline order is 9Router design -> owner approval -> PhotoRoom cutout -> SSOT object placement -> text pass.",
		"Lock rule: chroma-key cleanup is debug-only and cannot be accepted as production alpha for UI object assets.",
		"Lock rule: no top tray/stat/modal text may be added until every object asset for that screen is placed and owner-approved.",
		"Replace temporary chroma-key alpha UI object assets with PhotoRoom-cleaned production cutouts before final UI approval.",
		"Re-audit PhotoRoom edges on dark background, light background, and checkerboard.",
		"Re-place all PhotoRoom object assets through SSOT before any text pass resumes.",
		"Top tray object-placement pass: current cyber `ui_top_tray_art_stack` renders `GeneratedTopTrayLayer` only; menu button, replay button, and bottom reserve are attached from SSOT-controlled PhotoRoom assets.",
		"Top tray art stack rule: active top tray art components share the full `TopTrayLayer` rect; `ui_top_tray_regions` is for menu/replay/readout/logo control ownership only.",
		"Floating button icon-baked contract: generated menu/replay button PNGs include their settings/replay symbols; `ThemeConfig.ui_top_tray_button_icon_source = \"baked_texture\"` disables runtime `GeneratedButtonIcon` overlays.",
		"Owner visual approved menu, replay, and logo top tray placement before text pass starts.",
		"Owner approved `total_play_time_readout = Vector4(0.6687, 0.3494, 0.1843, 0.1843)` for the top-right stat region.",
		"Top-right stat region uses SSOT `ThemeConfig.ui_top_tray_time_*` typography plus `ThemeConfig.ui_top_tray_moves_font_size`: Poppins Bold, energy-green text, dark outline, cyan-green shadow.",
		"Elapsed time no longer renders in the top tray; it renders as the bottom tray sprite timer and freezes when the level is solved.",
		"Runtime treats `total_play_time_readout` as a hard clipping region: `TotalPlayTimeLabel.clip_contents = true`, and font fitting subtracts padding, outline, and shadow bleed.",
		"`TotalPlayTimeLabel` is the top-right moves readout while the node name remains for scene compatibility: one-line `MOVES N`, right-aligned and font-fitted inside the owner region.",
		"`LeftStatsLabel` uses `left_stats_readout`: username on top, best wave on bottom, left-aligned and clipped/fitted by the same SSOT typography rules.",
		"UI screen order for future agents: design all objects first, place all objects second, add text last.",
		"Use PhotoRoom for every non-background transparent cutout; chroma-key cleanup is debug-only preview."
	]:
		passed = passed and _assert_true(checklist.contains(required_text), "Checklist should lock PhotoRoom workflow %s" % required_text)

	for required_text in [
		"Trial A. Neon Circuit Cockpit",
		"Trial B. Industrial Reactor Bay",
		"Trial C. Holographic Terminal",
		"Trial D. Bright Cyber Lab",
		"Start with Trial A.",
		"Use only `cx/gpt-5.5-image`. No fallback model.",
		"Owner-approved key policy",
		"If `NINEROUTER_IMAGE_KEY` is missing, use `NINEROUTER_KEY` as the image authorization key.",
		"Generated Trials",
		"style_trial_a_full_mockup.png",
		"style_trial_d_bright_cyber_lab.png",
		"F8FDAF4752C337C1DC8B36BD18D69CFF95DCFBCF2CEAE07A03B1B989EB5F37C5",
		"F332869464B092D8D1A8F6EC689741CBC661B29F82BE614A2B565333DE0077F5",
		"Procedural live VFX colors can change through `ThemeConfig` fields consumed by `Scripts/pipe_vfx_layer.gd`.",
		"Static energy overlay sheets are PNG/atlas based",
		"https://6893f1e40b.image-hosting.uk/images/glyph-arrows-cyber-ui-ref/current_cyber_gameplay.png"
	]:
		passed = passed and _assert_true(style_trials.contains(required_text), "Style trials should document %s" % required_text)

	for required_text in [
		"9Router UI Generation Runbook",
		"Use only `cx/gpt-5.5-image` for image generation.",
		"Key selection order",
		"`NINEROUTER_IMAGE_KEY`",
		"`NINEROUTER_KEY`",
		"R2 Upload",
		"Model Check",
		"Generate Full-Screen Style Trial",
		"Generate Production Component Asset",
		"Visual Audit Rules",
		"Production Slice Rule",
		"Do not use any fallback model or provider.",
		"PhotoRoom is mandatory for every non-background transparent production object.",
		"Chroma-key cleanup is debug-only preview work and must not be recorded as production alpha.",
		"Production asset paths must point to PhotoRoom cutouts, not chroma-key outputs.",
		"Text work starts only after all object assets for that screen are placed through SSOT and approved from screenshots.",
		"Never print or write API keys",
		"Do not generate poster art, full-screen mockups, sample gameplay screenshots, or decorative compositions.",
		"Canonical queue:",
		"docs/ui_cyber_9router_component_call_queue.md",
		"Minimal call loop for queued components"
	]:
		passed = passed and _assert_true(runbook.contains(required_text), "Runbook should document %s" % required_text)

	for required_text in [
		"Cyber 9Router Component Call Queue",
		"Every component call must include",
		"Base Prompt Block",
		"background_full_portrait",
		"background_full_landscape",
		"Do not stretch portrait into landscape or landscape into portrait.",
		"logo_socket",
		"stats_capsule",
		"floating_menu_button_default",
		"floating_replay_button_default",
		"bottom_reserve_layer",
		"modal_frame",
		"board_backplate",
		"No fallback model, provider, style, or hand-drawn replacement.",
		"Every prompt must repeat the object-only rule.",
		"Fixed production pipeline: 9Router design -> owner approval -> PhotoRoom cutout -> SSOT object placement -> text pass.",
		"Chroma-key cleanup is debug-only preview work. It is not a production background-removal method.",
		"Do not add or tune text until every object asset for the screen is PhotoRoom-cleaned, placed from SSOT, screenshot-audited, and owner-approved.",
		"every non-background object has a PhotoRoom production cutout.",
		"Godot Integration Gate"
	]:
		passed = passed and _assert_true(component_queue.contains(required_text), "Component queue should document %s" % required_text)

	for required_text in [
		"docs/ui_cyber_9router_component_call_queue.md",
		"Every production GUI component must be generated from the canonical call queue with R2 references for style synchronization.",
		"Non-background UI objects must use PhotoRoom production cutouts after owner design approval.",
		"Chroma-key outputs are temporary previews only and cannot unlock final UI approval or text pass.",
		"9Router design -> owner approval -> PhotoRoom cutout -> SSOT object placement -> text pass",
		"production_background_removal_method",
		"approved_dark_light_checkerboard",
		"blocked_until_all_screen_objects_are_photoroom_cleaned_and_ssot_placed"
	]:
		passed = passed and _assert_true(generation_manifest.contains(required_text), "Component generation manifest should document %s" % required_text)

	for required_text in [
		"background_full_portrait.png",
		"background_full_landscape.png",
		"orientation",
		"select_by_orientation_then_cover_safe_area_without_cross-orientation_stretch",
		"pending_owner_visual_approval"
	]:
		passed = passed and _assert_true(generation_manifest.contains(required_text), "Component generation manifest should include background metadata %s" % required_text)

	for required_text in [
		"logo_socket_alpha.png",
		"top_tray.center_logo_socket",
		"stack_full_top_tray_canvas_preserve_aspect_centered",
		"runtime_region",
		"chroma_key_magenta"
	]:
		passed = passed and _assert_true(generation_manifest.contains(required_text), "Component generation manifest should include logo socket metadata %s" % required_text)

	for required_text in [
		"stats_capsule_alpha.png",
		"top_tray.stats_capsule",
		"stack_full_top_tray_canvas_preserve_aspect_centered",
		"three readout zones receive Godot text/icons"
	]:
		passed = passed and _assert_true(generation_manifest.contains(required_text), "Component generation manifest should include stats capsule metadata %s" % required_text)

	for required_text in [
		"floating_menu_button_default_icon_photoroom.png",
		"top_tray.floating_menu_button_default.icon_baked",
		"fit_inside_canonical_floating_button_rect_preserve_aspect_centered",
		"icon_baked_into_button_texture; no runtime GeneratedButtonIcon overlay"
	]:
		passed = passed and _assert_true(generation_manifest.contains(required_text), "Component generation manifest should include floating menu metadata %s" % required_text)

	for required_text in [
		"floating_replay_button_default_icon_photoroom.png",
		"top_tray.floating_replay_button_default.icon_baked",
		"fit_inside_canonical_floating_button_rect_preserve_aspect_centered",
		"icon_baked_into_button_texture; no runtime GeneratedButtonIcon overlay"
	]:
		passed = passed and _assert_true(generation_manifest.contains(required_text), "Component generation manifest should include floating replay metadata %s" % required_text)

	for required_text in [
		"bottom_reserve_layer_alpha.png",
		"bottom_reserve.layer",
		"fit_width_inside_bottom_region_preserve_aspect_centered",
		"empty reserve for future boosters/ad/reward controls"
	]:
		passed = passed and _assert_true(generation_manifest.contains(required_text), "Component generation manifest should include bottom reserve metadata %s" % required_text)

	for required_text in [
		"Production output must be object assets, not poster images.",
		"Generate isolated UI objects on transparent or removable plain background.",
		"Do not generate full-screen beauty compositions for production components.",
		"Prompt for one object per image.",
		"Background is the only full-screen production image allowed.",
		"Must be an isolated object asset, not a poster/mockup/full-screen composition.",
		"dark mode uses black/deep-green/cyan cockpit materials.",
		"light mode uses pearl white/pale mint/cyan lab materials."
	]:
		passed = passed and _assert_true(component_design.contains(required_text), "Component design should document %s" % required_text)

	for required_text in [
		"reference_only",
		"top_tray_ref.png",
		"bottom_reserve_ref.png",
		"full_demo_ref.png",
		"glyph-arrows-cyber-ui-components"
	]:
		passed = passed and _assert_true(component_refs.contains(required_text), "Component refs should include %s" % required_text)

	for required_text in [
		"current_cyber_gameplay.png",
		"cyber_cell_bg.png",
		"cyber_pipe_l.png",
		"owner_reference_layout.jpg",
		"project_logo.png",
		"glyph-arrows-cyber-ui-ref"
	]:
		passed = passed and _assert_true(r2_manifest.contains(required_text), "R2 manifest should include %s" % required_text)

	if passed:
		print("test_ui_gameplay_layout_checklist_contract: PASS")
		quit(0)
	else:
		print("test_ui_gameplay_layout_checklist_contract: FAIL")
		quit(1)

func _assert_true(condition: bool, message: String) -> bool:
	if not condition:
		push_error("%s: expected true" % message)
		return false
	return true
