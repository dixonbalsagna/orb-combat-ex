# Parked: a shot's handover eases the outgoing pane (gw1b-handover-ease)

Camera, 2026-11-21, the EP's word: fix cross_ko's handover jolt rather than land a ceiling. Orb's rule is that every camera move eases. The third small piece on the 44-line GW1b stack.

**Apply after gw1b-camera-checks** (cut on the 44-line stack + gw1b-split-sweep + gw1b-camera-checks): `git -c core.autocrlf=false apply gw1b-handover-ease.patch` (sha1 832e3924). Three files, mine.

| File | What |
| :--- | :--- |
| `render/camera/split_rig.gd` | in the tick a shot's slot changes (`e_slot` or `solo_slot`: a handover), a pane anchor's step of over `ANCHOR_JUMP_PX` goes into an offset that eases out over `ANCHOR_JUMP_TAU`; a cut resets it, and so does a snap of the cameras |
| `render/camera/camera_params.gd` | `ANCHOR_JUMP_PX` 24, `ANCHOR_JUMP_TAU` 0.25 s (the anchors' own pace) |
| `render/camera/tests/cross_ko_check.gd` | gw1b-camera-checks' `HANDOVER_JOLT_CEIL` comes out: the row holds the 0.06 jolt limit again |

## What it was

On the planet, as the across shot gives the screen to the winner, the other pane is still easing out of the KO close-up: its anchor reads 446, 431, 417, 402 px, easing toward its rest at 282. The handover moves `e_slot` to the winner's pane, and that pane dropped the ease in one tick (402 → 282 px, a jolt of 0.093). The rig's anchor hold covered a shot fading out with nothing after it, not a handover to another shot.

**A first cut** eased every anchor step over 24 px without a cut. Then split_sweep failed two rows: a layout's change of sides carried the old anchor across the divider, into the other pane. A layout's change has its own rules and lands at once, so the ease now takes in only the handover's step.

## Proof (`docs/camera/runs/c860b5a7/gw1b-handover-ease/runs.txt`)

| Run | Result |
| :--- | :--- |
| cross_ko without the ceiling | **passes, 21 checks.** First KO jolt **0.093 → 0.010**; the flight's rush jolt 0.093 → 0.043 |
| every camera check on the stack | **all pass**: chase_rush 130, cross_ko 21, flight_shots 632, launch_shots 1,029, own_pane 12, peak_retry 1, peak_shot 24, split_share 26, split_vision 13, swing_fight 10, swing_places 33, swing_read 14,420, swing_real 48, swing_shot 164, split_sweep |
