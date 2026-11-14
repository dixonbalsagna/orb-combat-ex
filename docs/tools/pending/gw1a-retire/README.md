# GW1a: the preview's switch rows that main's data lands are retired (Tools, parked 2026-11-14)

The EP's GW1a item for Tools: when the switch groups land as main's own data, the preview's switch rows and launch words for them must retire, or the page build double-applies or lies. This park retires **exactly the rows the GW1a stack lands**, and proves it with `switch-diff` against the 9 November build. **Apply it after GW1a lands, not before**: until then the preview needs these rows to turn the data on.

| File | What |
| :--- | :--- |
| `gw1a-retire.patch` (sha1 `9187a2eec1143bcd0cdeb480aece63d9182ffa73`) | `tools/preview/`: `switches.mjs` (76 rows out, 17 stay), `retired-rows.json` (the old rows whole, with the evidence) and `retired-rows.mjs` (new), `preview.mjs`, `stack-preview.mjs`, `smoke.mjs`, `preview-selftest.mjs`, `stack-selftest.mjs`. All Tools' files. Applies to HEAD 0c1f5b25 (`git apply --check --cached`; `switch-diff --tree` is already in HEAD). |
| `ci-sets-step.patch` (sha1 `f106b1fd586a8458b1fd62177508b5ff12e2320a`) | `.github/workflows/ci.yml`: the audio sets check step (docs/tools/pending/ci-later section 1), after the babble check. **Lands WITH Audio's group** (below). |
| `generator/` | the scripts that cut the patch from the table (`retire-gw1a.mjs`, `retire-consumers.mjs`, `retire-selftest.mjs`, the id list `retire-data.txt`), so it can be re-cut if GW1a's composition changes: `node retire-gw1a.mjs <a copy of tools/preview/switches.mjs> retire-data.txt`, then the other two on the copy. |

## What "lands" means here, and the evidence

A data row retires when **the GW1a scratch tree** (`...\58be913b-...\scratchpad\gw1a`, read only) already holds the row's `to` value at its key: **68 rows**. Two more rows retire on **Combat's park** (`docs/combat/pending/gw1a-rows`, the EP's note): `phrases` and `mixed`, whose two data files it turns on (the scratch tree does not hold the files). The `mixed` row's probe looked for `sim/director/mixed.gd`, which was never on main, in the stack or in the kept build, so that probe could never be read and is not kept. Three more rows are page words, retired because the tree turns what they asked for on by default in code: `tiles` (`RenderTileGround.on = not args.has("notiles")`), `craterlook` (`crater_look = not args.has("nocraterlook")`) and `meteor` (`VfxLook.METEOR_DEFAULT` is `true` in the tree, `false` on main today). Three sound rows (`soundTug`, `soundMoments`, `soundCarry`) retire on **Audio's park**, not on the scratch tree, which has no `audio/` folder: their three data files in the working tree say `enabled: true`, and the EP lists "sound sets" among GW1a's groups. **If Audio's group or Combat's park does not land in GW1a, take those rows out of the extra list in `generator/retire-gw1a.mjs` and re-cut.** Every row is in `retired-rows.json` with its old definition and a line of evidence.

By data file (the groups the EP named): `data/input/timing.json` 20, `data/director/stick.json` 8 and `ui/data/options.json` 2 (pad); `data/director/ai.json` 2 (computer opponent); `data/director/interrupts.json` 21 (match-ending and the director rows), `launch.json` 3, `swing.json` 3; World: `climate.json` 1, `contact.json` 1, `field.json` 2, `rings.json` 1, plus `data/combat/launch_biome.json` 1 (four files plus launch_biome here, not five: `brunt.json` is not in the scratch tree, so `cityHold` stays); `data/camera/swing.json` 1 (`splitShare`, the row at switches.mjs:60); `data/fight/power.json` 1; `ui/data/features.json` 1 (`menusRail`); Combat's `mixed.json` and `phrases.json`; the three look words; the three sound files.

**The 17 rows that stay** are the ones the golden window does not land: the water group (`water`, `surface`, `floor`, `waterWarm`), the held city rows (`wallPush`, `wallPushAi`, `slamTurn`, `cityHold`, `aimCuts`), rows whose files are not in main yet (`powerPace`, `airBrake`, `kick`), `slip`, `hitstopAny`, and the three page rows (`gen3`, `blackbox`, `go`).

## What changes in the tools

- `switches.mjs`: the rows are out; `needs` that named a retired row are dropped from the rows that stay (`floor`, `slamTurn`, `slip`: a row that needed a retired one would otherwise cascade off for a switch that is not there). New exports: `LANDED_IDS`, `LANDED_PROBES` (the probes of the retired rows stay, so the smoke check goes on verifying that the running game reads each landed thing as on) and `isOn(active, id)`. `resolve()` returns `landed`: asking to turn a landed row on or off is **said so** ("main's own data since GW1a: there is no switch to turn on or off here"), not "unknown" and not silently ignored.
- `preview.mjs` and `stack-preview.mjs`: the launch words `tiles=1`, `meteor=loud` and `craterlook=1` are no longer added; the landed probes join the page's state probe (only for rows no longer in the table); the page's comparison words that depend on a switch being on (`?struggle=0`, the dash) read `isOn`, so they behave as before.
- `smoke.mjs`: what the running game must report counts landed rows as on (the data generation 2, the biome, the interrupts, the turn, the right stick, the meteor, ...).
- `preview-selftest.mjs` and `stack-selftest.mjs`: their engine checks (flip, the cascade, waiting, the scratch patch, the stack builds) run on **the table as it was before the retirement**, rebuilt by `retired-rows.mjs` from `retired-rows.json` and the live rows in their old order (SWITCHES and IDS are changed in place and put back), so they still prove the engine; a new section checks the live table (10 checks: the 76 are out, the 17 are the right ones, no kept row needs a retired one, landed ids are said so, the look words are gone and the page words stay, the smoke expectations, the probes, `isOn`, the record).

## Proof

On a scratch git of HEAD (clean `git archive`, then this patch): `preview-selftest` **181 checks ok** (it was 171; the 10 new are the live-table section), `stack-selftest` ok, `build-check`, `switch-diff` and `pck-verify` self-tests ok. Before the history trick the stack self-test failed 5 checks on the new table, which is why `stack-selftest` also runs on the old one.

`node tools/preview/switch-diff.mjs` against the kept 9 November build (`orb-first-play-6a30b4c9-6627cb9d`), with `--tree` reading the GW1a scratch tree plus Audio's three data files plus Combat's two:

| Main side | Table | Rows that differ |
| :--- | :--- | :--- |
| main today (HEAD) | old (87 data rows) | **69 of 87** |
| the GW1a tree + Audio's and Combat's data | old | **11 of 87** (water, surface, floor, waterWarm, power, powerPace, cityHold, slip, hitstopAny, airBrake, kick) |
| the same tree | **new (14 data rows)** | **10 of 14**: the same rows without `power` |

So after the GW1a stack the diff to the 9 November build is exactly the rows GW1a does not land, and they are the only rows left in the table. **It does not reach 0**, and cannot: 10 data rows belong to groups that are not in GW1a (the water group, and the Simulation and Encounter rows whose files are not in main yet). `power` is a special case: main will say `enabled: true` and the 9 November build said `false` (the build played the energy model through the page's setup, not through the data): main is ahead of the build on that row, so it retires.

## Not proven, and what to check when GW1a lands

- The evidence is a **scratch tree**: it has no `audio/`, no `data/biomes/world.json` and no `data/biomes/brunt.json`. When the real stack lands, run `node tools/preview/switch-diff.mjs --list` on HEAD: the rows it lists must be exactly the 10 above (a retired row that shows up there was not landed; a kept row that is missing was landed and can retire).
- A page build with the new table has **not been built or played**: the self-tests build against a throwaway repository with a stand-in for Godot. The first kept build after GW1a is the test; its smoke match must report planet generation 2, the biome, the right stick and the meteor as on.
- Netcode's `--tiles=1` in `lan_kit.mjs` goes separately (the EP's note).

## The audio sets check step (`ci-sets-step.patch`): READY, and it lands with Audio's group

`audio/tools/sets_check.gd` passes on a clean HEAD copy with Audio's three data files laid over it (`gate.mjs` exit 0, "sets check passed", no SCRIPT ERROR) and **fails on HEAD alone** (gate exit 1): the step is red until the three sets are on in `audio/data`, so it must land in the same batch as Audio's group, and `audio/tools/sets_check.gd` is still untracked in the working tree (Audio's file: it has to be committed with the group, or the step names a file git does not have, which `tools/check-workflow-paths.mjs` refuses). The scripts table counts it as CI from then on (it is not counted today: it is untracked).
