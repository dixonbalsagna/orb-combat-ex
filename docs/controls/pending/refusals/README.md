# refusals: every press answered, Controls' part (Controls, 2026-11-06; job 4 of the controller-vision brief, row 2)

Reason codes and the knock for the presses the game lets go of with no sign. Full contract (the code table, what Encounter emits, what UI reads): `docs/controls/refusals.md`.

## Files
`refusals.patch`: `sim/input/strike_law.gd` (`dropped`, recorded at the expiry and the overflow), `layout.gd` (`take_dropped()`), `hub.gd` (`_note_drops`, `take_refusals()`, the existing no-answer knock carries its code), `haptics.gd` (the `REFUSALS` table with suggested words, `refusal_code`, `refusal_word`, the `reason` key on `stick_refused` requests, the new cue `press_refused`), `input_data.gd` (`refusal_cues_on()`), `sim/input/test/refusals_test.gd` (78 checks) with its `.uid`. No host change (the host passes the request through; the extra `reason` key is ignored by it), no data key (the switch is the existing `hapticRefused`).

Apply after `../landing/controls-landing.patch`, `../stall-keep/stall-keep.patch`, `../impact-haptics/impact-haptics.patch` (cut on that tree).

## Checked (headless, below normal priority)
refusals_test 78 of 78: the law drops a face press that waited past its life as `face_late` just after the life ends (and not before), a fourth press as `face_overflow`, a press that waits and then goes is not dropped, with the stick at rest nothing is dropped, with rightStick off nothing; through the hub the drop is one `stick_refused` with its reason for slot 0 and one `take_refusals()` entry (slot, code, tick, button), deterministic; every director text maps to a code; `press_refused` with `stun_limit`, `queue_expired` and `block_lockout` knocks the right slot and needs only the refused switch; slots 2 and 3 are not knocked; the table is complete (a word, an owner, what happened); with the switch off nothing is knocked or listed. haptics_test 80, stick_feel_test 142, all 32 input tests, `word_check` 620, `rollback_check --right-stick` PASS (1,200 comparisons), lint and validate clean. No sim file touched: the golden is unaffected.

## What is not done (Encounter's)
The three director-side drops (the stun limit, the attack queue's expiry, the perfect-block lockout) need Encounter to emit `press_refused` with the code at the drop: the mapping, the table and the knock are ready. UI's words and the first-few-times counter are UI's.
