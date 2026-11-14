# flick-kept (park, on 4890bdd9)

The held flick that knocks "Didn't start" and then fires anyway (the stand-in's review, item 5). Design and measurements: `docs/controls/flick-kept.md`. Records: `docs/controls/runs/4890bdd9/` (CD-22).

## Apply

`git apply docs/controls/pending/flick-kept/flick-kept.patch` (five files; `git apply --check` is clean on the working tree at b345ba1b). Independent of the other four parks; it touches `timing.json` beside `chordPick`, so apply it after chord-full-send if they go in together (the hunks are separate lines).

| File | Change |
|---|---|
| `data/input/timing.json` | `switches.flickKept` false; `strike.refuseTicksKept` 120 |
| `tools/schemas/input-timing.schema.json` | both, described |
| `sim/input/input_data.gd` | `flick_kept_on()`; `flickKept` in `pin_switches_off` |
| `sim/input/hub.gd` | `consumed()` waits `refuseTicksKept` when the switch is on, else `refuseTicks` (one line) |
| `sim/input/test/refusal_cue_test.gd` | 8 checks (52, was 44): held flick told nothing at 60 and at 112; a director refusal adds no hub knock; an unanswered flick told once at 120; off, the control (told at 30, then it fires) |

## Switch (Tools' row)

Flip `switches.flickKept` together with `stick.flickKeep.enabled` and `stick.pendFollow.enabled` (the page row for flickKeep, as the flightStrikes row flips three). Off, nothing changes: `refuseTicks` 30.

## Why not just 30 to 95 in data

95 moves the hub's no-answer knock for everything, flickKeep on or off, and was too short (2 flicks answered at 97 and 113). Cue-driven refusals do not move either way. See the doc.

## Tested

All 40 input tests pass (`flick-kept-input-suite.txt`); lint and validate clean (321 files, 0 errors); the patch reproduces the tested tree byte for byte. Negative control: with `hub.gd` put back, the four flickKept checks fail (`flick-kept-negative-control.txt`). End to end, `refuse-wait-fault-wait30-gap30-60` shows the fault (441 knocks, 403 on flicks the director was holding) and `refuse-wait-fix-wait120-gap30-60` shows it gone (0). Not run: parity golden, director checks, `hud_check` (nothing here touches the sim; the switch is off).

## Not in this park

Encounter's quiet `stick_kept` cue and a one-line `note_press_answered` in `render/core/main.gd` (about line 1002; a Rendering grant) is the proper fix; `flickKept` costs nothing after. Also Encounter: with long gaps, 24 of 477 flicks sat in the director's buffer past 120 ticks with no cue.
