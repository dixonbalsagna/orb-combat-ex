# After a launch: the player always knows where the opponent is (Camera, 2026-10-16)

Orb played the live demo against the computer (docs/ep/vision.md, "Orb plays the live demo against the computer"): "when I did manage to launch them, the split screen didn't really catch up with them, and I felt like I had no idea what they were doing until they rushed back at me at full speed and got some cheap hits."

## What it was (reproduced)

`render/camera/tests/launch_probe.gd` plays AI against AI through the real scene, tells the camera that slot 0 is the human (`SplitRig.test_human_slot`, camera-only, the sim is untouched) and follows every launch: where the launched fighter is on the screen through the flight and through his return to the next blow. Twelve seeds, 3,600 ticks, 18 launches of the computer (slot 1) by the human:

- **The hybrid rule of camera-v2 section 3 was the cause.** One human who launches the opponent *holds*: the camera stays on the human, the opponent flies off the frame for the whole flight, and a cut shows the impact. That is what Orb saw. Measured, the old behaviour: the computer is off the picture for **479 of 2,979 flight ticks (16%)**, in runs of up to 90 ticks; the human is off the picture for 359 (a cut to the impact is a cut away from him); and in the return (landing to the next blow) the computer is a dot under 32 px in 259 of 1,342 ticks.
- **The return is a rush at 10,000 units a second** (seed 12: 7,467 units to contact in 0.7 s). The pane that chases is at the zoom floor (26 px) by the governor.
- A second cause, found on the way: the flash bundle I had made the default for reduced flashing included the **merge zoom limit**, which made the zoom crawl in at 0.2 e-folds a second after a closing, so the pair that had come back together was drawn at 26 px for two to five seconds. It is out of the bundle.

## What changed

| Piece | Switch | Default |
| :--- | :--- | :--- |
| **The computer a human launched is kept in a pane for the whole flight.** `launch_follow` "auto" for one human who launched the opponent returns "split": the opponent's pane chases, no solo shot, no hold and cut. The old hybrid is `launch_follow = "hold"`. | `SplitRig.launch_follow`; UI option `camera_launch_follow` | on ("auto") |
| **The launch rule's hold does not apply to that computer** (`keep_opponent_in_view`, `_keeps_in_view`): a frozen frame he flies out of is the opposite of the above. Against the computer only; AI against AI (the clips) and two humans are as they were. | `keep_opponent_in_view` | on |
| **The flash bundle** (`launch_hold`, its eager engage, the slam off), under reduced flashing only (the EP's decision of 2026-10-16). The merge zoom limit is not in it. | `flash_bundle`, `flash_bundle_reduced_only` | on, reduced flashing only |

**Measured with the new defaults** (the same 18 launches): the computer off the picture **6 of 2,979 flight ticks (0.2%)**; the human off the picture **0**; the return's dot ticks 259 to **177** (13% of the return: five returns of 15 to 44 ticks each, at the moment the pair comes back together). What is left is the governor's arming tail: a charge's cue arms the scroll governor until 0.3 s after the move ends, so the panes of a pair that has just made contact stay at the zoom floor for 18 ticks. Shortening it is a flash question (the charge clips) that I did not touch.

**Not claimed:** the return framed before he arrives, beyond his own pane. The computer's pane shows him at its size the whole way, and UI is asked for an off-screen pointer on the human's side; the camera cannot put a body 7,000 units away in a pane that holds 1,500.

## Flash

Scratch exports of HEAD plus the files, Tools' path, 1,024 x 768, primary / area -15% / 2 s memory (AI against AI: the human path is measured by the probe, since the clips have no human launching a computer):

| Clip | Reading |
| :--- | :--- |
| ai 39 reduced | 2.5 / 2.5 / 2.5 PASS |
| ai 12345 reduced | 1.5 / 2.5 / 2 PASS |
| collapse reduced | 2 / 2.5 / 1 PASS |
| ai 1 reduced | 1.5 / 2 / 1 PASS |

## Gates

`split_sweep` (seeds 10 and 17, and the `--launch-hold` pass on 3 and 10) passes with two rows changed: "hybrid hold and cut" runs under `launch_follow = "hold"`, and a new "hybrid keeps the computer in a pane" checks no hold, no cut, a pane, the human always in the picture. `depth_inert` digests equal a clean HEAD's (881773481156056933 and 1623366814117928698); `seam_sweep`, `pane_check` and determinism (plain and `--intro`) pass.
