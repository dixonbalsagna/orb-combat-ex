# The calm-moment turn (window 3): in scratch on main's HEAD, parked, not applied

Re-cut 2026-10-22 on 03427822 (the calm turn's fix, Game Design's rulings-2026-10-22 5a, below), earlier on 79693404 (windows 0, 1, 4 and farColumn applied, and the surface-class fix) against Encounter's `docs/director/calm-turn.md` and Game Design's `rulings-2026-10-19b.md` section 1 with 1e. Design and findings: `docs/world/calm-turn-world.md`. **Behind a switch, off (`rings.json` `turn.on` 0, or `setup.arena.turn`): the golden is unchanged.**

| File | What |
| :--- | :--- |
| `calm-turn-window3.diff` (14 files) | `sim/world/epoch.gd` (`WorldEpoch`) and `epoch_check.gd` (+ `.uid`); `planet.gd` (`readSlice` in three steps, `RingJob`, `memoRing`); `planet_world.gd` (`gen` split into `chordsOf`, `settleBiomes`, `platform`, `settle`: the same world); `ringpick.gd`, `rings.json` and its schema (the `turn` block); **Simulation's lines** `state.gd`, `hash.gd`, `view/fx.gd`, `sim.gd`; **Tools'** one case in `cases.json`. `mk_turn.py` makes it |
| `epoch.gd.txt`, `planet_world_tail.gd.txt`, `epoch_check.gd.txt` | The module, the new `planet_world.gd`, the check as they stand |
| `turn_dump.gd.txt`, `gen_turn.py`, `turn_whole.json` | The picture: a real turn dumped by `turn_dump.gd`, drawn by `gen_turn.py` into `homework/31c-a-turn.svg` |

## Game Design's fix (rulings-2026-10-22 5a) and Encounter's grant, both in

- **A landing turns less rather than not at all.** The pivot is fixed at the ask. At the swap the larger distance `s` of a fighter from it is read: if `s` x sin(angle) would move the ground under a fighter more than `moveMax` (300 units, in the data), the angle is scaled down to the one that moves exactly that much, never under `minDeg` (2) and never over the chosen bearing (the 10 degree cap stands). The pivot is not re-picked at the swap. A scaled turn reads its ring on the tick (a warm read is of the chosen angle): a hitch (about 150 to 450 ms) only when the pair is off the pivot. `epoch_check`: a pivot off by 0, 3,600, 9,000 and 40,000 units gives 10.00, 4.60, 2.00 and 2.00 degrees; the ground under the fighters moved 22, 299, 311 and (floor) units.
- **Encounter's calm-turn grant is folded in** (`choose` records the pick's tick and `due`, `cancel(S)` drops a pending pick): do not run `docs/director/pending/calm-turn/grant_world.cjs` (it refuses: `cancel` exists already). Neither is hashed.

## Simulation's two conditions on `hash.gd` (2026-10-22), in

- **(a) The decided turn is hashed:** while `S.epoch` is set the hash also holds 0 or 1 for a turn that is decided but not swapped, and, when it is, its bearing and pivot column.
- **(b) The turned world is pinned:** the epoch keeps the hash of the slice of the ring the match is on (`WorldPlanet.sliceHash`, set when the match starts and at each swap) and the hash holds it, so the new ground and biomes show in the state hash and not only the buildings. `epoch_check` has two new checks: a decided turn and its bearing change the hash before the swap, and after the swap two different turns from one state hash differently and the hash holds the new ring's slice hash.
- The surface-class fix (`contact.gd`) is on main (79693404), so the patch no longer carries it.

## Proof (clean export of 79693404 plus the patch; below-normal priority)

- `epoch_check.gd`: **0 failed**: the data stands at Game Design's caps and is off; no bearing over 10; a turn keeps the pivot's column on the same point and turns by its bearing (worst error 0.0000 degrees; a Whole ring drifts its bearing); under 60 s no ask, at 100 s the candidates, none after the fourth turn, none inside 60 s of the last; a body in flight or no hold stops the swap; the swap: the buildings near the pair are the same buildings with the same hurt and fallen state, the ground and crater under the pair are as they were, outside the zone the ground is the new ring's and unmarked, arrays keep their length and the ledger is untouched, every building unique by place and plan, inside the world and on dry ground; an `arena_turn` event; the epoch is in the hash; the drift cap (a ring 36 degrees from its first axis is offered the one turn that keeps it within 40); the listed places are held by the new ring, not the old, within view (192 candidate lists over 8 planets); a ring read 64 columns at a time is `readSlice`'s slice; a Half match turned with or without the warm read plays 300 ticks on to the same hash; a Close match to the -x side and a Whole match turn and play on, the same twice.
- **Cost** (busy PC): the slice read 450 ms Whole, 286 ms Half, 147 ms Close (warm it a few columns a frame); the swap itself 10.9, 6.9 and 2.2 ms (one tick).
- `run-all.js`: **all 5 stages passed** (unit 8.5 s, parity 57.7 s, soak 13.6 s, golden 0.4 s, godot 241.4 s): the golden is unchanged. Rendering's 15 gates all passed. `node tools/validate.js` 234 files, 0 errors, 0 warnings; `--self-test` 8577 of 8577. `arena_check`, `ringpick_check`, `far_check`, `planet_check`, `planet_world_check`, `brunt_check`, `wall_check`, `collateral_check`, `interior_check`, `repeat_check`, `props_check`, `probe`: 0 failed.
- `git apply --check` of the diff on the newest main (79693404): ok; applied it equals the scratch tree.

## For the others

See `docs/world/calm-turn-world.md`: Simulation's lines (`state.gd`, `hash.gd`, `view/fx.gd`, `sim.gd`), Tools' case, Encounter's `DirCalm` calls, Rendering's and Camera's `arena_turn` event, Game Design's first values. 
