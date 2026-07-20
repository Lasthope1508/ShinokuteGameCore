# {{GAME_NAME}} Asset Coverage Matrix

Lifecycle statuses:

| Status | Meaning |
|---|---|
| `source_raw` | raw source exists |
| `polygon_extracted` | object extracted by outline/object, not blind grid |
| `trimmed` | transparent bounds or exact shell normalized |
| `runtime_registered` | game SSOT points at runtime asset |
| `screenshot_passed` | runtime screenshots exist |
| `ART_DESIGN_PENDING` | art design is not final-approved |
| `OWNER_APPROVED` | owner accepted final look |
| `final` | ship-ready after all gates |
| `blocked` | must not be called done |
| `prototype` | function test only |

## Required Runtime Keys

| Key | Family | Required lifecycle | Art design gate |
|---|---|---|---|
| `{{ASSET_KEY}}` | {{FAMILY_NAME}} | `runtime_registered` | `ART_DESIGN_PENDING` |

## Final Approval Blockers

- {{BLOCKER}}
