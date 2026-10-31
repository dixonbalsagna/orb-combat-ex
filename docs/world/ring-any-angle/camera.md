# The ring at any angle: how a swing is shot

Owner: Camera & Cinematography, by the EP's brief. Research page, 2026-10-31, paper and scratch only: no game code. Orb picked the turntable, E and E2: the world visibly swings round the fighters (`docs/ep/vision.md`, "The fight's bearing"), and the goal is "the experience of speed and power", not a strict lap.

**How far to trust the numbers.** Section 4's bound is **measured**, on 28 AI matches in a scratch tree of e8a95e35. Everything else is **arithmetic from constants in the repo, plus first values I chose**. Nobody has seen any of this rendered, and the prototype draws bars on a 2D side view with no depth rows, so it can't answer the look. Rendering hasn't written its section; what I need from it is marked.

## The plain answer

**The ground turns under a fixed camera. The fighters stay still in the frame, side-on, in their band, and the world goes round them.** It reads as power if four things hold:

1. **A blow causes it.** The world is dead still through the hit-stop, then starts to turn on the release.
2. **The fighters don't drift.** The frame around them holds, so the only thing moving is the world. Drifting fighters are what reads as the camera losing its place.
3. **It arrives.** The swing ends before the landing, with the destination in frame, then holds still.
4. **The far land carries it.** Up to 150°/s at the peak, which is about 0.05 of the screen's width a tick, the same limit the camera already keeps in a transition.

**The biggest conflict, for the EP:** the look wants up to 150°/s, and Research tested E at 30°/s, where it's already over budget (E2: 46 ms p99 on the laptop). At 30°/s a 90° swing takes 5.6 s. Section 4 finds a possible way out: the field may need about a quarter of the area the prototype reads. That's arithmetic; Research would have to run it.

## 1. Orbit, ground turning, or a mix

| | **Camera orbits, the fight's line stays fixed in the world** | **Ground turns under a fixed camera** (or the camera orbits *and* the line turns with it: on screen, the same picture) | **Recommended: ground turns, with three small camera gestures** |
| :--- | :--- | :--- | :--- |
| **Side-on read** | Lost. The gap on screen is `s × cos φ`: at 45° it's 71%, at 90° the fighters stack | Kept at every angle | Kept |
| **Depth band** | The band's axis turns toward the lens, so "the same relative band" stops looking like one | Unchanged: the band turns with the fighters | Unchanged |
| **Left and right** | Flips past 90°. A held stick reverses, which fails Game Design's test 1 | The rival stays on the same side and the stick means what it meant. Scenery changes sides: at 180°, the city on your right is now on your left | Same, and the visible swing is what lets a player follow that |
| **Reads as** | A camera move, around a fight that didn't change | The world moved, and the fighters did it | Same, with weight |
| **Renderer** | Needs ground and buildings on all sides, including where the near ground is a flat cap today (`Z_FORE`, `look.gd`) | Needs the 2D field, on the far side only (section 4) | Same |

**Why they're the same picture.** In the pair's frame, turning the camera and the line together is identical to turning the ground. So the choice is really between the first column and the other two, and the first fails on left and right alone.

**The three gestures, all eased, none needed for the turn itself:**

| Gesture | First value | Why |
| :--- | :--- | :--- |
| Low angle | Pitch -4° (`SCAPE_PITCH`), in over the swing's first half, out after the landing | Puts the far land against the sky, where its sweep shows. A dolly barely changes far land |
| Lean toward what's arriving | 0.04 of the width, the same timing | Leaves room on the side the destination comes from |
| Bank into the turn | 3° at the peak, in flight only, inside `ROLL_DEG.x` (4°) | A flight curving should lean. **The roll is off by default today** (`CAMERA_ROLL_ON`), so this one needs a clip with and without it |

**No true yaw.** The bend, the near cap and the rows are written for a camera looking straight along the depth axis. I haven't tested yaw in them, and the swing doesn't need it. Rendering can correct this.

### The near side is the hard part

Turning the world brings things on one side forward: what stood behind the fighters crosses their plane and heads for the lens. The camera stands only 1,000 to 4,400 units back (`K_FACTOR × vh / zoom`, at the largest and smallest sizes), so a tower can pass through it. And a point nearer than the fighters moves faster the nearer it gets, with no limit. Those are the only points without a safe rate.

**The rule I need: nothing stands in front of the fighter plane, as today.** No tower ever passes between the lens and a fighter, and nothing is drawn over the fighters. Ground in front stays the flat cap.

**How a tower leaves at that line is Rendering's question, and the one the clip most has to answer.** A hard clip would show its insides. Sinking it (the implode's `IMPLODE_S` ease, over about 300 units before the line) may read as the ground swallowing it, and it would happen several times a swing inside the frame. A dissolve isn't allowed. I don't have an answer I trust without seeing it.

## 2. Easing, and how it stacks with a launch

**The shape:** smootherstep, like the rest of the camera's moves, so the peak rate is `1.875 × θ / T`.

**The rate limits come from the camera's existing comfort limits.** A point on the far land moves `1.05 × ω` screen widths a second at 16:9, with ω in radians a second (`vh × K_FACTOR` over the width).

| Limit in `camera_params.gd` | Share of the width a tick | Largest ω |
| :--- | ---: | ---: |
| `ANCHOR_STEP`, ordinary | 0.02 | **60°/s** |
| `ANCHOR_STEP_TRANS`, in a transition | 0.05 | **150°/s** |

So **150°/s peak with a launch behind it, 60°/s for anything else.** These are the project's own numbers carried over. Nobody has tested them on a swing, and they don't come from any comfort study.

| Swing | T, launch (150°/s) | Flight at 6,100 u/s | T, otherwise (60°/s) |
| ---: | ---: | ---: | ---: |
| 10° | 0.6 s (floor) | 3,700 u | 0.6 s |
| 45° | 0.6 s (floor, peak 140°/s) | 3,700 u | 1.4 s |
| 90° | 1.13 s | 6,900 u | 2.8 s |
| 135° | 1.69 s | 10,300 u | 4.2 s |
| 180° | 2.25 s | 13,700 u | 5.6 s |

**A swing can't outlast its flight.** It has to end before the landing, so **the largest swing is about 80° per second of flight.** Game Design's 6,000-unit launch flies for about 1 s, which allows about 80°. Anything larger needs a longer flight, which agrees with Research's "destination launches fly further". This limit belongs in the sim's data: the sim sets the schedule and the camera only reads it.

**The peak's arc radius:** `v / ω` = 6,100 ÷ 2.62 rad/s = 2,330 units, close to the prototype's tightest arc (2,400).

**The launch, beat by beat:**

| When | Launch today (constants) | The swing | Others |
| :--- | :--- | :--- | :--- |
| Wind-up | Anticipation push, launch weight 0.3 | Nothing. No counter-turn: it would read as hesitation | |
| Hit-stop, 12 to 16 ticks | Blow push rises over 7 frames (0.020) | **Dead still.** The stillness is what the swing is measured against | |
| Release, then 0.2 s | Whip: 12 frames, up to 3 widths | Starts here. At 0.2 of a 90° swing it has only turned 3.8° and is at 51°/s, so the whip stays as crisp as it is now | |
| Flight | Launch shot, trail 0.35 of the width, floor 0.05 | Peak. Far land sweeps; the fighter's place in the frame holds | Low angle, lean and bank go in |
| Last of the swing | | Eases out and **ends at least 0.35 s before contact** (`LAND_HOLD`), so the world is still when he hits it | Destination in frame |
| Landing | Land hold and push (0.08) | Done | Gestures ease out together after it |

**Stacking rules:**

- **Speeds add on the ground, and that's fine.** The whip's translation already goes far past the comfort limit, as an approved crisp move, and it hardly moves far land. The swing hardly moves near ground at the pivot. Each shows where the other doesn't.
- **No zoom-in during a swing,** and no zoom reversals. One change only: an eased pull out, never below the launch floor. Legal e12 (never zoom in on a fighter held in the air) applies anyway.
- **One thing at a time.** No swing while a strip or the damage inset is up, and neither opens during one: their camera stands on a building's `x`, which is moving. The landscape shot and angle shots stand down too.
- **Never twice in a row.** A second swing doesn't start within 6 s of the last ending (first value). It should come from Game Design's falling score, not a cap.

**Where the pivot goes.** Game Design and World use the midpoint, so the ground under each fighter slips by `s × sin(θ/2)`. **I'd pivot on the fighter who's on the ground, when one is:** his feet don't slide, and the airborne one has nothing under him to notice. With both grounded, the far one's slip rate is `s × ω`: at 300 units, 120 u/s means 23°/s at most. So a swing with both grounded is slow, and there's no reason to take one with a big gap. **Both in the air: the midpoint.**

**Which way it turns.** A destination **behind** the fighter plane can be seen coming: its silhouette is on the far land, then it swings round to meet him. One **in front** is on the near side, where nothing is drawn, so it arrives from the frame's edge late in the swing. **Ask for Encounter:** weigh destinations behind the plane higher. This is what makes "it arrives" work.

### Split panes

- **One bearing, both panes, same rate.** The far land sweeps the same way in each, so the two skies agree. The divider reads `x` and doesn't change.
- **Each pane's ground moves differently.** With the pivot on the fighter in pane A, pane B's ground slides at `s × ω`. If B's fighter is flying, that's just more speed. If he's grounded, the limit above applies.
- **First value:** a swing with both grounded in a split doesn't happen. With a launch, the launched body's pane carries it.

## 3. Crossing a planet

**The arithmetic.** At flat out (10,000 u/s) a full-size ring (153,600) takes 15.4 s to lap, and a Half ring (76,800) 7.7 s. **A 4 to 6 s flight is a quarter to two-fifths of the full ring**, which is enough: Orb has said the lap itself isn't the goal.

| Need | First value | Why, and the check |
| :--- | :--- | :--- |
| **The horizon must move** | Far land and sky turn at the true rate `v / R` while he flies: 23°/s on the full ring, 47°/s on the Half ring, flat out | **This is the read of crossing a planet.** Ground flow says fast anywhere; only a moving horizon says the world is round and he's going round it. Below the 60°/s limit by itself; with a swing on top, the total keeps to 150°/s. **For Rendering and World: this needs the far land reading a planet frame (Research's stage 1).** If the sky has a sun, it should move too: about 100° over a 4 s flight on the full ring, which I haven't checked is possible |
| **Curvature** | Add 0.05 to the curve at the screen's edge, eased in from 4,000 to 10,000 u/s | At sizes the camera allows, curve sits at `CURVE_NEAR` 0.035. The true sag at the floor size is close to it on a full ring (89 u, 3.8% of the height) and double on a Half ring (7.6%). So 0.085 is about true on a Half ring and about twice true on a full one. A planet that looks small is the point. **Render only** |
| **Near ground for speed** | At the flight's start and end, no more than 0.6 of the height above ground (about 1,400 units at the floor size) | Speed reads from parallax, and parallax needs something close. At the launch floor, ground crosses at 0.0625 of the width a tick, right at the crisp edge; rows behind are slower, and that gradient *is* the speed |
| **A reveal in the middle** | Flights of 3 s or more: crane up, the body down to about 0.8 of the height in the frame, pitch -6°, size no lower than the floor, over about 1 s at the flight's middle | Low, high, low is the shape: fast, then the planet, then arriving. **The climb itself is the sim's:** the camera can only crane within what his altitude allows |
| **Framing** | Keep the launch shot: trail 0.35 of the width, so 0.65 of the frame is ahead | Already built. Adds nothing to the mass rule |
| **Arrival** | The destination's silhouette over the curve by about 1.5 s before contact | Needs Encounter's pick and the far land together. **Biome changes under him** should pass in view rather than wait for a calm landscape shot |
| **No lens tricks** | No lens widening; the lens stays 30° | The camera's distance, the near cap and the bend all depend on it |

**A chase across a planet** is two panes in the same flight: the same far land at the same rate, and the chaser's pane sits at the same trail. No new rule.

**Comfort.** The peak total is about 3 widths a second of far land, for at most 2.25 s, and only after a blow the player saw coming. What I can't tell from here: whether the sweep of a whole background is more tiring than the same speed on a follow.

**Under reduced motion,** a swing is a real problem: the sim's schedule is the same for every player online, and rendering can't change it. My first answer is a near-cut at the whip, as the slam does (`SLAM_TIME_REDUCED`), showing the new bearing's ground at once, with a cinematography reason: a cut on action. It depends on whether the field can show the end bearing early. **Open for Rendering.** A player who's turned it on shouldn't get 150°/s.

**Flashing.** A swing moves the whole background, so it should be read on Tools' clips. Flash work is paused, so report the reading and don't chase it.

## 4. The sim-side bound: corrected

**Research's placeholder, half-width 3,600 or 0.7 × gap + 3,000, is too tight when they're close and too loose when they're apart, and it leaves out depth.**

**Measured:** the farthest column any pane shows, from the pair's midpoint. AI matches through the real rig, every tick: 10 on gen 2 and 10 on hand-made at 16:9 and the default zoom, and 4 each at zoom setting 0 and at 21:9. Scratch: `ring/view_bound.gd`, not parked.

| Gap up to | 16:9, default: fighter plane, max (p99.9) | 16:9, default: back row at 9,000, max | Zoom setting 0, plane | 21:9, plane | Placeholder | Recommended, default | Recommended, any setting |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 300 | 3,679 (2,402) | 7,966 | 4,267 | 4,227 | 3,600 | 3,850 | 5,150 |
| 1,200 | 4,014 (3,381) | 8,301 | 4,579 | 4,122 | 3,840 | 4,300 | 5,600 |
| 2,400 | 4,573 (3,988) | 8,860 | 5,124 | 4,639 | 4,680 | 4,900 | 6,200 |
| 4,800 | 5,773 (5,271) | 10,060 | 6,431 | 5,890 | 6,360 | 6,100 | 7,400 |
| 9,600 | 8,165 (7,528) | 12,452 | 8,400 | 8,074 | 9,720 | 8,500 | 9,800 |
| 19,200 | 12,707 (11,836) | 16,994 | 13,360 | 12,420 | 16,440 | 13,300 | 14,600 |

(The plane columns take the larger of gen 2 and hand-made. The recommended columns are the plane's; add the depth term for a row.)

**The bound:**

```
B(gap, d) = 0.5 × gap + H + A × d      distance from the pair's midpoint
```

| Term | 16:9, default zoom | Any setting (zoom 0, up to 21:9) | Where it comes from |
| :--- | ---: | ---: | :--- |
| Gap | 0.5 | 0.5 | Measured slope, 0.43 to 0.49. Geometry: each fighter is half the gap from the midpoint. **0.7 has no basis** |
| `H` | 3,700 | 5,000 | Measured. Zoom 0 and 21:9 each add about 600; I added both, but **never measured them together** |
| `A`, per unit of depth behind the plane | 0.48 | 0.63 | **Arithmetic, and it matches:** aspect ÷ (2 × K_FACTOR). It doesn't depend on zoom. The back row's measure comes from this term |

**Checks and limits:**

- Every measured value in the table is inside `B`. The 3,679 at gap 300 is a rare moment: p99.9 is 2,402.
- **It's a function of the gap only, so the sim never reads the camera.** It needs the worst setting any player may have, so it's the "any setting" row. Wider than 21:9 raises `H` and `A`; a 32:9 player would need its own check.
- **It's AI matches only,** with no swing and no human. Whips and catch-ups are in the data. The rig's shake and the fighter leaving the picture aren't separately counted. **With swings, the fighters' places along the line don't change, so I expect no change, unmeasured.** Add Netcode's lead separately: 20 ticks at flat out is 3,300 units.
- **For a big gap, two windows are enough.** Past a split nothing between the panes is shown, so `H + A × d` round **each fighter** is enough. This is arithmetic from the same fit; I measured from the midpoint only.

### What the bound means for E

D3 needed it as the line nothing crosses. **Under the turntable it's the field's radius instead.** Everything inside gets rewritten on purpose, so the bound tells Research how much field a swing has to have.

**Possibly large savings, arithmetic only, not run:**

- **Only the far half is drawn.** Near ground is a flat cap. That halves the area.
- **Radius.** At close quarters, `B` at the back row is about 8,300 (default zoom), against the prototype's 12,000 all round. **The area is about a quarter:** 1.1 × 10⁸ against 4.5 × 10⁸ square units.
- **Swept nodes a tick:** half a disc of radius 8,300 sweeps `½ r² dθ`. At 150°/s (0.044 rad a tick) that's 1.5 × 10⁶ square units a tick, or **about 6 nodes of 512 units a tick**, or about 90 of 128 units. Research's read budget is 6 a tick, so **E2 might fit at the peak.** Its 512-unit relief error (4.7 RMS, 60 max on gen 1, gen 2 unmeasured) is the price, and the area right round the pair would need finer ground.
- **The known end bearing.** A launch tells the sim where the swing is going, so the sweep can be read in order, ahead of it.

**Research should re-run E2 with the half disc, radius `B`, and 150°/s.** That decides whether the look's rate is possible at all.

## What a clip has to show

Research's bars can't show any of this, so this needs a scratch render on the real panes, in the web build, side by side with the reference build (ADR 0010). Inputs drawn at the frame edge.

| # | Clip | What it must show | Fails if |
| :--- | :--- | :--- | :--- |
| 1 | 90° launch, 2 s flight, into a city behind the plane | Still through the hit-stop, whip as crisp as today, far land sweeping, city swings round to meet him, still before contact | The fighter drifts in the frame, the whip smears, or it reads as a camera move |
| 2 | Same at 30, 60, 150°/s | Which reads as power and which as a glitch. **This one settles the conflict with the budget** | |
| 3 | A tower reaching the near line | How a building leaves, on sink and on a hard clip | Anything crosses a fighter, or anything fades |
| 4 | 180° | The rival on the same side, held stick unchanged, a player can say where the city went | They can't |
| 5 | Split, launched body against a grounded chaser | Same sky in both panes; the grounded one's feet don't slide | |
| 6 | A flat-out 5 s flight on a full ring | Horizon moving, curve at 0.085, low, reveal, low, arrival over the curve | It reads as fast but not as far |
| 7 | Bank on and off; low angle on and off | Whether each gesture earns its place | |
| 8 | Collapse and a swing, both flash modes | Readings only, flash work being paused | |

**Orb judges 1, 2, 3, 4 and 6.**

## What this costs Camera, if it's built

Rough, for planning. The rig reads `b.x` along the ring for the landmark list (the lean step's cached list), the inset, landmarks and the ground-shows test, and under E those places move every tick. The swing's own beats are small: they reuse the push, pitch and lean machinery. **One to two windows, after the field exists.** Today's director-20 and director-21 stay parked and don't bear on it.
