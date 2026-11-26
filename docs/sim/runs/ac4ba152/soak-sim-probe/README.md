# The sim alone across matches: does it keep memory? (Simulation, 2026-11-26)

The EP's question after the two-hour soaks of 0.1.1 (Linux `docs/tools/runs/ac4ba152/linux-soak-7200.md`, Windows `docs/qa/readings/soak-two-hours.md`): about 18 MiB more memory each match, never given back. Is it the sim's?

**Answer: no.** The sim alone keeps about 0.5 MiB a match, and its object count at every match start is the same (9,555). The soak's growth is outside the sim.

## The probe

A clean `git archive` export of ac4ba152, headless Godot 4.7.2, one process at below-normal priority, with its own data folder. It runs the sim alone, as the soak does (`qa/soak/soak_probe.gd`):
- one state, reused, with matches back to back on the next seed;
- the host's default world (`WorldDefault.apply(.., true)`: the fixed planet), the computer on both sides;
- each match runs to its KO or 300 sim seconds;
- no rendering and no host idle work.

At each match start and end it prints:
- the engine's memory (`OS.get_static_memory_usage`) and the object count;
- the size of every static cache that outlives a match;
- every container field of the state whose size changed since the same point of the last match.

| Pass | What | Result | Record |
| :--- | :--- | :--- | :--- |
| 2 (as the game does) | 6 matches; `S.out` is emptied after every step, as `SimHost` does; memory every 60 sim s | **Memory at match start: 107.8 → 109.1 → 109.5 → 110.3 → 110.6 → 111.1 MiB** (about 0.5 a match). It rises about 2 MiB during a 300 s match and comes back at the next start. Objects stay 9,555 to 9,590 | `pass2.log` |
| 1 (output never emptied) | 13 matches; nothing empties `S.out` | Memory at match start: 113.8 → 121.6 MiB over 13 matches (about 0.44 a match from match 2). Objects are 9,555 at every start. Inside a match, memory climbs to about 420 MiB because the undrained effect events pile up (about 35,000 a match). The next start frees them all | `pass1.log` |

**Static caches:** every one stays at its cap or below, match after match:
- planets 1, slices 1, fields 1, store and water index 1 each;
- ring jobs 0;
- collateral 1 to 9 (it clears at its cap of 8);
- plan memo 7 or 54, building-ground memo 241 to 582.

**State fields:** only per-match fields change between match ends (store, craters, slides, beams, shots, the swing list). Each one resets at the next start.

## A side note for Performance

Each effect event (`SimState.FxEvent`) is one object carrying all 108 of the event fields. Pass 1 suggests about 8 KB an event, and a match makes about 120 a second. The host frees them every frame, so this is churn, not a leak. It is a cheap allocation win if the frame budget ever needs one.
