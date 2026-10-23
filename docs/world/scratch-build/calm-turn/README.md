# The calm-moment turn (window 3): in scratch on main's HEAD, parked, not applied

Re-cut 2026-10-22 on e09dbbbf (the arena_turn event at the end of the pass list, beside the ricochet's; every sin and cos is the sim's own: SimDetMath, pi from its bits; the sim drives the warm: no host calls anything; then the warm-only swap and the refusal, the Executive Producer's two rulings, below; before that Game Design's rulings-2026-10-22 5a), earlier on 79693404 (windows 0, 1, 4 and farColumn applied, and the surface-class fix) against Encounter's `docs/director/calm-turn.md` and Game Design's `rulings-2026-10-19b.md` section 1 with 1e. Design and findings: `docs/world/calm-turn-world.md`. **Behind a switch, off (`rings.json` `turn.on` 0, or `setup.arena.turn`): the golden is unchanged.**

| File | What |
| :--- | :--- |
| `calm-turn-window3.diff` (14 files) | `sim/world/epoch.gd` (`WorldEpoch`) and `epoch_check.gd` (+ `.uid`); `planet.gd` (`readSlice` in three steps, `RingJob`, `memoRing`); `planet_world.gd` (`gen` split into `chordsOf`, `settleBiomes`, `platform`, `settle`: the same world); `ringpick.gd`, `rings.json` and its schema (the `turn` block); **Simulation's lines** `state.gd`, `hash.gd`, `view/fx.gd`, `sim.gd`; **Tools'** one case in `cases.json`. `mk_turn.py` makes it |
| `epoch.gd.txt`, `planet_world_tail.gd.txt`, `epoch_check.gd.txt` | The module, the new `planet_world.gd`, the check as they stand |
| `turn_dump.gd.txt`, `gen_turn.py`, `turn_whole.json` | The picture: a real turn dumped by `turn_dump.gd`, drawn by `gen_turn.py` into `homework/31c-a-turn.svg` |

## Game Design's fix (rulings-2026-10-22 5a) and Encounter's grant, both in

- **A landing turns less rather than not at all, with no hitch (re-cut 2026-10-22 for the Executive Producer's two rulings).** The pivot is fixed at the ask. **No ring is read on the swap tick, ever.** `choose(S, i, k, fallbackDeg)` (Encounter's pick: k columns of each ring a sim tick, fallback 2.5 for a landing pick and 0 for a form pick) marks the rings to warm (the chosen bearing and the fallback); **`WorldEpoch.tick` warms them itself, k columns of each every sim tick, so a host never calls anything** (the old `prewarm` is gone; a headless replay or a tool with no host warms and swaps on the same ticks as play); `warmAngles(S)` lists the warm bearings; `k` and the fallback are hashed with the warm count. At the calm tick the larger distance `s` of a fighter from the pivot is read: the swap takes the largest **warm** angle with `s` x sin(angle) within `moveMax` (300 units); if none does it **waits** (the turn stays decided, the next calm tick looks again); if even `minDeg` (2) would move the ground more than 300 (`s` over about 8,600) it **refuses** (the pick is dropped, `E.refused`, and the director asks again). The 300 rule wins over the 2 degree floor. `epoch_check`, a pivot off by 0, 3,600, 7,000, 7,800, 9,000 and 40,000 units: 10 degrees (ground moved 22), 2.5 degrees (163), waits, waits, refused, refused; a waiting turn swaps at its own 10 degrees once the pair stand on the pivot; a refused pick can be asked again. The hash also holds how many of the decided turn's rings are read. A ring read to completion in any chunking, or read cold in a process that never warmed it (`E.cold` 1), plays on to the same hash.
- **Encounter's calm-turn grant is folded in** (`choose` records the pick's tick and `due`, `cancel(S)` drops a pending pick): do not run `docs/director/pending/calm-turn/grant_world.cjs` (it refuses: `cancel` exists already). Neither is hashed.

## Simulation's two conditions on `hash.gd` (2026-10-22), in

- **(a) The decided turn is hashed:** while `S.epoch` is set the hash also holds 0 or 1 for a turn that is decided but not swapped, and, when it is, its bearing and pivot column.
- **(b) The turned world is pinned:** the epoch keeps the hash of the slice of the ring the match is on (`WorldPlanet.sliceHash`, set when the match starts and at each swap) and the hash holds it, so the new ground and biomes show in the state hash and not only the buildings. `epoch_check` has two new checks: a decided turn and its bearing change the hash before the swap, and after the swap two different turns from one state hash differently and the hash holds the new ring's slice hash.
- The surface-class fix (`contact.gd`) is on main (79693404), so the patch no longer carries it.

## Proof (clean export of e09dbbbf plus the patch and Encounter's calm park (ct.cjs, grant_sim.cjs, in scratch); below-normal priority, one Godot at a time)

- `epoch_check.gd`: **0 failed** (41 checks). New for the sim-driven warm: `SimCore.step` alone warms (10 ticks at k 16 read 160 columns of each ring); fallbackDeg 0 warms one ring and 2.5 two, a fallback not under the chosen bearing is left out, and `k` and the fallback are in the hash; **a headless replay of matches that turn (seeds 1 and 2, played by `SimCore.step` alone with no host) swaps on the same tick (186 and 65) and to the same hash when replayed, when the slices kept outside the state are lost mid-warm (the catch-up), and when the state is hashed every tick**. The earlier checks stand: no ring is read on the swap tick (`E.cold` 0), a part-read ring never swaps, the swap table (10 / 2.5 / waits / waits / refused / refused for pivots off by 0 / 3,600 / 7,000 / 7,800 / 9,000 / 40,000 units), geometry, caps, carry, hash, drift cap, listed places, Close and Whole.
- The twelve other World checks: 0 failed.
- `sim/core/tools/run-all.js`: **all 5 stages passed** (unit 9.6 s, parity 69.5 s, soak 15.1 s, golden 0.4 s, godot 284.9 s): the golden is unchanged. Rendering's 15 gates all passed. `node tools/validate.js` 234 files, 0 errors, 0 warnings; `--self-test` 8577 of 8577.
- `git apply --check` of the diff on e09dbbbf: ok. The move test in `tick` and the geometry use `SimDetMath` and pi from its bits (`_PI`), no engine trig; `state.gd`'s comment names the hashed terms.
- **Cost:** the slice read 450 ms Whole, 286 ms Half, 147 ms Close, spread over k columns of each ring a tick; the swap itself a tick with no read. Rendering's old-laptop bench puts the read at about 0.75 ms a column: see the profile note once it lands.

## For the others

See `docs/world/calm-turn-world.md`: Simulation's lines (`state.gd`, `hash.gd`, `view/fx.gd`, `sim.gd`), Tools' case, Encounter's `DirCalm` calls, Rendering's and Camera's `arena_turn` event, Game Design's first values. 

## The ground rule to 450 units (Game Design 2026-10-23, ruling 3), parked: `move-450.diff`

`data/biomes/rings.json` `turn.moveMax` 300 to 450 at every size, with `epoch.gd`'s comments and `epoch_check`'s pivots and thresholds following the data (`mk_move450.py`). At 450 a turn takes the chosen 10 degrees up to 2,590 units off the pivot, the 2.5 degree ring up to 10,300, waits up to 12,900 and is refused past it; `epoch_check` pivots 0 / 3,600 / 11,000 / 12,000 / 14,000 / 40,000 give 10 degrees, 2.5, waits, waits, refused, refused. Proved: `epoch_check` 0 of 41 failed, World's other 14 checks, `run-all` 5 of 5 (the golden unchanged), Rendering's 15 gates. Encounter's `DirCalm` reads `moveMax` from the data, so it follows.
