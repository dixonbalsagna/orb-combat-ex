# A held flick is not "Didn't start" (switches.flickKept)

Owner: Controls. Park: `docs/controls/pending/flick-kept/`. Run record: `docs/controls/runs/4890bdd9/` (CD-22). From the stand-in's pre-play review, item 5 (`docs/ep/proposals/sunday-build-review.md`).

## The fault

With the director's `flickKeep` on, a flick it cannot start now (he is stunned, reeling, in a planned exchange, or launched) is held, quietly, and becomes his first blow out. The director says nothing while it holds. The hub's wait for an answer (`strike.refuseTicks`, 30) does not know that, so at 31 ticks the pad knocks "Didn't start" (code `no_answer`) and the held flick then fires anyway.

## Is `refuseTicks` 30 to 95 the right lever? Partly.

Only the hub reads `refuseTicks` (`sim/input/hub.gd` `consumed`). It is the right place, but a plain 95 on main is wrong in two ways, and 95 is short:

1. **It moves the hub's own fallback for everything.** With `flickKeep` off (main as shipped) the director answers by cue and the hub's `no_answer` is only the silent gaps. A flick the director never answers would then knock at 95 ticks instead of 30. So the longer wait belongs with the row that turns the keep on.
2. **95 is short.** In 4 medium matches with long gaps between flicks, 477 flicks were answered; the longest answer came at 113 ticks and 2 came after 95. At 95, 2 of the 41 knocks were still false (the flick fired later, at 97 and 113); at 120, none. So the park uses 120.
3. **At Orb's cadence the hub's wait is restarted by each new flick**, so any long wait hides the silent gaps for as long as he keeps flicking. That is a property of the wait, not a cost of the number.

So: `switches.flickKept` (off) picks `strike.refuseTicksKept` (120) instead of `strike.refuseTicks` (30). Tools' flickKeep page row flips it together with `flickKeep` and `pendFollow`, as the flightStrikes row flips three. Off, nothing changes.

## Does it delay a real refusal's knock? No.

A refusal the director says (`stick_refused`, `press_refused`) knocks on its cue and ends the hub's wait the same tick; the timer is not on that path. The probe's answer-cue counts are identical at `refuseTicks` 30, 95, 190 (same seeds, the timer is haptics only). What does move, with the switch on: a flick that nothing ever answers is told "no answer" at 120 ticks, not 30.

## What the probe measured

Probe: `tools/feel/refuse_wait_probe.gd` (a scratch tool, saved as `runs/4890bdd9/refuse_wait_probe.gd.txt`). A scripted pad on the real hub plays 4 seeded matches against the medium computer with `flickKeep`, `pendFollow` and `press.refusedCue` on; every flick is timed from the hub's `rsStart` to the director's first answer cue.

| Run (record file in runs/4890bdd9/) | Wait | Flick gap | no_answer knocks | held by the director | answered later (false) |
|---|---|---|---|---|---|
| fault (`refuse-wait-fault-wait30-gap30-60`) | 30 | 30 to 60 | 441 | 403 (359 in the buffer, 44 queued) | 35 |
| fix (`...fix-wait120-gap30-60`) | 120 | 30 to 60 | 0 | | 0 |
| long gaps (`...fix-wait95-gap120-200`) | 95 | 120 to 200 | 41 | 32 | 2 (at 97 and 113 ticks) |
| long gaps (`...fix-wait120-gap120-200`) | 120 | 120 to 200 | 34 | 26 | 0 |
| long gaps (`...fix-wait190-gap120-200`) | 190 | 120 to 200 | 1 | 1 | 0 |

The director answered 1,295 of the first run's flicks (the longest at 54 ticks) and 477 of the long-gap runs (the longest at 113, 2 of them after 95). The answers are the same in every row: the wait only moves the pad's knock.

- At the Sunday page's state 403 of 441 knocks (91%) were on a flick the director was holding. 38 (9%) were silent gaps: he was launched, down or free with nothing held and no cue.
- With long gaps, 24 flicks were still in the director's buffer at 121 ticks, 17 at 141 and 1 at 191, with no cue (they sit in `locked` exchanges; the hub counts live ticks and may run faster than the director's clock in a slow-motion finisher, not checked). The director's own 90-tick bound should have told them. That is Encounter's to look at (flick_keep_check does not cover a locked exchange held this long); it is why no wait value clears everything, and why the proper fix is below.

## The proper fix (not in this park)

Encounter sends a quiet `stick_kept` cue when it keeps a flick, and `render/core/main.gd` (about line 1002) calls `note_press_answered` on it; the hub then stops waiting while the director holds. That needs Encounter and a Rendering grant. `flickKept` stays useful until then and costs nothing after.

## Tests

`sim/input/test/refusal_cue_test.gd` (52 checks, was 44): with `flickKept` on, a flick held 60 ticks and then started is told nothing; held 112, still nothing; a director refusal at 60 adds no hub knock; a flick nothing answers is told once at `refuseTicksKept`. Off (the control): the same held flick is told "no answer" at 30 and then fires.
