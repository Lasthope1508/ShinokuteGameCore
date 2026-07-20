# Asset Generation Guardrails

Use this document when a reskin needs generated or edited art assets.

Also read `docs/art_ui_design_gate.md` and run
`tools/validate_art_ui_gate.py` with the game-owned contract before claiming
any UI/art pass is complete.

This policy borrows the useful parts of Godogen's asset workflow: keep an asset
manifest, record in-game size, review generated images before downstream work,
and prove results visually instead of claiming they should look right.

## Build-Block Asset Workflow

For a new game, test game, or reskin whose source visuals are only basic
placeholders, build assets as reusable blocks before final art:

1. Define the block kit in the game-local `docs/asset_manifest.md`.
2. If the inherited game only has debug shapes, generic controls, or contract
   placeholders, choose an owner-approved production art direction before
   generating or assembling final art.
3. Make the smallest useful visual pieces first:
   - logo placeholder,
   - button shell,
   - panel shell,
   - input shell,
   - leaderboard row,
   - settings row,
   - HUD score owner,
   - gameplay tile/block/piece,
   - background test swatch,
   - VFX placeholder.
4. For each block, record role, source, path, owner rect, padding, and
   In-game Size before wiring scenes.
5. Build a small asset test scene that places every block in its intended
   control role.
6. Capture desktop and mobile screenshots of the test scene.
7. Only after the block kit fits, wire assets into real gameplay screens.

Stop gate:
- Do not build a full game screen from untested loose assets.
- Do not treat source placeholder art as final art. If the source stops at
  basic shapes or generic UI, the polished Block Kit gate is mandatory before
  final art/screen work.
- Do not use an asset in production scenes until the asset manifest has a
  Block Kit entry with owner rect, padding, and In-game Size.
- Do not continue if text does not fit the block that owns it.

## Generated Asset Rules

- Inventory approved existing assets before creating anything new.
- Get owner approval before spending money or compute on paid generation;
  confirm paid generation in chat or checklist before the call.
- Generate or edit 2D PNG/WebP assets first when possible.
- Review every generated PNG before downstream conversion, slicing, cropping,
  or import.
- Agents must review every generated PNG before downstream conversion.
- Do not convert to GLB, sprite sheets, atlases, or Godot scenes until the
  source image passes role, ratio, crop, padding, and owner rect review.
- Store every accepted asset under game-owned paths, not Shinokute core.
- Add every accepted asset to the game-local asset manifest.

## Proof Over Claims

Visual work is not done because code builds.
Visual work is not done because `RUNTIME_FIT_PASS` passes. Runtime fit proves
geometry only; final art approval requires the Art UI Design Gate and no
remaining `ART_DESIGN_PENDING` rows.

Required evidence:

- asset test scene screenshot,
- desktop gameplay/menu screenshot,
- mobile gameplay/menu screenshot,
- checklist note that text fits owner regions,
- checklist note that the screen still reads as a game screen.

Use proof over claims: if no screenshot/video evidence exists, the reskin is
not ready.

## Asset Manifest Fields

Each asset row must record:

- role,
- asset key,
- path,
- source,
- approved/reused/generated,
- owner rect,
- padding,
- In-game Size,
- viewport proof path,
- notes.

## Hard No

- No random generated art in gameplay scenes.
- No untracked paid generation.
- No asset without an owner rect.
- No text-bearing asset without padding and max text region.
- No reskin completion report without visual proof.
