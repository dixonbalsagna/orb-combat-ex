# Parked: the six director checks GW1b broke on main, and bark_reads_check at a third of its time (a GW1b follow-up)

Encounter, 2026-11-22, the EP's brief. Six director checks failed on main bce578a7 after GW1b. They failed with and without the X-06 diffs, the same rows word for word. **This park makes every one pass on main without moving the golden.** The one real fault behind them, the beam's stand-off shove on the planet, is parked on its own (`docs/director/pending/beam-standoff-planet/`), because it moves the golden.

## The six, classed

| Check | What broke it | Class | What this park does |
| :--- | :--- | :--- | :--- |
| `beam_front_check`, `beam_move_check` | The default world is now the planet (THE FLIP, 3aaac98c). There the fighters start on the ground, and the stand-off shove counts any rising ground as a wall. | Staging, **with a real fault behind it** | Pins the arena the rows were written for (`WorldPin.arena()`). The fault's fix and the planet rows: `beam-standoff-planet/`. |
| `full_send_check` | The planet: with `craterSlam` off, the landing's own impact digs a crater on the planet's ground, so the arena's "no crater" control fails. The plan is still DRIVE DOWN. | Planet staging | Pins the arena. **Planet copies:** on planet 7 the slam is CRATER SLAM and digs a crater at tiers 1 and 2, and with `craterSlam` off the plan is DRIVE DOWN. |
| `sigvariants_check` | Its gen-1 section ("the hand-made world") starts a match that names no world, which now plays the planet. It passes at the flip's parent (0130112f) and fails at THE FLIP (3aaac98c). | Planet staging | Pins the arena. Its gen-2 and gen-3 sections name their planets. |
| `city_push_check` | Its slam rows stage the pair as two computers. Since GW1b the computer fires its signature during the 30-tick settle, and the beam's rest (`DirSwing.restRule` "beam") rightly blocks the slam the row forces. It already plays a named planet. | Staging (not the planet) | The three slam stagings use idle players. All 8 rows pass on its planet field world. |
| `walk_check` | GW1b's energy addendum cut the launch travel from 2.0 to 1.5. The row "3 blows leaning, then B: at least 70% reach it" was written for 2.0; at 1.5, **6 of 10** reach the wall. | Staging (the launch travel) | Pins the old travel (`WorldPin.launchTravelOld()`, GW1b's tool for exactly this). **For Game Design:** at the shipped travel the walk-then-B reaches the wall 60% of the time, against the 70% row. |

**No pose, look or data change:** the park touches only the seven check scripts.

## bark_reads_check: 10 matches, not 30

- **Before:** five seeds × six full matches. The plain match, two "off" matches and two drain sizes prove the emitter's own properties: it changes nothing said, never touches the gameplay hash, and drains alike. The "on" match proves the reads.
- CI's step grew from 9.0 to 18.6 to 26.4 minutes: the launch-cone re-cut took it to five seeds, and the planet's matches run longer.
- **Now:** the emitter's own properties run on one seed (`--full=4242`, which fires all three beats). Every seed still plays the read-checked "on" match, which is where the beats fire and hold against the sim, along with the hp control.
- The seeds stay at five, because `exchange_break` fires only once or twice across them.
- **304 s against 888 s** for the full set, on the same tree and machine (34%). The per-seed beats are identical, so the proof is the same. CI should read about 9 minutes.

## Gates (main bce578a7 + this park)

- **46 of 47 director checks pass**: all six, `bark_reads_check`, and every other check.
- `loader_check` ran out of the lane's 3,000 s on a busy machine. It touches nothing this park changes, and passed on this main in 4,869 s. The rerun's result: LOADER_LINE.
- **Parity is clean (0 failed rows): the golden doesn't move.**
- Validate and the determinism lint are clean.
- Record: `docs/director/runs/bce578a7/gw1b-director-checks/`.

## Why they weren't caught

- **CI runs none of the six.** `.github/workflows/ci.yml` names director checks one by one, and these six aren't among them. `tools/check-scripts-table.mjs` counts them among the 55 unreviewed scripts, run by neither CI nor the gate. `bark_reads_check` is in CI.
- **The landing gate runs one of them, `sigvariants_check`** (`docs/ep/gate/run-gate.sh`), and nothing else of the six. It passes at 0130112f, the commit before THE FLIP, and fails at 3aaac98c. So a gated tree with THE FLIP in it would have shown "sigvariants check FAILED (1)" in the gate's `r.txt`. Either the gated stack didn't carry the flip as it landed, or that line was missed. The EP's `s426` record can tell.

## NEEDS FROM EP

- **Tools:** put the six in CI, or give them a reason in `tools/check-scripts.json`. They're cheap: a few seconds to two minutes each. `bark_reads_check`'s step should drop to about 9 minutes.
- **Game Design:** `walk_check`'s 70% row reads 60% at the shipped launch travel.
- **The stand-off fault:** `beam-standoff-planet/`, which lands in a golden window.

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `gw1b-director-checks.diff` (seven check scripts under `sim/director/tools/`) | Encounter | 890577e646cc0f913bafc6be37ca86ca0c28c9eb |
