# Responsiveness: where the ticks go between a thumb and the screen (Controls, 2026-11-01)

The EP's order of 2026-11-01 (Orb: "as playable, responsive and fun as possible"): know how long a press takes to reach the screen and shorten it. One tick is 1/60 s (16.7 ms). Everything below is **native and headless** unless it says web; the probes are `sim/input/tools/latency_probe.gd` (the input stages, synthetic thumbs) and `sim/input/tools/stick_hit_probe.gd` (the thumb to the hit through the real sim, needs Encounter's stick hook in the tree). The tree for the second was the EP's stack (`node tools/preview/stack.mjs --no-godot --keep-tree`, parks applied, `rightStick` on) with Controls' working-tree code laid over it.

**Short answer.** A face-button tap is already as fast as the sim can be: it reacts on the press tick and the blow lands 3 ticks (50 ms) later at close range. The stick strike is not: from the thumb moving to the blow landing is **15 to 16 ticks (250 to 270 ms)** at close range, against 3 for a tap. Of that, **3 to 4 ticks are the input read** (mine) and **12 are the director's wind-up** (Encounter's `windTicks` 10 plus a 2-tick contact lead; Game Design's number). The quick read below takes **1 tick off the read and puts the pose 2 to 3 ticks before the request starts**; the rest is the wind-up, which is a design number, and a pose hides it.

## 1. What was measured

### 1.1 Face-button taps (native, the real hub into SimCore, idle dummy; press tick = 0)

| Press | Distance | Sim reacts | press_ack | First event the animator starts a pose from | Body moves | Blow lands on him |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Light (X, J) | 80 / 150 / 250 u | 0 / 0 / 0 | 0 | tick 0 (`brawl_start`, `rush` at 250) | 0 / 0 / 6 | **3 / 5 / 14** |
| Heavy (Y, K) | 80 / 150 / 250 u | 0 / 0 / 0 | 0 | tick 0 | 0 / 0 / 10 | 13 / 15 / 18 |
| Signature (B, L) | 80 / 150 / 250 u | 0 / 0 / 0 | 0 | tick 0 | 0 / 0 / 10 | 29 / 31 / 32 |
| Dodge (Space, LT), Guard (Shift, LB) | any | **0** | | | | |

Keyboard and pad are identical, tick for tick. This is T1 (`t1_latency_test.gd`, 62 checks) restated with the body and the hit added. Performance's old 5-tick light start (`docs/perf/input-latency-2026-10-22.md`) is gone since Encounter's press-tick; at 250 units the body waits for the lunge's wind-up (6 ticks light, 10 heavy and signature), which Animation draws as a crouch.

### 1.2 The strike stick, input stages (synthetic thumbs, switch on; ticks from the first tick the thumb moves)

The reader (`strike_read.gd`): dead zone 0.25, rescaled and quantised in 1/16; a request is a push past `on` 0.60 of that; it **starts `settle` ticks after the crossing, and no sooner than the build after it**; the direction is taken then; a stick back at rest before `dwell` 12 live ticks is the quick strike.

| Thumb: ramp to full in R ticks | crossing | **start (settle 2, as shipped)** | start (settle 1, quick) | throw (stick back) |
| :--- | :--- | :--- | :--- | :--- |
| 1 (a snap) | 0 | 2 | 1 | 5 |
| 2 | 1 | 3 | 2 | 6 |
| 3 | 2 | 4 | 3 | 7 |
| 4 | 2 | 4 | 3 | 8 |
| 6 | 4 | 6 | 5 | 10 |
| 8 (a slow push) | 5 | 7 | 6 | 12 |

The thumb's own speed is most of it: a snap starts at 2 and a slow push at 7. The reader adds the settle (2, or 1 quick) on top of the crossing.

### 1.3 The thumb to the hit, through the real sim (the stack tree: Encounter's stick hook on; ticks from the first tick the thumb or finger moves)

| Distance | Face tap (X) | Stick flick, ramp 2: start / **hits him** | Same, quick read | Stick flick, ramp 4: start / hits | Same, quick |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 80 u | 0 / **3** | 3 / **15** | 2 / **14** | 4 / 16 | 3 / 15 |
| 150 u | 0 / 5 | 3 / 17 | 2 / 16 | 4 / 18 | 3 / 17 |
| 250 u | 5 / 14 | 3 / 30 | 2 / 29 | 4 / 31 | 3 / 30 |

- The sim reacts **on the start tick** (the hook turns the request into a heavy press): no ticks lost between the second word and the director.
- The blow lands **12 ticks after the start** whatever the flick: 10 ticks of the hook's wind-up (`data/director/stick.json` `windTicks`) plus 2. A stick held (a charge) lands on the release.
- At 250 units the stick's body also waits for the heavy lunge's 10 ticks (the sim reacts at 13 to 14), as a heavy does.
- A flick up is the same as toward him.

### 1.4 The left hand

| Read | As shipped | Quick |
| :--- | :--- | :--- |
| Brace, flick from rest with LB (ramp 1 / 2 to 3) | edge at +2 / +3 | +1 / +2 |
| Brace button (L3), stick already held | +2 | +1 |
| **Vanish**, LB and LT together (gap 0 to 4) | **+6 from the first press** | **+2 (from the second)** |
| Vanish, LT 3 ticks after LB | +6 | +5 |
| Vanish, LT 6 ticks after LB | +8 | +8 |

The vanish waits for its 6-tick window to close, then for the second press + 2, whichever is later. That wait only gathers the stick's direction (the flick often begins as the second press lands), but a simultaneous press has its direction already at the second press + 2. The dodge itself starts on the press tick either way; the vanish is an upgrade of it, so the cost is the upgrade arriving 4 ticks late.

### 1.5 The no-claw law's cost

A face press and then the stick: the strike's start is held to R = 8 ticks after the face press (L = 6 the other way). Motion at -2 relative to the press (the thumb moves 2 ticks *before* the press): start at motion +10 instead of +3. Motion at +4 after the press: +4. At +6 or later: no cost. This is the law doing its job (it is what makes a claw grip gain nothing); it is the only deliberate delay in the input path and it is **not** a candidate for shortening: it applies only to a face press within 8 ticks of a stick request, and zero claw advantage is the standing rule.

### 1.6 Not measured here

- **The web page and the display.** Performance measured the keyboard path on the web build (`docs/perf/input-latency-2026-10-22.md`): the browser's share is half a frame (7 ms at 60 Hz), the draw adds at most one frame (17 ms), the display one more (about 17 ms), and a heavy or signature's body shows in the first frame (26 to 31 ms). I did not rerun it for the stick: the bench sends keys, not a gamepad, and the stick path needs the stack build with the hook. Run `docs/perf/tools/latency-bench.mjs` on a stack build with a scripted pad (`render-web-test-recipe`) if the web number for the stick is wanted; the native tick counts above are what it would add frames to.
- **Real thumbs.** The thumb model is synthetic (a linear ramp, an aim error, a rest offset). No stick capture exists yet (`right-stick-capture.md`). The direction-accuracy table (1.7) is only as good as that model.
- **Pose changes natively.** The animator is render-side and not run headless; "body moves" is the fighter's position, and "first event the animator starts a pose from" is the first fx event of the presser. The pose itself starts on those.

### 1.7 Direction accuracy by the settle (synthetic thumbs, 4000 flicks per cell, on = 0.60)

| Thumb | settle 0 / 1 | settle 2 | settle 3 |
| :--- | :--- | :--- | :--- |
| Aim within 35 degrees, rest offset up to 50 | 100.0% | 100.0% | 100.0% |
| Aim within 40, offset up to 90 | 100.0% | 100.0% | 100.0% |
| Aim within 45 (the edge of the quadrant), offset up to 120 | 100.0% | 100.0% | 100.0% |

At `on` = 0.50 the harshest thumb reads 99.0% at settle 0 or 1 and 100% at 2. So **one tick off the settle costs no measurable direction accuracy at the shipped `on`**, because the reader already waits for a build after the crossing and the rescaled 0.60 is raw 0.70, well into the push. A settle of 0 gives the same start as 1 (the build after the crossing) and is not worth having.

## 2. Where the ticks go (stick quick strike, close range, a ramp-2 flick)

| Stage | Ticks | Whose | Can it shrink |
| :--- | :--- | :--- | :--- |
| The thumb to the crossing | 1 | the thumb | no |
| The settle (the build after the crossing, plus `settle`) | 2 (1 quick) | Controls, `strike.settle` | **yes: 1 saved, built** |
| The director's wind-up | 10 | Encounter / Game Design, `windTicks` | a design number; see 3.1 |
| The contact lead | 2 | the brawl | no change proposed |
| The sim to the first frame | 0 to 1 | Rendering (the interpolation) | no |
| The browser and the display | 0.4 and 1 | the browser, the display | no |
| **The pose, if it waited for the start** | start + 1 | Animation | **yes: pre-read, built** |

## 3. Fixes, ranked by ticks saved

| # | Fix | Ticks | Where | State |
| :--- | :--- | :--- | :--- | :--- |
| 1 | **Shorten the quick strike's wind-up** (`windTicks` 10 to 6 or 7, with the pose carrying the first frames) | 3 to 4 | Encounter's `data/director/stick.json`, Game Design's ruling | proposed, not mine. Combine with the pre-read so the wind-up is a drawn crouch from the first moved tick |
| 2 | **Pre-read for the pose** (`SimLayout.strike_pre()`, `SimHub.strike_pre(slot)`): the stick leaning in past `preAt` 0.25 (rescaled; raw 0.44) is published as `{dir, depth}` while the request has not started; the animator starts the anticipation on it | the pose is **2 to 3 ticks earlier than the start** (a ramp-3 flick: pre at +1, start at +3, hit at +15) | Controls publishes; Animation / Rendering draws | **built, behind `switches.quickRead`**; render-side only, never in the intent, never in the hash, so it is rollback-safe by construction. The animator side is not written |
| 3 | **Settle 1** (`strike.settleQuick`) for the strike and the brace | 1 on every strike and every brace | Controls | **built, behind `switches.quickRead`**. Direction accuracy unchanged (1.7); the no-claw law unchanged (the model gives zero claw gain with settle 1, `right-hand-attacks-model.mjs`) |
| 4 | **Vanish on the second press** (no wait for the window to close) | 4 for a simultaneous press, 1 at a gap of 3, 0 at a gap of 6 | Controls | **built, behind `switches.quickRead`** |
| 5 | **Peak-hold sampling**: the layout is built once a tick from the stick's latest value; a flick that goes out and back inside one host frame is read as nothing. Reading the largest deflection since the last build would keep it | 0 ticks, but turns a missed snap into a quick strike (the fastest thumbs lose a strike today) | Controls + the host (main.gd would collect the peak between ticks) | **not built**: needs the host to pass the peak; pitch it, measure with a real capture first |
| 6 | **Velocity direction**: take the direction from the stick's first two samples (the vector's trend) at the crossing instead of the settle | would allow settle 0 without the accuracy risk; 0 more ticks than 3 | Controls | not worth it: settle 1 is already as good (1.7) |
| 7 | **The dwell** (12 ticks to tell a quick strike from a charge): none of it is wait; the quick strike lands at start + 12 regardless | 0 | | nothing to fix |

What I did **not** propose: shortening the law's R and L (they are the zero-claw rule), speculative sim starts from the pre-read (a sim start that may be wrong needs a rollback; a pose that may be wrong costs only a frame), and a tick rate change.

## 4. What is built

Everything is behind **`data/input/timing.json` `switches.quickRead` (false)** and needs `rightStick`; with either off every number above is the shipped one.

- Code (in the tree, inert while the key is absent): `SimInputData.quick_on()`; `SimStrikeRead` (`settleQuick`, `pre_dir`, `pre_depth`, follows a rising stick only, none on an inert layer); `SimLeftHand` (`early`: settle for the brace, the vanish on the second press); `SimLayout.strike_pre()`; `SimInputHub.strike_pre(slot)`.
- Test: `sim/input/test/quick_read_test.gd` (30 checks): the shipped numbers with the switch off; each read one tick sooner with it on, the same directions; the vanish at 2 / 5 / 8; a stick leaning up before the presses is sent up; LT 9 ticks after LB is no vanish; LB let go is no vanish; the pre-read comes at least 2 ticks before the start, in the right direction, goes at the start, none at rest or on an inert layer, and asking for it changes no intent (`pack` and `pack2` equal); the no-claw law (R, the face press before the strike wins, the faces inert while it is out, L); the swapped layout makes the same stream; nothing with the right-hand switch off.
- **Parked** (`docs/controls/pending/quick-read/`): `quick-read.patch`, `timing.json` (`switches.quickRead`, `strike.settleQuick`, `strike.preAt`) with the `input-timing` schema (Tools'), made together because the closed schema fails `validate` on a data key it does not know. The code defaults every key (switch off, settle 1, preAt 0.25), so the code in the tree is inert and valid without the patch. Apply it with the hook's park; then add `quickRead` to `tools/preview/switches.mjs` if the preview should turn it on (it is the ninth switch).
- **Needs from others**: Animation draws the anticipation from `hub.strike_pre(slot)` (the host passes it as it passes the stick); Encounter / GD consider `windTicks` (3.1); Rendering carries nothing.

## 5. Re-running

```
godot --headless --path . --script res://sim/input/tools/latency_probe.gd          # the input stages, quickRead off and on
godot --headless --path . --script res://sim/input/tools/stick_hit_probe.gd        # thumb to hit; needs Encounter's stick hook in the tree
godot --headless --path . --script res://sim/input/test/quick_read_test.gd         # the checks
```

Use a scratch export of the tree (never the repository root with a stale import). The hit probe needs the stack tree (`node tools/preview/stack.mjs --no-godot --keep-tree --out <scratch>`).
