# {{GAME_NAME}} Asset Count Matrix

Count source:

`runtime surface -> asset family -> semantic key -> state variant -> proof requirement`

Current Canonical Static Runtime Count: `{{CANONICAL_STATIC_RUNTIME_COUNT}}`.

## Family Totals

| Family | Count | Asset keys |
|---|---:|---|
| {{FAMILY_NAME}} | {{FAMILY_COUNT}} | `{{ASSET_KEY}}` |

## Detailed Static Runtime Inventory

| Family | Key | Runtime use | PNG size | SSOT size/metric | Runtime path |
|---|---|---|---:|---|---|
| {{FAMILY_NAME}} | `{{ASSET_KEY}}` | {{RUNTIME_USE}} | `{{PNG_SIZE}}` | `{{SSOT_METRIC}}` | `{{RUNTIME_PATH}}` |

## Image Quality Profile

Selected core `image_quality_profile`: `{{IMAGE_QUALITY_PROFILE}}`.
For UI source assets, PNG size must match or exceed `owner_size * runtime_ui_source_scale` according to the game contract `size_policy`.

## Post Check

- family totals sum to canonical total
- every key appears in coverage matrix
- every key appears in manifest/resource registry/theme SSOT where used
- screenshots exist for screen-facing keys
