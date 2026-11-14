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

## 6. Game Design's ruling checked (2026-11-01; `rule-of-cool-map.md` section 5)

Ruled: wind-up 10 to 7 with the commitment staying at 14, settle 1, the vanish on the second press, and **the blow lands at the later of the wind-up's end and the stick's return**.

- **The landing rule against the reader: confirmed.** `stick_feel_test.gd` (parked in `pending/stick-feel/`) sweeps a flick held 0 to 20 ticks past its ramp, quickRead on: the request is held (`rsHeld`) from the start to the return; the level at the return is 0 for a stick out less than the dwell (12 live ticks) and 1 or more from there; a return at or before start + 6 comes before a 7-tick wind-up ends, so the blow lands at the wind-up's end; a stick still out at start + 7 is still held at level 0, so the director has something to wait on, and it is a charge at the dwell with the ladder at 12 / 30 / 50 unchanged (beams 54). A release keeps the level it had. So the rule needs nothing from the reader: **the dwell stays 12 and must not move with the wind-up**.
- **A trap for the hook.** Encounter's hook today reads the wind-up as `strike.dwell` less `strike.settle` (10 now). With settle 1 and the dwell at 12 that derivation gives 11, not 7, and moving the dwell to 8 would turn every stick held 8 ticks into a charge. GD's note says `data/director/stick.json` holds the 7; the hook needs its own `windTicks` key (or a constant 7), not the derivation. Measured on the stack tree (wind-up 10, derived): start at +2 with the quick read, the blow at +14 (start + 12); at 7 it would be start + 9.
- **The claw model at the ruled numbers: zero.** `right-hand-attacks-model.mjs` with the 4a commitment at 14 and settle 1 (and at 11 and 15 for the sensitivity): every claw check holds with the law on (+0 on every link; off, the only gain is X then a stick command, +3); the D-pad and key forms act on the stick form's tick (1, 1, 1). The strike throughput in the model's X mix rises with the law on (55 / 55 / 53 / 43 blows per 600 ticks for claw / fast / median / slow thumbs at commitment 14 and settle 1, from 50 / 50 / 47 / 39 at 16 and settle 2); that is a balance number for QA's stick-only bot (GD's own warning), not a claw one.
- **The vanish on the second press** and **settle 1** are the quick read (`switches.quickRead`), built and tested (`quick_read_test.gd`, 30 checks); the D-pad and strike-button forms move with settle 1 (`quick_read_test` and the gate's mirror rows pass).
- **Haptics for pitches 1 and 3** are built behind two more switches, parked: `pending/stick-feel/` (`haptics.md` has the table).
- **Energy section 21 (E120 to E138), what moves for the pad** (parked in `pending/stick-feel/`): E120 beams on the stick need nothing new: RB + the stick (and its D-pad mirror, key and left-handed forms) is already the energy-layer strike, on the beam ladder 12 / 30 / 54; no button becomes a beam. E131: while B is held in the energy layer the stick is inert (a push is ignored until it rests), and the release of that hold counts as a face event (a request waits R from it); the stick first already strips B. E129 Loaded on a beam held at level 3 works: nothing throws a held stick by a timer (the director's beam path has no auto-go). E133 pumping the stick along its aim is later. The claw model's new section 7 covers these rows: a Driver banked on B with the stick drawing a beam gives a claw +2 to +6 beams naive and +0 with the law; B released then the stick starts at +8 for the claw and for the fast thumb, +2 naive.

## 7. Press to result, input by input, on the real path (2026-11-01; the s400 stack with every park, measured by `latency_probe.gd`, `stick_hit_probe.gd`, `kick_wire_probe.gd`)

Ticks from the finger or thumb to the sim's first answer, then to the result. **Online add the input delay: 2 ticks by default (33 ms), chosen between 2 and 8 by the link** (`docs/net/rollback.md` section 9); every row below moves by that much, and nothing here changes with it except that one saved tick is a bigger share of a short wait.

| Input | First sim answer | The result | With the quick read | With settle 0 |
| :--- | ---: | :--- | :--- | :--- |
| X, Y, B tap (close, 80 units) | 0 | a blow lands at 3, 13, 29 (250 units: 14, 18, 32) | same | same |
| Dodge (LT), guard (LB) | 0 | the dodge starts, the guard is up | same | same |
| **Kick takeoff** (LT held, stick pushed, kick switch on) | 0 | speed 5013 on tick 1 (91% of the peak 5491), peak at tick 9; off, 702 on tick 1 and the peak at tick 12 | the pad is wired: `dash` is written on the dodge press and the kick starts on that tick | same |
| **Stick quick strike**, ramp-2 flick, close | 3 (shipped) | the blow lands at **12** (150 units: 14; 250: 27) | answer 2, lands **11** | answer 1, lands **10** |
| Stick charge | 3 | rungs at 12, 30, 50 after the start | rungs one tick sooner | two |
| Brace (LB + flick, or L3) | 2 or 3 | the intent says brace; **the sim does nothing with it** | 1 or 2 | 0 or 1 |
| Vanish (LB + LT) | 6 | the dodge only | **2** | **0** when the stick is already out at the second press |
| D-pad, keyboard arrows (strike mirrors) | the stick's tick | as the stick | as the stick | as the stick |

**The landing rule works in the real hook** (the s400 stack, wind-up 7): a flick held 0 to 6 ticks lands at 10; held 8 ticks it lands at 12, at the stick's return; held 14 it is a charge.

**Wires cut (built behind the quick read, parked):**
1. **The reader's extra build.** A push past `on` started a request on the *next* build, so even `settle` 0 cost a tick. With `strike.settleQuick` 0 the direction is taken on the crossing tick itself. 1 tick on every strike. Direction accuracy on synthetic thumbs: 100% at the shipped `on` 0.60 (99.0 to 99.6% at 0.50 on the harshest thumb); the claw model passes at settle 0 (law on: +0); the mirrors, the swapped stream and the law's rules (a face press before or on the crossing tick wins and the strike waits R) hold (`stick_feel_test`, 101 checks). GD's ruling is settle 1; settle 0 is one data number Orb can try.
2. **The vanish waited its settle even with a direction already held.** With the stick out at the second press the read is known: it now resolves on that tick (2 ticks saved); with no stick it still waits the settle for a flick.

**Wires I did not cut:** the law's R and L (zero claw); the pose's pre-read (already built); the host's frame wait (Performance's).

**Cost a tick in Encounter's code, for the EP to route:** at 250 units the stick strike's sim answer is at 11 to 13 and it lands at 25 to 27, against 5 and 14 for X, because the hook asks for the *heavy* lunge (10 ticks of wind-up crouch) for a blow that is a medium. Asking for the light lunge (6) would save about 4 ticks at range.

**Which are final** (the question the EP asked): the quick read (settle 1, the vanish on the second press, the pre-read, the code defaults) and the stick-feel park are final as built and gated; `responsive-2.patch` (settle 0 and the immediate vanish) is optional and off by default (`settleQuick` stays 1).

## 8. The stick's input buffer, and the 36 (2026-11-01; `stick_swallow_probe.gd`, `input-buffer.patch`)

The stand-in asked for a buffer for the stick (a flick in the last ~9 ticks before the fighter can act, newest only, behind a switch, the law unchanged; a refusal knock only if it expires) and for a defended number for the face-press queue's 36 ticks.

**Is there a buffer? Yes, in the director, and it does not work.** `DirStick` leaves a note for 90 ticks (`pendTicks`) when it takes a request, but the note is only used by the next *medium* blow it throws. Measured in real fights (a bot flicking toward the rival every 25 ticks, the AI fighting back, 6 seeds x 3,000 ticks): of **795 requests, 428 started a strike within 12 ticks, 2 more within 90, and 365 (46%) never did**. There are no late starts: a request either starts at once or is lost. By what the fighter was doing when he asked: launched or down, 100% lost (85 requests); in an exchange (`locked`), 237 of 656 lost; free of any exchange, 43 of 54 lost (probably the far band, where a tap is a taunt: GD's row 42). Of the 365 lost, **109 became some other blow of his own** (a press taken as a brawl blow) and 256 vanished.

**What a buffer at the input layer can buy.** Of the lost requests, the fighter was free of any exchange within 9 ticks in 44 (12% of the lost, 5.5% of all requests), within 18 in 56, within 36 in 77 (21%); for 199 it was later than 36 ticks and for 89 never. So the best a 9-tick wait can rescue is about 1 request in 18; a 36-tick wait about 1 in 10.

**Built:** `strike.bufferTicks` (0 = off, 9 is the smallest version). The reader holds a request that finds the fighter unable to act (the host's `hub.set_can_act(slot, on)`, each tick, next to `set_struggle`) for that many ticks from the moment it could have started; the newest flick replaces an older one waiting; if the fighter can act in time it starts that tick (a quick strike if the stick is already back); if not it is dropped and the pad is knocked once (the `stick_refused` kind, `hapticRefused`). The law is unchanged: a face press while the request waits goes out and holds the strike R from it. Tested (`stick_feel_test`, 130 checks): off and on, the window's edge, an expiry and the flick after it, newest only, the law, the knock, the swapped stream.

**It changes nothing in the real-fight soak** (a stand-in `can_act` of "not launched, down or in an intro", the states the host can see): strikes started 430, 430, 430 and 430 with the buffer at 0, 9, 18 and 36. The reason is above: the requests that die in a launched or down state wait longer than 36 ticks, and the rest die inside the director's own refusal, where the fighter is "able" by any state the host can read. **So a longer or smarter wait in the input layer does not find them. The fix is in `DirStick`:** honour the 90-tick note on the fighter's first free tick inside 9 ticks (it would rescue the 44), and tell the pad the moment a request is dropped (`stick_refused`, built, waiting for Encounter's cue). I would not ship the input-layer buffer on for Orb to play: it would feel identical. It is off, tested and parked in case Encounter's reading of `can_act` gives it something to wait for.

**The 36.** `strike.queueTicks` is how long a face press made while the stick is out may wait to go out when the stick is quiet. A press made at the start of a quick flick waits the flick's length plus L: the stick may be out up to `dwell` (12) after its start (settle 1 or 2), then L = 6: **about 19 ticks at the worst**. A press older than that was made during a deliberate charge (a stick held past the dwell), and the player chose the charge: it should die, not go out half a second later after the charge is thrown, which is what the friend's note ("queuing up moves instead of seeing them execute") describes. **I would defend 20** (a third of a second): long enough that no press made during a quick flick is ever lost, short enough that nothing made during a charge fires after it. 36 is the value that keeps a press made in the first half of a charge. Not changed: the shipped value stays 36 until you say; it is one number, `strike.queueTicks`. For comparison block and dodge buffer 4 ticks; the queue's depth (3) is unaffected.

## 9. `strike.queueTicks` 20 (2026-11-01; parked as `pending/queue-20/queue-20.patch`, shipped value still 36)

The EP set the number at 20 on the reasoning in section 8 and asked for it as its own small change that can go back. `queue-20.patch` changes `data/input/timing.json` `strike.queueTicks` 36 to 20 and adds three rows to the law's gate (`strike_gate_test`, row K, 268 checks): a press exactly `queueTicks` old when the stick goes quiet goes out; one tick older has expired; a press made at the start of a quick flick (stick out 11 ticks) is never lost. All 26 input tests pass with it. To put it back: `git apply -R` the patch, or set the number to 36. The docs that still say 36 (`input-scheme.md`, `right-hand-attacks.md` K3, `claw-bot-gate.md`, `phone-feasibility.md`) are history or describe the face queue before this change; they change when the patch lands.

**Section 8, split by what the fighter was doing (re-run 2026-11-01, after Encounter could not reproduce the 237).** The 365 requests of the soak that never became a stick strike (of 795): **109 were thrown as some other blow of his own** within 30 ticks (94 as the attacker in an exchange, 15 free or defending), so a press taken by a brawl is not lost, only not the stick's strike; **131 were made when he could not act at all**: launched or down (85) or being attacked in an exchange (47): nothing to answer with; **125 are unexplained**: 92 as the attacker in an exchange with no blow of his own within 30 ticks, 33 free of any exchange (probably the far band's taunt). My earlier "237 in an exchange" counted the first two groups with the third; Encounter's 384 of 391 thrown are the attacker's presses that became blows, which agrees with the 94 + the strikes that started. **The share a player would actually lose, on this bot: about 16% of presses (125 of 795), when he is attacking or free, and about 17% more when he cannot act at all.** The 92 attacker-side presses are what Encounter's count does not show; they may be thrown later than 30 ticks, or named differently. To be re-run on Encounter's park (`stick_refused`, the 9-tick wait, the light lunge) when it is in the tree: `stick_swallow_probe.gd`, same seeds. Not in the tree yet (its README of 31 October has none of the three).
