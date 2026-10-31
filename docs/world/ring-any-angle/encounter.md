# A swing and the choreographer: what drives it and what it breaks (Encounter, 2026-10-31)

For the EP, on Orb's pick of the turntable. Paper only: no Godot, nothing built. I read the code on main e8a95e35, and `game-design.md` and `netcode.md` as revised for the swing. Arithmetic is marked as such. The only measured numbers are my 2026-10-30 counts of blows across depth: 20 AI matches a world.

## The answer

1. **A swing can arrive at a place on purpose, and the plan can be made at the send.** Turning about a fixed point doesn't change a place's distance from that point, so the force for a flight can be worked out before the turn starts. This only holds if **the pivot stays put until the swing rests**, which differs from Game Design's pivot rule (section 3).
2. **Every long-range plan in the director reads one frozen line.** Fine once the world rests, wrong within a few ticks while it turns. So plans read the line the swing will end on, and a launch with no arrival stops any swing already running.
3. **The request belongs in a new `DirSwing`, decided before `chooseLaunch`, one line only.** Scoring several lines inside the plan's frame would break the budget Performance just asked for.
4. **Stale depth gets worse unless Option A lands first. With it, the worry changes.** No code stops a body at a building with depth off. That is safe today only because **World builds nothing on the fighters' plane**: 0 of 84,455 strikes crossed a box in the three worlds. A swing ends that rule. This is the largest thing it breaks (section 4).

## 1. Who reads the ground ahead, and what a swing does to each

Today's plans read column `x` on a line that can't move. How fast a place on the old line moves under a turn, by arithmetic, at 1° a tick (Game Design's launch rate, 60°/s):

| Place at | 1,500 | 3,000 | 6,000 | 12,000 |
| :--- | ---: | ---: | ---: | ---: |
| Units a tick | 26 | 52 | 105 | 209 |

`PROP_STOP` is 30 and `contact.reach` is 68, so an aim made on the old line is wrong within about 1 to 3 ticks.

| Planner | Reads | If the ground swings during the plan's flight | If it swings after | Needs |
| :--- | :--- | :--- | :--- | :--- |
| **`chooseLaunch`, scoring** (`predictFlight`, `popNear` at the landing, mountainside, cliff, skim, downhill, tree line) | Along ±x from the target, once, at the send. Flight up to 240 ticks. Reach: haul 13,200, mountainside 12,480, cliff 12,450, skim 12,000 | Scores were for ground he won't cross. Care counts people who aren't there, and a "landing" may be anywhere. No crash and nothing to undo | Nothing: the plan is spent at the send | Reads on the final line (below). Most of these reach past Netcode's strip of about 170 columns (5,440 units), so they get coarse far ground: fine for a score, not for an exact landing |
| **BUILDING SMASH** (`WorldBrunt.aim`, `chainPlan`; kept on the fighter as `aimB`, `aimX0`, `aimZ1`, `aimD`) | One building index and a depth waypoint | **Breaks.** `checkHit` reads the building's edge in ring `x`. With the aim gone he "flew past without touching it", which is safe, but the plan's name, score and camera beat were for a hit. `camintent` and `wallkick` read `aimB` too | Nothing once he's landed, but `aimB` must stay valid while it's held | Stable building slots (Simulation, World). Ring `x` taken from a planet point. The aim made on the final line |
| **PROP SMASH** (`_propFlight`, `_hookArm`, broken props) | Simulated flight, reach 3,000. The record holds the prop's `x` and column, and the broken ring holds columns | **Breaks at once:** 26 to 52 units a tick against a stop of 30. `propreach_probe`'s hard row (none ends short) fails. A column stops naming a prop, so a broken prop could come back | The broken ring is wrong after any swing, even a slow one | Props and broken props keyed to the planet, not the column. The flight stepped on the swing's own curve (below). My `plan-cost` park first |
| **Camera's feed** (`DirCamIntent`, `SimFlight.predict`) | Landing `x` and time at the send | Along the line it stays right if the pivot holds. It knows nothing of the turn | Nothing | The swing in the feed, so Camera doesn't whip against it |
| **`DirChase`** | `predictFlight` at each catch, for his landing tick | Small: it re-reads, and the gap is along the line | Nothing | Nothing beyond the frame's ground |
| **`DirLocation.roam`, the lure** | The whole ring: 48 buckets of `S.popHist`, `_bucketBiome` built once per world, one direct `S.base` read | Tables are stale from the first tick, and nearly all of the ring lies past any strip. The harm is low because it only returns left or right, and it's asked again | Stale until rebuilt | **Its job moves.** "The cheapest way round" is a ring idea. Where to lead the fight becomes a term in the swing's score, without its people reads (RL-213, below); `roam` keeps only the near choice |
| **Beam plan, signature variants** (`beamplay`, `sigvariants`) | Biome and buildings along the line at the tell | Game Design rests the swing during the tell (about 33 ticks), but it may still be easing when the plan reads | Nothing: no swing until the beam is gone | Plan at the tell's end, or on the line it will rest on. Not checked against the code's order |
| **`DirCalm`** | Warms a ring, predicts a pivot, takes a pick | Nothing left to do: there's no swap to wait for | | **Retire its ask and warm.** Its score table moves to `DirSwing`, and its hooks become `DirSwing`'s asks |

**The fix common to all: plans read the line the swing will end on, and flights read it on the swing's own curve.** The curve is fixed once asked (bearing, rate, eases), so a planner can ask for the frame `n` ticks ahead: `WorldSwing.frameAt(S, n)`. `predictFlight` and `_propFlight` then make the same number of ground reads as now. Each read costs a field look-up, and that price is World's and Performance's to measure.

**A launch with no arrival.** A slow brawl swing may be running at the send (10°/s, 17 units a tick at 6,000). It eases to rest, as for a beam, and the plan reads the line where it will rest.

## 2. Where the request sits

**A new `sim/director/swing.gd`, `DirSwing`, with one arbiter.** The director asks and scores; World or the core runs the turn and enforces Game Design's rate law. No caps: Game Design's "6 to 12 a match" comes from the score, and QA reads it as a band.

**What asks.** Each is a call at a moment that exists today, so nothing is polled except the brawl's slow check.

| Moment | The hook | Runs at |
| :--- | :--- | :--- |
| A launch | `DirMelee.launchBeat`, before `chooseLaunch` | Decides at the send; the swing starts as the hit-stop ends |
| A chase, a flee, a zip away | `DirChase`, `DirZip`, at the start | Their start |
| A form's pause | `DirExchange._transforms`, where `DirCalm` asks today | The pause |
| A brawl | `DirSwing.tick` from `dirUpdate`, about once a second after about 45 s with no swing | Any live tick; never from a press, so it can't be a dodge |
| Story and set pieces | The same `ask`, with a large score | Setup, a set piece's end |

**Who else may ask:** only the sim's own systems, through that one call. World may slow or rest a swing (the rate law, a face) but doesn't choose. Camera, UI and Audio read it and never ask: rendering doesn't write the sim. A player moves it only through the fight (lean, 1c).

**What scores it.** Candidates are places from World's list, plus a slight tilt the way the fight is being pushed, plus **stay, which scores 0**. So a swing to nothing isn't taken. No random draws from `S.rng`: any noise is a keyed draw. Weights are for Game Design.

| Term | Reads | Already exists as |
| :--- | :--- | :--- |
| Arrival, by kind | The place's structures or terrain, or a fighter: rival's home, landmark, city, own home, town, mountain, cliff | `calmTurn.score` 5, 4, 3, 2, 1 |
| Personality | Care × **standing buildings** at the place and on the way, and the place's wear. A villain hunts buildings and what's already damaged; a hero leads to empty, interesting ground. **Never people** | `A.care`, on a new input |
| Variety | That biome's time share against its share of the planet | `S.dirS.biomeT` |
| Lean | The way the pair has been pushed (1c) | New, small |
| Recency | Falls with time since the last swing: `-w × exp(-t / τ)` | New; replaces the old caps |
| Fit | How much of the angle fits his flight's time; the part that doesn't is lateral miss at the place | `predictFlight`'s `t` |
| Sweep | Buildings the turn would bring to a fighter or across the pair's line | New; needs World's query (section 4) |
| Street | How close the bearing is to a street's, inside a place | New; needs World's plan (section 4) |

**Decided first, then planned on one line.** `DirSwing` picks a line from the list, then `chooseLaunch` runs once on that line, and its candidates are today's, with today's names. A candidate per line would cost a plan per line: at my `plan-cost` figures of 1.9 ms median and 4.4 ms p99 native, three lines are about 6 and 13 ms, and by Performance's ×4 about 23 and 53 ms on the laptop, against the 8 ms it asked for. The price is that the launch can't pick the bearing whose PROP SMASH happens to be best. That's acceptable, as the bearing is chosen for the place. If the picked line's best launch is poor, the swing still runs and he's sent somewhere ordinary.

**Legal's conditions (RL-213) bind this score.** "Toward towns" and "arrives at something" mean buildings, terrain, a place's wear or a fighter. No term reads civilian count, density or the toll, including to avoid them, so the hero's care reads buildings too. No school, hospital or place of worship is a target or an arrival. The 12 to 30% band is a test result, not a target, and a run over 30% fails the tuning.

**The test, `swing_legal_check`, in CI with the code:**

| Row | How | Fails if |
| :--- | :--- | :--- |
| Blind to people | Each ask scored twice from one state, with `popAlive`, `S.popHist` and the toll zeroed in one and doubled in the other, across gen 2 planets | Any candidate, score or pick differs by a bit. Negative control: a scratch term reading `popAlive` must make it fail |
| Source | A lint over `swing.gd` and the place list's fields | It names `popAlive`, `popNear`, `popHist`, `pop_mult` or a casualty read |
| Excluded places | Every place on many planets, and every pick, against a `noTarget` list in the data | A listed kind is a candidate or an arrival |
| Words | The feed line and cue text at every ask | They name people, or say a swing brings the fight to them |
| The band | QA's arms with swings on | Civilians lost at the KO over 30% |

**Two lines on main already fall short of RL-213, and a swing would run through them. Neither is mine to settle alone:**
- **`chooseLaunch` and `bruntScore` read people.** `k.s += -care × CARE_W × popNear(landing)` and the same over a building's `popAlive`, so a villain's landing scores up with people near it. `DirLocation` reads `S.popHist` the same way, and `popL <= OPEN_POP` gates the distance and new-ground terms. RL-213 is about swings, but its words are "no term in any score", so these may be covered too; **Legal should say.** Since `DirSwing` plans on one line through `chooseLaunch`, the swing's launch inherits them either way. Blind-to-people can't pass for the launch until they change, and replacing them moves the golden and QA's civilian bands.
- **`hill_chapel` is a landmark in `settlements.json`,** a real building that `WorldBrunt.candidates` can aim at today and `calmTurn.score`'s landmark term would count as an arrival. It goes on `noTarget`, but that's a data line and a filter in `candidates`, on World's and my lines. `bell_tower` needs Legal's eye too: it may just be a tower. I found no school or hospital in that file.

**Conflicts.** One swing runs at a time. A new ask replaces it only if it scores above what's left of the running one's score, less a reversal term that grows with how far it would turn back. State rules aren't scores: the beam's rest, and the states below, always win.

**States that rest it.** From Game Design: a beam and its tell, a beam struggle, hit-stop, finisher, KO, intro, a grab's set piece. **Added from the code:** a tower chain (`f.interior` and `splashed` hold building indices, and it's in World's calm test for that reason). Burial and a slide count as standing, so the rate law covers them.

**Explaining it.** Every ask prints one feed line, taken or not, in the launch planner's format, top three including stay:

```
SWING launch: +48° to HARBOUR city 21.4 = arrive 16 + rival's home 5 + lean 2.4 - recent 1.0 - sweep 1.0; next +12° RIDGE 14.2; stay 0; pivot launcher; rests by 1840
```

A cue goes with it for QA and Camera (`swing_start`, cause in `source`, place in `text`). A cue moves the golden, which is fine as it's behind the switch. The feed itself isn't hashed. Netcode's page says a gradual swing needs no lead, so an ask starts at once, and its ease-in hides a late correction.

**Depth drift.** Depth is off, so nothing today. With depth on later, Game Design's rule (the band turns with the line) leaves `lineEnter` and `lineLeave` alone, but `WorldLanes.depthRoom` and `home`, which `_moveZ` reads, assume lanes laid along the line. Those stop meaning anything off a street.

## 3. Arriving at something

**Yes, in principle.** The arithmetic: with the pivot fixed, a place at distance `d` and bearing `φ` ends on the line at `d` from the pivot once the world has turned by `φ`. So at the send the planner knows both how far he must fly (`d`, by the existing square-root force rule, as `town.haulTarget` does) and how long the turn takes. Game Design's fit is 55° in a 1.6 s launch at 45°/s and 90° in 1.8 s at 60°/s. The prototype steers by feedback (`aimAt`: the bearing to the place, each tick); Research's 42 units off was on the ribbon, and I found no such figure for the turntable.

**The conflict with Game Design's pivot.** Its rule moves the pivot to the midpoint once the launcher leaves the ground, and a launcher can give chase. A moved pivot changes where the place lands on the line. Feedback fixes the bearing but can't fix distance along the line, since the flight's force is already spent. By arithmetic, for a place at 6,000 and a pivot moved 3,000 along the line:

| Bearing at the time | 30° | 60° | 90° |
| :--- | ---: | ---: | ---: |
| Place ends up further along the line by | 718 | 2,196 | 3,708 |

**So I ask for this rule:** an arrival's pivot stays on its planet point until the swing rests, whoever leaves it. Both fighters are still on the line, which still passes through the point. Sweep speed is `r × rate`, as Game Design has it; it's only a different `r`. Otherwise the arrival has to be a rough one, near the place and not at it: enough for a mountain, not for a chosen tower.

**What it needs from World:**

| Need | Why | Today |
| :--- | :--- | :--- |
| **A list of places in planet coordinates:** stable id, kind, buildings, wear, and **no people field**. Query by point and radius gives bearing and distance, cheaply | The candidates, at the launch's frame | `WorldEpoch.candidates` reads rings per bearing, within the old caps |
| **Places by plan** (Research's stage 3) | A city must be the same at any bearing. Game Design says the same | Layouts come from the chord: 12, 12, 8, 16 buildings on four chords, 15 of 32 matching by index |
| **`frameAt(n)`** and ground, biome, look, buildings through it, with no writes | Section 1's plans | None |
| **Buildings found by planet point,** ring `x` derived, stable slots | `aim`, `near`, `along` while turning. Re-indexing every tick is out | `S.buildings = keep + made` re-indexes (Simulation) |
| **Standing buildings and wear by planet cell** | The score's Personality term, which replaces people | None |
| **A street's bearing and offset at a point** | Section 4 | None |

**Also owed:** RL-213 stays open until Legal has read the score's terms (section 2), and QA's bands on what a swing reaches.

## 4. Stale depth and hits through buildings

**The baseline** (my counts, 2026-10-30, 20 AI matches a world, preview switches on):

| | Hand-made | Gen 1 | Gen 2 |
| :--- | ---: | ---: | ---: |
| Strikes across a depth gap over 30 | 4.1% | 0.02% | 1.1% |
| Strikes with a box on the line, or a fighter in one | 0 of 27,318 | 0 of 28,091 | 0 of 29,046 |
| Strikes with a tower in the row behind the pair | 1.5% | 3.7% | 2.9% |

**Without Option A, worse:**
- **He drifts with nothing to explain it.** Game Design has depth relative to the line, so a fighter left 1,200 behind stays 1,200 behind, while the building he was at swings away. He hangs in open air, fighting across a gap.
- **He slows the swing.** At 1,200 from the line, Game Design's limit of 75 units a second allows about 3.6°/s if he's standing. It's unclear whether distance from the pivot means along the line or in three axes: **a question for Game Design.**
- **A tower can enter the gap.** Rows are 187 from the plane, so a gap wider than that can have a face swept through it.

**With Option A, on the plane, in a brawl on a street: fine during the swing.** Turning about the midpoint keeps each fighter at the same distance from it, so nothing comes near that wasn't already near. A brawl's radius is 29 and a body about 37 more, against 187 to the nearest row (`lanes.json`, front street ±2.5 bh). By this arithmetic a pair up to about 300 apart never meets a face in the turn itself, wherever they stand on the street's centre.

**After the swing is the real change.** Nothing stops a body at a building with depth off, in a brawl, a rush or free flight; `SimFighter.contact` runs only with depth on. Unaimed buildings aren't checked in a flight either; `_checkHitSwept` is depth-on too. That's safe today because the plane is clear. A line tilted off a street runs into a block within:

| Tilt | 10° | 30° | 45° | 90° |
| :--- | ---: | ---: | ---: | ---: |
| Units to the row behind | 1,080 | 375 | 265 | 187 |

Brawl drift, rushes and zips then pass through walls, and blows land inside them. **A rough estimate, not a run:** about 1,400 strikes a match, times 1.5 to 3.7% near towers, times about half of a tilted line inside a block (17 of the band's 32 bh are blocks) gives **about 10 to 26 strikes a match with a wall in the way, against 0 now.** A villain hunting towns raises that on purpose, and human play will differ.

Game Design's row 9 makes "no standing face in the gap" a hard test, and its §3 lets faces pass through airborne fighters. **With swings on, those two conflict for a brawl in the air, which is most brawls.**

**What I'd do, in order:**
1. **Land Option A first,** as Game Design says.
2. **Treat a locked pair as standing for the face rule,** so a swing eases to rest 0.5 bh short of them. That needs no new code path beyond the rate law's.
3. **Inside a place, prefer a bearing along a street** (the score's Street term), so the plane is clear again where the swing rests. Outside places, any bearing. This keeps the law that makes the rest of the game safe, softly, at the cost of cities being approached along their own grid. It looks like choreography, and needs World's street query.
4. **For what's left, a flight's contact with depth off:** `_checkHitSwept` on a swung line, which is Game Design's "only his own flight makes one". That adds collateral, and the planner has to read it (chain limits by tier). Brawl drift into a wall needs a ruling: stop as at a face, or pass through.

**Where it gets better.** An arrival can put a building on the line, so `aimZ1` is 0, with no depth move and no stale gap. Game Design asks for this. A launch on an unswung line still uses the waypoint, so Option A stays. I'd retire the waypoint only for swung launches, at first.

## 5. What this doesn't know

- **Nothing here has run.** Section 4's estimate is arithmetic on AI counts; only a prototype with real buildings or a scratch build would give a real number. Research's prototype has no collision or lanes.
- **The field's read price at planner rates.** `predictFlight` alone is up to 240 reads a candidate.
- **Whether a launcher chasing away from a fixed pivot looks right.** The look gate's question.
- **Beam plan order** in section 1, and which other director files read `aimB` or a column between ticks. I read the ones named, not all 14 files that read the ground.
- **Scoring weights.** None tuned; the 6 to 12 a match needs QA runs.
- **Whether reading buildings in place of people holds the civilian band.** People live in buildings, so the two should track, but nothing has measured it, and the hero's lure was what cut collateral in the prototype.
