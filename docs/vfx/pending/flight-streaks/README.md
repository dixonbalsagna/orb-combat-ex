# Parked: the background carries a launch's speed (VFX, 2026-10-19, on HEAD 86983120)

Research's cinematic paper, rec 8 (launch in three parts: snap, a velocity-matched chase with the background carrying the speed, an arrival hold; the VFX half is the background) and rec 12 (speed on the background, never over a fighter). One file, render/vfx/shots_view.gd, no grants: `_flight_streaks`.

While a body is launched and moving faster than 700 units a second, thin streaks lie along his line of flight on the background (hashed grid cells anchored in the WORLD, so they stay put as the camera chases him and slide past it), behind the fighters' plane (z -2, depth-tested, so a fighter always hides them), in his lane colour, quiet (at most 56, half in Reduced motion, 30% of cells at full speed). Skips anything within a body height and a half of either fighter. No flicker (they only move with the camera), no random number (a hash of the cell), none when he is slow or has landed. Behind the same switch as the other speed lines (`hub.speedlines_enabled`).

## Checks
effects_check, validate pass (scratch build of HEAD + patch); `git apply --check` clean. Side by side before and after on the `launchai` scenario (the player launches the AI; speeds 3,000 to 9,000 units a second), ticks 90 to 130, GIF in homework/flight-streaks/ (private).

## Honest limits
The scene is a split screen, where the pane is narrow; the grid is sized in body heights so it reads in one view too, but I have not looked at it with the camera's chase of Camera's step 4 at full speed. Not a Legal clearance (thin lane-coloured lines, no flicker, nothing over a fighter). Flash readings not re-run. The streak colour is the lane colour, so on a pale ground it is a quiet tint, not a bright line.
