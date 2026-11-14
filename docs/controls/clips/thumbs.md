# Synthetic thumbs for the moving reel: the file, how to feed it, and what the reader did (Controls, 2026-11-01)

For Tools' reel and the black box. `docs/controls/right-stick.md` section 4 describes the model: min-jerk strokes with timing and angle noise (practised thumb: 8 degrees; casual: 18 degrees and 1.5 times slower), **a 50% recentring overshoot after flicks** (10 to 45% into the opposite side), **drift** up to 0.08 (casual) or 0.04 (practised) plus noise, 1/16 quantisation. These are not people; the black box's raw log of Orb's stick replaces them.

## The file

`docs/controls/clips/thumbs.json` (691 KB, deterministic: `python docs/controls/clips/export-thumbs.py 60 > docs/controls/clips/thumbs.json`; the generator imports `docs/controls/right-stick-model.py`, so the model and the file cannot drift apart).

```
{ "hz": 60, "stick": "right", "y": "up",
  "traces": [ { "id": "casual-flick-17", "kind": "flick", "skill": "casual",
                "intent": ["flick", 2] | null,   // what the thumb meant, and its 8-way sector (0 right, counter-clockwise)
                "dir4": 1..4 | null,             // the screen quadrant when the intent is on an axis (UP 1, DOWN 2, LEFT 3, RIGHT 4)
                "samples": [[x, y], ...] } ] }   // one per sim tick, x right, y UP, each -1 to 1, already quantised
```

720 traces: 6 kinds (`flick`, `hold`, `snap_hold`, `pump`, `idle`, `aimwander`) x 2 skills x 60. **To feed a browser pad:** the axis values are `(x, -y)` (the game reads JOY_AXIS_RIGHT_Y down-positive and flips it, `render/core/main.gd`), one sample per tick, and 30 ticks of zeros between traces so the reader rests. `idle` is drift and noise only: it must make no request.

## What the reader did with them (`sim/input/tools/thumb_phantom_probe.gd`, headless, Arena pad, shipped read and the quick read at settle 1 and 0: identical)

| Trace | Result |
| :--- | :--- |
| **Flick with the recentring overshoot** (60 practised, 60 casual) | **100% one request, 0% a second.** No phantom flick from a spring-back: the overshoot (at most 0.45 raw, 0.27 rescaled) stays under the 0.35 release line and well under the 0.60 request line, so the hysteresis swallows it. No request started after the stick came back |
| Hold, snap then hold | 100% one request each |
| **Idle** (drift and noise only) | **0 requests in 120 traces** |
| Direction of the axis-aligned flicks | practised 100% (28 of 28); casual 96.4% (27 of 28) |
| **Pump** (two to four flicks) | all make more than one request, as meant |
| **Aim wander** (a sloppy continuous aim, radius 0.6 to 1.0 raw) | practised 100% one request; **casual 13% make a second request mid-hold**: the thumb dips below the release line and crosses again, so the held charge is thrown early and a new one starts. Not a spring-back; the hold is what a casual thumb does badly. The reader does not smooth it. If the black box shows Orb's thumb doing this, the answer is a wider release line (`strike.off`) or a short re-arm hold-off, both data |

Settle 0, 1 and 2 give the same counts: the thumb's behaviour at rest and in recentring decides these numbers, not the settle.

## To do with Orb's own log

Read the stick log of the black box the same way (the raw `(x, y)` per frame at the page's rate, resampled to ticks): run it through `thumb_phantom_probe.gd` by pointing it at a JSON of the same shape. What to look for: the real recentring overshoot (size and which side), the real drift at rest (is it under the 0.25 dead zone?), the real rise time to 0.60, and any re-crossing during a hold.
