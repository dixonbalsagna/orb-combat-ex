# tools/movegen: the moveset generator

Generates each fighter's moveset, per stance and face button, from parts and an identity row (`docs/combat/moveset-generator.md`). Node, no dependencies, no clock, no generator state: the only randomness is a hash of the seed, the fighter, the cell and the candidate, so the same inputs give the same bytes. Owner: Combat and Choreography (built under the cloud brief `docs/ep/cloud-briefs/combat-moveset-generator.md`; Tools holds `tools/`).

It is a function-for-function port of Combat's reference script `docs/combat/pending/movegen/gen_moveset.py` (version 21). The port writes the same files byte for byte, and `test/run.mjs` proves it on a full `--relock` whenever `python3` is on the path. The Python stays beside its data as the reference until the EP retires it.

## Use

```
node tools/movegen/movegen.mjs                   generate the build's movesets (docs/combat/pending/movegen)
node tools/movegen/movegen.mjs --check           regenerate and compare; exit 1 on any difference, Legal match, name match,
                                                 dead-end string, gate under a fifth, or a piece of today's brawl pools not generated
node tools/movegen/movegen.mjs --self-test       the reference's 91 refusal cases
node tools/movegen/movegen.mjs --propose         generate the proposals of docs/combat/proposals/identity.proposals.json
node tools/movegen/movegen.mjs --propose --check
node tools/movegen/movegen.mjs --merge-legal     copy Legal's new or reworded rows (mirrored groups) into parts.json
node tools/movegen/test/run.mjs                  the tool's own tests (40 checks, about 20 s)
```

Options: `--dir DIR` (the folder of inputs and outputs), `--relock` (ignore the lock: a deliberate act, with its own sheet), `--recipes PATH` (the recipes whose blur patterns and burst pools are checked; default `../recipes.brawl.json` beside the folder), `--live PATH` (the recipes the fighters have today, for `coverage.md`; default `data/combat/recipes.json`).

It refuses to write when any move matches one of Legal's rows, any name has one of Legal's words, or a string runs out of blows.

## Inputs and outputs (one folder)

| File | | What |
| :--- | :--- | :--- |
| `parts.json` | in | the grammar, Legal's rows (a copy `--check` compares with `docs/legal/movegen-banned.json` row by row), and `nameScreen` |
| `identity.json` | in | how each fighter bends the grammar |
| `cells.json` | in | five stances by four buttons: what each cell holds, its count and quotas, the seed; and `pools`, the rules that write the recipes' pools |
| `lock.json` | in and out | every strike move's id and shape: an id never changes shape |
| `moveset.<fighter>.json` | out | `combat.moveset/1`, every cell's moves |
| `review-sheet.md` | out | every move on one row, for Combat, Animation, Legal and Orb |
| `pools.json` | out | the pools of `data/combat/recipes.json`, written from the cells in the recipes file's own shape |
| `coverage.md` | out | the generated pools against what each fighter has today, and what the generator cannot express |

Animation's data is read in place: the strike and entry manifests in `data/anim/waves/`, and `data/anim/tips.json`.

## Legal

- **Shapes and strings.** Every shape row (b01 to b14 and the shape rows of other groups) refuses a candidate before it is picked; every sequence rule is applied to whole strings, bursts and mashed runs; the energy and motion rows refuse table and travel moves. `--check` also re-tests the files on disk, so a move edited by hand is caught.
- **The copy is Legal's.** `--check` fails when a row of Legal's file is missing from `parts.json` or reworded; `--merge-legal` brings the copy up to date without touching Combat's machine form of a row (a new row arrives as a condition, with no `kind`, until Combat gives it one).
- **Names.** `lib/names.mjs` screens every name the generator writes (a heavy's plain name, a special's id, words and looks, a fighter's key and title) against Legal's word lists, read from Legal's own files each run: `movegen-banned.json` e11 and e14, `never-use-words.md`, and stage 0 of `name-screening.md`. Nothing is copied into Combat's data, so a word Legal adds is screened at once. A source that yields no words is a failure (Legal's wording changed). `parts.json` `nameScreen.allow` takes out plain anatomy ("ball of the foot").

## Proposals

`--propose FILE` lays each row of FILE over the build row it is `like` (as `docs/combat/pending/roster/build_roster.py` does for the roster sketches), generates the rows beside the two fighters of the build in a temporary folder, runs twice so each proposal's shares count against the others' locked moves, and stops if the build's fighters' moves move. It writes `moveset.<key>.json`, `lock.proposals.json` and `review-sheet.md` beside FILE. A proposal must reach a fifth of Game Design's gate on blows.

## Schemas

`schemas/` holds the shapes this tool writes or added: `combat-moveset` (`combat.moveset/1`), `combat-moveset-lock` (`combat.moveset.lock/1`), `combat-movegen-pools` (`combat.movegen.pools/1`), `combat-identity-proposals` (`combat.identity.proposals/1`) and `combat-movegen-inputs` (the two new input blocks, `nameScreen` and `pools`). They use only the keywords `tools/lib/schema.js` supports, and `test/run.mjs` validates every file against them. They live here and not in `tools/schemas/` because nothing they describe is under `data/` yet: when the movesets move to `data/combat/movesets/`, Tools moves them, maps them and adds the fixture cases.

## The port's one change

The string report's proof that a fighter's four point-blank bolts can make a mashed run of 30 under Legal's e09 is a depth-first search with a budget, ordered by a hash of the fighter's key. One key can run out of budget where a run exists (the Prodigy's did, with the same four bolts the rival passes with). The port tries up to seven more keys before it says the run cannot be made. Only that verdict can change; no generated move does, and a fighter that passed on the first key is as before.

## Files

`movegen.mjs` (the CLI and `generate()`), `lib/generator.mjs` (the grammar, the cells, the checks), `lib/sheet.mjs` (the review sheet), `lib/selftest.mjs` (the reference's cases), `lib/names.mjs`, `lib/pools.mjs` (pools and coverage), `lib/roster.mjs` (proposals), `lib/legal.mjs` (`--merge-legal`), `lib/py.mjs` (Python's JSON text, ordering, rounding and truthiness, which the byte-for-byte output depends on), `test/run.mjs`.
