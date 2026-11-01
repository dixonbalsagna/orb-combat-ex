# The meteor's arc: one curve, written down

Research & Prototyping, 2026-10-31, on Orb's note: "the arc doesn't fully complete, the knocked-back fighter reaches the apex then drifts, and then stops and goes straight down". For Simulation and Encounter to follow. **Play it:** `research/ring-any-angle/proto-v2.html`, key M or RB+Y. **Reference code and table:** `node research/ring-any-angle/meteor-arc.mjs`.

**A launch at the top of the ladder now flies one parabola from the launcher's ground to the landing's ground, and a single clock runs along it. It's a rule-of-cool path, not physics.** He leaves at 60° and comes in at 60°, 36° round the planet, with no corner anywhere.

![The whole arc at the widest view](img/meteor-arc-whole.png)

**How far to trust this.** Measured in the proto: the shape and the in-frame share. By arithmetic: everything in the sim's terms. Nobody has played this version, and none of it has run in the game.

## What was wrong, and it isn't only the proto

**In the proto,** the flight was three pieces: a climb, a hang and a drop, each with its own height and its own distance rule. They met at corners, and the drop covered only the last 5% of the distance. That's the drift, the stop and the straight fall in Orb's picture.

**The game's own law does the same thing, so fixing the proto alone would have moved the fault into the build.** `stepLaunched` multiplies sideways speed by 0.55 a second and leaves the climb alone. So he spends his carry on the way up:

| Send, today's law | Apex | Carry spent by the apex | Comes in at |
| :--- | ---: | ---: | ---: |
| 6,600 at 60° (Game Design's meteor) | 16,300 | **97%** | **90°** |
| 7,000 at 60° | 18,300 | 97% | 90° |
| 7,000 at 45° | 12,200 | 95% | 90° |
| 5,000 at 45° | 6,200 | 89% | 89° |

`SimFlight`'s curve doesn't help: it paces the same path, and "where it goes and lands" don't change. Game Design's "he comes down almost straight" and Simulation's "lands almost straight down" both describe this law. **So the meteor launch can't run on it.** Whether ordinary high launches should change too is the open question at the end.

## The curve

Two separate things, so timing can never bend the line.

**1. The path.** A quadratic Bézier, which is exactly a parabola, in the plane of the great circle, with the origin at the planet's centre. `R` is the ring's radius (24,446 on a Whole ring), `g0` and `gL` the ground at launch and landing, `top` the apex above `g0`, `D` the carry along the ground, `lean` 0.

```
ph   = D / R
P0   = (0, R + g0)
P1   = ((R + gL) sin ph, (R + gL) cos ph)
M    = (P0 + P1) / 2
b    = (sin(ph/2), cos(ph/2))                  the radial through the middle
up   = 2 (R + g0 + top) - 2 (M . b)
C    = M + up b + lean (P1 - P0) / 2

P(q) = (1-q)^2 P0 + 2 q (1-q) C + q^2 P1       q from 0 to 1
s(q) = R atan2(P.x, P.y)                       along the line, from the launch point
h(q) = |P| - R                                 height above sea level
```

**2. The clock.** A cubic from `q = 0` to `q = 1` over the flight's `T` ticks. `t = tick / T`:

```
c    = crest / T                               0.565 (3.5 s of 6.2)
s1   = (0.5 - (c^3 - 2c^2 + c) s0 - (-2c^3 + 3c^2)) / (c^3 - c^2), kept to 0.2 .. sqrt(9 - s0^2)
q(t) = (t^3 - 2t^2 + t) s0 + (-2t^3 + 3t^2) + (t^3 - t^2) s1
```

With `s0 = s1 = 1`, `q` is `t` and he flies exactly like a thrown ball. **`s0` 1.25 and `s1` 1.66 are the rule of cool:** he leaves harder than gravity would allow, eases over the top, and arrives hardest of all. The range on `s1` is what stops a cubic running backward.

**Values, in data.** `s0` 1.25, `crest` 3.5 s of 6.2, `lean` 0. `T` scales with the height's root, as the proto's ladder does. `D` by tier is below, and it's solved once for the 60° start, so the sim needn't solve it. **Half and Close rings:** scale `R`, `top` and `D` together, and the angles and the picture stay.

| Lower tier | Apex | Carry | Round a Whole ring | Time | Leaves at | Comes in at | Leaves, u/s | Slowest, u/s | Arrives, u/s |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 700 | 1,528 | 3.6° | 1.28 s | 60° | 60° | 3,144 | 939 | 4,167 |
| 2 | 2,500 | 4,759 | 11.2° | 2.42 s | 60° | 60° | 5,912 | 1,554 | 7,835 |
| 3 | 5,000 | 8,040 | 18.8° | 3.42 s | 60° | 60° | 8,290 | 1,863 | 10,985 |
| 4, not a meteor | 9,900 | 12,150 | 28.5° | 4.81 s | 60° | 60° | 11,456 | 2,004 | 15,181 |
| **4, the meteor** | **16,400** | **15,297** | **35.9°** | **6.2 s** | **60°** | **60°** | **14,442** | **1,954** | **19,138** |

Flat ground, from the reference code. On real ground the angles move a degree or two. At the top row he's above 90% of his height for 2.3 s and above 99% for 0.75 s, so the hang is there without his ever stopping.

**Why 60° now gives 36°.** The curve is a clean parabola across the chord, and the ground under it falls away. So 60° above the local ground is about 78° across the frame, which is the tall arch in the picture. It brings back Game Design's first arithmetic of 37°, against the 31° my old path gave.

## For Simulation

- **This launch doesn't step `stepLaunched`.** While he's on the arc, `x` and `y` come from the closed form of `(launch tick, x0, D, top, g0, gL, T)`. Nothing accumulates, so a re-run lands on the same bits, and `frameAt`-style reads are one evaluation. The numbers are constant for the flight, so they can be hashed once.
- **Only `+ - * /`, sqrt, sin, cos and atan2.** All float64, on our own trig.
- **In the sim's terms** `x = x0 + dir * s(q)` and `y = h(q)`. The sim's world is flat along the line and the curve is the view's, so these are the same numbers the view maps back to the sphere.
- **The ceiling isn't touched:** 16,400 is under 24,000.
- **Contact ends the flight.** From the crest on, the first tick with `h(q)` at or under the ground is the landing, wherever that is. He never skims along the ground to reach the planned spot; that was the last kink I took out. A mountain or tower in the way takes the meteor.
- **Before the crest,** what a tall building beside the launch point does to him is Game Design's call. The proto only keeps him above the ground.
- **Leaving the arc** (Game Design's brake from the end of the hang; a catch by the launcher): his velocity is `dP/dq * dq/dt`, closed form:

```
dP/dq = 2 (1-q) (C - P0) + 2 q (P1 - C)
dq/dt = ((3t^2 - 4t + 1) s0 + (-6t^2 + 6t) + (3t^2 - 2t) s1) / T
```

- **Rollback:** by my reasoning there's no new state beyond those constants and a flag.

## For Encounter

- **The forecast is now cheap and exact.** The landing is at `x0 + dir * D`, known at the send, one ground read a side. `predictFlight`'s 240 ticks aren't needed. Check the descending half against the bake for an earlier contact; I'd sample every 500 units or so, which is about 15 reads, but I haven't measured it.
- **A planned rest** (`restBy`) is `T - 31` ticks from the send, or earlier if the check finds a mountain. No swing runs in this shot, so it's only a guard.
- **The side** stays as ruled: the stick nudges which side, one candidate each way.
- **What `D` does to §12's rulings.** Game Design's "about 31°" and "he comes down almost straight" are replaced, and "inside the sixth of a loop" still holds at 36°. Game Design's to confirm.

## What it did to the shot, in the proto

Read at the top tier on planet 7, with exact projection, foe in the picture:

| | Before | Now |
| :--- | ---: | ---: |
| Climb | 149 of 180 ticks | 145 of 180 (the first 0.6 s, as Camera expected; the trail stays in frame) |
| Hang | 72 of 72 | 72 of 72 |
| Descent | 120 of 120 | **120 of 120,** but only after the change below |
| Biggest turn in a tick | Corners at the joins | 1.13°, at the crest |
| Biggest change in that turn, tick to tick | | 0.01°, so no corner |
| Slowest he goes | Near stopped sideways | 2,009 u/s at 3.4 s |

**One change for Camera to check.** He now comes in fast and on a slant, and the old focus lost him for the last 11 ticks, so the impact was off screen. The focus now passes smoothly from the pair to just short of where he's going, as the width stops holding both of them. That's 120 of 120, and it also removes a lurch when the pair stopped fitting. The descent's width is Camera's ruled "follows him", so the crest leaves the frame as it closes; the other setting, "steady", is still there to compare.

**Sliders for Orb:** the angle he leaves at (45 to 85°), the arc's lean (crest earlier or later), the launch pace, and when the crest comes. All of them stay one curve: the reference code flies 1,080 combinations of height, angle, lean, pace, crest and uneven ground, and each one lands exactly and never doubles back. At 85° the top is a needle, up to about 9° of turn in a step, so that end of the slider will look tight.

## Open

- **Should ordinary high launches lose this fault too? I think so, and it's Game Design's and Simulation's call.** Any launch high enough for the player to read its shape falls straight down at the end. Less sideways drag on a launch is one data value, though it moves carry, so it moves the golden behind its switch and every launch forecast. Not changed, and not costed.
- **A slanted impact wants a slanted crater and blast.** A 60° arrival with a round crater may look wrong now that it's visible. World's and VFX's.
- **Game Design's reasons for a steep launch still hold** at 60°: the one picture stays. Orb's "diagonally up" may want it lower. The slider will show what happens to the picture.
