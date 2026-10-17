# Launch anywhere: the launcher from any point in a string (parked, 2026-10-17)

Owner: Encounter Systems Director. Game Design's thirteenth round (`docs/design/launch-anywhere.md`, 992adcbb, section 9's six steps), after Orb: "launchers should have an intuitive way to activate and aim at any point in a combo string", and no cooldowns. It is the window after window 1 (9d0530dc). **Built and read in scratch on main 17059561 (window 2 on it). Not applied.**

## To build it

1. `node la.cjs <root>` from this folder, on main with window 1 (it refuses without it). Then regenerate the golden.
   - `--check` reads every anchor and writes nothing; any other option is refused.
   - Its slots go at `END`, so it stacks with the parks before it. It applies before or after the grapple's `gr.cjs` (`pending/grapple-g1/`).
2. **The grants, when Simulation and World take them** (the power that reaches the building ladder):
   - `grant-simulation.patch`:
     - `sim/core/state.gd`: `Fighter.launchPower`, 1 for any launch but the launcher's;
     - `sim/core/fighter.gd`: reset at the flight's end;
     - `sim/core/hash.gd`: hashed only while it isn't 1, so nothing else moves.
   - `grant-world.patch` (`sim/world/brunt.gd`): `tierOf`. A launch meets buildings at the launcher's tier × its power, rounded, at least 1.
   - Until they're in, `la.cjs` sets `launchPower` only where the field exists, so it builds and plays without them.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/brawl.gd` | Encounter | The link, safety, power, freshness by kind, the AI's in-string launch and its guessed answer, Combat's enders, `launcherNow` for UI; the rest and the hammer retired |
| `sim/director/melee.gd` | Encounter | The launch step: power before the planner, the kind's freshness after the pick, the kind marked on the fighter sent |
| `sim/director/launch.gd` | Encounter | The planner: a fresh kind preferred; each candidate's flight predicted with its own kind's freshness; the bend inside the stick's kind at most 30 degrees; no long-haul boost for a launcher |
| `data/director/interrupts.json` | Encounter | `brawl.launcher`: `link`, `kept`, `mashTicks`, `power`, `fresh`, `aim`. `restS` stays, unread: 605 of Tools' fixture cases carry it, and the self-test fails without it |
| `data/director/ai.json` | Encounter | `brawl.launchInString`, `brawl.answerLauncher` by level |
| `tools/schemas/director-interrupts.schema.json`, `director-ai.schema.json` | **Tools** | The same keys; `restS` kept |

## As built

**1. The link.**
- **Any B within 24 ticks of one of his clean landed blows is the launcher:** a light, a medium, a heavy, a bolt or a blast.
- **A B pressed 10 ticks or fewer before one lands** waits on his line, and is thrown as the launcher at the landing.
- **A B within 9 ticks of his last B is the heavy flurry,** never a launcher.
- **An opening** (the window around the close, window 1's) is a launcher too.

**2. Safety.**
- **Sure:** he is staggered (an opening). It always lands, holds his stagger, and can't be perfect-blocked.
  - Only a sure launcher holds his stagger until it lands. Window 1's line held it for every launcher, which would have left him stunned through any launcher's wind-up, so none could be answered.
- **Hard to answer:** he reels from a medium or a heavy.
- **Answerable:** he reels from a light or a bolt, or is free.
- **The answers:**
  - Any blow that lands on a launcher winding ends it (it has no armour).
  - A perfect block staggers the launcher's player 20 ticks, an opening, so the defender's own launcher is sure: the counter-launch.
  - A dodge or giving ground leaves him open 20 ticks, as after a heavy that misses.

**3. Power: string × state × timing × wounds, then × freshness at the send.**
- **The string:** by his run's whole points, 1 to 4: 0.55, 0.7, 0.85, 1.0.
- **The state:** sure 1.0, hard 0.9, answerable 0.8.
- **The timing:** ×1 for now. The perfect launcher waits on the perfect window, which isn't on this build.
- **The wounds:** the region the launcher's piece strikes, battered ×1.1, broken ×1.2.
- **What power scales:** the launching blow's worth (3 × power) and the send's force. The landing's damage follows the speed, so it scales too.
- **Effective tier against buildings:** tier × power, through the grants above.

**4. Freshness by kind, in place of the rest.**
- **The kinds:** up, across, down, behind, into a building.
- **Marks:** each launch, of any cause, marks its kind on the fighter it sends. A launch of a kind is ×0.75 for each mark of that kind within 60 s of fight time, never under ×0.4. A kind not marked is full.
- **Kept across brawls:** the marks persist from one brawl to the next.
- **Retired:** `launcher.restS`, the hammer and the rest.
- **The stick's kind is kept:** a stick up, toward or down filters the planner to that kind, and the choreographer bends at most 30 degrees inside it.
- **Neutral stick:** the planner picks, and prefers a fresh kind (12 off a candidate's score for each mark of its kind).
- **Behind has no send yet.** The planner has no turned send, so a stick held away is the planner's own pick until it does.

**5. The AI.**
- **In its string at a hard-to-answer moment** it launches at 0.05, 0.12 or 0.2 by level, once a landed blow.
- **After an opening:** at its level's share, as before (0.15, 0.25, 0.6 in the data; Game Design's paper says 0.35 at medium).
- **Its answer to a launcher that isn't sure** is a guess. Its reaction time is the wind-up's length, so it can't answer one it sees.
  - When a blow of his lands clean on it, it decides at 0.1, 0.25 or 0.4 that a launcher will follow while his B would still be one (the link, 24 ticks).
  - If one that isn't sure is thrown in that time, it presses guard its reaction time after the throw. That is never sooner (Game Design's hard test), and the contact is still inside the perfect window.
  - It never perfect-blocks his other blows by it.

**6. For UI.** `DirBrawl.launcherNow(S, f)`:
- whether a B would launch now;
- sure or not;
- its power in pips, 1 to 5;
- the four kinds fresh on his rival.

UI draws the lit B, the solid or broken ring, the pips and the rose. The rest's ring is retired.

**The cues, by UI's proposal** (`docs/ui/pending/launch-anywhere/`). The fields follow the cue list's rules; the event has no field named `fresh`, so the mask goes in `amount`.

| Cue | When | Fields |
| :--- | :--- | :--- |
| `launcher_open` | An opening, as before. Audio and Animation read it as an opening | `text` the cause, as before; `source` `sure`; `k` the pips (1 to 5); `amount` the fresh kinds as a mask (1 up, 2 across, 4 down, 8 behind); `n` the window's end; `dur` the stagger |
| `launcher_link` (new) | Each clean landing of his, when he has the ki: his B is the launcher for the link | `text` `link`; `source` `sure`, `hard` or `answerable`; `k`; `amount`; `n` the link's end; `dur` its length |

UI lights B on either cue, until its `n`.

**Combat's enders** (`docs/combat/pending/launch/enders.json`): the launcher's piece by his last blow's family and path, and the send his stick asks, read from `res://data/combat/enders.json` when Combat lands it there. Until then the piece is picked as before.

**Not built:**
- the perfect launcher (it waits on the perfect window);
- the air sense (a sent fighter recovering 25% sooner for each mark: Simulation's flight);
- the 15% extension for a set piece on the line (it would part the planner's prediction from the flight);
- the behind send.

## What it read

On main 15a833e5 (window 2 on it), with every fix below. The probe is `probes/lap.gd`, against medium: 50 matches with a 15-minute cap; AI v AI is 10 matches of 5 minutes.

**Three bugs, fixed on the way:**
1. **Every launcher held the rival's stagger until it landed.** That was window 1's line, where only openings launched. Now only a sure launcher holds it. Before this, no launcher that wasn't sure could be answered: 0 of 9,170 against the spammer.
2. **The AI's guess dropped out under the light's own hit-stun,** which is always on at the landing. It is now decided at the landing and pressed its reaction time after the launcher's throw.
3. **The probe pressed B without the held level.** That is a Simple Attack, already wound, which lands 2 ticks after the throw. It had given 188 launches a match.

**Game Design's rows (section 7):**

| Row | Band | Read |
| :--- | :--- | ---: |
| The route: B at every opening (QA's script, `players.gd`) | at most 80% | **48%** (24 of 50) |
| ... over the same script's masher | 0 to 25 points | **0** (the masher also 48%): at the band's edge |
| The spammer: one light, then B | below the route, at most 70% | **0 of 50** |
| The varied route: the route, the stick turned through the kinds | within 10 points of the route | the probe's route and varied route both win **0 of 50** (the probe's player never guards, so only QA's route reads a win rate). Their launches: 12.7 and 12.6 a match. Across falls from 39% to 28% of his launches |
| Launches a match by the route's player; on him | 4 to 10; 4 to 8 | **50.7; 15.9** |
| AI v AI launches a match | 6 to 12 | **3.8** |
| One kind's share, AI v AI | at most 50% | **46%** (across, 42 of 90) |
| The spammer's launchers answered by medium | 30 to 60% | **96%**: 11,609 stopped or missed, 245 perfect-blocked, 498 launched |

- **The answers are mostly the AI's string.** Any blow that lands on a winding launcher ends it, and the medium AI is nearly always mid-string. The guess's perfect blocks are 2%.
- **The route's launches are the structural row.** The rest held them down; with no rest every opening launches. None of the five levers touches a sure launcher at an opening. A higher ki cost on the launcher (5 now) is the soft lever that would.
- **Gates**, on main 15a833e5 + la.cjs: **33 of 35**; the golden moves in 11 cases. The two that fail are other owners' gates, newly exposed by the new play:
  - `flash_count`: its AI scenario now shows a double hit, and `double_hit` isn't registered in `tools/flash/sources.json` (Tools': add it, counted or reserved);
  - `lead_scan --strict`: one frame of feet leading at 718 units a second while not tumbling, holding `ag.hold.charge_heavy` (Animation's lint).
  - The self-test passes, 7545 of 7545.
