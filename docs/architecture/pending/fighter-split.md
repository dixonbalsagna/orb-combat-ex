# Patch plan: the fighter rename onto neutral ids

Owner: Simulation and Engine. Date: 2026-10-05, read against d309a54. Status: **a plan only.** Nothing is built or run. Orb approved running it tonight; the EP schedules the window after World's stages and the dynamic intros.

The rename: roster id `KAI` becomes `PROTAGONIST` and `VORR` becomes `RIVAL`. Orb's real names come later and must then be a one-file change.

## 1. The rule that makes the later change one file

**An id is a key. A name is text.** After this window nothing may look anything up by a displayed name.

- `Fighter.id` is the roster id. It is already what the director keys on (the finisher choice, the recipe pools) and it is in the state hash.
- `Fighter.name` is what is shown: the HUD, the feed, the banners. The mirror arms already change it (`KAI-A`) without touching the id.
- Today the two happen to be equal, and several places outside the sim key on the name. Those are the real work of this window (section 3).

## 2. Should the displayed names come from a strings file? Yes

Today a fighter's `name`, `title` and `sigName` sit in his own `fighter.json`, so Orb's names would be a two-file edit that grows with the roster.

**One file: `data/fighters/names.json`,** read by `FighterData`:

```json
{ "PROTAGONIST": {"name": "...", "title": "...", "sigName": "..."},
  "RIVAL":       {"name": "...", "title": "...", "sigName": "..."} }
```

- `fighter.json`'s `identity` keeps `role` and the colours and loses the three strings. A fighter with no row shows his id.
- The file is part of the roster data hash, so a replay knows which names it was recorded with.
- Orb's names are then an edit to that one file and one golden regeneration, with no code and no other data touched. Section 5 says what that regeneration may move.
- Narrative owns the text; Simulation owns the file's shape and the loader; Tools adds its schema.

**What the placeholders read tonight is the EP's to say.** If the file keeps `KAI` and `VORR` for now, tonight's window is provably neutral (section 5). If it shows `PROTAGONIST` and `RIVAL`, the feed text moves and the proof is one step weaker.

## 3. What changes, and whose it is

Counts are files that name `KAI` or `VORR` as a word: sim 6, data 11, qa 12, render 12, ui 6, tools 5.

### Simulation (mine)

| What | Change |
| :--- | :--- |
| `data/fighters/KAI/`, `data/fighters/VORR/` (4 files each) | The folders become `PROTAGONIST/` and `RIVAL/`. `FighterData` finds a fighter's files by his id |
| `data/fighters/roster.json` | `["PROTAGONIST", "RIVAL"]` |
| Each `fighter.json` | `id`; the three display strings move to `names.json`; `finishers.base` follows Combat's finisher key (below) |
| `data/fighters/names.json`, new, and its read in `sim/core/fighter_data.gd` | Section 2 |
| `sim/core/tools/golden_recipes.gd` | The arm setups: `slots` by the new ids. The mirror arms' names are built from the fighter's own name plus `-A` and `-B`, not written out |
| `sim/core/tools/parity.gd` (53 lines) | The roster order check, the arm checks and the tallies read the ids from the roster, not from literals. The forced probe keeps its seeds |
| `sim/core/tools/batch.gd` | A record gains `ids` beside `names`, so QA can key on the id |
| `sim/core/test/golden.json` | Regenerated (section 5) |
| `sim/core/roster.js`, `sim/core/test/frozen/golden-js.json` | **Untouched** (ADR 0006: the JS core and its record are frozen) |

### Combat

| What | Change |
| :--- | :--- |
| `data/combat/finishers.json` | `select.byFighter` keys become the new ids; the two finishers' `fighter` strings; the finisher keys `kai` and `vorr` if Combat renames them (then `finishers.base` in my two files follows) |
| `data/combat/styles.json` | The two fighter keys |
| `data/combat/recipes.json` | A comment only |
| `sim/director/test/combat-parity/finishers.json` | The frozen copy, refreshed through the EP by the usual rule |

### Encounter

| What | Change |
| :--- | :--- |
| `data/director/alchemy.json` | Drop the `fighters` map. `DirRecipe` falls back to the id in lower case, which is then `protagonist` and `rival`, the pools' own keys |

### Tools

| What | Change |
| :--- | :--- |
| `docs/tools/pending/apply-split-keys.cjs` (parked) | Run in this window: the finisher schema's archetype key and the rule that a finisher's `fighter` and every `byFighter` key is a roster id |
| `tools/fixtures/cases.json` (8 lines) | Cases that point at `/select/byFighter/KAI`, `/fighters/KAI` and `"replaces": "VORR"` |
| A schema for `data/fighters/names.json`, and the three strings out of the fighter schema | New |

### Animation, Rendering, VFX

| What | Owner | Change |
| :--- | :--- | :--- |
| `data/anim/fighters.json` `replaces` (2), `data/anim/pair_live.json` aliases, `data/anim/ragdoll_motion.json` `fighters` keys | Animation | The roster ids. `replaces` and the aliases can go once the roster id is the fighter's own key |
| `render/anim/anim_data.gd` (the id-to-fighter rule), `render/anim/tools/*` (6 tools; `anim_check.gd` has 21 lines) | Animation | Ids from the roster; the tools' literals |
| `render/core/look.gd` `DAMAGE_OUTFIT` keys | Rendering | The two keys |
| `render/vfx/glare.gd` `WEARERS` (a list of ids **and names**), `render/vfx/aura.gd` (a comment), 2 VFX tools | VFX | Key on the id only |

### UI

| What | Change |
| :--- | :--- |
| `ui/core/ui_sim_bridge.gd` | It maps the placeholder fighters to readout profiles **by name**. It must map by id |
| `ui/data/readout_profiles.json` | The alias rows `kai` and `vorr` become `protagonist` and `rival` (or the ids themselves) |
| `ui/hud/ui_hud.gd`, `ui/core/ui_data.gd`, `ui/mock/ui_mock_feed.gd`, `ui/tools/hud_check.gd` (12 lines) | The displayed names come from the sim (`f.name`), the profile ids from `f.id`; the mock and the check's literals |

### Narrative and Audio

| What | Owner | Change |
| :--- | :--- | :--- |
| `data/narrative/combat_barks.json`: the per-fighter blocks keyed `KAI` and `VORR` | Narrative | Keyed by roster id. The line ids (`last.kai.1`) can stay: they are ids of lines, not of fighters, and the voice lab knows them |
| `audio/data/cues.json`, `audio/data/grunts.json`, the babble's voice keys | Audio | Keyed by roster id |
| The text in `names.json` | Narrative | The placeholders tonight; Orb's names later |

### QA

| What | Change |
| :--- | :--- |
| `qa/godot/bands.js`: the bands `1.kai` and `9.kai42`, read from a record's `names` | Key on `ids` (the new field in the batch's record). Whether the band's own label is renamed is QA's call; renaming it breaks comparison with older reports |
| `qa/run-godot.js` | It reads `data/fighters/VORR/meters.json` **by path**, and its S0 re-test text names KAI |
| `qa/lib/arms.js` (labels), `qa/godot/selftest.js`, `qa/lib/probes.js`, `qa/balance-report.js`, 2 tests | Literals and labels |
| `qa/baseline-p0.json`, `qa/baseline-p0.md`, `qa/known-bugs.md` | **Not rewritten:** they are records of past runs |

### Not in this window

- Docs. Hundreds of mentions; they are history and prose. `CLAUDE.md`'s line about the placeholders is the EP's.
- The prototype and the JS core.
- Arm names (`mirror-hero`, `mirror-villain`): they name roles, not fighters.

## 4. The order of edits, for one window and one regeneration

1. **Simulation, step A (ids only).** The folders, `roster.json`, the two `id` fields, `golden_recipes.gd`, `parity.gd`, `batch.gd`. The displayed names stay as they are.
2. **The keys that follow the ids, in the same working tree,** each owner in turn or by the EP's grant: Combat's two files and the frozen copy; Encounter's `alchemy.json`; Tools' parked script and fixtures; Animation's three data files and `anim_data.gd`; Rendering's and VFX's two tables; UI's bridge and profiles; Narrative's and Audio's keys; QA's scripts.
3. **Gate A.** Section 5's first proof. Everything must pass here before any name moves.
4. **Simulation, step B (names as data).** `names.json`, the loader, the three strings out of the two `fighter.json` files. With the placeholder text the EP chose.
5. **Gate B, then the one regeneration and the full gates:** `npm test` 5 of 5, parity, determinism, the loader check, the validator and its self-test, `anim_check`, the HUD check, QA's self-test.

Steps 1 and 2 cannot be committed apart: between them the director finds no finisher or style for the new ids.

## 5. Goldens and proofs

| Step | Must not move | Moves |
| :--- | :--- | :--- |
| A, ids only | Tick counts and **every light digest** (the feed and the events carry names, not ids) | Every full-state checkpoint and tick-0 state (the id is in the state hash); the roster data hash; the combat data hash |
| B, names as data, same text | Everything in step A's result | The roster data hash only |
| B, with new placeholder text | Tick counts and every full-state checkpoint (a name is not in the state hash) | Light digests, by the feed lines and banners that print a name |
| Later: Orb's names | As the row above | As the row above |

One caveat for step A: if Combat also renames the finisher keys `kai` and `vorr`, any event or feed line that carries a finisher's key moves the light digest of the matches that reach a finisher. Renaming only the fighter ids that point at those keys avoids it (question 3).

So with the old text kept, the whole window is proven by "light digests and tick counts identical". With new text, the proof is "tick counts and full-state checkpoints identical after step A's". Either way the matches are the same fights.

## 6. What is risky

1. **A lookup by name that nobody listed.** The grep finds words, not habits. A table keyed on the name keeps working tonight if the text stays `KAI` and breaks silently on the day Orb's names land. Step B with *changed* placeholder text is the only test that finds these now. I would change the text tonight for that reason, and take the weaker proof.
2. **A half-applied tree.** Many owners, one window. Gate A must be run on the whole tree, not on each owner's part.
3. **QA's comparisons.** Band ids named after a fighter (`1.kai`) either keep an old name for a new fighter or break the series. QA's call, before the window.
4. **Paths.** `qa/run-godot.js` and Tools' fixtures hold folder paths. A missed one fails loudly, which is the good kind.
5. **Replays.** The roster data hash changes, so replays recorded before the window are refused. Intent version 4 has just done that anyway.
6. **The frozen combat-parity copy** must be refreshed in the same commit, or the loader check fails.
7. **Animation's aliases** (`replaces`, `pair_live`) exist because the roster id was not the fighter's own key. Dropping them is cleaner; keeping them one more window is safer. Animation's call.

## 7. Rulings (the EP, 2026-10-05)

1. **The displayed names change in this window: `PROTAGONIST` and `RIVAL`** (Orb's own words for the neutral ids). That is the test that finds a lookup by name. So the proof is section 5's third row: tick counts and full-state checkpoints must not move after step A; light digests move by the text.
2. **`title` and `sigName` move to `names.json` with `name`.** Their text stays as it is tonight.
3. **Combat renames the finisher keys too:** one spelling everywhere, `protagonist` and `rival`. Light digests move where an event carries a finisher's key; accepted.
4. **QA's band ids keep their historical names** (`1.kai` stays as an id; only its label changes), so the series is not broken.
5. **Not this window, but mine:** a stun ends the stance mask and the two new held levels, as it ends `lightHeld` and `heavyHeld` (three lines in `SimWounds.gateIntent`). It rides in my next window, not as its own regeneration.

## 8. The checklist: every owner's lines

Line numbers are as of 208c6c7 (re-read on 2026-10-06 after intent version 4, World's stages, Animation's gesture wave and the dynamic intros; what that added is listed under the table). "Key" means a lookup key; "text" means a comment, a label or a message. A row is done when the file no longer names `KAI`, `VORR`, `kai` or `vorr` as a fighter's key, or the row says it stays.

| Owner | File | Change |
| :--- | :--- | :--- |
| **Simulation** | `data/fighters/KAI/`, `data/fighters/VORR/` | Rename the folders to `PROTAGONIST/` and `RIVAL/` |
| Simulation | `data/fighters/roster.json` | `["PROTAGONIST", "RIVAL"]` |
| Simulation | `data/fighters/*/fighter.json` line 4 | `id` |
| Simulation | `data/fighters/*/fighter.json` line 6 | `name`, `title`, `sigName` leave `identity` (step B) |
| Simulation | `data/fighters/*/fighter.json`, `finishers.base` | `protagonist`, `rival` (Combat's new keys) |
| Simulation | `data/fighters/names.json`, new | The two rows: name `PROTAGONIST` and `RIVAL`, the titles and signature names as they are |
| Simulation | `sim/core/fighter_data.gd` | Read `names.json`; fold it into the roster hash; a fighter with no row shows his id |
| Simulation | `sim/core/tools/golden_recipes.gd` lines 418 to 424 | The arms' `slots` from the roster; the mirror names built from the fighter's name plus `-A`, `-B` |
| Simulation | `sim/core/tools/parity.gd` (117 lines) | Ids and names from the roster, not literals: the order check, the arm checks, the tallies |
| Simulation | `sim/core/tools/batch.gd` lines 118, 302 | A record gains `ids` |
| Simulation | `sim/core/test/golden.json` | Regenerated once, at the end |
| **Combat** | `data/combat/finishers.json` line 7 | `byFighter`: `{"PROTAGONIST": "protagonist", "RIVAL": "rival"}` |
| Combat | `data/combat/finishers.json` lines 110, 154 | The finisher ids `kai`, `vorr` become `protagonist`, `rival` |
| Combat | `data/combat/finishers.json` lines 112, 156 | `fighter`: the new roster ids |
| Combat | `data/combat/finishers.json` line 6 | Text (`by fighter name` should read `by roster id`) |
| Combat | `data/combat/styles.json` lines 27, 28 | The two fighter keys |
| Combat | `data/combat/recipes.json` line 5 | Text |
| Combat, through the EP | `sim/director/test/combat-parity/finishers.json` (6 lines) | The frozen copy, refreshed to match |
| **Encounter** | `data/director/alchemy.json` lines 7, 8 | Drop the `fighters` map (the lower-cased id is the pool's key) |
| **Tools** | `docs/tools/pending/apply-split-keys.cjs` | Run it |
| Tools | `tools/fixtures/cases.json` lines 155, 161, 187 | The finisher cases: `/select/byFighter/KAI`, the id `kai` |
| Tools | `tools/fixtures/cases.json` lines 1397, 1403, 14031, 14048, 14054, 14064, 14070 | The `/fighters/KAI` and `/fighters/kai` cases (styles, ragdoll motion) |
| Tools | `tools/fixtures/cases.json` lines 1955, 1961, 10234 | The UI profile alias cases (`/aliases/kai`, `/fighters/kai`), to match UI's new alias |
| Tools | `tools/fixtures/cases.json` lines 41113, 41145 | The `replaces` cases, to match Animation's change |
| Tools | `tools/fixtures/cases.json` line 11853 | Stays: `last.kai.1` is a line's id |
| Tools | `tools/fixtures/virtual/data/fighters/FIXTURE_*/` (4 files) | Text only |
| Tools | A schema for `data/fighters/names.json`; the fighter schema's `identity` | New; the three strings leave `identity` |
| **Animation** | `data/anim/fighters.json` lines 6, 41 | `replaces`: the new ids, or dropped if the roster id is now the fighter's own key |
| Animation | `data/anim/pair_live.json` lines 4 to 6 (`aliases`) and line 8 | The aliases already map `rival` to `antihero`. Confirm that the roster ids as the sim spells them, `PROTAGONIST` and `RIVAL` in upper case, resolve to the `protagonist` and `antihero` roles (line 50, line 194: the strikes, entries and the ten gestures hang there). `AnimData.ensure_fighter` is given `f.id` |
| Animation | `data/anim/ragdoll_motion.json` line 4 | `fighters` keys |
| Animation | `render/anim/anim_data.gd` line 208 | The id-to-fighter rule's text; the rule if `replaces` is dropped |
| Animation | `render/anim/tools/anim_check.gd` (35 lines), `coverage_live.gd` (3), `gesture_lab.gd` (lines 9, 52, 90), `zip_entries_lab.gd` (line 8), `zip_lab.gd` (2), `press_lab.gd` (2), `laststand_lab.gd`, `anim_reel.gd` | The tools' literals: ids from the roster. `gesture_lab.gd` and `zip_entries_lab.gd` are new since the first list: each holds a table `{"protagonist": "KAI", "antihero": "VORR"}` |
| **Rendering** | `render/core/look.gd` line 171 | `DAMAGE_OUTFIT` keys |
| **VFX** | `render/vfx/glare.gd` line 23 | `WEARERS`: it lists `VORR`, `antihero` and `rival` as "ids and names". Key on the id: `RIVAL` |
| VFX | `render/vfx/aura.gd` line 112; `render/vfx/tools/effects_check.gd` (2), `react_shots.gd` (1) | Text; the tools' literals |
| **UI** | `ui/core/ui_sim_bridge.gd` line 18 | **A lookup by name:** the profile id is `f.name` in lower case. Use `f.id` |
| UI | `ui/data/readout_profiles.json` lines 42, 43 | The alias rows `kai`, `vorr` become `protagonist`, `rival` |
| UI | `ui/hud/ui_hud.gd` lines 13, 315; `ui/core/ui_data.gd` lines 104, 105 | Text |
| UI | `ui/mock/ui_mock_feed.gd` lines 28, 158; `ui/tools/hud_check.gd` (12 lines) | The mock's and the check's literals |
| **Narrative** | `data/narrative/combat_barks.json` lines 18, 31, 145, 146 | The per-fighter keys become roster ids |
| Narrative | The same file, lines 21 to 23, 34 to 36 | Stay: `shout.kai.sig.1` and the rest are line ids. The shouted text names the signatures, which now live in `names.json`: say if a shout should follow `sigName` |
| Narrative | `data/fighters/names.json` | The text is Narrative's from here on |
| **Audio** | `audio/audio_babble.gd` line 87 | **A lookup by name:** the voice is found by `S.fighters[actor].name`. Use `.id` |
| Audio | `audio/data/cues.json` lines 5, 6 | `fighters` keys become roster ids |
| Audio | `audio/data/grunts.json` lines 7, 252 | Text |
| **QA** | `qa/run-godot.js` line 92 | **A path:** `data/fighters/VORR/meters.json` becomes `RIVAL` |
| QA | `qa/godot/bands.js` lines 45, 81 to 83 | Read a record's `ids`; the ids `1.kai` and `9.kai42` stay; the labels change |
| QA | `qa/run-godot.js` lines 108 to 131; `qa/godot/selftest.js` (4 lines); `qa/lib/arms.js` (8 labels); `qa/lib/probes.js` | Text and literals |
| QA | `qa/balance-report.js`, `qa/tests/tables.test.js`, `qa/tests/diff.test.js` | Stay if they run on the prototype's own roster (the legacy baseline); QA to confirm |
| QA | `qa/baseline-p0.*`, `qa/known-bugs.md` | Stay: records of past runs |
| **Nobody** | `sim/core/roster.js`, `sim/core/test/frozen/golden-js.json`, `prototype/` | Stay (ADR 0006) |

**What tonight's files added (re-read on 208c6c7).**

- **New rows above:** Animation's two new tools and its alias check; ten more lines in `anim_check.gd`. Line numbers moved in `golden_recipes.gd`, `fixtures/cases.json` and `data/anim/fighters.json`.
- **No new fighter id or key** in World's stages data (`data/biomes/stages.json`), the intro data (`data/fight/intro.json`: it names roles, `first`, `second`, `left`, `right`, never a fighter), Tools' new schemas, or the new waves `protag9` and `rival6` (wave names, keyed to Animation's own fighter keys).
- **`sim/director/intro.gd` line 117** prints the first fighter's displayed name in a feed note (`INTRO first: ...`). It is text and follows `names.json` by itself. It keys on nothing.
- **Still to be written, so key it right the first time:** the host's intro memory (the no-repeat list for each pair, UI's) and Narrative's plot grammar (`data/narrative/intro_plots.json`, not in the tree yet) are both per pair. They must key a pair by roster ids, never by displayed names. One more line each for UI's and Narrative's briefs.
- **QA has uncommitted edits** in `qa/godot/bands.js` and `records.gd`; its rows above are unchanged, but the line numbers there will move.

**Two lookups by name were found while listing:** UI's bridge and Audio's babble. Both work tonight only because the name and the id are the same word. With the names changed in this window, both fail visibly if missed, which is the point of ruling 1.
