# Parked: the four camera checks red on the GW1b stack (gw1b-camera-checks)

Camera, 2026-11-21, the EP's go. The second park on the 44-line stack, after gw1b-split-sweep. Each check is classified by the EP's rule: a pin for a staged row; a fix, or a ceiling until the fix, for a real fault. A real match on the planet that fails is a fault, not a pin. **Checks only: no camera code changes.**

**Apply after gw1b-split-sweep** (cut on the 44-line stack): `git -c core.autocrlf=false apply gw1b-camera-checks.patch` (sha1 8bc5e197). Four files, mine, in `render/camera/tests/`.

| Check | Red on the stack | Cause (`docs/camera/runs/c860b5a7/gw1b-camera-checks/runs.txt`) | Class | Change |
| :--- | :--- | :--- | :--- | :--- |
| `swing_places_check` | 3 rows: a landmark at the wider edge not seen, a frame at rest moved the camera | the flip. The check makes its own turned frame ("until Simulation's frame lands") and poses a landmark on the hand-made arena; on the planet the sim's own frame is there | **pin** (staged) | `WorldPin.arena()` |
| `split_vision_check` | "only 1 merge to judge" | GW1b's data. The merge row plays two real AI matches and needs two merges between them to judge how the line goes; with the slower flight they give one (seeds 12345: 1, 2: 0) | **a sample, not a pin** | a third seed, 5 (1 merge), so the row judges two. The two rules it checks on every seed (no soft edge, no part-faded line) run on all three |
| `chase_rush_check` | the non-energy chain row: "the chain caught him 2 times" (4 taps) | GW1b's data. The row asserts the sim's chase (4 taps, at least 3 catches). At the slower flight each catch takes longer, so 35 ticks between taps caught him twice | **staging** (the camera rows are the same) | that row's taps 55 ticks apart (measured: 35 → 2 catches, 45 → 3, 55 → 4). The energy rows keep 35, so their ceilings stay keyed to the same scene |
| `cross_ko_check` | the first KO: "every move eases: a jolt of 0.093" (tick 364, pane 1, across) | **real, on the planet.** As the across shot gives the screen to the winner (`e_slot` moves to his pane), the other pane is still easing out of the KO close-up: its anchor reads 446, 431, 417, 402 px, easing toward its rest at 282. It loses that ease in one tick (402 → 282, a jolt of 0.093). The rig's anchor hold covers a shot fading out with nothing after it, not a handover to another shot | **a ceiling until the fix** | `HANDOVER_JOLT_CEIL` 0.094 on that row (it may only come down) |

## Proof

On the 44-line stack with gw1b-split-sweep: swing_places 33, split_vision 13, chase_rush 130 and cross_ko 21 all pass. The other camera checks were already green there: flight_shots, launch_shots, own_pane, peak_retry, peak_shot, split_share, swing_fight, swing_read, swing_real, swing_shot and split_sweep.

## Owed

None now: cross_ko's handover is fixed in `../gw1b-handover-ease/`, which takes the ceiling out again (the EP's word, 2026-11-21).

## gw1b-split-sweep's wide-hold fix: before and after, on one-view frames

`docs/camera/runs/c860b5a7/gw1b-split-sweep/one-view-before-after.txt` covers every real match in split_sweep on the stack (the planet). One-view ticks at the floor (23 px), before → after:

| Row | Before | After |
| :--- | :--- | :--- |
| real match 3 | 20 | 1 |
| real match 3 human 1 | 63 | 5 |
| real match 17 human 1 | 24 | 2 |
| real match 17 full | 3 | 1 |
| real match 10 human 1 full (Rendering's row: 201 → 33 under the line) | 181 | 14 |

- The other nine rows are unchanged.
- Layout changes are unchanged except real match 3 human 1 (9 → 13 in 60 s: the split opens when the view is pinned, rather than holding it at 23 px). split_sweep's dwell rule passes.
- So the fix takes the pair off the 23 px floor and into a split sooner. It's a small visible change, eased, with no cut and no fade.
