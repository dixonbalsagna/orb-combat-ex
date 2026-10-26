# The camera roll on climaxes (Rendering, 2026-10-22)

The EP's brief: a dutch tilt of 4 to 8 degrees on a fight's climaxes, eased, switchable, with the HUD never rotated, and off by default. The EP's second brief (2026-10-22): motivated and rare, so the climax decides when and the story decides how much.

## What it does

The main panes' cameras roll about their view axis on the fight's top climaxes only. **The sim's event decides when:**

| Event | Weight | Roll |
| :--- | :--- | :--- |
| `finisher_start`, `ko` | 1 | 8 degrees |
| `decisive` (a decisive exchange won) by a beam clash | 0.5 | 6 degrees |
| `decisive` by a guard break or a launch | 0.25 | 5 degrees |

- **What does not roll:** a plain knock-back, a heavy clash, a beam won, an interrupt, a shot and a barrage.
- **The gap:** a roll starts at least 8 s of match time after the last one began. A finisher's start and a KO roll whatever the gap.
- **The list, the weights and the gap are data:** `RenderLook.ROLL_EVENTS`, `ROLL_DECISIVE` and `ROLL_GAP_S`.
- **How much and which way:**
  - With Encounter's camera-intent feed on (`cameraIntent.enabled` in `data/director/interrupts.json`, false today), the story picks, if Camera's split rig holds one for the climax:
    - **Weight:** 1 or 2 is 0.25, 3 is 0.5, 4 is 0.75, and 5 or `finisher` is 1. It is never under the event's own weight.
    - **Direction:** it leans toward `story_d`'s side of `story_a`.
  - Otherwise the event's own weight applies, leaning toward the loser's side of the winner. That covers the feed off, no story held, and no rig stepped (main's `--nosplit`, the tools).
- **Timing:** it comes in over 0.5 s of match time (30 frames, the low end of Research's dutch roll in `cuts-and-eases.md`; 0.25 s until 2026-10-23), holds 0.8 s and goes back over 0.9 s, each eased. A hit-stop holds it.
- **A second climax mid-roll:** it turns the roll from where it stands and never snaps.

The numbers are `RenderLook.ROLL_DEG` and `ROLL_TIMES`.

- **Off by default** (`RenderLook.CAMERA_ROLL_ON` false). Main's `--roll`, or `?roll=1` on a page, turns it on.
- **The HUD is UI's canvas** and is never rotated. Its anchors on the fighters go through the camera, so they follow the roll.
- **Camera's inset strip stays level.**
- **The sky, the haze and the horizon glow** work from world-space view directions, so a rolled camera keeps them right.

`render/core/camera_roll.gd` (`RenderCameraRoll`) reads the sim's events, the fighters' places and the rig's story only. It writes nothing and draws no random number. `pane_world.gd` turns its camera after `CameraRig.frame`, so CameraRig (Camera's) is unchanged. If Camera wants the angle from its director later, a pane takes it as an argument.

## Against d3f1ca0e

Seed 4, Reduce flashing on as the demo has it, motion normal. The roll is switched on in a scratch build; d3f1ca0e is on the left:

- `img/roll-d3f1ca0e-1760.png`, tick 1760, after the launch and beam at 1739;
- `img/roll-d3f1ca0e-1850.png`, tick 1850, the roll back to level.

Both uncommitted.

## Motivated and rare, measured (2026-10-22)

A scratch probe ran AI-vs-AI matches through main with the split view attached and the roll on. It used seeds 1 to 3 for two minutes each, with the feed on and then off, on c6980e25 plus Camera's story slots. Play was the same in every run: 60 decisive exchanges, 47 of them knock-backs. Ten were on the roll's list: 5 launches and 5 beam clashes.

| | Feed off | Feed on |
| :--- | :--- | :--- |
| Rolls | 8 | 8 |
| Listed climaxes rolled | 8 of 10 (2 within the 8 s gap) | 8 of 10 (the same 2) |
| Rolls with no climax | 0 | 0 |
| Match time rolled | 4.2% | 4.2% |

- **The two runs differ only in which story was read.** Every story live at these climaxes weighed 1 or 2, which is the launch's own weight, and the beam clashes had no story.
- **Seed 1, played to its KO** (6 min 51 s of match time, feed on): 12 rolls on 15 listed climaxes, 4.9% of match time.
  - The finisher's start (with its guard break) and the KO 4 s later both rolled 8 degrees; the KO went through the gap.
  - Two launches with a story of weight 3 (reversal, decisive, crippling) rolled 6 degrees in place of 5.
  - Two climaxes fell within the gap: a launch and a beam clash.

**Before this, a plan's story started the roll on its own** (the first story trigger, the same three seeds). It rolled 88 times, and 53 of those rolls had no decisive exchange in them. It rolled for 23 of the 60 decisive exchanges and kept the camera tilted 29.4% of match time. The rig held no story at 40 of the 60 decisive exchanges, and "decisive" is tagged on any big plan. The event list before the second brief rolled on all 60, 33.8% of match time.
