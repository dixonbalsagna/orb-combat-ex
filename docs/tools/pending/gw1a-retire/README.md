# GW1a: the preview's switch rows that main's data lands are retired (Tools, parked 2026-11-14, re-cut on the full stack)

The EP's GW1a item for Tools: when the switch groups land as main's own data, the preview's switch rows and launch words for them must retire, or the page build double-applies or lies. This park retires **exactly the rows the full GW1a stack lands** and proves it with `switch-diff` against the 9 November build. **Apply it after GW1a lands, not before**: until then the preview needs these rows to turn the data on.

| File | What |
| :--- | :--- |
| `gw1a-retire.patch` (sha1 `8bf4586ce97a19996a5fcb26cbd80639988b2890`) | `tools/preview/`: `switches.mjs` (85 rows out, 8 stay), `retired-rows.json` (the old rows whole, with the evidence) and `retired-rows.mjs` (new), `preview.mjs`, `stack-preview.mjs`, `smoke.mjs`, `preview-selftest.mjs`, `stack-selftest.mjs`. All Tools' files. Applies to HEAD cc3bf4d7 (`git apply --check --cached`). |
| `ci-sets-step.patch` (sha1 `f106b1fd586a8458b1fd62177508b5ff12e2320a`) | `.github/workflows/ci.yml`: the audio sets check step, after the babble check. The EP says Audio's sound-sets park includes `sets_check.gd`; the step lands in the same batch as that park (it is red on a tree without Audio's three data files). |
| `generator/` | the scripts that cut the patch from the table: `rows-at-to.mjs <tree> <old switches.mjs>` lists the rows whose `to` value the tree holds (the rows that print AT-TO go in `retire-data.txt`), then `retire-gw1a.mjs <a copy of switches.mjs> retire-data.txt`, `retire-consumers.mjs <the copy's tools/preview>` and `retire-selftest.mjs <same>`, with `retired-rows.mjs` copied into the folder. Re-cut it when GW1a's composition changes. |

## What "lands" means here, and the evidence

The tree is **the EP's `s422`** (HEAD plus every GW1a park: World's water and data switches, Combat's rows, Audio's sound sets, the camera, the pad, the computer opponent, the match-ending rows and the menus), read only, with **Simulation's `data-fight-gw1a`** applied to a copy of its data (that park was not yet in `s422`; its five `data/fight` rows are brake, hitstop `budgetAny`, kick, ladder `chargePerSec` 2 and power `dash.slip`: I applied the park's patch to a copy and read the result).

A data row retires when that tree holds the row's `to` value at its key: **82 rows**. Three more rows are page words, retired because the stack has what they asked for on by default in code, read in `s422`: `tiles` (`RenderTileGround.on = not args.has("notiles")`), `craterlook` (`crater_look = not args.has("nocraterlook")`) and `meteor` (`VfxLook.METEOR_DEFAULT` is `true`; false on main today). Every row is in `retired-rows.json` with its old definition and a line of evidence. The `mixed` row's probe looked for `sim/director/mixed.gd`, which was never on main, in the stack or in the kept build, so that probe could never be read and is not kept.

By file: `data/input/timing.json` 20, `data/director/stick.json` 8 and `ui/data/options.json` 2 (pad); `data/director/ai.json` 2 (computer opponent); `data/director/interrupts.json` 21 (match-ending and the director rows), `launch.json` 3, `swing.json` 3; World: `climate.json`, `contact.json`, `field.json` 2, `rings.json`, `water.json` 4 (water, surface, floor, waterWarm), plus `data/combat/launch_biome.json`; `data/camera/swing.json` (`splitShare`, the row at switches.mjs:60); `data/fight/power.json` 2 (`power`, `slip`), `hitstop.json`, `brake.json`, `kick.json`, `ladder.json`; Combat's `mixed.json` and `phrases.json`; `ui/data/features.json` (`menusRail`); Audio's three sound files; the three look words.

**The 8 rows that stay**: the three page rows (`gen3`, `blackbox`, `go`: not data the stack flips) and the five held rows that stay off by default and wait for a read (`wallPush`, `wallPushAi`, `slamTurn`, `cityHold`, `aimCuts`). `cityHold` is one of the EP's guesses for what stays; `powerPace` and `airBrake` retire, because Simulation's park lands them.

## What changes in the tools

- `switches.mjs`: the rows are out; the one `needs` that named a retired row (`slamTurn` needed `swing`) is dropped. New exports: `LANDED_IDS`, `LANDED_PROBES` (the probes of the retired rows stay, so the smoke check goes on verifying that the running game reads each landed thing as on) and `isOn(active, id)`. `resolve()` returns `landed`: asking to turn a landed row on or off is **said so** ("main's own data since GW1a: there is no switch to turn on or off here"), not "unknown" and not silently ignored.
- `preview.mjs` and `stack-preview.mjs`: the launch words `tiles=1`, `meteor=loud` and `craterlook=1` are no longer added; the landed probes join the page's state probe (only for rows no longer in the table); the page's comparison words that depend on a switch being on (`?struggle=0`, the dash) read `isOn`, so they behave as before.
- `smoke.mjs`: what the running game must report counts landed rows as on (the data generation 2, the biome, the water, the interrupts, the turn, the right stick, the meteor, ...).
- `preview-selftest.mjs` and `stack-selftest.mjs`: their engine checks (flip, the cascade, waiting, the scratch patch, the stack builds) run on **the table as it was before the retirement**, rebuilt by `retired-rows.mjs` from `retired-rows.json` and the live rows in their old order (SWITCHES and IDS are changed in place and put back), so they still prove the engine; a new section checks the live table (10 checks: the 85 are out, the 8 are the right ones, no kept row needs a retired one, landed ids are said so, the look words are gone and the page words stay, the smoke expectations, the probes, `isOn`, the record).

## Proof

On a scratch git of HEAD (clean `git archive`, then this patch): `preview-selftest` **181 checks ok** (it was 171; the 10 new are the live-table section), `stack-selftest` ok, `build-check`, `switch-diff` and `pck-verify` self-tests ok. Before the history trick the stack self-test failed 5 checks on the new table, which is why `stack-selftest` also runs on the old one.

`node tools/preview/switch-diff.mjs` against the kept 9 November build (`orb-first-play-6a30b4c9-6627cb9d`), `--tree` reading the stack:

| Main side | Table | Rows that differ |
| :--- | :--- | :--- |
| main today (HEAD) | old (87 data rows) | **69 of 87** |
| `s422`, as built | old | **6 of 87** (power, powerPace, slip, hitstopAny, airBrake, kick) |
| `s422` + Simulation's `data-fight-gw1a` | old | **1 of 87**: `power` |
| the same | **new (5 data rows)** | **0 of 5** |

**It reaches 0.** `power` is the one old-table row left, and it is not a gap: main will say `enabled: true` and the 9 November build said `false` (the build played the energy model through the page's setup, not through the data), so main is ahead of the build on that row, and it retires.

## Not proven, and what to check when GW1a lands

- The proof reads **a scratch stack** with Simulation's park applied by me to a copy of its data. When the real stack lands, run `node tools/preview/switch-diff.mjs --list` on HEAD: it must say 0 of 5 (if a retired row's value is not on main, it shows up there as differing and the row comes back in).
- A page build with the new table has **not been built or played**: the self-tests build against a throwaway repository with a stand-in for Godot. The first kept build after GW1a is the test; its smoke match must report planet generation 2, the biome, the water, the right stick and the meteor as on.
- Netcode's `--tiles=1` in `lan_kit.mjs` goes separately (the EP's note).

## The audio sets check step (`ci-sets-step.patch`)

`audio/tools/sets_check.gd` passes on a clean HEAD copy with Audio's three data files laid over it (`gate.mjs` exit 0, "sets check passed", no SCRIPT ERROR) and **fails on HEAD alone** (gate exit 1): the step is red until the three sets are on in `audio/data`, so it lands with Audio's park (which carries `sets_check.gd` per the EP; if the file is not committed with it, the step names a file git does not have, which `tools/check-workflow-paths.mjs` refuses). The scripts table counts it as CI from then on.

## Confirmed on the final stack (`s422 final`, HEAD 30ca5423 plus every GW1a park, read only)

The same 82 data rows read at their `to` value in the final tree itself (no copy of Simulation's park needed any more): the id list equals the one the patch was cut from, so the patch, **sha1 `8bf4586ce97a19996a5fcb26cbd80639988b2890`, is unchanged**. The three look words are still on by default in the final tree's code (checked by line). `switch-diff --tree` on the final tree: the **old table 1 of 87** (`power`, the row where main is ahead of the build), the **new table 0 of 5**. The patch still applies to HEAD 59ef5597 (`tools/preview` has not changed since its base).
