# Pad lab

A small web page with no fight in it. It reads what your thumbs do on a gamepad, tells you which pad is really moving, measures each stick, and saves the numbers to a file on your computer. **Nothing is sent anywhere**: the page makes no network requests at all, and the only file written is the one you save yourself.

## Run it

```
node tools/padlab/serve.mjs
```

It prints an address (`http://127.0.0.1:8790/`). Open that in Chrome or Edge. It does not open a browser by itself. Stop it with Ctrl+C. If port 8790 is taken: `node tools/padlab/serve.mjs --port=8791`.

If no pad shows up, press any button on the controller once. Chrome hides a pad until its first press.

You can run the whole thing with your other hand: **Space** starts a step, Space again goes to the next one, Esc cancels a running step.

## What you see

**1. Every pad the browser reports.** One card per slot, including empty slots and pads a game might skip. Each card shows the pad's index, its id text, its mapping, whether it is connected, how many buttons and axes it has, live bars for the left stick (axes 0, 1) and right stick (axes 2, 3), the trigger values, and every button. The pad that is really changing right now gets a blue outline and "moving now".

**2. Is there a phantom pad?** A phantom is a hidden or virtual pad (a second controller entry from Steam Input, DS4Windows or similar) that can hide the real stick from a game. This is what hid Orb's right stick on 2026-11-06: the game read a different pad index than the one that moved. The lab says what it found in plain sentences:

- "moves by itself": during the idle test one of the pad's axes wobbled by more than 0.03, or a button changed, with nobody touching anything. That is a phantom or a drifting stick.
- "sits off centre": a stick axis rested further than 0.10 from zero with hands off.
- "mirror of pad N": while you pushed a stick, another pad showed exactly the same values at the same time. One of the two is a copy.
- "did not react": this pad stayed still while another pad was pushed hard. If the game reads this pad, it sees nothing.

## The guided steps (section 3)

Pick the pad to measure at the top (the lab picks the one that moved most and is not a phantom or a copy; you can change it). Each step shows plain instructions, a progress bar and a live picture of the stick.

1. **Hands off every pad** (5 s). The idle test above.
2. **Push a stick around** (3 s). On your own pad, push a stick in circles. This tells the lab which pad is yours.
3. **Right stick: let go** (3 s). Gives the rest position, the wobble and the drift. The suggested dead zone is the biggest rest reading times 1.5, rounded up to 0.01, never below 0.05.
4. **Right stick: flicks** (5 flicks). Flick fully to any side and let go. Gives the **rise time** (10% to 90% of that flick's peak), the **spring-back** (from letting go until the stick is back inside its rest wobble and stays there) and the **overshoot** (the biggest push on the opposite side after letting go, as a share of the peak). Each is shown as a median and a range.
5. **Right stick: eight directions.** A ring on the picture lights up; point the stick at it and hold for 1 second, then let go. Gives, per direction, the average angle error and the wobble in degrees, and overall the **aim spread**. Plus means the stick points counter-clockwise from the target on screen, minus clockwise. Space skips a direction.
6. to 8. The same three for the left stick.

Results appear as plain text lines and three small pictures per stick: the rest cloud inside a circle (dashed ring = suggested dead zone), the flick curves, and the aim result.

## Save profile (section 4)

The "Save profile" button downloads `orb-pad-profile-YYYYMMDD-HHMM.json` to your browser's **Downloads folder** (or asks where, if the browser is set to ask), and keeps a copy in the browser's local storage (`orb-pad-profile:last`; if storage is blocked, the file is still saved). It holds: the pads seen with ids and indices, the pad you tested, the phantom findings, per stick the rest, flick and aim numbers, and suggestions in the units of `data/input/timing.json` (`deadzone`, `awayDead`, `triggerOn`, `triggerOff`, plus flick rise, spring-back and aim tolerance). The suggestions are only suggestions: nothing in the game is changed. `triggerOn` and `triggerOff` come from how high the triggers rest in the idle test (standard pads only); they equal the game's values (0.35 and 0.25) unless a trigger rests above about 0.1, and stay at the game's values if it was not measured.

## Honest limits

- **Time resolution is one frame.** The page reads the pad once per animation frame (about 16 ms at 60 Hz) and times it with `performance.now()`. Rise-time and spring-back differences smaller than one frame mean nothing. The page prints the frame time it saw.
- **The browser decides how often the pad is polled.** Chrome refreshes pad state on its own schedule, and a controller that reports at 125 Hz or 1000 Hz is still seen through that. Two frames can show the same reading.
- Browsers hide a pad until its first button press, and a pad that is not a "standard" layout may keep its sticks on other axes. The page has two small menus to change which axes count as the sticks.
- The phantom test finds a pad that moves on its own or copies another. A phantom that sits perfectly still is found by "did not react" instead, and only if you push a stick on another pad.
- Aim error is measured against the eight screen directions; it includes your thumb, not only the stick.

## Self-test

```
node tools/padlab/padlab-selftest.mjs
```

Ends with `padlab self-test ok` (exit code 0) or `FAILED`. It checks the maths in `core.js` on synthetic data, scans the page for anything that could send data, tests the server, and runs the page in headless Chrome with fake gamepads (a real pad, a jittering phantom, empty slots, then a mirror copy) through every step and the save. The browser part starts Chrome only through `tools/machine/browser.mjs` (one browser, below-normal priority, 150 s limit). If Chrome cannot be started it prints `browser part skipped: <reason>` and the rest still decides the result. `PADLAB_SKIP_BROWSER=1` skips it on purpose. `?fast=1` on the page address shortens every guided duration, for tests only.

## Files

`tools/padlab/index.html` (the page), `core.js` (all the maths, also loaded by Node), `serve.mjs` (the server, 127.0.0.1 only, serves just those two files), `padlab-selftest.mjs`.
