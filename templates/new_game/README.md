# New Game Reskin Template

Copy this folder into a new Godot game repo before reskin work starts.
Replace `example` names with the game id, then fill the checklist.

Required use:

1. Copy `docs/reskin_checklist.md` into the target game docs folder.
2. Copy `docs/screenshot_verification_checklist.md`.
3. Create real `.tres` files from the `.template` resources.
4. Rename `Scripts/ExampleRules.gd` to `<GameName>Rules.gd`.
5. Copy `Tests/test_shinokute_reskin_contract.gd` and update the paths.
6. Run `tools/reskin_audit.ps1 -GameRoot <game> -FailOnWarnings`.

Do not start gameplay edits until the checklist, config, theme, rules adapter,
contract test, and screenshot checklist exist.
