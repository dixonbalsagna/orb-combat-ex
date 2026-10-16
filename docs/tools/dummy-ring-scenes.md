# The dummy, ring and launch scenes of the flash set (2026-10-16)

Owner: Tools. Legal's RL-139: each new pairing at least 3 captures, and a mash-on-the-dummy scene for each fighter in both modes. The EP's brief added a ring of three to five bodies (Camera's 3v1) and a clip where player one launches the AI (Camera's keep rule).

## The scenes

All three are in `tools/flash/sources.json` (a scenario may now carry `slotsList`: one run for each list of fighters, one seed, named `<scene>-<ids joined by ->-<mode>` the way an AI pairing is), `tools/flash/flash_worst.gd` and, as a patch for Rendering's file, `docs/tools/pending/flash-capture-dummy-ring-launch.patch`. The hook patch also lets the page's `slots` be three to five ids.

| Scene | Fighters | What player one does (a pad, as a person would) | Clips |
|---|---|---|---|
| `mashdummy` | PROTAGONIST v REFERENCE, RIVAL v REFERENCE (the dummy stands idle) | A cycle of 600 ticks: X mashed at the fastest tap (every 4 ticks), Y mashed, X held (the burst), RB held and X mashed in reach (the energy mash), RB and B (the blast), then B to launch and X after it (the launcher chain). Ki kept full | 4 |
| `ring` | PROTAGONIST v RIVAL with 1 guard (3 bodies), PROTAGONIST v RIVAL with 3 guards (5 bodies); the guards fight | X mashed, Y now and then, the signature once in 300 ticks. Ki kept full | 4 |
| `launchai` | the default pair, the real AI | B tapped every 45 ticks, walking into reach. In the seed's 1,800 ticks he launches the AI twice and is launched once | 2 |

Read headless on HEAD ee822c5e (1,800 ticks each): `mashdummy` 84 and 153 damage events, the register's worst 1 in 60 ticks; `ring` 140 and 138, worst 3; `launchai` 106, worst 1 (P1 launches the AI once). Player one sprints (dodge held) when a launch has sent them 900 units or more apart, or the scenes spend their ticks flying back (launchai read 42 damage events without it, after Encounter's changes). The check wants 60. The required set is now 66 clips (56 before).

The pairings of the dummy (Simulation's roster) were already in the set in 06b0200e: 7 seeds for the Protagonist and the dummy, 6 for the Anti-hero and the dummy, so each new pairing has at least 3 captures.

Not done: the ring runs with the game's defaults, so Camera's `many_framing` (off by default) is not on in these clips. When Camera wants the clips with it on, it is a page switch like `hold=1`; say so. The sun pan (`w04`) waits for the sun.

## The schema keys of the parked changes

Checked on a scratch export of main with every park applied (Animation's four-patch stack: many-bodies, runs-look, tenth-round, combat-pieces; VFX's energy-and-choreo vfx.patch; Combat's `recipes.split.json`, Encounter's scripts (with the beam struggle's two grants)). Before the keys: 18 unknown-property errors from Animation's stack alone; after: 0 (203 files).

| Key | Where | Status |
|---|---|---|
| `mediumMash`, `heavyMash` | `combat-recipes` `brawl` and `fallback.lower` | added now (the pool must exist for every fighter: `xref:recipes-brawl` already reads it) |
| `breath_ticks`, `press_run`, `march`, a style's `squash_pose` | `anim-press-styles`, on every style | added now; a style's `squash_pose` names fighters and real poses (new rule `xref:pressstyles-squash`). (the file's own top-level `squash_pose` was already there) |
| `ease` per fighter | `anim-fighters` | added now: a map of a press style to `{prof, carry_ticks, twist, ...}`; every key is a style of `press_styles.json` (new rule `xref:fighters-ease`) |
| `chargeGuess`, `heavy.charge.guessTicks` | `director-ai`, `director-interrupts` | added now, byte for byte what Encounter's `pg.cjs` writes (their script finds the keys there and writes the same) |
| `beamStruggle` | `director-interrupts` | added now, byte for byte what `bs.cjs` writes |
| a `cash_in` style | `anim-press-styles` `styles` | added (a full style definition, as `tech`); optional |
| `roles.<fighter>.beam` `{charge, fire, bone}` | `anim-pairlive` | added: charge and fire are wave sequence ids, bone optional |
| manifest strike field `named` | `anim-wave-manifest` | added (boolean) |
| the `common` row | `fighters.json`, `pair_live.json` roles | nothing to add: a fighter and a role are open keys; validated with the stack |
| a wave called `guard1` | the four wave schemas (manifest, keysets, entries, entrymap) | the wave-name pattern is now `^(wave|protag|rival|guard)[0-9]+$` |
| wave `round10`, prefix `rt`; `pair_live` shared `round10` | `anim-pairlive`, the wave schemas | already accepted: the name pattern is `^[a-z]+[0-9]+$` and the pose ids are generic. Nothing to add |
| `energy.json` keyed by roster id | `vfx-energy` | nothing to add: VFX's re-key (9bde4409: default, protagonist, rival, rival_short, reference) fits the schema their `energy-and-choreo/vfx.patch` carries; validated with it applied. My earlier `apply-vfx-energy-ids.cjs` is dropped |

Eleven fixture cases cover the new keys (`tools/fixtures/cases.json`: `recipes-brawl-mash-*`, `anim-pressstyles-run-*`, `anim-pressstyles-march-*`, `anim-pressstyles-style-squash-*`, `anim-fighters-ease-*`).

A warning that is not Tools': with Combat's split recipes in place, `data/director/alchemy.json` says roster id REFERENCE "has no entry here and no pool reference in data/combat/recipes.json".
