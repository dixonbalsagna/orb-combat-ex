# Launch anywhere: the launcher from any point in a string (parked, rebuilt 2026-10-17)

Owner: Encounter Systems Director. Game Design's thirteenth round (`docs/design/launch-anywhere.md`, 992adcbb), as re-ruled on Encounter's reads (ff68e994).
- **It sits behind a switch, `brawl.launcher.anywhere.enabled`, which is false.** With it off, nothing new is read into play and nothing new is written, so play is window 1's to the bit, its rest and its hammer included.
- **Built and read in scratch. Not applied.**

## To build it

`node la.cjs <root>` from this folder, on main with window 1 and the grapple G1 (`../grapple-g1/`).
- The launcher's integers sit after the grapple's (`DirGrapple.END`). They are found at run time and sized only when written.
- `--check` reads every anchor and writes nothing; any other option is refused.
- With the switch off the golden doesn't move, so it needs no new golden.
- It applies before or after G2 (`../grapple-g2/`) and the forms holds (`../forms-holds/`).

**The grants:**
- `grant-simulation.patch` (state.gd, fighter.gd, hash.gd: `Fighter.launchPower`).
- `grant-world.patch` (brunt.gd: `tierOf`).

Until they're in, the launcher sets `launchPower` only where the field exists.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/brawl.gd` | Encounter | Behind `anywhere()`:<br>• the link, safety, power and the armour against lights;<br>• freshness by kind and in general;<br>• the AI's opening and in-string launches, and its guessed answer;<br>• Combat's enders;<br>• the cues;<br>• `launcherNow` for UI |
| `sim/director/melee.gd` | Encounter | The launch step: power before the planner, freshness after the pick, the kind marked on the fighter sent, the `launch_power` cue |
| `sim/director/launch.gd` | Encounter | The planner: each candidate's flight predicted with its kind's freshness; a fresh kind preferred; the bend inside the stick's kind at most 30°; no long-haul boost for a launcher |
| `data/director/interrupts.json` | Encounter | `brawl.launcher.anywhere`: `enabled`, `link`, `kept`, `mashTicks`, `power`, `fresh` (with `general`), `aim`, `full`. Window 1's keys (`restS` among them) are unchanged |
| `data/director/ai.json` | Encounter | `brawl.anywhere` by level: `launcher` (0.15, 0.35, 0.6), `inString` (0.08, 0.18, 0.28), `answer` (0.1, 0.25, 0.4) |
| `tools/schemas/director-interrupts.schema.json`, `director-ai.schema.json` | **Tools** | The same keys, as optional blocks. Tools' fixture cases need no change |

## As built (with the switch on)

**1. The link.**
- **A B within 24 ticks of one of his clean landed blows is the launcher.**
- A B pressed 10 ticks or fewer before one lands waits on his line and is thrown at the landing.
- A B within 9 ticks of his last B is the heavy flurry.
- An opening is a launcher, as in window 1.

**2. Safety.**
- **Sure:** he is staggered. It holds his stagger and can't be perfect-blocked.
- **Hard to answer:** he reels from a medium or a heavy.
- **Answerable:** otherwise.
- **The launcher is armoured against lights**, as a fist heavy is: half damage, and nothing more. A medium or a heavy that lands ends its wind-up.
- **Only a sure launcher holds his stagger.** Window 1's line held it for every launcher, which would have made none answerable.

**3. Power** = string (his run's points, 1 to 4: 0.55, 0.7, 0.85, 1.0) × state (sure 1.0, hard 0.9, answerable 0.8) × wounds (battered ×1.1, broken ×1.2).
- The timing is ×1: the perfect window isn't on this build.
- It scales the launching blow's worth and the send's force.

**4. Freshness at the send.**
- ×0.75 for each launch of that kind on him within 60 s, and ×0.9 for each launch of him of any kind in that time. Never under ×0.4.
- The rest and the hammer give way to it.
- The planner prefers a fresh kind. The stick's kind is kept, with the bend inside it at most 30°.

**5. The AI.**
- After an opening it launches at 0.15, 0.35 or 0.6 by level.
- In its string at a hard-to-answer moment it launches at 0.08, 0.18 or 0.28.
- **Its answer to a launcher that isn't sure is a guess:** made at the landing before it, at 0.1, 0.25 or 0.4, and pressed its reaction time after the throw. It never answers within its reaction time.

**6. The cues.**

| Cue | When | Fields |
| :--- | :--- | :--- |
| `launcher_open` | An opening, as before. Audio and Animation read it as one | With the switch on, UI's marks: `source` `sure`; `k` the pips (1 to 5); `amount` the fresh kinds as a mask (1 up, 2 across, 4 down, 8 behind) |
| `launcher_link` (new) | Each clean landing of his, when he has the ki | `text` `link`; `source` `sure`, `hard` or `answerable`; `k`; `amount`; `n` the link's end; `dur` its length |
| `launch_power` (new) | Each launch | `text` the kind; `amount` the power at the send after freshness (1 for a launch that isn't the launcher's); **`k` 1 for a full launch (0.8 and over): QA's counter** |

**Combat's enders:** read from `res://data/combat/enders.json` when Combat lands it there.

**Not built:**
- the perfect launcher (it waits on the perfect window);
- the air sense (Simulation's flight);
- the behind send.

## What it read

In scratch on main b0542bae + G1 + G2 + the forms holds + this. Against medium: 50 matches with a 15-minute cap; AI v AI is 10 matches of 5 minutes.

**Gates, every switch off:** 35 of 35, and the golden is main's, byte for byte. Validate and Tools' self-test (7,966 of 7,966) pass.

**With the switch on** (Game Design's §7 as re-ruled; "full" means power 0.8 or more at the send, by the `launch_power` cue):

| Row | Band | Read |
| :--- | :--- | ---: |
| The route: B at every opening (QA's `players.gd`) | at most 80% | **58%** (29 of 50) ✓ |
| ... over the same script's masher | 0 to 25 points | **+36** (the masher 22%) ✗ |
| The spammer: one light, then B | below the route, at most 70% | **0 of 50** ✓ |
| The varied route against the route | within 10 points | my probe's two both win 0 of 50: its player never guards, so only QA's route reads a win rate. Full launches 1.6 against 1.5 a match |
| Full launches a match by the route's player; on him | 4 to 12; 4 to 10 | my probe's route: **1.5; 6.4**. QA's runner counts every launch (46.5; 18.1), and its full count needs the cue ✗ |
| Full launches a match, AI v AI (a fighter) | 6 to 12 | **2.0** in 5 minutes ✗ |
| The spammer's launchers answered by medium | 20 to 50% | **27.3%** ✓ (2,090 perfect-blocked, 864 stopped) |
| AI v AI's launchers answered | (20 to 50%) | **43.5%** |
| One kind's share, AI v AI | at most 50% | **40%** (across) ✓ |

- **Why full launches are rare:** power is string × state, so a launch is full only from 3 points of string on a sure launcher, or 4 on a hard one. Freshness then multiplies by 0.75 a kind and 0.9 a launch for 60 s. So most full launches are the first in a minute.
- **The levers that would move the full count:** the full line (0.8), the freshness factors, the string's steps.
- **The masher fell from 48% to 22%** once the launcher was armoured against lights, so the route's lead grew.
