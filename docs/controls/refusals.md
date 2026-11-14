# Every press answered: the reason codes (Controls, 2026-11-06; for UI, Encounter and Audio)

The brief (controller vision section 5): four places still swallow a press with no sign: a face press that waits too long behind the stick; a stick stun held back by the one-a-string rule; the director's attack queue running out; the perfect-block anti-mash lockout. Each gets a knock on the pad and, the first few times, a word at the edge. This is Controls' part: the knock, the code table, and the two drops that are in the input layer. The park is `docs/controls/pending/refusals/`; everything is behind `switches.hapticRefused` (off).

## One knock, many reasons
The pad's knock is the existing `stick_refused` kind (two dull knocks on the low motor: a press that went nowhere). It is the same for every drop, so a player learns one feeling; **what differs is the reason code**, which rides on the request's `reason` key and which UI reads to put a word at the edge.

| Code | Suggested word | Whose drop | What happened |
| :--- | :--- | :--- | :--- |
| `face_late` | Too late | Controls (built) | a face press waited behind the stick for longer than `strike.queueTicks` and went |
| `face_overflow` | Too many | Controls (built) | a fourth face press behind the stick: the oldest went (`strike.queueDepth`) |
| `no_answer` | No answer | Controls (built, existed) | a stick request the director never started inside `strike.refuseTicks` |
| `stun_limit` | One a string | **Encounter** | a stick stun held back by the one-a-string rule |
| `queue_expired` | Too slow | **Encounter** | the director's attack queue ran out before it could start the blow |
| `block_lockout` | Block cooling | **Encounter / Combat** | the perfect block's anti-mash lockout held the press |
| `no_energy`, `hit`, `too_late`, `replaced`, `no_reach`, `answered`, `dodged`, `cancelled`, `not_yours`, `busy` | No energy, Hit, ... | Encounter (the texts its `stick_refused` cue already carries: `ki`, `taken`, `late`, `replaced`, `chase`, `answered`, `dodged`, `cancel`, `refused`, a state number) | mapped by `SimHaptics.refusal_code(text)` |
| `other` | Not now | Controls | a text the table does not know |

The words are suggestions (`SimHaptics.refusal_word(code)`); UI owns the final strings and how many times a word shows.

## The two drops in the input layer (built)
The strike law queues a face press behind the stick (3 deep, `queueTicks` live); an old press and the oldest of a full queue used to vanish. Now `SimStrikeLaw.dropped` records them, `SimLayout.take_dropped()` hands them on, and the hub knocks the slot's pad (one `stick_refused`, `reason` `face_late` or `face_overflow`, once for a tick whatever number went) and keeps each for UI: **`SimInputHub.take_refusals()` returns `[{slot, code, tick, button}]`** (the host or UI calls it once a frame; it empties the list). The hub's existing 30-tick no-answer knock now carries `no_answer` and is listed too.

## What Encounter supplies (the three director-side drops)
Emit a cue **`press_refused`** (`SimFx.cue(S, f, "press_refused", "", code)`: `actor` the presser, the text one of `stun_limit`, `queue_expired`, `block_lockout`) at the tick the press is let go of. `SimHaptics.requests("press_refused", ...)` turns it into the same knock with that `reason`, needing only `switches.hapticRefused` (not the right-hand switch: a perfect block is not a stick press). The director's own `stick_refused` cue texts need no change: `ki`, `taken`, `late` and the rest map to their codes now. A drop that is already told some other way (a `press_ack` of `refused`) should not also emit this.

## What UI does
Read `reason` from the host's haptic request (it is passed through), or read the same cue (`stick_refused`, `press_refused`) and the hub's `take_refusals()`, and use `SimHaptics.refusal_code` and `refusal_word`. Show the word the first few times, then only the knock.
