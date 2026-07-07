# External Godogen Notes

Reference: `https://github.com/htdt/godogen`

This file separates ideas worth remembering from pieces that should not be
imported into the Shinokute reskin pipeline.

## Ideas Imported Into Shinokute Guardrails

- Asset manifest discipline.
- In-game display size recorded before scene wiring.
- Visual proof over claims.
- Review every generated PNG before downstream conversion.
- Owner approval before paid generation.
- Build small reusable asset blocks before full screens.

## Do Not Import Into Shinokute Reskin Pipeline

- Godot C#/.NET scene builder architecture.
- Whole-game prompt-to-repo generator flow.
- Generated scene code replacing hand-owned Godot scenes.
- Runtime loop that assumes a fresh generated repository instead of an
  existing mobile game repo.
- Any rule that bypasses `GameCoreConfig`, `ShinokuteThemeConfig`,
  `GameRulesAdapter`, `GameSession`, or game-local SSOT resources.

## Keep For Possible Other Work

- Godot C#/.NET scene builder ideas may be useful for a separate prototype
  generator.
- Agent proof-loop ideas may be useful for fully automated test-game creation.
- Video proof scripts may be useful for a future smoke-test harness.

These are not part of the production Shinokute reskin contract until they get
their own design, tests, and owner approval.
