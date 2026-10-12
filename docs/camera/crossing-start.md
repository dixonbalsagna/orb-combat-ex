# The opening at a crossing: the first two seconds (Camera, 2026-10-12)

Owner: Camera and Cinematography. Asked by the EP, from Rendering's still `docs/rendering/img/lanes/crossing-start.png` (the game's own start at a crossing, depth off): "the pair stands at the two edges, two thirds of the width apart, and the middle of the picture is an empty crossing." Reads: `city-in-depth.md` D4 (a crossing: one view, the pair's midpoint within 0.12 of the width of the centre, the camera inside the avenue), `rule-of-cool-shots.md` row 7 (the intro's shots), `sim/core/intro.gd` and `data/fight/intro.json`.

## 1. What the first two seconds are today (measured, `setup.start == "crossing"`, intro off, seed 3, 1,280 x 720)

| Tick (s) | What happens | Camera |
| :--- | :--- | :--- |
| 0 (0.00) | Pair 896 units apart (12 bh), standing astride the crossing's centre; on their craters | One view; camera x = the crossing's centre exactly (midpoint 0.000 of the width from the middle); zoom 0.949; fighters at 215 and 1,065 px (0.168 and 0.832 of the width), 9.9% of the height; chests at 0.70 of the height |
| 0 to 36 (0.0 to 0.6) | **The AI rushes at once.** The gap closes: 815 u at tick 6, 525 at 18, 232 at 30, 77 at 36 (25 units a tick at the end) | The zoom follows the pair in: 0.949, 1.00 at tick 12, 1.08 at 24, 1.117 at 36 (+18%, 0.002 of travel a tick). No cut; the camera is on the avenue's axis, so the fighters meet at the centre of the picture with the avenue's mouth and the sky behind them |
| 36 to 84 (0.6 to 1.4) | They collide and pass (tick 42), trade, lock (tick 84) | The camera follows the midpoint with its 0.15 s filter. A cut flag at tick 48 is the orientation flip (the pair swapped sides) in one view: no dip, no change in the picture |
| 84 to 132 (1.4 to 2.2) | The brawl leaves the crossing: the midpoint is 1,030 units east of it at tick 84; the pair separates to 1,480 units at tick 132 | The avenue is at the left edge of the frame by tick 72 and out of it by tick 84 (1.4 s); the pair is the picture. The split opens at tick 132 and is two panes at tick 150 (2.5 s) |

So the empty crossing the still shows is there for about **0.6 s**, and the avenue stays behind the pair for about **1.4 s**: the visitor's first image is a poster that is already moving when it is first seen, and by the time it has been read the fight is somewhere else.

## 2. The decision

Nothing is wrong with the framing as a frame. It is symmetrical, the camera is in the avenue, the sky wedge is between the towers, the fighters are the right size and in one view (D4's four conditions all hold: midpoint 0.000, one view, the lead and the anchor's offset are zero, the focus is the pair's). **What is wrong is the time**: the picture is gone before it can be read, and the sim sends the fighters at each other on tick 0, so the poster is a 0.6 s flash.

So the design is a **beat**, not a different camera:

1. **A look of 1.0 to 1.5 s (72 ticks proposed) before the clock.** Both fighters already standing on their craters, the pair as in the first frame; the HUD hidden (row 7: the HUD is hidden by UI until the clock), so the first picture a visitor sees is the world and two figures. The camera: the two-shot at the fit (today's), no cut at all, a push of 10% over the look, eased (existing, `INTRO_STARE_PUSH`). The avenue is the picture: the towers at both sides, the sunset wedge between them, the crossing's mouth, the crowd on the far sidewalk.
2. **The clock** (`clock_start`, the bell: a 3.9% punch, existing). No cut: the look ends on the same frame the fight begins on.
3. **The rush** (0.6 s): the pair closes on the avenue's axis and meets at the centre of the picture with the sunset wedge behind. The camera's job is only to be where it is: on the axis, the zoom following, no cut, no travel but the zoom (0.002 a tick).
4. **The brawl leaves the crossing** and the camera follows it, as it does anywhere.

Total: the avenue is behind the pair for 1.2 s of look and 0.6 s of rush, **1.8 s in all against 0.6 s today**, with nothing to be read but the picture for the first 1.2 s.

What I considered and did not take:

| Option | Why not |
| :--- | :--- |
| A tighter fit (margin 0.20, the pair 0.60 of the width) so they are less at the edges | The fighters are 8.7% of the height instead of 9.9%, under the 10% the brawl keeps; and with the HUD off in the look there is nothing at the edges to clear |
| A wide establishing shot that pushes in (zoom 0.6 to 0.95) | A push of 58% in 1.2 s is `0.5 |d ln z|` = 0.0053 a tick, inside the bound, but the scenery is the full-frame towers at every contrast: a quarter of the edges moving by 100+ px a second is what the flash rules count. The 10% push moves them 6% |
| A pitched or low camera at the first frame | The avenue is composed side-on; a pitch is the depth work's (49 degrees at the grid's look), and the first frame must match the brawl's |
| Holding the avenue in the frame while the brawl leaves it | The camera cannot: the fight is not there. Where the fight goes is the sim's and Encounter's (the tug between the care terms) |
| Face cuts (A's face, B's face) in the look | Three cuts in 1.2 s: three flashes in a second against a gate of 2.5. They stay in the classic 5 s intro (2 s staredown or more) |

## 3. What I built (and what it costs)

- **No face cuts in a staredown shorter than 2 s** (`CamParams.INTRO_FACES_MIN` = 120 ticks, `SplitRig._update_intro`). The classic intro's staredown (156 ticks) keeps them: its cut ticks are still [0, 36, 84, 114, 144, 239, 263, 287]. A 72-tick look has one cut frame, the first.
- **Two rows in `split_sweep`**, `crossing start` (the clock opens the match) and `crossing start staredown 72` (the look then the clock, injected `intro_start`, `staredown_start`, `clock_start`; the sim held for the look): one view in the first 100 ticks, no brightness dip, both fighters inside the screen with at least 0.10 of the width through the look and the rush, 0.075 of the height tall, the camera inside the avenue while the gap closes (half a body of pad), no cut inside the look, the push lands at 10% +/- 3.

Measured: `crossing start` edge margin 0.168 of the width, smallest 0.099 of the height, 0 dips, 0 of 20 closing ticks off the avenue; `crossing start staredown 72` 0.123, 0.099, 0, 0 of 20; travel at most 0.0169 a tick (the push and the bell).

## 4. What I need

| From | What |
| :--- | :--- |
| **Simulation / Narrative** (`data/fight/intro.json`, `sim/director/intro.gd`) | A template whose only beat is the staredown: both fighters standing on their craters at tick 0 (as `"intro": "skip"` leaves them), `intro_start {dur: 1.2}`, `staredown_start {dur: 1.2}`, `clock_start {kind: "full"}` at tick 72. Every template today starts with the falls and runs 5 to 7.6 s; none fits a demo. Skippable by a press, as the others (`skipFrom`). The camera needs nothing else |
| **Simulation** (the web demo's setup) | The demo's setup uses that template with `"start": "crossing"` |
| **UI** | Nothing new: the HUD stays off until `clock_start` (row 7). The still shows the control hints and a toast over the first frame; with the look they are not there for its first 1.2 s |
| **Rendering** | A still of the first frame with the HUD off, the one the page would use |
| **Encounter** | Not asked. How long the brawl stays astride the crossing is the care terms' and the planner's; I have no lever on it |

If the template does not come, the camera is as it is today and the first frame is the poster for 0.6 s. A cheaper variant in the sim, if a template is more than is wanted: a 72-tick hold of the AI's first intents at the start of a `"start": "crossing"` match (the clock running, the fighters not moving), which gives the picture without the intro machinery and without the HUD change.

## 5. Reduced motion and a human first

- **Reduced motion:** no push (row 7's rule), no bell, no face cuts (there are none), the look is a still two-shot. Nothing else changes.
- **A human on a slot at the start:** a press skips the look after `skipFrom` (30 ticks), as for every intro: `clock_start` says `skip`, and the camera takes the skip rule of row 7, one cut with the 0.08 s fade to the ordinary framing (a flash, once, by the player's own press).
- **Two humans:** the same camera (it is one view).
