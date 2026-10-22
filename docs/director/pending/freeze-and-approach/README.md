# No window shorter for a freeze (4c) and the AI's approach held near the whip limit (4d) (parked, 2026-10-22)

Owner: Encounter Systems Director. Game Design's `rulings-2026-10-19b.md` 4c and 4d: Encounter's part of Simulation's `docs/architecture/feel-core.md` §5.
- **4c sits behind Simulation's hit-stop by weight** (`S.hitstopOn`, `data/fight/hitstop.json`, off). **4d sits behind `approachCap.enabled`** (false) in `data/director/ai.json`. Off, nothing runs, so play and the golden don't move.
- **Built and read in scratch. Not applied.**

## To build it

`node fz.cjs <root>` from this folder, on main with Simulation's hit-stop by weight (c09c3bef). It copies `files/sim/director/windows.gd` (`DirWindows`) and its `.uid`. `--check` reads every anchor and writes nothing. It composes with the recoil-flip, wall-kick, balance and interior-aim parks.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/windows.gd` | Encounter | New: `DirWindows` (4c) |
| `sim/director/exchange.gd` | Encounter | `dirUpdate` runs its body (now `_update`), then `DirWindows.afterTick` |
| `sim/director/brawl.gd` | Encounter | `freezeWindows` (the riposte and the launcher's late window, counted every tick, put back by the freeze); `holdBlow` (a blow put back moves its line) |
| `sim/director/ai.gd` | Encounter | `_capApproach` (4d) |
| `data/director/interrupts.json` | Encounter | `freezeWindows.minLiveTicks` 5 |
| `data/director/ai.json` | Encounter | `approachCap`: enabled false, speed 4,000, vsHumanOnly true |
| `tools/schemas/director-interrupts.schema.json`, `director-ai.schema.json` | **Tools** | The same keys |

## The rules as built

**4c.** At the end of each live tick of the director, if a hit-stop starts with it:
- A perfect block's window open on a pending strike keeps its ticks, because the exchange's clock holds through the freeze. One with fewer than 5 live ticks left has its strike put back so it has them.
  - In a planned exchange, every beat after it moves with it, so the rhythm holds.
  - A brawl blow moves alone, with its line (its contact and its wind-up). A `window_hold` cue says so (actor the striker, `n` the new contact, `dur` the ticks), for the render.
- **A brawl light is left as it is.** Its whole window is its 2 ticks from press to contact, under 5, so "at least 5 after the freeze" would stretch every flurry. It keeps what it has, which a freeze can't take.
- The chain window counts live time; one ending sooner than 5 live ticks after the freeze is held open to 5.
- The brawl's riposte and launcher windows count every tick, so a freeze would eat them. They are put back by the freeze's ticks, and to at least 5 after it.
- `freezeWindows.minLiveTicks` 0 turns the rule off in data.

**4d.** In free flight at a human rival, the AI's speed is held at 4,000 u/s by its stick's reach, near Camera's whip limit (`docs/camera/whip-pan.md`). The traversal dash still carries it most of the way. At another AI the demo's camera rides the flight, so nothing is held. Director rushes (a lunge, a far flight, a zip) keep their own speeds. So does an Escape away from him.

## What it read (main c538c681, in scratch)

| Read | Off | On |
| :--- | :--- | :--- |
| 4d: the AI's top speed flying at a standing player, 14,000 units off, 10 matches | 9,139 to 11,298 | **2,993 to 4,025** |
| 4c: open heavy windows on the first live tick after a freeze (hit-stop by weight on; 10 AI matches of 3 min) | 122 windows; 49 had under 5 live ticks left, as few as 0.7 | 147 windows; **the fewest 4.7 left after that first live tick,** so 5 or more live ticks after every freeze. 51 strikes put back |

- An Escape away from the player reached 12,685 u/s in one match. 4d doesn't hold it, since it isn't an approach; a note for Camera.
- Perfect blocks: 80 off and 66 on. The AI weighs each strike once, so its block rate doesn't follow the window's length; the difference is the matches' own.
- **Off** (c538c681): the golden is main's, byte for byte, and the full gate list is 34 of 35. Its one red is anim_check's "a blow within reach ends 5.00 units short", the same as clean main.

## The chase with Simulation's launch curve (`probes/chp.gd`, 10 AI matches; the date of 2026-10-23)

| | Curve off | Curve on |
| :--- | ---: | ---: |
| A send's flight, median (90th percentile), ticks | 70 (351) | 86 (512) |
| The launcher's gap to him at the landing, median (90th percentile) | 2,119 (7,479) | 2,633 (14,006) |
| The launcher's top speed meanwhile, median | 1,064 | 1,517 |
| Sends where the launcher passed him | 6% | 7% |
| The landing to the next exchange or approach, median ticks | 44 | 19 |

- **The curve can go on as far as the chase goes.** The launcher doesn't overtake his rival, and the fight comes back sooner.
- **The AI hardly chases in the glide** (about 1,500 u/s), so a long flight leaves it far behind at the landing in the tail. Game Design's glide is "for the attacker to chase or zip": an AI chase or zip in the glide is a possible next piece, not a blocker.

## Probes (`probes/`, from a copy's root)

- `fzp.gd -- <matches> <seed0> --mode=approach [--cap]`, and `--mode=windows [--fzoff]`.
- `chp.gd -- <matches> <seed0> [--curve]`: the chase after a launch, with Simulation's curve off or on.
