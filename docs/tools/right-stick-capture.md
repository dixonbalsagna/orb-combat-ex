# The right-stick capture page and its analysis

Owner: Tools. 2026-10-23, to Controls' spec (`docs/controls/right-stick-capture.md`, for GD's R20: a real-thumb capture comes before any pattern ships).

## The page: `tools/capture/right-stick.html`

One self-contained file (no library, no network, no server). A person opens it in an ordinary desktop browser (Chrome, Edge or Firefox) with a pad in hand, or on a phone, or with the arrow keys. It shows one prompt at a time, records, and at the end **saves one JSON file** to their Downloads folder. It never uploads: the page carries a content-security policy that forbids every request, and the self-test checks that the script has no `fetch`, `XMLHttpRequest`, `WebSocket`, beacon, storage or external URL.

How a session goes (about nine minutes of trials, a little more with the screens between parts):
1. **About you**: a code (typed or given; letters and digits, never a name), hand, which thumb is on the right stick, how the pad is held (thumbs, claw, back paddles, other: for the thumb-transfer table), a self-rating (new to sticks, regular, fighting-game or shooter player), and how they are taking part (pad, finger, keys).
2. **Check the stick** (pad only): the browser needs a button pressed; a live dot shows the right stick. A standard-layout pad uses axes 2 and 3; any other pad is asked to move its right stick and the two axes that move most are taken (the person can pick the axes by hand).
3. **The parts**, each with an intro, a one-second countdown before every trial and a tone at the end: rest calibration (2 s); four-way flicks (6 a direction comfortable, 3 fast); eight-way flicks (3 each); holds (3 a direction, 1.5 s); double flicks (6); zig-zags (8: horizontal and vertical, 3 and 4 strokes); circles (a quarter, a half and a full circle, clockwise and anticlockwise, 3 of each: 18); free aim (two 20 s sweeps); hard flicks (10); **thumb moves** (pad only: 24 timed trials for Controls' no-claw law, in the next paragraph); idle (10 s); "as in a fight" (5 free trials, each followed by "what did you just do?"). A on the pad (or the button) goes on; any part can be repeated; **Stop and save what I have** is always there.
4. **Done**: the file is saved (and can be saved again).

A pad whose layout the browser does not know is never trusted: the page records which axes it used (`env.gamepad.axis_x/axis_y`).

### The file (`meridian.right-stick-capture/1`)

`person` (code, hand, thumb, rating, pad model as the browser names it), `env` (mode, user agent, screen, **frame rate at rest**, the gamepad's mapping and axes used), `protocol` (the parts, the estimated seconds), `trials` (per trial: block, prompt id, number, instructed speed, what is expected, the start and end marks `start_f`/`end_f` in frame time, the index ranges `i0..i1` into the sample list and `b0..b1` into the button list, `interrupted` if the tab was hidden or the pad lost, the "what did you do" label), `events` (visibility, pad connected or lost, repeats), and the data of the mode used:
- `samples`: `[t, f, x, y]` for **every animation frame**: `t` the pad's own timestamp (ms), `f` the frame time, `x`, `y` the right stick as the browser reports it (no dead zone, no quantising; **y down is positive**);
- `buttons`: `[t, f, index, pressed, value]` for every change (R3 and L3 are 11 and 10 on a standard layout);
- `touch`: `[t, f, dx, dy, phase, pointerId]` in dp from the first contact (phase 0 down, 1 move, 2 up, 3 cancel);
- `keys`: `[t, f, key, down, repeat]`.

Raw files go in `tools/capture/raw/` (git-ignored). They hold only an anonymous code and stick samples. The summary tables and the fitted thresholds are what is committed.

## The analysis: `node tools/capture/right-stick-analyse.mjs <folder or files...>`

Turns every trial into recognizer input (60 ticks a second, the last sample held, y flipped to up, each component quantised to 1/16 as the recognizer's own pipeline does; a finger's offset divided by `--pad-radius`, 60 dp), runs the recognizer, and prints:
1. who took part, against the spec's minimums (8 people, 3 skill bands, 4 pad models);
2. the **confusion matrix** per pattern and skill, and the recall;
3. the double flicks (flicks seen, the gap between them);
4. **direction accuracy** four-way (comfortable, fast) and eight-way, per rise time 2 to 5, with the angle error;
5. the **span and rise-time distributions** (p5/25/50/75/95, in ticks) to set the windows and the dial;
6. the **flick-versus-hold curve** for rise times 2 to 5;
7. **false patterns a minute** in free aim and at idle;
8. **R3 and L3 clicks per hard flick**, per pad, raw and with **the R3 guard** (a click is ignored while the stick is past 0.9 or within 6 ticks after it was; `--guard-mag`, `--guard-ticks`): the rate the guard would leave per 100 hard flicks is what the bar judges;
9. rest and idle drift; 10. the keyboard's key-down times; 11. a summary against the spec's **proposed bars**; 12. **thumb transfer** (below).

Options: `--rise N` (the rise the tables use, default 3), `--rises 2,3,4,5`, `--by rating|pad|mode`, `--export-traces <dir>` (each person's per-trial ticks with each trial's direction: `dir` clockwise or anticlockwise for a circle, `sector` for a flick; so a threshold can be re-fitted), `--json <file>`, `--include-interrupted`, `--no-quant`, `--guard-mag 0.9`, `--guard-ticks 6`.

**Engines.** `--engine python` (default) runs Controls' model, `docs/controls/right-stick-model.py`, through `tools/capture/right-stick-run.py` (it needs Python 3 on the PATH, or `--python <exe>`). `--engine godot --godot <exe> --godot-script res://<runner>.gd` will run the GDScript recognizer through a runner that speaks the same two small JSON files (the contract is at the top of the analyser and in the runner's docstring); that runner does not exist yet.

Judgements Controls should confirm: a vertical zig-zag counts as the model's "pump" (or zig-zag); "casual" is *new to sticks* and *regular* (bar 85%), "practised" is *fighting-game or shooter player* (bar 95%); the circle trials do not discriminate direction (the model has one label per size); the click bar is judged after the R3 guard (the raw figure is printed as information). **Controls confirmed these readings on 2026-10-23, and asked for the direction in the traces and the guarded click rate (both done).**

## Checks

`node tools/capture/right-stick-selftest.mjs` (76 checks): lints the page (one inline script, no network, no storage, no external URL, a request-forbidding policy, the privacy promises), runs the protocol builder without a browser and checks the spec's counts, and runs the analysis on synthetic captures (an ideal thumb at 60 and 144 Hz, a pad that clicks on hard flicks, a phone, a keyboard) through the Python model. It is not in CI (it needs Python and Node together; it runs in about five seconds).

## Thumb moves (Controls' no-claw law, docs/controls/right-thumb.md)

A pad-only part between the hard flicks and the idle: how long the one thumb takes to go between **the bottom face button** (A on Xbox, the cross on PlayStation, B on a Switch pad: index 0 of a standard layout) and the right stick, and back. Three sequences, each at a comfortable pace and then as fast as the person can without mistakes, four directions each, one trial per direction: **button, flick, button** (24 trials in all with the other two), **button then flick**, and **flick then button**. The page asks how the pad is held (`person.grip`: thumbs, claw, paddles, other).

Table 12 of the analysis, per pad, grip, pace and sequence, in ms: **b2s**, the button's release to the stick going on (rescaled 0.6); **s2b**, the stick back at rest (0.2) to the button's next press; for the three-step sequence also the whole **total** (first press to second press). It prints the count, the **median**, the **p90** and the share of **overlaps** (a negative time: the thumb, or another finger, was on both at once). Times come from the raw frames, not the ticks.

## The browser test: `node tools/capture/right-stick-browser-test.mjs`

Headless Chrome through the guarded launcher (`tools/machine/capture.mjs eval`, session tag `tools`, below normal, a time limit). A fake standard-layout pad is installed before the page loads; a driver in the page walks the intro, the details, the stick check, the rest calibration and two flicks (pressing the bottom button in one), then "Stop and save"; the saved file is read back (the download is intercepted, nothing is written) and 14 things are checked: the screens in order, the pad found, the file's name and format, the frame rate measured, the sample rows, the three trials with their marks and windows, the scripted flick in the samples, the button press recorded, empty touch and keys, and no request to anything outside. About 40 seconds. It is not in CI (it needs Chrome and the machine's quiet).
