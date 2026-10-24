# Real-thumb capture for the right stick: the tool spec (one page, paper)

Controls, 2026-10-23, for GD's R20 (a real-thumb capture comes before any pattern ships). Companion to `right-stick.md`, whose thresholds and windows are **modelled from synthetic thumbs**; this replaces the model with people. Not built. The EP briefs QA or Research to run it, and Tools to build the page (it lives under `tools/`).

## What it is

**One self-contained HTML page** (no libraries, no network, no server), opened in an ordinary desktop browser by a person with a pad in hand. It uses the browser's Gamepad API, so it works with any pad Chrome sees (Xbox, DualSense, Switch Pro, Steam Deck, a cheap third-party pad). It shows one prompt at a time, records the raw stick, and at the end **downloads one JSON file**. It never uploads anything. (A human-run page in a normal browser: not headless Chrome, so the capture-launcher rule does not apply.)

## What it records

- **Raw samples:** for every animation frame, `t` (the pad's own timestamp in ms), the right stick `(x, y)` as the browser reports it (no dead zone, no quantisation), and the frame interval. A second pass at the page's best polling rate is not possible in a browser, so the file also records the frame rate, because a 144 Hz screen sees more of a fast flick than a 60 Hz one.
- **Buttons:** every button state change with `t` (R3 and L3 matter: a hard flick can click the stick).
- **Per trial:** the prompt id, the trial number, the instructed speed ("comfortable" or "as fast as comfortable"), a start and end mark.
- **Per person (anonymous):** a code the person types or is given, the pad model as the browser names it, hand (right, left), a self-rating (new to sticks, regular, fighting-game or shooter player), and "which thumb is on the right stick". No name, no email.
- **Touch and keyboard variants:** the same prompts with pointer events (the finger path from first contact, in dp from the contact point) for a phone's gesture pad, and arrow-key timings for the keyboard.

## The protocol (about 9 minutes per person)

Rest calibration (2 s, hands on the pad), then, in this order, each prompted on screen with a 1-second countdown and a "done" tone:

| Block | Trials | What it measures |
| :--- | :--- | :--- |
| Flicks, **four-way** | 6 per direction, comfortable; 3 per direction fast | onset speed, direction error, recentring overshoot |
| Flicks, **eight-way** | 3 per direction | the eight-way accuracy and what a diagonal turns into |
| Holds | 3 per direction, 1.5 s, then release | flick-versus-hold onset; drift at rest after release |
| **Double flick** (pump) | 6, four directions | cadence and the overshoot between |
| Zig-zag | 8 (horizontal, vertical), three strokes and four strokes | stroke length, speed, completion |
| Quarter, half, full circle | 6 each, clockwise and anticlockwise | angle swept, duration, radius |
| **Free aim** | two 20-second sweeps, "aim around as if tracking a target" | **the false-pattern rate**, with no pattern intended |
| **Hard flicks** | 10 as hard as possible | R3 and L3 clicks |
| Idle | 10 s hands on the pad | drift and noise |
| "Do it as you would in a fight" | 5 free trials of any pattern | whether people use them the way the model assumes |

Anyone may stop at any time. Each block can be repeated.

## The analysis (scripts, to be built with the page)

A Node script reads the folder of files and, once the recognizer exists in GDScript, runs **that** recognizer (until then, the Python model `right-stick-model.py`), printing: the confusion matrix per pattern and skill, direction accuracy four-way and eight-way, the span distributions (to set the windows), the flick-versus-hold curve for rise times 2 to 5 (to set the dial), false patterns per minute in free aim and at idle, and R3 or L3 clicks per hard flick. It also exports the per-person traces so a threshold can be re-fitted.

## When a pattern may ship (proposed acceptance)

| Measure | Bar |
| :--- | :--- |
| Four-way flick recall and direction | 95% or better, casual included, at the chosen rise |
| Hold read as a hold | 98% or better; a hold also read as a flick is acceptable by design (R4) |
| A pattern | 85% or better recall for casual thumbs on the **loose** preset, 95% for practised, and a wrong match is a harmless command |
| False patterns in free aim | none (patterns are off in Aim), and at most 1 a minute if a family leaves them on |
| False patterns at idle | zero |
| Stick clicks during hard flicks | the R3 guard keeps accidental Escapes under 1 in 100 hard flicks |

## Who, how many, where the files go

- **At least 8 people across three skill bands, and at least 4 pad models** (an Xbox pad, a DualSense, a Switch Pro or Steam Deck, one cheap pad). Orb may be one. A phone run needs 3 people on 2 phones.
- The raw files hold only anonymous codes and stick samples, but they are **kept out of the repository** (a scratch folder or a git-ignored one); the summary tables and the fitted thresholds are what is committed.
- **Owner:** Tools builds the page and the script; QA or Research runs the sessions; Controls reads the results and fixes the thresholds, the windows and the schema.
