# The launcher's wider window and its rest at 30 s (parked, 2026-10-16)

Owner: Encounter Systems Director. Game Design's eleventh round item 1, kept by the twelfth (`docs/design/brawl-second-pass.md`), after Orb's playtest: "I couldn't quite figure out how to launch my opponent." It is window 1 of the EP's go order, with the return fix (`../return/`). **Built and read in scratch on main ee822c5e. Not applied.**

## To build it

After the return fix (`node ../return/ret.cjs <root>`): `node lw.cjs <root>` from this folder, then regenerate the golden.
- `--check` reads every anchor and writes nothing.
- `--rest=40` keeps the rest at 40 s: the twelfth round's fallback if the route passes an edge. It didn't.
- Any other option is refused. Its slot goes at `END`, so it applies after the return fix's.

| File | Change |
| :--- | :--- |
| `sim/director/brawl.gd` | A slot, `LC_LATE`. The opening lasts the stagger, or `lateTicks` after the close if that's longer. B is the launcher while it's open. A launcher thrown after the stagger isn't sure, and doesn't hold the stagger. `launcher_open`'s `n` is the window's end and its `dur` the stagger. `launcher_close` goes out at the window's end. `launcherOpen()` returns the window's end |
| `data/director/interrupts.json` | `brawl.launcher.restS` 30 (from 40); `brawl.launcher.lateTicks` 24 |
| `tools/schemas/director-interrupts.schema.json` (Tools') | `brawl.launcher.lateTicks` |

## As built

- **B counts as the launcher until 24 ticks after the close,** where it was the stagger's 12.
  - Inside the stagger it always lands, as before.
  - After it, it is still the launcher, with its 14-tick wind-up, but he can answer it: it can be guarded, perfect-blocked or dodged, and it doesn't hold his stagger.
- **The early side.** A B pressed while his closing light is on its way waits on his line, and is thrown as the launcher at the close. That is today's hold, unchanged; the light lands in under 10 ticks, so it covers Game Design's 10.
- **The rest is 30 s.**
- **For UI:** B's light comes from `launcher_open` and goes at `launcher_close`, so it now stays lit for the whole window. `launcher_open`'s `dur` says how long it is sure.

## What it read (window 1: the return fix and this, on main ee822c5e)

**The window** (`probes/w1p.gd`, 20 matches against medium). After each opening a scripted player taps B a set number of ticks later. With `--early`, he presses B instead as his closing light leaves.

| B pressed | Bs | Thrown as the launcher | Sure | Launched |
| :--- | ---: | ---: | ---: | ---: |
| 6 ticks after the opening | 21 | 21 | 21 | 21 |
| 12 | 20 | 20 | 20 | 20 |
| 18 (after the stagger) | 4 | 4 | 0 | 4 |
| 22 | 12 | 12 | 0 | 12 |
| 26 (after the window) | 6 | 0 | 0 | 0 |
| 32 | 5 | 0 | 0 | 0 |
| While his closing light is on its way | 171 | 129 | 129 | 76 |

- **The window ends at 24, as ruled.** Inside the stagger the launcher is sure; after it, it isn't, and the medium AI still let all 16 through.
- **The early B becomes the launcher whenever the light closes.** A B is the launcher only once an opening is open, so the 42 that weren't came after a light that didn't close.
- **53 of the 129 launchers didn't launch.** With the rest at 30 s, a launcher that lands while it rests is the hammer. The probe's other columns also count his later blows, so they don't split those 53.

**QA's tools on window 1** (against medium; QA's same-cadence scripts).

| Read | Seeds 1 to 100 | 101 to 200 | Over the 200 | The twelfth round's edge |
| :--- | ---: | ---: | ---: | :--- |
| The route's player | 68 | 62 | **65%** | At most 80% |
| The same script's masher | 47 | 44 | **45.5%** | |
| Route over masher | | | **19.5 points** | 0 to 25 |

- **Both edges pass, so the rest stays at 30 s.**
- **The route reads lower than the return park's 76%.** That was read on main 775968bc with the return fix alone, and main has moved a long way since, so the two aren't on one base.
- **Gates:** the full list, 35 of 35. Play changes in all 11 golden cases.
- **QA's harness** (the default arm and the crossing, 100 each): 91 pass, 19 fail, no hard test failing; median 454.8 s.
  - The failing rows are main's standing ones.
  - Among them are the bodies into buildings and wall slams from the crossing (1.15 and 0.68 a match), which window 2's levers and World's offers are for.
