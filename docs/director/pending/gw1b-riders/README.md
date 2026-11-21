# Parked: Encounter's three GW1b riders

Encounter, 2026-11-14, sprint A1. **Built on main 1c19d81d + Simulation's energy-on (both patches) + energy-on-pins**, as the EP asked. It stacks with Simulation's meters-zero (`apply --check` clean). All seven files are Encounter's, so there are no grants.

**Re-cut (2026-11-15):** energy-on-pins now holds `arc_check`'s meteor bowl and `beam_ai_check`'s beam hold as GW1a ceilings, under the model and the dash, instead of pinning them off (the GW1a review's major 2). So these riders' two check hunks now take the ceilings off and put both rows back in full: the bowl more than 5,000, the rival locked 0 ticks. The other five files are unchanged.

## The three riders

| # | What | Where | Why |
| ---: | :--- | :--- | :--- |
| 1 | **The meteor's own bowl keeps its tier** in both models. `arc_check`'s GW1a ceiling comes off | `sim/director/arc.gd` `_impact`; `tools/arc_check.gd` | With the model on, `WorldCrater.impactEnergy` drops the tier, because a model speed already carries it. The meteor's landing speed is authored data, not a model speed, so its bowl lost its tier (4,571 against World's 6,046) |
| 2 | **The computer starts no beam hold while it can't act** (`DirBeamMove.aiStart`): not unless it is free or charging and not stunned. Its old press goes instead. `beam_ai_check`'s GW1a ceiling comes off | `sim/director/beam_move.gd`; `tools/beam_ai_check.gd` | With the dash on it closes fast and starts its hold inside the brawl (brawl.gd:4120), locked. A locked hold never climbs a stage, so its beam was lost |
| 3 | **Decision 6 (the meters steer nothing in A1)**: `swing.json` `direction.anguish` 0; the swing's tension reads the mood alone (`swing.gd` `_tension`) | `data/director/swing.json`; `sim/director/swing.gd`; `tools/swing_legal_check.gd` | Simulation's list in `docs/architecture/pending/meters-zero/README.md` |

**On rider 3, two choices of mine:**
- **swing.gd:496** (the anguish term in the swing's direction) is zeroed in data and the code is kept, which is decision 6's own rule ("zero in data, remove the code after Alpha"). **:462** (the tension) has no data weight, so the meters are dropped from its code.
- **Legal's lint** (`swing_legal_check`, RL-215) required the tension to name all three listed scalars. It now asks for the mood, and that neither meter is read. Legal's list is what the swing may read at most, so reading less is inside it.
- **A play row** was added beside the menace row: the swing's direction doesn't move with the hero's anguish (0 against 100).
  - Main's Protagonist has `care` 0, and the term only reads the anguish for a fighter who cares, so the weight was already inert on today's roster. The row gives him care 1 for the comparison.
  - Its negative control, the weight back at 2, fails on 3 of 4 planets.

**My call on the other two sites: keep both as they are.** They key on which meter a fighter has (his role: hero or villain), not on its value, so no meter's number reaches them. They are the personality pillar 5 asks for. After Alpha, when the meter code goes, both should key on a personality field (`care`), not the meter's presence.
- `beamplay.gd:508-513`: a deflected beam goes at the sky for the hero, toward the nearest building for the villain.
- `location.gd:116-117`: which side of the roam the computer leads.

## Apply

On main + energy-on + energy-on-pins (the re-cut): `git -c core.autocrlf=false -c core.eol=lf apply gw1b-riders.diff`. Checked on main 4327cfbb + energy-on + the re-cut pins, with main's data and with the 9 November data.

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `gw1b-riders.diff`: `sim/director/arc.gd`, `beam_move.gd`, `swing.gd`, `data/director/swing.json`, `sim/director/tools/arc_check.gd`, `beam_ai_check.gd`, `swing_legal_check.gd` | Encounter | 76d967bee6c40922c8978507c400daa8363bdedb (the re-cut; the first cut was beda3233) |

## Proof of the re-cut

Records are in `docs/director/runs/4327cfbb/energy-on-pins-v2/` (`r9_*` the 9 November data, `rm_*` main's). With the re-cut pins and these riders: `arc_check` 0 failed on both (the bowl 6,046) and `beam_ai_check` 0 failed on both (0 locked). Without the riders, the ceilings hold at 4,571 and 29. Only the two check hunks changed, so the first cut's proof below stands for the rest.

## Proof of the first cut

Records are in `docs/director/runs/1c19d81d/gw1b-riders/`, and every output went through `tools/gate.mjs`.
- **Every director check passes:** 41 of 41, with `loader_check` and `launch_cost_check` left out for their length. That includes `arc_check` and `beam_ai_check` with their pins off.
- **Negative controls:**
  - With the pins off and the two code fixes taken out, `arc_check` fails 1 (the bowl at 4,571) and `beam_ai_check` fails 4.
  - With the anguish weight back at 2, `swing_legal_check` fails 3.
- **On the GW1a data (main b0e20f9a) the riders move 9 of the golden's 11 rows**, from early on: matches 0 to 7, and match 8, which ran 40,833 ticks, now runs to the backstop (43,200). Tick 0 and the two replays don't move. The lane is in `docs/director/runs/b0e20f9a/b17-lane/` (the GW1b review's B-17). Earlier, on main's data with energy-on: the golden failed with exactly the same lines with and without the riders (base worktree compared). The riders' switches (the arc, the swing, the computer's own beam move) are off in main's data, so nothing here moves main's golden today. With the 9 November switches on (GW1a), all three change play: re-record in GW1b.
- These core checks pass: `two_states` and `load_split`. Validate: 0 errors; self-test 10,093 of 10,093. The two-fighter count is 365 of 365.
- **Render:** 14 of 15 pass. `after_check` fails one row ("the match has a rush in it: the five are reached (0)"). It fails identically on the base without the riders, so it comes with energy-on, not this park.

## NEEDS FROM EP

- **Simulation or Rendering:** `render/tools/after_check.gd` fails with energy-on on main's data (above). It's not mine, but GW1a's set will meet it.
