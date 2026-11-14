# refusal-knocks: the pad's refusal knock reads Encounter's new reasons and knocks only real refusals (Controls, 2026-11-07)

Run record: `docs/controls/runs/cb477edf/` (the knock audit).

## Files
- `refusal-knocks.patch` (2 files), Controls': `sim/input/haptics.gd` and `sim/input/test/refusal_cue_test.gd` (44 checks, was 27).
  - New codes `launched`, `down`, `stunned`, `locked`, `queue_full` (Encounter's `refusal-reasons` park names what holds him and the full queue), each with a suggested word and read as itself, never "busy" or "other".
  - **A stick strike stopped by a blow (`stick_refused` source `hit`) knocks nothing while the impact rumble is on:** `hit_taken` is the same news on the same tick. The screen word "Hit" is untouched. A beam charge taken (source `taken`) still knocks.

Apply: `git -c core.autocrlf=false -c core.eol=lf apply refusal-knocks.patch`. It works with or without Encounter's park.

## The audit (Encounter's `refusal-reasons.diff` applied, `press.refusedCue` on)
A scripted pad through the real hub, the host's wiring and the director, 3 matches a cell. **Every refusal cue is one knock with a named reason, none is silent and none reads other, busy, replaced or stun_limit** (`stun_limit` and `replaced` are no longer sent). A landed flick never knocks. **Finding:** before the `hit` change **53% of the knocks were `hit`** (1,215 of 2,306 in three easy matches, about one every second of a pad that flicks all the time), each on the tick of the `hit_taken` rumble. A human flicks less, but every blow taken in a wind-up would have buzzed twice.

## Checked
All 38 input tests; lint and validate clean; the patch on clean HEAD gives the tested tree byte for byte.

## NEEDS FROM EP
Nothing. `hapticRefused`'s knock now excludes `hit` by this rule: say if Orb wants it back.
