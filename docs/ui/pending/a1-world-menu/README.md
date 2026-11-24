# a1-world-menu (UI & UX; re-cut 2026-11-23 for GW1c with Medium alone): the first match across sessions, the planet in the seed line, the planet size row

Parked, not landed. Design: `docs/ui/menus-a1.md` sections 9 to 11 (in the patch).

## What changed in this cut

- **The size row and its "This match" line appear only when there is a choice**: `UiModes.size_row()` is `sizes().size() > 1`. GW1c lands with Medium alone (`offered: false` on the others), and a cycle row of one choice would step to itself and look like a control that does nothing. The menu config still carries `planet_size` (the one size, Medium) and the host still sends `planetSize`; World says a named Medium plays the same as an unnamed one. The two places are `ui/widgets/ui_menu.gd` (the row, and the summary card's kv line).
- **hud_check rows** (`_menus_world_rules`): one offered size gives no row and no summary line, two give both, and with one size the HUD's cfg still carries `planet_size` medium and the setup has no row. Negative control, run: with `size_row()` back to "not empty", the two one-size rows fail.
- **Re-cut on HEAD bc1e5558** (the old cut no longer applied: the unplug pause, X-28 and others had moved `ui_hud.gd`, `terms.json`, `hud_check.gd`, `strings.md`). Pseudo-locale and `docs/ui/strings.md` regenerated.
- **The main.gd grant is gone from this park.** `grant/main-gd-first-match-size-world.patch` was a delta on World's `grant-rendering-main.patch`, which World withdrew (review B-07) in favour of Rendering's `docs/rendering/pending/world-menu-merge/world_menu_merged.diff` (sha1 78abe08e). That merged diff already contains my delta (no `_played_one`, the first match from `ui_hud.first_match_played()`, `planetSize` from the size row, `WorldDefault.describe` in the report's context). It applies strictly on HEAD and on HEAD plus World's stage 2, and it is what lands with this patch. My standalone delta no longer applies and is not needed.

## Files

- `world-menu.patch` (12 files, clean on HEAD bc1e5558 with `git apply --check`, and on HEAD plus World's stage 2): `ui/core/ui_modes.gd`, `ui/widgets/ui_menu.gd`, `ui_pause.gd`, `ui_feedback.gd`, `ui/hud/ui_hud.gd`, `ui/data/terms.json`, `ui/data/feedback.json`, the two pseudo-locale files, `docs/ui/strings.md`, `ui/tools/hud_check.gd`, `docs/ui/menus-a1.md`.
- `runs/`: hud_check on the stack, the unplug probe and the mode smoke on the stack, the two ratchets.

## What lands with it (checked)

On a clean copy of HEAD, World's stage 2 in `docs/world/planet-stack-recut.md` order (their sha1s: `planet-sizes.diff` 57d6e4be, `gw1c-world.diff` b7c42e20) all apply as they stand, in this order: `globe-step2/grant-tools-lint`, `globe-step2`, `grant-simulation-field`, `planet-sizes/grant-simulation-sizes`, `planet-sizes`, Rendering's `grant-world-field-size-key`, VFX's `planet-sizes-meteor/apply.patch`, `gw1c-world`, `gw1c-world-fix`, `store-parts`, `box-key-20bit`, `crater-tiers` and its Tools grant, `relief-cap` and its Tools grant, `globe-check-pin`, `swap-blocks-gw1c`. Then this park's `world-menu.patch`, then Rendering's `world_menu_merged.diff`: both apply.

**Which GW1b pieces are still needed: none.** `WorldDefault` (`sim/world/default.gd`, with `part`, `describe` and `planetDefault`) and Simulation's grant for it are on main; so are UI's start-flow (the `quit_requested` signal the merged diff's neighbours use) and the rest of the A1 stack (`a1-save-reason`, `a1-rail-default`). What the merged diff still needs in the same landing is this park's `UiHud.first_match_played()`. World's `grant-rendering-main.patch` is superseded and stays out.

## Proof (data folder pointed away from Orb's)

- Full hud_check: on the stack (HEAD + World's stage 2 + this patch + Rendering's merged diff) 8651 checks, 0 failed; on HEAD with this patch alone 8651 checks, 0 failed.
- Mode smoke, solo and two, on the stack: 24 steps each, pass (the walk goes by row names, so the setup with no size row is fine; Start sends `planetSize` medium through the merged diff and the sim plays it).
- Unplug probe (the host's side in the real main scene), solo 17 ok and two 22 ok, 0 failed, on the stack with the merged main.gd.
- **The two ratchets on the grant** (Rendering's merged diff, with the park): two-fighter 365 against a baseline of 365, ok (main.gd stays at 6); fighter-specific 0 against 0, ok. Records in `runs/ratchets.txt`.

## Words for Orb (all in the patch, unchanged by this cut)

"Planet size", "Tiny", "Small", "Medium", "Big", "Huge"; "Planet {planet}", "The hand-made arena", "Planet {planet}, generator {gen}, {cols} columns around"; and the report label "World". With Medium alone the player sees none of the size words (no row, no line); they are there for the day a second size is offered.

## The schema grant (2026-11-23, from the EP's GW1c gate)

`grant/schema-feedback-world.patch` (Tools' files `tools/schemas/ui-feedback.schema.json` and `tools/fixtures/cases.json`; clean on HEAD and on the full GW1c stack): the world-menu patch adds `report.world` ("World") to `ui/data/feedback.json`, and the schema's `report` object is closed, so `node tools/validate.js` gave `ui/data/feedback.json:20 /report/world [additionalProperties] unknown property "world"`. The grant adds `world` (a non-empty string, in the file's own style, after `seed`; not required, so a feedback file without it stays valid) and one fixture case, `feedback-empty-report-world` (an empty `world` fails `minLength` at `/report/world`).

On the full stack (`docs/ep/reviews/GW1c-stack.txt` on bc1e5558, strict in order, then this grant): `node tools/validate.js` 325 files, 0 errors; `--self-test` 10170 of 10171, the data cases 8401 to 8402. Without the grant: 1 error, and the self-test also fails "the unmutated data has no errors". **One self-test failure is left and is not UI's:** `coverage: biomes-sizes.schema.json: at least three invalid cases, has 0`: World's planet-sizes park adds that schema without invalid cases for it (`tools/fixtures/cases.json`). Records: `runs/validate-gw1c-stack.txt`, `runs/validate-gw1c-stack-without.txt`.
