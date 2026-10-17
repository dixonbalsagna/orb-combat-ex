# Can the arena shift during a fight? (World, research, 2026-10-16)

Owner: World and Environment. Orb (homework 22): "research if this slice can dynamically shift through the course of a combat, rather than being determined and built at the start of the fight. Is there a procedural system we can use to achieve an arena like this? please push against this if it will create too much impact or break our current systems." **Research only; nothing built.** Read from `sim/core/state.gd`, `sim/world/crater.gd`, `planet-slice-core.md`, `run-core.md` and the measured costs of `WorldPlanet` (`planet-module.md`).

## The short answer

**Yes to a shift at a pause; no to a shift that is always going on.** The planet function is already the procedural system: a slice is a smooth function of three numbers (the loop's centre, its radius, its bearing), so a shifting arena is just a path through those numbers. The generator is not the problem. **The match's state is**: it is built from fixed ground at tick 0 and a hundred things in it assume the ground does not move. The cheapest version that keeps Orb's spirit is three layers, cheapest first, and the first two are cheap:

1. **A cosmetic drift (no sim change).** The far land and the backdrop turn slowly round the fight (the sky, the far skyline, the centre of a small loop), driven by the tick. Players see "the world is turning round us"; the sim's band does not move. World gives the data (the slice's neighbours), Rendering draws it. Days, not weeks.
2. **A re-anchor at a pause (an epoch).** At a calm moment the loop is re-read round the pair's midpoint with a new bearing (or a new centre or radius), and swapped in as one step, hidden by a cut or wipe. A match has such moments already: a finisher's cinematic, an act's change, a beam struggle's end. A match would have at most about four epochs. **This is the version worth considering.**
3. **A continuous shift (do not build).** Breaks too much (below).

## What a shift is, mathematically

The arena is the loop `p(a; c, theta, phi)`: centre `c`, angular radius `theta` (the arena's length), bearing `phi` (which way the loop's start points). Moving any of them changes the columns. A change of bearing of a few degrees about a pivot leaves the ground near the pivot nearly the same and moves the ground far from it sideways (a point `s` units from the pivot moves `s sin(phi)` laterally: 520 units at 3,000 units for 10 degrees); a change of `theta` grows or shrinks the loop round its centre. A re-read costs 4,800 columns: **0.56 to 0.78 s** on a busy PC (the same function as the start's), so it can be prepared ahead, outside the sim state, a few columns a tick over several seconds, and applied at a fixed tick.

## Where it breaks (the sim's side)

| What | Why a shift touches it | The cheapest answer | Cost |
| :--- | :--- | :--- | :--- |
| **Per-column state** | Ten arrays are indexed by column and describe the ground: `base`, `deform`, `water`, `scorch`, `rubble`, `crack`, `low`, `deformZ` (the depth rows), `lanes`, `popHist` (`state.gd`). A swap re-lays all of them | Craters (up to 400 records, `LIST_MAX`) are points already and go back through the wear list's place frame. **`deform` is not a sum of the list**: beams, slides and the heap write it directly, so those marks are lost unless they are turned into point records first (the wear list's open-country craters) | M. The loss is the honest cost: a swap can forget a thin beam scar |
| **Buildings** | A building has `hp`, `floors`, `fmask`, `fdmg`, breaches, a failing state, its people. The new slice has other buildings | Carry by identity: **place id and plan index** (collateral-run.md, ask 1) are exactly that key. A building that leaves the slice returns its state to the wear list; one that enters starts from the wear list. The ones near the pivot are the same buildings at a new lateral offset | S once ask 1 exists; the plan (window 3) |
| **Depth (`z`)** | A building's depth row and a fighter's `z` assume the street runs along the arena. A bearing change slides a street sideways | Keep the bearing change small (under about 10 degrees) so the front street stays the front street near the pivot; or re-anchor onto a street (`clearLane`) | S |
| **Things in flight** | Beams, shots, flights, slides, water windows, a failing stack, magma and the crowd's flight all hold `x`, `y`, `z` and column indices | **Swap only on a calm tick**: none of them live. A finisher's cinematic already clears most; a check gates the rest. This is also what makes the replay simple | S, but it bounds when a swap may be |
| **The fighters** | Their `x`, `y`, `z` | The pivot is the pair's midpoint, so `x` is unchanged; `y` is set to the new ground and eased over the cut | S |
| **Determinism and replays** | A swap changes `S.base`, which is hashed only at tick 0 today (it is constant) | The swap is a sim event at a tick the sim chooses, so it needs no replay entry: the new bearing is a keyed draw of (planet, touch, epoch). Simulation hashes the epoch number every tick from then on (a conditional append: a match with no swap hashes as before) and the slice's hash at the swap (one more `world` hash in the checkpoint chain). `planet-slice-core.md`'s header is unchanged; **a playback recomputes the slice at the swap (0.6 s, synchronous)** | M, Simulation's |
| **Rendering** | The ground mesh, the buildings and the far land are rebuilt | At a cut or wipe, as a stage change; 0.1 to 0.5 s of hitch hidden by the cinematic | M, Rendering's |
| **Cost** | 0.56 to 0.78 s | Precomputed outside `S` over several seconds (14 columns a tick); in a headless replay it is simply done at the tick | S |
| **The run's wear** | The marks a swap forgets (above) | Keep the swap's records in the stage's own wear: a stage's end writes the whole match's marks | S |

## Why not a continuous shift

A ground that slides all the time moves every building's depth, makes every crater a moving target, and turns the 4,800-column array into a stream: each tick the ten arrays would be re-laid (about 0.17 ms a column for the function alone, or 14 columns a tick at best, so the *far* ground could lag) and the hash would have to cover `S.base` every tick (one more hash of 4,800 values on every vector of the golden). It would also break the plain fact that a launched fighter lands where the ground is. **It is the one version I would push against.**

## What the player would feel, and where it pays

- **A set piece that travels:** the finisher's cut, and the fight resumes with the loop turned a few degrees so a city that was off to one side is now the street behind them; the same crater, the same fallen tower, a different far side. That reads as "the fight moved on".
- **The cheap, always-on feeling:** layer 1's slow drift.
- **With small circles (small-circles.md):** a shrinking or growing loop (the centre closes in as the match goes on) is an escalation device: the same `theta` change, applied at the act breaks. Only worth it if small arenas are built.

## Recommendation

Build layer 1 when Rendering has the far land for a loop; hold layer 2 until the planet windows and the run are in the game (it needs the place id and plan index, the wear list's point craters and Simulation's epoch hash), and decide it with Orb from what the first stages feel like. Do not build layer 3.
