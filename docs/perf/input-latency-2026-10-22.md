# Input-to-screen latency of the web build (2026-10-22)

Owner: Performance and Platform, for the EP (standing brief, item 1). Build: clean `git archive` of HEAD, the web export, a scratch hook (`hook-latency.mjs`, the `lat` variant of `make-audit-sites.mjs`), run by `latency-bench.mjs` through the guarded browser launcher. Valid by the load rule in every config below.

## What was measured, and how

- **A real browser key press.** Chrome's `Input.dispatchKeyEvent` sends a keyDown (light: J, dash: Space, guard: Shift, the keys of the solo keyboard layout), so it goes through the browser's own input path to Godot's web input queue and the game's `_unhandled_input`.
- **The game's own frame loop**, not Tools' tick-per-step: `main.frame(delta)` with the real elapsed time, so the sim runs the ticks a frame's time allows and the view is drawn at the interpolation point, as in play. Paced to 60 Hz by a busy wait (headless Chrome runs animation frames unlocked, so this stands in for vsync). Reduce flashing on (the shipped default).
- **A scene made for it:** a new match per trial, player one on the keyboard, the idle training dummy 250 units away (also tried at 80 and 150), the press sent after a random wait so it lands at a random phase of the frame. 20 trials per action (12 for the RTX at x4).
- **Per trial, in the page's own clock:** the DOM keydown time; the frame and tick in which the game's handler got the key; the player's action state after every tick; and for every drawn frame how much the middle of the picture (where the pair is) changed from the frame before, area-averaged to 160 by 90. The "first changed pixel" is the first frame whose change is over the idle noise (the larger of the mean plus 5 deviations and 1.25 times the largest of the 40 frames before the press).
- **Stages reported:** `browser` = DOM keydown to the game's handler; `sim ticks` = from the handler to the first tick whose action state differs (0 = the very next tick); `draw frames` = from the frame that ran that tick to the frame whose picture changed; `total` = DOM keydown to the END of the first changed frame.
- **What it does not see:** the browser's compositor and the display (about one display frame, 17 ms at 60 Hz, more on a real screen), the OS, the device. Add about 17 ms for a 60 Hz display. Headless Chrome has no real vsync, so frame phase here is the pacing's. A high-speed camera is still the only measurement of button to photon (Orb's phone checklist in docs/controls/).

## Results (ms from the DOM keydown to the end of the first frame whose picture changed; p50 / p95 / max)

| Action | RTX 5070 Ti, 60 Hz pacing | Integrated Radeon, 60 Hz pacing | Radeon, CPU x4 | RTX, CPU x4 |
|---|---|---|---|---|
| **Light** | 135 / 141 / 143 | 129 / 139 / 143 | 155 / 185 / 515 | 139 / 203 / 203 |
| **Dash** (the dodge key) | 44 / 58 / 58 | 39 / 50 / 52 | 133 / 504 / 504 (16 of 20 valid) | 62 / 173 / 173 (11 of 12) |
| **Guard** (Shift) | 32 / 48 / 56 | 33 / 42 / 43 | 87 / 228 / 228 (19 of 20) | 48 / 73 / 73 |

| Stage | Light | Dash | Guard |
|---|---|---|---|
| Browser (key to the game's handler), p50 / max, 60 Hz | 7 / 20 ms | 7 / 18 ms | 7 / 19 ms |
| Sim, handler to the first state change | **5 ticks (83 ms), every trial** | 0 ticks (the next tick) | 0 ticks (the next tick) |
| Draw, tick to the first changed picture | 1 frame | 0 to 1 frame | 0 frames |

x4 (CPU four times slower, frames of 30 to 50 ms) lengthens the browser stage to 16 to 30 ms (the key waits for a slower frame) and puts the spikes of cold-start frames (the first dash or guard of a match) into the tail: the 504 ms and 228 ms are single first-use frames, as at ticks 131 and 238.

## What is over 3 frames (the controls budget: press to first visible reaction at most 3 ticks, 50 ms excluding display) and where it sits

1. **The light, in every trial, on every GPU: 7 frames at 60 Hz (129 to 143 ms).** The sim itself starts the rush **5 ticks (83 ms) after the press, whatever the distance (80, 150 or 250 units) and however long the key is held (40, 90 or 250 ms)**; nothing in the sim state, the exchange or the press-acknowledge events changes in ticks 0 to 4, and the picture does not change either. So the delay is **in the sim's melee press (the director's authored lead), not in the browser, the render or the platform**: the controls ruling's own wording is "the rush begins on the request tick" (3 ticks). Owners: Combat and Simulation (is the 5-tick lead authored, and should the first four ticks show an anticipation or a `press_ack`), Animation if it should be a pose. At 60 Hz the light is 135 ms before the display adds its frame; the web budget for button to photon is 133 ms.
2. **The dash at p95 on the RTX: 58 ms** (2 frames: one for the browser's wait for the next frame, one drawn). Inside the 133 ms web budget, a little over the 50 ms excluding display. Nothing to fix; the wait for the next frame is the browser's (a key that lands just after a frame waits for the next one).
3. **At x4 the dash and guard are 2 to 5 times longer in the tail** (the cold-start frames), and the light is 3 to 4 slow frames. This is the frame time, not the path: the path adds nothing beyond the frame it waits for.

## What is fine

- **The sim reacts on the very next tick** to a dash and a guard (the controls rule T1: no latency on taps): 0 ticks in every trial.
- **The render adds at most one frame** (the interpolation draws the tick it just ran; the pose appears in the same or the next frame).
- **The browser's share is one frame's wait**: 7 ms on average at 60 Hz (half a frame), 16 to 30 ms at x4 (half a slow frame). There is no extra queue between the key and the game.

## Re-run on aa927bb5 (Encounter's press-tick), early and mid-match presses

Build: HEAD 7410e1ac (aa927bb5 is in it). `latency-bench.mjs --timing early|mid`: early = the key about 0.5 s after the match starts (a claim press of E first, then the action about 0.15 s later, inside the match's 0.6 s opening cooldown); mid = the action about 9 s into the match (a claim press of E 8 s before).

| Press | What the sim does | First changed picture |
|---|---|---|
| Early light, dash, guard (RTX, Radeon, x4) | **reacts on the press tick** (the light's press shows `queue = 1`, the dash and guard change their state on tick 0): the press-tick fix works | the light's picture changes about **10 frames (170 to 210 ms) later**, when the cooldown ends, as designed; the dash and guard could not be timed by pixels (the opening scene's camera still settles, idle noise 0.9 to 1.0 against 0.04 mid-match) |
| **Mid-match light** | the rush starts **5 ticks (83 ms) after the press, still, in every trial** (RTX 10 of 10, Radeon 10 of 10 valid) | Radeon 132 ms p50 (p95 140); x4 145 ms (p95 324) |
| Mid-match dash | tick 0 | Radeon 37 / 56 ms; x4 105 / 221 (the x4 numbers carry cold-start frames) |
| Mid-match guard | tick 0 | Radeon 33 / 40 ms; x4 97 / 161 |

- **So the 5-tick light start is not (only) the opening cooldown**: in the mid-match runs there has been no exchange and no recent press (the throwaway claim press of E was 8 s before), and the light's rush still starts exactly 5 ticks later, at 80, 150 and 250 units and for any hold. This is the same measurement as before the fix; Encounter is looking at it. A possible cause to rule out on their side: the claim press of E (the power button) being the player's "first press" and the light the second, so a rule on the second press, or the 5-tick grid Controls' T1 test found (24 of 62 fail on main, all starting at tick 5).
- The RTX mid-match runs were invalid by load (the ticks are exact, the milliseconds are not reported). Re-run when Encounter's 7a lands.

## Files

`docs/perf/tools/latency-bench.mjs` (`--hold`, `--page-args latd=80`, `--pace60`, `--throttle`, `--igpu`, `--raw`), `scratch-hooks/hook-latency.mjs`, the `lat` variant in `make-audit-sites.mjs`. The raw runs are in my scratch folder.
