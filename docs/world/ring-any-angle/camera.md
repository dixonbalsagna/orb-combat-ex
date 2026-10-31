# The ring at any angle: how a swing is shot

Owner: Camera & Cinematography, by the EP's brief. Research page, 2026-10-31, paper and scratch only: no game code. Orb picked the turntable, E and E2: the world visibly swings round the fighters (`docs/ep/vision.md`, "The fight's bearing"), and the goal is "the experience of speed and power", not a strict lap.

**How far to trust the numbers.** Section 4's bound is **measured**, on 28 AI matches in a scratch tree of e8a95e35. Everything else is **arithmetic from constants in the repo, plus first values I chose**. Nobody has seen any of this rendered, and the prototype draws bars on a 2D side view with no depth rows, so it can't answer the look. Revised the same day against Game Design's rulings, Rendering's section and Legal's RL-213: where they settled something, this page now follows them, and section 5 answers what they asked.

## The plain answer

**The ground turns under a fixed camera. The fighters stay still in the frame, side-on, in their band, and the world goes round them.** It reads as power if four things hold:

1. **A blow causes it.** The world is dead still through the hit-stop, then starts to turn on the release.
2. **The fighters don't drift.** The frame around them holds, so the only thing moving is the world. Drifting fighters are what reads as the camera losing its place.
3. **It arrives.** The swing ends before the landing, with the destination in frame, then holds still.
4. **The far land carries it,** at Game Design's 60°/s, which is under half the camera's travel budget.

**The conflict I raised is smaller now.** I asked for up to 150°/s against Research's budget at 30°/s. Game Design ruled 60°/s, and Rendering's plan makes a turn one uniform a frame with no new reads, so the view's cost no longer grows with the rate. **The sim's own re-lay is still open** (Research's 1.7 to 3 ms a tick, an estimate). None of this has been run.

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

**The rate limits.** The lens is 30° vertically, which is 50.9° across at 16:9 and 39.3° at 4:3. Section 5 has the table. **Game Design's 60°/s is the ruling, and 100°/s, far land and flight's horizon together, is the most any screen shape takes inside the travel budget.** I withdraw my 150°/s: it came from `ANCHOR_STEP_TRANS` (0.05), over the 0.045 budget, and I hadn't looked at the budget.

**The curve.** Game Design's "90° in 1.8 s" is a near-constant rate, not a smootherstep, whose peak would be 94°/s. So ramps at the ends: **20 ticks in, on a launch, so the whip stays clean, and 10 out, as ruled.** The camera's own limit on acceleration (`MASS_ACC`, 0.006 of the width a tick each tick) allows it: 60°/s is 0.018 of the width, reached over 10 ticks at 0.0018 a tick.

| Swing, at 60°/s with those ramps | T | Flight at 6,100 u/s |
| ---: | ---: | ---: |
| 10° | 0.5 s, peaking at 40°/s | 3,050 u |
| 45° | 1.0 s | 6,100 u |
| 90° | 1.75 s | 10,700 u |
| 135° | 2.5 s | 15,300 u |
| 180° | 3.25 s | 19,800 u |

**A swing can't outlast its flight,** as Game Design rules: it rests by the arrival. So the largest swing is about **60° per second of flight, less 15°.** A 1 s flight gets about 45°; 90° wants 1.75 s, matching Game Design's 1.8 s and Research's "destination launches fly further".

**The arc's radius** at 6,100 u/s and 60°/s is 5,800 units, well clear of the prototype's tightest (2,400).

**The launch, beat by beat:**

| When | Launch today (constants) | The swing | Others |
| :--- | :--- | :--- | :--- |
| Wind-up | Anticipation push, launch weight 0.3 | Nothing. No counter-turn: it would read as hesitation | |
| Hit-stop, 12 to 16 ticks | Blow push rises over 7 frames (0.020) | **Dead still.** The stillness is what the swing is measured against | |
| Release, then 0.2 s | Whip: 12 frames, up to 3 widths | Starts here, on a 20-tick ramp. By the whip's end it has turned about 4°, so the whip stays as crisp as it is now | |
| Flight | Launch shot, trail 0.35 of the width, floor 0.05 | Peak. Far land sweeps; the fighter's place in the frame holds | Low angle, lean and bank go in |
| Last of the swing | | Eases out over 10 ticks and **is at rest by contact**, as Game Design rules, so the world is still when he hits it. (I'd asked for 0.35 s of stillness first and cited `LAND_HOLD`, which is a hold *after* landing. Clip 1 can test more) | Destination in frame |
| Landing | Land hold and push (0.08) | Done | Gestures ease out together after it |

**Stacking rules:**

- **Speeds add on the ground, and that's fine.** The whip's translation already goes far past the comfort limit, as an approved crisp move, and it hardly moves far land. The swing hardly moves near ground at the pivot. Each shows where the other doesn't.
- **No zoom-in during a swing,** and no zoom reversals. One change only: an eased pull out, never below the launch floor. Legal e12 (never zoom in on a fighter held in the air) applies anyway.
- **Other shots.** A fighter's strip stays: its camera is in the view frame, and Game Design's swings run at up to 10°/s through the fights strips come from. The damage inset (parked, off) can't credit a beam in a swing, and its camera stands on a building that moves, so it doesn't open in one. The landscape and angle shots stand down: the swing is already the shot.
- **How often** is Game Design's falling score, 6 to 12 a match. I withdraw my 6 s gap.

**The pivot** is Game Design's rule, checked in section 5.

**Which way it turns.** A destination **behind** the fighter plane can be seen coming: its silhouette is on the far land, then it swings round to meet him. One **in front** is on the near side, where nothing is drawn, so it arrives from the frame's edge late in the swing. **Ask for Encounter:** weigh destinations behind the plane higher. This is what makes "it arrives" work.

### Split panes

- **One bearing, both panes, same rate.** The far land sweeps the same way in each, so the two skies agree. The divider reads `x` and doesn't change.
- **Each pane's ground moves differently.** With the pivot on the fighter in pane A, pane B's ground slides at `s × ω`. If B's fighter is flying, that's just more speed. If he's grounded, the limit above applies.
- **Far apart,** see section 5's last table.

## 3. Crossing a planet

**The arithmetic.** At flat out (10,000 u/s) a full-size ring (153,600) takes 15.4 s to lap, and a Half ring (76,800) 7.7 s. **A 4 to 6 s flight is a quarter to two-fifths of the full ring**, which is enough: Orb has said the lap itself isn't the goal.

| Need | First value | Why, and the check |
| :--- | :--- | :--- |
| **The horizon must move** | Far land and sky turn at the true rate `v / R` while he flies: 23°/s on the full ring, 47°/s on the Half ring, flat out | **This is the read of crossing a planet.** Ground flow says fast anywhere; only a moving horizon says the world is round and he's going round it. Fits the budget by itself; with a swing on top, see section 5. **For Rendering and World: this needs the far land reading a planet frame (Research's stage 1).** If the sky has a sun, it should move too: about 100° over a 4 s flight on the full ring, which I haven't checked is possible |
| **Curvature** | Add 0.05 to the curve at the screen's edge, eased in from 4,000 to 10,000 u/s | At sizes the camera allows, curve sits at `CURVE_NEAR` 0.035. The true sag at the floor size is close to it on a full ring (89 u, 3.8% of the height) and double on a Half ring (7.6%). So 0.085 is about true on a Half ring and about twice true on a full one. A planet that looks small is the point. **Render only** |
| **Near ground for speed** | At the flight's start and end, no more than 0.6 of the height above ground (about 1,400 units at the floor size) | Speed reads from parallax, and parallax needs something close. Flat out, the scroll governor (`SCROLL_MAX`, 0.045 of the width a tick) sets the size, about 0.036 of the height. Rows behind are slower, and that gradient *is* the speed |
| **A reveal in the middle** | Flights of 3 s or more: crane up, the body down to about 0.8 of the height in the frame, pitch -6°, size no lower than the floor, over about 1 s at the flight's middle | Low, high, low is the shape: fast, then the planet, then arriving. **The climb itself is the sim's:** the camera can only crane within what his altitude allows |
| **Framing** | Keep the launch shot: trail 0.35 of the width, so 0.65 of the frame is ahead | Already built. Adds nothing to the mass rule |
| **Arrival** | The destination's silhouette over the curve by about 1.5 s before contact | Needs Encounter's pick and the far land together. **Biome changes under him** should pass in view rather than wait for a calm landscape shot |
| **No lens tricks** | No lens widening; the lens stays 30° | The camera's distance, the near cap and the bend all depend on it |

**A chase across a planet** is two panes in the same flight: the same far land at the same rate, and the chaser's pane sits at the same trail. No new rule.

**Comfort.** The peak total is about 1.1 widths a second of far land, or about 2 with a flat-out flight's horizon on a Half ring, and a launch's swing follows a blow the player saw coming; a brawl's slow one doesn't. What I can't tell from here: whether the sweep of a whole background is more tiring than the same speed on a follow.

**Under a motion setting,** see section 5: each shot degrades to a cut or a still.

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
- **Swept nodes a tick:** half a disc of radius 8,300 sweeps `½ r² dθ`. At Game Design's 60°/s (0.017 rad a tick) that's about 6 × 10⁵ square units a tick, or **about 2.3 nodes of 512 units a tick,** or about 36 of 128 units, against Research's budget of 6 and Rendering's of 4. These are the sim's or the store's reads: Rendering's own drawing of a turn reads nothing, and only flight uncovers ground.
- **The known end bearing.** A launch tells the sim where the swing is going, so the sweep can be read in order, ahead of it.

**Research should re-run E2 with the half disc, radius `B`, and 60°/s.**

## What a clip has to show

Research's bars can't show any of this, so this needs a scratch render on the real panes, in the web build, side by side with the reference build (ADR 0010). Inputs drawn at the frame edge.

| # | Clip | What it must show | Fails if |
| :--- | :--- | :--- | :--- |
| 1 | 90° launch, 2 s flight, into a city behind the plane | Still through the hit-stop, whip as crisp as today, far land sweeping, city swings round to meet him, still before contact | The fighter drifts in the frame, the whip smears, or it reads as a camera move |
| 2 | Same at 30, 60, 100°/s | Which reads as power and which as a glitch | |
| 3 | A tower, then a mountain, reaching the near line, at a launch's 60°/s and a brawl's 10°/s, low angle on and off | How they leave (section 5) | Anything crosses a fighter, or anything fades |
| 4 | 180° | The rival on the same side, held stick unchanged, a player can say where the city went | They can't |
| 5 | Split, launched body against a grounded chaser | Same sky in both panes; the grounded one's feet don't slide | |
| 6 | A flat-out 5 s flight on a full ring | Horizon moving, curve at 0.085, low, reveal, low, arrival over the curve | It reads as fast but not as far |
| 7 | Bank on and off; low angle on and off | Whether each gesture earns its place | |
| 8 | Collapse, signature and a swing through a city, both flash modes, at 16:9 and 1024 by 768 | Readings only, flash work being paused. RL-213 and RL-208 make reduced mode the one that counts | |
| 9 | Each shot under the motion setting | Section 5's table | A cut with no action to hide on, or a fighter's feet off the ground |

**Orb judges 1, 2, 3, 4 and 6.**

## What this costs Camera, if it's built

Rough, for planning. **Rendering's plan leaves the rig's framing as it is:** cameras and fighters stay in the view frame. What changes is what reads a building's place: the landmark list, the inset, the ground-shows test and the rig's six ground reads (Rendering's count). The swing's own beats reuse the push, pitch and lean machinery. **About one window, after the field exists,** down from my first guess of two. Today's director-20 and director-21 stay parked and don't bear on it.

## 5. Answers to Game Design, Rendering and Legal

### The field of view, and 60°/s against the travel budget

**The lens is 30° vertically (`TAN_HALF_FOV`). Across, that's 50.9° at 16:9, 64° at 21:9 and 39.3° at 4:3,** so Game Design's "near 40°" is the 4:3 case, as Rendering also found. Arithmetic: `ω / (2 tan(h/2))` widths a second at the screen's centre, and `1 + tan²(h/2)` times that at its edge.

| Far land, share of the width a tick | 21:9 | 16:9 | 4:3 | Budget |
| :--- | ---: | ---: | ---: | ---: |
| 60°/s, centre | 0.014 | **0.018** | 0.024 | 0.045; 0.03 under Reduce flashing |
| 60°/s, edge | 0.019 | **0.023** | 0.028 | |
| Most inside 0.045, at the edge | 139°/s | 120°/s | **98°/s** | |
| Most inside 0.03, at the edge | 93°/s | 80°/s | **65°/s** | |

- **60°/s fits both budgets at every screen shape, but with less to spare than Game Design wrote under Reduce flashing:** 0.028 at the edge at 4:3.
- **A flight's horizon adds to it.** Flat out, `v / R` is 23°/s on the full ring and 47°/s on a Half ring. **60 + 47 = 107°/s is over both ceilings at 4:3 and over the Reduce flashing one at 16:9.** So either the horizon's turn gives way during a swing on a Half ring, or the swing slows to about 65° less what the horizon takes, under Reduce flashing. I'd ease the horizon's turn off during a swing: the swing is already saying it.
- **The budget is a yardstick today.** `travel_budget` ships off, by Orb's calls of 10-19 and 10-22, so nothing enforces it, and the flash analyser is the real test.
- **Near things aren't covered.** Rendering's `z / (D − z)` is right. The flat near ground is what keeps it from mattering, and it's why nothing may stand there.

### The pivot: agreed

The standing fighter, else the midpoint, eased over 20 ticks. It's what I'd proposed, and I checked three things:

- **The ease is enough.** A change of pivot changes the ground's velocity by `ω × distance moved`. Game Design's sweep limit keeps that to 6,000 u/s at most. At the sizes the camera holds that's about 0.025 to 0.0375 of the width a tick, over 20 ticks: at most 0.0019 a tick each tick, under `MASS_ACC` (0.006). **On a launch's start the gap is small, so it's nothing.**
- **It moves in depth, not across.** The pivot lies on the line, so the change shows as ground flowing toward or away from the lens. It doesn't shift the fighters in frame.
- **One word, two things.** Rendering's panes each centre their frame on their own fighter; Game Design's pivot says how the ground moves. Both must hold: a pane's frame travels with its fighter, and the ground under it moves by the ruled `r × rate`. **Rendering should confirm its pane frames come out that way.**

**No swing during a beam, a hit-stop or a finisher: agreed,** and a KO, the intro and a grab's set piece too. The beam's 33-tick ease to rest is plenty: 60°/s to nothing is well within the camera's limit.

### Rendering's plan against question 1: agreed

Rendering keeps the camera, fighters and beams in the view frame and turns the world. That's my answer. Its finding that a tower can pass through the lens is what section 1 raised, and its stateless near rule for buildings is the right kind of answer, since speed doesn't matter to it.

### Framing a mountain in the foreground

**This is a framing answer, untested. Only the clip decides it.** Four facts from the geometry:

- **What crosses in frame is small.** A point at radius `r` crosses the fighter plane on the line, so it's only inside the frame if `r` is under the half-width: 476 to 2,083 units on the plane.
- **What then comes into view has `r` under `D`,** the camera's distance. Past that it passes beside the lens, off frame. `D` is 1,000 at the closest, 2,800 at the launch floor and 4,376 at the smallest size.
- **So a tight camera sees less sinking.** Pulling wide to show a turn is the wrong way round when land is near.
- **Speed helps.** At 60°/s, land 1,000 units out moves 1,000 u/s and leaves in about a second. **At a brawl's 10°/s it's 175 u/s, slow enough to watch. The slow swing is the worst case.**

**So I'd frame it like this:**

| Rule | First value | Does what |
| :--- | :--- | :--- |
| **Low angle during every swing** | Pitch -4°, -6° with land taller than the frame's height within `D` | Moves the fighter plane from 0.7 to about 0.83 to 0.9 of the height. Everything in front is then a thin strip at the bottom, so the sinking happens **under the fighters' feet**, not at eye level. It also raises the far land's share of the picture, which is what's carrying the swing |
| **No pull out with land near** | Hold the size from the swing's start, with tall land inside `D` | Keeps `D` small. A launch's pull comes only over open ground |
| **Don't choose the swing that does it** | **For Encounter:** a falling score for a swing that brings land above about 1,500 units into the side turning forward, within 4,400 units of the pivot | A fixed radius, so the sim never reads the camera. It's a score, in keeping with Game Design's "it never refuses". Height only, nothing about people |
| **No slow swing into it** | **For Game Design:** a brawl's 10°/s swing eases to rest rather than bring tall land round in front | That's the worst case, and a brawl has no need of it |

**What I wouldn't do:** cover it with dust, fade it, or cut. If the clip still reads as the ground swallowing a mountain, the honest levers are Rendering's: cap how far land rises in front, or limit how far a swing turns near mountains.

### About 24,000 apart at 30°/s

**The rate doesn't match Game Design's limit unless both are in the air and the pivot's the midpoint.** There `r` is 12,000, so the 6,000 u/s limit gives 29°/s. **With one standing, `r` is 24,000 and the limit gives 14°/s;** with both standing it holds still.

**The framing is fine and needs no new rule, with one thing to watch:**

| | At 24,000 apart, both airborne, 29°/s |
| :--- | :--- |
| **Panes** | A split, each pane on its fighter at its own size, the rig unchanged |
| **Far land** | The same way in both panes, 0.009 of the width a tick. The skies agree |
| **Ground at each fighter** | Flows **in depth**, at 100 units a tick: toward the lens in one pane and away in the other. That reads as a chase camera's flow, so I expect it to read as speed, not as an error. Across the frame it's about 0.011 of the width a tick at the plane, reaching the 0.045 budget within about 1,100 units of the lens, where the ground is flat anyway |
| **To watch** | In the pane where ground flows **away**, land comes out from the near line and rises as it goes. It's the sinking run backwards, and it's as untested. Clip 5 should include it |

Legal e12 still applies: no zoom in on a fighter held in the air.

### Legal's RL-213

**(4): the camera never turns to or holds on civilians or bodies, and a swing is not a zoom on a victim.** What I build to:

- **Nothing in a swing's shot reads people.** The lean follows the bearing, the low angle the land, the end of the swing the structure or terrain the planner chose. A swing has no aim of its own.
- **It holds on the fighters.** Whatever a swing brings past, the frame stays on them, and the swing ends on the landing's usual shot. A swing adds no zoom in.
- **The reveal and the arrival frame structure, terrain or a fighter,** per (2), and never linger: they're fixed lengths from the flight, not from what's in frame.
- **What I can't promise:** a crowd may be in frame, because it's on the street he lands on. That's framing past them, which today's camera does too. **The camera's `_ground_shows` looks for craters, buildings and scorch, not people:** I'd keep it that way, and it needs a check that no body counts.

**(7): a setting turns a swing into a cut or a still.** Rendering's heading is a view-side value, so the shown heading can differ from the sim's. That answers what I left open: **a player's setting doesn't touch the sim, so online is no problem, and it needs no setup value for this.** The catch is that the sim's plane must equal the drawn plane under anyone standing, so holding a heading only works where nobody's feet depend on it.

| Shot | Under the motion setting | Reason it's allowed | Holds if |
| :--- | :--- | :--- | :--- |
| **Launch swing** | **Cut,** at the whip: the shown heading goes to the end bearing at once, then holds. The whip stays a near-cut (`SLAM_TIME_REDUCED`) | A cut on action, on the blow. He's in the air, so nothing's at his feet | The launcher's standing: shown heading is wrong for his ground until the swing's over, unless he's the pivot, which he is. Rendering to confirm |
| **Chase swing** | **Cut,** when the chase starts, same way | A cut on the chase's start | Both in the air. If one lands first, see the last row |
| **Form's pause** | **Still:** the pause plays with the world held, and the new bearing comes in **a cut at its end** | Nothing moves in a pause, and the gather is the change of scene | Nobody's feet move in a pause |
| **Brawl or rally, at 10°/s** | **Still:** the shown heading holds and **catches up at the next launch's cut** | Nothing's asked of the player, and the far land simply doesn't turn | Fighters close together. **It can't hold for long: a standing fighter away from the pivot gets his feet off the drawn ground** as the angle grows, about `r × sin(Δ) × slope`. So it's only while `r` stays within reach |
| **Crossing flight's far land** | **Still:** no horizon turn; curvature stays | Only ever a cue | Always |
| **Anything held too long** (a standing fighter's ground has parted from the shown ground) | **A cut at the next hit-stop's start,** or the slower setup rate Game Design proposes if there isn't one | | **The open one. It needs Rendering's and Simulation's answer:** how far shown and sim may part |

**Game Design's half rate is then a second choice, not the setting:** it's still a whole-view move, and online it'd slow the other player. RL-213 asks for a cut or a still, and this is how each shot gets one. **Accessibility reviews it before it ships, and a cut is a large change of picture, so it counts in the flash register:** at 2 to 5 launches a match that's small, but it has to be read, with the two settings together. A cut under Reduce flashing cross-dissolves today (`CUT_DISSOLVE_S`), which Orb rejected for play: **the setting must be a plain cut.**
