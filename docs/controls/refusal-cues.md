# The director's refusal cues, read as they are sent (Controls, 2026-11-07; from Encounter's morning fixes)

Two fixes in the pad's refusal knock, from `docs/director/pending/morning-fixes/README.md` (Controls' two items). Behind the switches that were already there (`hapticRefused`; `rightStick` for the stick's own cue).

## 1. The double knock
A director `stick_refused` knocked the pad, then 30 ticks later the hub's own "no answer" knocked again, because only `stick_start` ended the hub's wait. Now **any answer ends it**: `SimInputHub.note_press_answered(slot)` (the old `note_stick_started` is what it calls), which the host calls on `stick_start`, `stick_refused` and `press_refused`. A press the director refused is knocked once, by the cue. Test: an unanswered flick is one "no answer" and one knock (the control); answered by any of the three, none.

## 2. The reason is the cue's `source`
`SimHaptics.requests` read the refusal code from the cue's `text`, but the director sends the stick's direction in `text` and the reason in `source` (`stick_refused`), and the code in `source` for `press_refused` (hud-spec sections 84 and 85). So every stick refusal read "other". `requests(name, actor, target, text, amount, firer, source)` takes a new last argument `source` and reads **it**, falling back to `text` only when `source` is empty (so an old caller still reads). The source wins over the text. UI reads sources directly, so only the haptic request's `reason` key changes.
New codes with their suggested words (UI owns the strings), for the sources Encounter now sends: `close` -> `too_close` "Too close", `cooling` -> `cooling` "Cooling", `soon` -> `soon` "Soon". `hit` and the rest were already codes.

## The host's lines (a grant, `render/core/main.gd`, `host-refusals.patch`, 3 lines changed in `_haptics_from_events`)
```
if name == "stick_start" or name == "stick_refused" or name == "press_refused":
	host.hub.note_press_answered(int(e.actor))
... SimHaptics.requests(name, int(e.actor), int(e.target), String(e.text), float(e.amount), _haptic_firer, String(e.source))
```
Applies clean on HEAD (`git apply --check`). Until it goes in, the double knock and the "other" reason stay (nothing worse than today).

## Proof
`refusal_cue_test.gd` (27 checks): the director's real shape (text a direction, source the reason) for nine sources, `soon` knocking nothing, and the three press codes; "other" for a direction with no source; the old shape still reads; source wins; one knock to the presser's slot; the three new words; the hub control and the three answers. All 37 input tests pass; lint and validate clean; the patch applied to the chain gives the tested tree byte for byte.

## Open
`soon` (a held release waiting on its target's gate) is not a refusal: `requests` knocks nothing for it (the EP, 2026-11-07), and the screen word is enough. It is still a code, for the word.

## 2026-11-07 addendum: Encounter's refusal reasons, and the `hit` knock (park `pending/refusal-knocks/`)
- **New codes** for Encounter's `refusal-reasons` park (`docs/director/pending/refusal-reasons/`): `launched`, `down`, `stunned`, `locked` (what holds him, replacing the number read as "busy") and `queue_full` (three blows waiting and the cooldown holds them), each its own code and suggested word. `stun_limit` and `replaced` stop being sent with that park; their codes stay for old callers.
- **The audit** (`docs/controls/runs/cb477edf/`): with the park applied and `press.refusedCue` on, a scripted pad gets one knock per refusal cue, each with a named reason, and none for a landed flick.
- **`hit` is silent while the impact rumble is on.** A blow that stops a charge (`stick_refused` source `hit`, `DirStick.stopped`) was 53% of the knocks in the audit (1,215 of 2,306 in three easy matches) and fell on the same tick as `hit_taken`. It knocks nothing now when `switches.hapticImpact` is on; the screen word stays. With the impact rumble off it knocks as before. A beam charge taken (source `taken`) still knocks.
