# The return from a launch: a readable approach, a tell, no free hits (parked, 2026-10-16)

Owner: Encounter Systems Director. The EP's brief after Orb's playtest (`docs/ep/vision.md`, last section): "when I did manage to launch them, the split screen didn't really catch up with them, and I felt like I had no idea what they were doing until they rushed back at me at full speed and got some cheap hits."

Camera takes the view. This park is the return itself: an opponent coming back from a launch is telegraphed and answerable. **Built and gated in scratch on main 775968bc, re-proved on 06b0200e (stage 1). Not applied.**

## To build it

`node ret.cjs <root>` from this folder, then regenerate the golden. `node ret.cjs <root> --check` reads every anchor and writes nothing; any other option is refused.

| File | Change |
| :--- | :--- |
| `sim/director/brawl.gd` | Two brawl slots: `RET_N` (he is returning) and `RET_AT` (when he came free). `returning()`; the first blow back's tell in `_throw`; `returnTell()` for a planned exchange's first beats |
| `sim/director/bands.gd` | His approach back is at least `minTicks` long and crouches `windTicks` first, with a `return` cue. `meetReturn()`: a press into his approach meets him in the middle |
| `sim/director/exchange.gd` | `requestAttack` tries `meetReturn` before the far band; `_start` calls `returnTell` |
| `data/director/interrupts.json` | `bands.return`: `enabled` true, `minTicks` 40, `windTicks` 10, `firstWindTicks` 10, `forTicks` 600, `meetMinTicks` 8 |
| `tools/schemas/director-interrupts.schema.json` (Tools') | The same six keys |
| `sim/core/test/golden.json` | Regenerated. Two new slots grow the hashed brawl state, so every match's checkpoints move from the first. Wounds, rally, cripple, mood, keyed, `rosterHash` and `fightHash` are unchanged |

## As built

- **Who is returning.** A fighter who comes free after a launch, a knock-back or a fall is returning until his first blow back is thrown, for 600 live ticks at most.
- **His approach back is readable.**
  - It lasts at least 40 live ticks, where a charge back took about 23 ticks inside the mid band on main.
  - It crouches 10 ticks before it moves, a far approach too.
  - It sends a `return` cue (text `charge`, `lunge` or `far`; the target; the crouch in `amount`) for Camera to catch him and for VFX and Animation to show him coming.
- **His first blow back has a tell.** It lands 10 live ticks later than it would, with a `windup` cue (text `return`, the landing tick in `n`).
  - VFX already draws a wind-up ring on any `windup` cue that is not an `end`, so the tell shows on screen today.
  - A planned exchange's first beats, and its perfect-block window, wait the same 10 ticks.
- **A press into his approach meets him in the middle.** The approach must be past its crouch and at least 8 ticks from arriving. The two meet there as an answered far taunt does: a trade, or a clash for a heavy. A `return_met` cue names the one who pressed.
- **Nothing else changes.** A blast or a beam from range is untouched; a bolt has its own tell.

## What it read

**The probe** (`probes/ret2.gd`). 20 matches against the medium AI, seeds 1 to 20. A scripted player launches the AI, then a defender script takes over until the AI's first blow back. Each script starts 15 live ticks after the approach's start cue (`--from=cue --react=15`). "Unanswered": the first blow back lands clean, and the player landed nothing first.

| Defender | Main 775968bc | With the fix |
| :--- | :--- | :--- |
| Presses nothing | 108 of 109 unanswered | 119 of 120. By design: no answer, no change |
| Strikes (X every 8 ticks) | **108 of 111 unanswered (97%)** | **47 of 114 (41%).** He meets the AI in the middle 85 times and lands first 67 times |
| Guards | 18 of 129 unanswered (14%): 78 guarded, 32 perfect | 14 of 114 (12%): 79 guarded, 20 perfect |
| QA's route player, unchanged after the launch (`probes/ret1.gd`) | 86 of 109 (79%) | 43 of 122 (35%) |
| Ticks inside the mid band before the blow: median (fastest tenth) | 23 (8) | 35 (26) |

- **Of the striker's 114 first blows back, 22 were a blast or a beam from range.** The fix leaves those alone.
- **The scripted guarder's perfect blocks fall from 32 to 20.** It presses at a fixed 15 ticks after the cue and again the tick after a wind-up cue, and the blow now comes later. A player times the press to the tell; this script does not.

**QA's tools** (100 matches each, seeds 1 to 100; QA's same-cadence pair against medium).

| Read | Main 775968bc | With the fix | Bound |
| :--- | ---: | ---: | :--- |
| QA's route player | 61 | **72** | **At most 70% (eighth round)** |
| ... on seeds 101 to 200; on the 200 | 71; **66%** | 80; **76%** | |
| QA's masher (the same script) | 50 | 48 | |
| Route over masher | 11 points | 24 points | 0 to 25 points |
| Default arm, AI against AI: median match length | 433.7 s | 449.0 s | 360 to 480 s |
| The full gate list (35) | | 35 of 35 | |

- **The route passes its 70% edge, and on 200 matches that is not noise.**
  - Seeds 101 to 200: 80 with the fix, 71 on main.
  - Over the 200: **76% with the fix, 66% on main**.
  - Before the fix, the AI got its first blow back in free 79% of the time against this player. Taking those free hits away makes a launch worth about 10 points more to it.
- **The default arm moves inside noise.**
  - No hard test fails.
  - Five rows that failed on main now pass: the slam share, a zip's clean blow, the beam escape rate, limb breaks, and long launches.
  - Two rows that passed now fail: crater-lip flights a minute (0.55 to 0.47, against a floor of 0.5), and zips ending with the zipper caught (30.2%, the interval's top over 35).
- **On main 06b0200e (stage 1)** the fix applies as it is and plays identically: the regenerated golden's light digests and tick counts match the run on 775968bc. Parity, determinism plain and with intros, and the validator all pass.

**Two lighter settings, for the route's edge** (100 matches each on the same seeds):

| Setting | Route | The striker from the cue | The guarder from the cue |
| :--- | ---: | :--- | :--- |
| The fix as built | 72 | 47 of 114 unanswered | 14 of 114 |
| A: `firstWindTicks` 6 (the tell shorter) | 71 | 54 of 116 | 11 of 126 |
| B: `meetMinTicks` 999 (no meeting in the middle) | 65 | **109 of 112** | 16 of 115 |

- **The meeting is what makes the return answerable.** Without it, a fighter who strikes into the approach is hit first 97% of the time, as on main.
- **A shorter tell buys one point of the route** and costs the striker 6 points.
- **So neither lighter setting is worth taking.** The real choice is the fix as built, or a lever outside the return.

## Open, for Game Design

- **The route's edge: 76% on 200 matches with the fix, against 70%.** The lighter settings above don't pay. So it is one of these:
  - **Move the edge.** It was set while the AI's return was a free hit. My recommendation, since a free hit on arrival is what Orb named.
  - **A lever outside the return,** such as the launching blow's worth, or the rest.
  - **Hold the fix.**
- **The eleventh round's rest at 30 s** isn't in this read. It raises the route further, so the two should be read together.

## The cue names

`cues.md` in this folder is the list agreed for VFX, Animation and UI: the return's three cues, the interjection's tell, and the tenth round's cues to build. It settles three differences between their proposals.
