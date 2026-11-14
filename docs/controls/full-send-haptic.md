# The stick's full send on the pad (Controls, 2026-11-07; from Encounter's stick-slam and Game Design's slam-and-pace, section 1)

Encounter's `stick_full_send` cue (`docs/director/pending/stick-slam/`): a stick strike held to the fighter's top stage, landed and not a trade, is sent at a full B's share. Game Design lists "the top stage's haptic" for Controls.

## What the pad does
The sender's pad gets one **`full_send`**, the heaviest pulse the pad has:

| | |
| :--- | :--- |
| **Shape** | a slam on the low motor with a bite of the high one (0.30 / 1.00, 60 ms), a roll-off (0 / 0.55, 45 ms at 65) and a settle (0 / 0.25, 40 ms at 115); inside the 160 ms every kind keeps. The phone: 60 ms, then 28 ms at 65 |
| **Weight** | the most low-motor weight of any kind in the table (94.8 against launch_felt's 88), so the top stage's payoff is felt as more than the charge's thud (ladder_3) and more than a launch |
| **Scale** | by the family in the cue's source: the slam (`slamDown`) 1.0, the grounded `bury` 0.9, `skyward`, `across` and `acrossBehind` 0.8 |
| **Who** | the sender only (the cue's actor). The one sent has `launch_felt`, the blow's `hit_taken` |
| **Rate** | at most one in 400 ms for a slot, so two in a row never buzz |
| **Gate** | `switches.hapticLadder` with the right stick (it is the end of the charge's rumble). Off, the cue asks for nothing |

The charge's own stage pulses already climb to the top stage (`stick_stage`, behind `hapticStages`); this is what answers the send.

## How
`SimHaptics.event_requests` hands the cue to `full_send_requests(e)`. **No host line:** `main.gd`'s `_haptics_from_events` already passes every event to `event_requests`. Presentation only, read from the cue and nothing else.

## Proof
`full_send_haptic_test.gd` (14 checks): each family's scale, either slot, slots outside 0 and 1, an unknown family, the shape (three steps, first at full strength, the heaviest weight, two phone pulses, the rate limit) and off.

## Also in this park: the other new reason codes
`recovering` ("Recovering"), `set_piece` ("In a move") and `chord` ("One at a time") join the table (`launched`, `down`, `stunned`, `locked`, `queue_full` are in `refusal-knocks`). UI owns the final words.
