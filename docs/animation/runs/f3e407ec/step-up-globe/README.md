# Step-up on the globe ground: the look gate's retake (Animation, 2026-11-20, B-08)

Two captures, A then B, through Tools' launcher (the capture list was empty twice, a minute apart, before the first), below normal priority, 120 ticks each at 20 frames a second, the default view (globe ground, split screen). A and B are the same build: the GW1a stack, World's floor-rise grant, `step-up.patch`, `water-tile-check.patch`, World's `lake-places` (with `lakeMax` 8) and Rendering's `water-everywhere`, i.e. GW1b's data; A has `step_up.enabled` false in `data/anim/ground_motion.json`, B true. The pictures are in `docs/animation/private-img/step-up-globe/` (git-ignored: fighters never go in git): a GIF of A beside B, a full-frame A-over-B sheet, a close A-over-B sheet.

## The lift is real, not staged by hand

Dry globe ground, away from water. No dry terrain step exists on planet 7's ring (a scan of the whole ring found no place where the floor rises more than 18.75 in 4 units), so the lift is the game's own terrain change: at tick 40 an impact digs a crater (`WorldCrater.dig`, energy 20, the second fighter the cause) at x 42,240, and the crater's rim rises under the first fighter, standing at x 42,976, by **62.8 units (0.84 body heights) in one tick** (his floor 849.5 to 912.4; the sim's, the floor-rise grant lifting him in the same tick). The tile ground draws the bowl and the rim, the camera shakes as it does for an impact, and dust and debris fly; the step-up fires once. A hand-raised terrain bump was not used: the tile ground does not draw one and its lift table does not see it (he would hover about 68 above the drawn ground).

## What it shows

- **The lift reads the same in both** (the sim's, and the camera's own ease: he rises and the frame follows over a few ticks; nothing is drawn inside the bank).
- **In B he crouches as he steps up.** Measured as the fighter's drawn height, head to boots, in pixels (94 px standing): A stays at 94 to 96 through the lift; B dips to **89 at tick 49** (5 px, 5 percent of his height: about 4 units of 75), is under A from tick 45 to 53, and is level again by tick 55. In at about 5 ticks and out at about 6, as built (12 ticks, in over 6, out over 6, with the solve on twos).
- **It is small.** At the split screen's size a 4-unit dip is a few pixels: a hitch you feel, not a gesture you see, which is the ruling's intent ("a short step-up"). The close sheet shows it (the knees bend a little more in B at ticks 47 to 51).

## Not shown

- One lift, one fighter (the Protagonist; the Anti-hero is the same pose math and was not captured).
- The crater is a real impact's, with its shake and debris; there is no way to lift him on dry ground without one.
