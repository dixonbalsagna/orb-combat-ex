# Launch anywhere, round 2 (parked, 2026-10-18)

Owner: Encounter Systems Director. It covers:
- Game Design's rulings of 2026-10-18 (`docs/design/rulings-2026-10-18.md` §1a, §1b);
- Orb's note on launches (homework 30);
- Combat's asks of 1e7e34aa (`docs/combat/launch-enders.md` §5).

It goes on main with launch anywhere (f4e8269c).
- **It sits behind the same switch, `brawl.launcher.anywhere.enabled`, which is false.** The data hash's new line reads Combat's enders file only when it exists, and it isn't on main.
- So with the switch off and no file, play and the golden are main's to the bit.
- **Built and read in scratch. Not applied.**

## To build it

`node l2.cjs <root>` from this folder.
- `--check` reads every anchor and writes nothing; any other option is refused.
- No new golden.
- It applies before or after `../grapple-g3/` and `../forms-2/`.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/brawl.gd` | Encounter | An answerable launcher's armour takes one light; `_aiAim`; the re-chamber's tell; `freshHurts` |
| `sim/director/melee.gd` | Encounter | The power World's building ladder reads (`tgt.launchPower`) is the launcher's own, before freshness |
| `sim/director/data.gd` | Encounter | `data/combat/enders.json` in the director's data hash, when the file exists |
| `data/director/interrupts.json` | Encounter | `anywhere.full` 0.7; `anywhere.fresh.destruction` false; `anywhere.aiAim` |
| `tools/schemas/director-interrupts.schema.json` | **Tools** | The same keys |

## As built (with the switch on)

**1a. An answerable launcher's armour takes one light.**
- A second light that lands in its wind-up stops it, as a medium or a heavy does.
- A hard-to-answer launcher, after a medium or harder, keeps full armour against lights.
- A sure one is armoured outright.
- So a flurry is an answer again to a launcher started off a light.

**1b. The full line is 0.7** (it was 0.8). A sure launcher from two points of string, and a second launch of a fresh kind within the minute, now count as full (the `launch_power` cue's `k`).

**Orb: "each time you launch an opponent against something, the more destroyed it will be."**
- Freshness still shortens the flight (the force) and lowers the power counted at the send (the cue's `amount`).
- But the power World's building ladder reads (`tgt.launchPower`, Simulation's and World's grants) is the launcher's own, before freshness. So a repeated launch breaks as much as the first, and the damage that accumulates on a building escalates.
- `anywhere.fresh.destruction` true puts freshness back on it.

**Combat (a): the enders file in the data hash.** `data/combat/enders.json` is folded into `DirData.dataHash` when the file exists.
- A change to the file alone would otherwise pass a replay's data check while it desyncs.
- The golden moves once, with the commit that lands the file. Today it doesn't exist, so nothing moves.

**Combat (b): the AI aims its launchers by its personality.**

| | Up | Across | Down |
| :--- | ---: | ---: | ---: |
| The hero (care above 0) | 1.0 | 0.6, less where people are 8 bh along the line, within 3 | 0.2 |
| The Anti-hero (care below 0) | 0.3 | 1.0 | 0.8 |

- A keyed draw, at its opening launcher and its in-string one.
- At care 0 it doesn't aim (the planner's pick, as before).
- Once Combat's enders land, its strings branch the same way a player's do.

**Combat (c): the re-chamber's tell.**
- A launch on the enders' step 3 or 4 (it doesn't follow the last blow's path) winds longer by the file's `rechamber.ticks` (6).
- Its wind-up counts from the reset (`HOLD_AT` moves with it), so the reset reads.

## What it read

In scratch on main 7d93624e + this + `../grapple-g3/` + `../forms-2/`.

**Every switch off:**
- the golden is main's, byte for byte;
- determinism (plain and `--intro`) and parity pass;
- validate passes, and Tools' self-test, 8,519 of 8,519.

The full gate list on main 4cf5802e (before the AI's aim by role, a change that runs only with the switch on) passed 33 of 35. The two that failed, `anim_check` and the world probe, fail the same way on a clean main (see `../grapple-g3/`).

**With launch anywhere on.** "Full" is power 0.7 or more at the send, by the `launch_power` cue. The probe is `probes/lap.gd`; QA's `players.gd` gives the route's and the masher's win rates.

| Row (Game Design's §7, as re-ruled) | Band | Read |
| :--- | :--- | ---: |
| The route against medium | at most 80% | **64%** ✓ |
| ... over the same script's masher | 0 to 25 points | **+12** ✓ (the masher 52%) |
| The masher's own band (mashed X alone) | 35 to 50% | **52%** (2 over) |
| Full launches, AI v AI, a 7-minute match, both fighters | 6 to 12 | **9.7** ✓ |
| One kind's share, AI v AI | at most 50% | **30%** ✓ (across 52, down 50, up 42, building 27) |
| The spammer's launchers answered by medium | 20 to 50% | **89.8%** ✗ (10,442 stopped, 542 perfect-blocked) |
| The spammer | below the route, at most 70% | **0 of 50** ✓ |
| AI v AI's launchers answered | | 70.5% |

- **1a overshoots on the spammer.** A launcher off a light is answerable, and the AI's own string lands a second light in nearly every wind-up. Before 1a, at full armour against lights, the same read gave 27.3%.
- **The AI's aim by role**, for its aimed launchers in AI v AI:
  - the rival (villain): across 13, down 14, up 2;
  - the Protagonist (hero): up 17, across 11.

  Its other launchers come through his string's link without its aim, and take the planner's send.
- **The route's full launches** need QA's runner to count the `launch_power` cue's `k`. It counts every launch today: 47.6 by him and 13.7 on him a match.

**The newcomer (QA's script, `players.gd` `newcomer`, 50 matches against medium, launch anywhere on):**
- a first launch in 50 of 50 matches, inside 60 s in **49 (98%; band at least 90%)** ✓;
- 23.7 launches by him a match, 16.7 on him;
- 28% wins.

QA's own read with launch anywhere off is 6 of 100. So the eleventh round's wider window is launch anywhere's link (24 ticks after a landed blow) and its keep (10 before one), with no separate fix.

**`lead_scan --strict` with launch anywhere on:** 0 frames of feet leading outside a tumble. The 718 u/s frame of an earlier build is gone.
