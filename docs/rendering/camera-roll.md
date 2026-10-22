# The camera roll on climaxes (Rendering, 2026-10-22)

The EP's brief: a dutch tilt of 4 to 8 degrees on a fight's climaxes, eased, switchable, with the HUD never rotated, and off by default.

## What it does

The main panes' cameras roll about their view axis when the sim says a climax happened:

| Event | Roll |
| :--- | :--- |
| `decisive` (a decisive exchange won) by a launch, a guard break or an interrupt | 5 degrees |
| `decisive` by a clash, a beam or a beam clash | 6 degrees |
| `finisher_start`, `ko` | 8 degrees |

- **Direction:** the roll leans toward the loser's side of the winner.
- **Timing:** it comes in over 0.25 s of match time, holds 0.8 s and goes back over 0.9 s, each eased. A hit-stop holds it.
- **A second climax mid-roll:** it turns the roll from where it stands and never snaps.

The numbers are `RenderLook.ROLL_DEG` and `ROLL_TIMES`.

- **Off by default** (`RenderLook.CAMERA_ROLL_ON` false). Main's `--roll`, or `?roll=1` on a page, turns it on.
- **The HUD is UI's canvas** and is never rotated. Its anchors on the fighters go through the camera, so they follow the roll.
- **Camera's inset strip stays level.**
- **The sky, the haze and the horizon glow** work from world-space view directions, so a rolled camera keeps them right.

`render/core/camera_roll.gd` (`RenderCameraRoll`) reads the sim's events and the fighters' places only. It writes nothing and draws no random number. `pane_world.gd` turns its camera after `CameraRig.frame`, so CameraRig (Camera's) is unchanged. If Camera wants the angle from its director later, a pane takes it as an argument.

## Against d3f1ca0e

Seed 4, Reduce flashing on as the demo has it, motion normal. The roll is switched on in a scratch build; d3f1ca0e is on the left:

- `img/roll-d3f1ca0e-1760.png`, tick 1760, after the launch and beam at 1739;
- `img/roll-d3f1ca0e-1850.png`, tick 1850, the roll back to level.

Both uncommitted.
