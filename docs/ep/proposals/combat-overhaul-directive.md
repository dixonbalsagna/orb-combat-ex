# Combat overhaul directive: beams you can read, shots that fly, fights that go somewhere

- **Who:** Orb's stand-in, with the EP, in the hour before the reset of 2026-11-27.
- **For:** the EP, on Orb's notes after playing build 0.1.1 (`docs/ep/vision.md:1932-1938`) and the overhaul asks of the same evening (`:1925-1930`).
- **Standing:** a design recommendation. No code was written and nothing was run. Every number is a starting point for Game Design to rule and for Orb to judge in a clip. "BH" is one body height, 75 units; a tick is a sixtieth of a second.
- **How:** three Opus readers took the current rules from the code and data (about 0.36M tokens); I checked the EP's two beam facts by hand. The design is mine.

## The one idea

**Physics decides whether and where. The director decides how it plays.**

Today the game decides a beam's result with a timer and a tap, decides a homing shot's arrival before it is fired, and lets any attack cross any gap in a fixed time. That is why the three things Orb named feel wrong: a dodge that costs nothing, a struggle nobody taught, and a charge that spacing cannot protect. The fix is the same each time: let the thing travel, let touching it be what counts, and keep the director for what it is good at, which is staging what happens after contact (the launch, the struggle, the slam into a building).

That is the "healthy hybrid". Nothing below takes choreography away from the director. It takes away three scripted outcomes and replaces them with things a player can see coming.

## 1. Beams

### What exists

| Rule today | Where |
| :--- | :--- |
| A beam's result is decided once, on the tick its front reaches the target. Standing in the drawn beam does nothing; flying out of it does nothing. Only a tap's timing counts | `sim/director/beamplay.gd` (`opReach`); `sim/director/beam.gd:680-706` carves ground only |
| A dodge tap from 18 ticks before the front to 2 after is a DODGE. It costs no health and no energy. The only sign is a "DODGED" banner | `data/director/interrupts.json:314-315`; `beam.gd:184-205` |
| A struggle is 15 pulses, one every 20 ticks. A press within 4 ticks of a pulse pushes; any other press cancels your next good one. The start position comes from tier, energy, a hidden random 0 to 16, and two more terms | `interrupts.json:273` (`beamStruggle`); `beam.gd:207`, `:244-257`, `:476-505` |
| The computer hits the pulse 40, 65 or 85 times in 100 by level | `beam.gd:273-284` |
| The struggle's meter is a line between the fighters' hands with a diamond and a closing ring | `ui/widgets/ui_tug.gd` |
| A beam that travels and hits only what it touches is already designed and ruled: front speed 6,000 units a second plus 2,400 a stage, 15 degrees of aim help, the ground stops it, firing plants the shooter | `docs/ep/proposals/beam-in-space-trial-design.html`; `docs/design/beam-physics.md:101-115`. Built in scratch only |

So Orb's read is exact on both counts. The dodge is a free third of a second. The struggle is a rhythm game with a four-tick window that nothing explains.

### The recommendation: dodging stays cheap, and the beam becomes real

Orb offered two fixes: make the dodge riskier, or keep it cheap and make beams reliable. Do the second, and the first follows by itself.

1. **Touch is damage.** Adopt the beam-in-space model as the beam. The front flies along the aimed line at its ruled speed; behind it the beam stays for its hold time. A fighter takes damage on every tick any part of their body is inside it.
   - Start: 40% of today's hit on the front's touch (with today's hit-stop, so it lands as a blow), the other 60% spread evenly over the hold. Someone who stands in the whole beam takes exactly what a HIT does today.
   - The scripted tap window (`dodgeBefore`, `dodgeAfter`) goes away. So does the "DODGED" banner, except when no damage at all was taken.
2. **The dodge is the dash you already have.** LT and a direction moves you; you are out when your body is out. It costs nothing extra and it has no protection against a beam.
   - Clearing a beam takes about 6 to 10 ticks of dash (the beam is 110 to 210 units wide and the dash builds from 1,000 units a second).
   - So from far away you can see the front coming and step out clean. Up close the front arrives in 3 to 10 ticks and you cannot react: you have to read the gather (30 to 60 ticks, already ruled) and move before the release.
   - Fly out late and you keep the front's 40% plus every tick you stayed. That is Orb's "tank it and leave at the last second", now with a price you can see.
3. **You see the damage.** While a fighter is inside a beam their health drains visibly tick by tick, with its own sound. No new marker on the fighter: the existing hit effects and the meter are enough.
4. **The shooter can follow, slowly.** While holding the beam the shooter may turn it with the right stick at a capped rate: start at 24 degrees a second for the plain beam, 12 for the top stage. A dash beats it easily; a slow drift does not.

### The struggle

**How it starts, on purpose.** Two beam fronts that touch start a struggle where they meet. To make that happen, fire back along an incoming beam: the same 15 degrees of aim help pulls your beam onto theirs. The window is the incoming beam's travel time, so the further apart you are, the easier a clash is to make. A heavy blast into a beam still starts one at a disadvantage, as today.

**Who is winning: the clash point is the meter.** The bright knot where the beams meet moves toward the loser. That is the whole display. I would retire the line, diamond and ring between the fighters (`ui_tug.gd`): they sit between the fighters, which is against Orb's rule of 2026-10-18, and the knot says the same thing.

**Why: three things, each visible.**
- **Power.** The thicker, brighter beam started ahead. Drop the hidden random from the start position (0 to 16 today, down to 0 to 4) so the start is what it looks like.
- **Pushing.** Hold the right stick toward your rival to push. Holding is steady pressure: if both hold, power decides; if you let the stick go, you slide back. This is new, and it is what makes the struggle make sense to someone who has never been told the rule.
- **Pulses.** A pulse of light runs down your beam from your hands to the knot. Flick the stick toward your rival as it arrives and the knot jumps. That is today's surge, made visible, with a rumble tick on each arrival.

**Numbers to start from** (today's in brackets): 8 pulses (15), one every 30 ticks (20), so four seconds at two a second. A good flick is within 6 ticks (4), a sharp one within 3 (2). The first two pulses are a count-in: a wrong press there costs nothing. After that a stray still cancels your next surge, as Orb ruled for the finisher on 2026-10-04: timing wins, mashing does not. Steady hold: 0.02 of the line per pulse. Easy hits 25 pulses in 100 (40) and never sharply.

**What to check in the clip:** a first-time player who only holds the stick toward the rival beats Easy about half the time, and one who also catches half the pulses wins clearly.

## 2. The ballistic hybrid

### What exists

`sim/core/shots.gd` already steps every shot's position and velocity each tick, inside the hashed state. It is nearly a physics body already. What is scripted:

| Kind | Today | Where |
| :--- | :--- | :--- |
| Straight shots (bolt, shard, charged) | Constant speed, no gravity. Stopped by ground, water, buildings | `shots.gd:579-606`; `data/fight/shots.json` |
| Seeking shots | Cover a fixed share of the gap each tick, so they arrive on a set tick whatever the target does. Ground and water do not stop them | `shots.gd:586-596`, `:8-9` |
| Lobs | A fixed-time arc to a point chosen at fire time | same |
| Launched fighters | Truly ballistic: gravity 1,000, drag, water skim, ground contact | `sim/core/fighter.gd:105-150` |
| Beams | Decided, not simulated | `beam.gd:6-8` |

### The model

Every shot is a body with a position, a velocity and four numbers in `data/fight/shots.json`: **gravity share** (0 for pure energy, up to 1), **drag**, **turn rate** (0 unless it seeks) and **touch radius**. Each tick: gravity, drag, then a seeker turns its velocity toward its target by at most its turn rate; then move; then test ground, water, buildings and fighters by touch. An impact makes the crater its energy earns, through the crater code that exists.

**Aimed, always.** A shot leaves along the right stick's line. With the stick at rest, the game solves the lead for the target's current speed and aims there, with the beam's 15 degrees of help. So a target that stands still or flies in a straight line is hit, and a target that changes direction after the shot leaves is missed. That keeps pillar 3 ("never out of range") as a real gamble, not a guarantee.

**Order of conversion:**

| Step | Kind | Change | Why this order |
| ---: | :--- | :--- | :--- |
| 1 | Seeking shots | Replace "arrives on a set tick" with a turn rate. Start at 4 degrees a tick at 60 units a tick (a turning circle of about 860 units), stopped by ground and water like the rest | It is the scripted rule Orb named, and the smallest change |
| 2 | Lobs | A real arc under the same gravity as a launched fighter, with a solved launch angle | Reuses `fighter.gd`'s gravity; lobs become skill shots over cover |
| 3 | Charged shot | A little gravity (start 0.15), a heavy impact and a crater sized by its energy | The first shot whose miss changes the ground |
| 4 | Beams | The stream in section 1: each tick the muzzle emits one segment that flies straight at the front's speed; the beam is the chain of segments; a hit is a body within its width of any segment | Largest; depends on the beam trial landing |
| 5 | Mines and deflected shots | Knocked by blasts; a deflection is a reflection off the guard, not a seeded arc | Last: nice, not needed |

Bolts and shards stay straight with no gravity. They are already honest.

**Deterministic and fixed-step.** All of it lives in `sim/core/`, in float64 with the sim's own trig, stepped once a tick, with no new random draws. Each step sits behind a data switch that is off (`shots.json`, a `ballistic` block; `interrupts.json`, `beamPlays.touch`), so the golden record does not move until a window is opened for it. Segments are capped (a beam's hold time in ticks, at most 60 per beam) so the state has a fixed worst size.

## 3. Fleeing

### What exists

Flight tops out at 3,500 units a second and the dash reaches the same speed (`data/fight/power.json:108`, `:113`). A press closes at 4,000, so attacks do catch a runner, but the runner pays nothing: energy returns at 5 a second anywhere (`sim/core/fighter.gd:693`), and the stamina meter that was meant to price flight is specified but not built (`docs/ep/proposals/energy-stamina-body-build-spec.md`; no `data/fight/vitals.json`).

### Four rules

1. **Running is paid for in wind.** Build the one piece of the stamina spec that prices flight: holding LT drains it, a full meter in about 17 seconds. When it is empty, flight is 20% slower, as the spec says.
2. **Wind comes back when you stand your ground, not when you get away.** The spec says stamina refills "only away from the fight". That rewards exactly what Orb is complaining about. Change it: it refills while the gap is not growing by your own flight.
3. **No energy for a turned back.** While you are beyond mid range (12.5 BH) and the gap is growing by your own flight, your energy does not return.
4. **A turned back is open.** If the gap has grown by your own flight for 90 ticks, the next blow or shot that reaches you counts as a counter-hit (start: 1.25 times damage) and cannot be guarded. With section 2, a straight line away from a seeking shot is also the worst dodge there is.

The escape stance stays the honest way to disengage: a gamble with a price. Rules 1 to 4 make flying away without it the bad version of the same bet.

## 4. Grab and interrupted charges

### What exists

| Rule today | Where |
| :--- | :--- |
| Grab: tap A in a brawl, reach 0.6 BH, a 10-tick tell, then a clinch of up to 60 ticks and a timed throw. It stops a charge and a guard, and ignores a charge's armour | `data/director/interrupts.json:680-689`; `sim/director/grapple.gd` |
| After a grab: 90 ticks before another, 120 before the same target. A hold-break is worth one and a half throws and skips the 120 | `interrupts.json:685-688` |
| The computer answers your second held heavy 30 times in 100 on Easy, your third 65. If it can reach you before your charge is full it flies in and grabs | `data/director/ai.json:42`, `:59`, `:92` |
| A heavy charge is full at tick 44. A light does not stop it; a medium stops it before tick 20; a grab, a heavy or a beam always does | `interrupts.json:445-470`; `sim/director/brawl.gd:1361-1371` |
| Any press closes the gap fast: from mid range in 3 to 20 ticks at 4,000 units a second, from far in at most 90 | `interrupts.json:79-82` |
| The defender can give ground only 2.4 BH | `interrupts.json:488` |

So spacing cannot protect a charge: everything arrives in under half the charge's time, and the grab walks through its armour. And the stall Orb felt is the rule working as written: the computer flies in, the clinch freezes both fighters for up to a second, and it can come again a second and a half later.

Orb chose the grab's shape (a catch into a clinch, `docs/combat/grapple-hybrid.md:5`). Keep the shape. Change what it beats and how often it comes.

### Grab

1. **A full charge beats a grab.** If the charge is full and is released during the grab's 10-tick tell, the charge lands as a counter-hit. Before it is full, a grab still stops the wind-up.
2. **No flying grab.** A grab only starts from inside its reach. A fighter who closes distance arrives with a blow, never with a grab. This one line removes the computer's fly-in.
3. **The clinch is short and ends in motion.** 36 ticks at most (60). A throw sends the fighters apart at once, so the fight is moving again.
4. **It cannot come twice.** 180 ticks before another grab (90), 240 before the same target (120), and a hold-break counts like any throw (worth 1.0, not 1.5).
5. **The computer slips more than it grabs.** Answering a held charge: Easy 15 and 40 in 100 (30 and 65), Medium 30 and 60 (40 and 90), and never a grab in answer to two holds running.

### Charges: spacing and timing

1. **Closing takes time you can see.** Mid-range lunge 2,600 units a second (4,000), never under 8 ticks (3). From the edge of mid range that is about 22 ticks, not 14.
2. **Room to back off.** The defender may give ground 4 BH (2.4).
3. **Once a charge is full, only a heavy or a beam stops a charge.** Not a grab (rule 1 above), not two quick lights.
4. **Timing is rewarded.** A release within 6 ticks of the charge going full reaches half a body height further.

Together: a charge started with about 8 BH of room finishes before a lunge can stop it; one started at arm's length does not. That is the spacing Orb asked for, and it still honours pillar 3: attacks always arrive, but arriving takes a time the charger can buy with distance.

## 5. The fight's angle and the camera

### What exists

- **Two systems turn the world.** A calm-moment turn of 2.5 to 10 degrees, at most four a fight, a minute apart (`sim/director/calm.gd`; `data/director/interrupts.json:597-608`). And the turntable Orb chose on 2026-10-31, with swings of 16 to 180 degrees on a launch or a chase (`sim/director/swing.gd`; `data/fight/swing.json`). The reader could not confirm which one build 0.1.1 ran. If only the calm turn ran, "placebo" is what it would feel like. **The first job is to find out.**
- **The player cannot steer it,** by a written rule: "never by a control" (`docs/world/ring-any-angle/game-design.md:7`). The director scores what a turn brings into view (a city 3, a town 1).
- **Camera.** The screen splits when a fighter would be drawn shorter than 5.5% of its height (`render/camera/camera_params.gd:7`); "sooner" is 7.7% and is built behind a switch (`ui/data/features.json:34`). A soft shadow is drawn on the ground under each fighter. Nothing keeps the ground or the horizon in the picture.

### Taking the fight somewhere

Keep the rule that no button turns the world. Make the turn follow what the player does and can see:

1. **A launch swings toward the biggest thing in view.** When you launch your rival, the turntable swings toward the highest-scoring place visible behind the fight, so the city you can see in the background is where they land. Raise a visible city's score so it wins unless the launch is aimed elsewhere.
2. **A swing is never subtle.** At least 20 degrees, or it does not happen.
3. **The launch's aim chooses near or far.** The winner's stick already aims a launch up or down. Up sends the fight deeper toward the far place; down keeps it here.
4. **The calm turn steps aside** on any world where the turntable runs, so there is one system and one feel.

### Never lost

No markers, nothing between the fighters, no fades. Four rules for Camera:

1. **The ground stays in the picture.** While a fighter is within 12 BH of the ground, that fighter's view keeps the ground line and their shadow in frame.
2. **High up, the horizon stays in the picture.** Above that, the view keeps the horizon or the cloud deck in frame, so there is always a level line to read height against.
3. **The picture never outruns the eye.** Outside a launch, the view moves no faster than about one screen width a second. Anything faster splits the screen instead.
4. **Split sooner by default in Orb's next build** (7.7%), for Orb to judge in play, as they said they expect.

Pace is the other half: sections 3 and 4 slow the two fastest things in a fight (the free run and the instant lunge), which is most of what makes a player lose their place.

## 6. Order of work

| # | Brief | Director | Depends on |
| ---: | :--- | :--- | :--- |
| 1 | Grab and charge retune (section 4), data first | Game Design for the numbers; Encounter for `ai.json` and the two code rules; Combat reviews against the grapple notes | Nothing |
| 2 | The beam you can read (section 1) | Encounter (`beam.gd`, `beamplay.gd`); Game Design; VFX for the knot and pulses; UI retires the tug widget; Audio for the drain and pulse sounds | The beam-in-space scratch landed behind a switch |
| 3 | Which turn ran, then the visible swing and the never-lost rules (section 5) | Encounter and World for the swing; Camera for the four rules | Nothing |
| 4 | Ballistic shots, steps 1 to 3 (section 2) | Simulation (`shots.gd`); Game Design | Nothing; lands off |
| 5 | Wind and the flee rules (section 3) | Simulation and Game Design, from the stamina spec | Brief 1 judged |
| 6 | The beam as a stream of segments (section 2, step 4) | Simulation with Encounter | Briefs 2 and 4 |

Each change sits behind a switch that is off on main and on in a private build for Orb, as the trials do. Anything Orb keeps goes into the next golden window together.

### The first three briefs

**Brief 1: grab and charges.**
- *Acceptance:* a full charge released in a grab's tell lands and the grab does not; no grab begins from outside 0.6 BH (a check row over 200 computer matches finds none); no two grabs by one fighter inside 180 ticks; on Easy, a player who holds three heavies in a row is grabbed in fewer than 15 of 100 tries; a charge begun at 8 BH completes against a lunge begun on the same tick; a charge begun at 2 BH does not; match length on Easy and Medium stays within QA's band.
- *Clip for Orb:* the same thirty seconds twice, before and after, with the buttons drawn: charge a heavy at arm's length, then with room; the computer's answer each time. One question: "Does charging feel earned now?"

**Brief 2: the beam you can read.**
- *Acceptance:* a fighter who never enters the beam takes nothing; one who stands in all of it takes today's hit to within 2%; one who leaves halfway takes between 40% and 75%; health visibly falls on each tick inside; two beams aimed within 15 degrees of each other always start a struggle and never pass through; a script that only holds the stick beats Easy between 40 and 60 times in 100; a script that floods presses does no better than one that only holds; replays reproduce.
- *Clip for Orb:* three moments with inputs drawn: stepping out of a beam early (no damage), late (part), and a struggle won by holding and catching pulses. One question: "Can you tell who is winning, and why?"

**Brief 3: the angle and the camera.**
- *Acceptance:* a written answer to which turn system ran in 0.1.1; with the turntable on, a launch with a city in view ends with that city in the fight's plane in at least 8 of 10 seeded tries; no swing under 20 degrees; in a two-minute flight test over open ocean the ground line or the horizon is in each view on every frame; the view's speed stays under the cap outside launches; the side-by-side against the reference build is taken (the look gate).
- *Clip for Orb:* one launch into a visible city; ten seconds of flight over open water, old camera beside new. One question: "Did you know where you were the whole time?"

## 7. Questions for Orb

At most three, each one line, each with what I think Orb would pick.

1. **Beams.** "A beam hurts for every moment you are inside it. Step out early and it misses; step out late and you have taken part of it. Dodging stays free. Go?" *Recommended: yes.* It is your second option, and it makes the first unnecessary.
2. **Struggles.** "In a struggle, hold the right stick toward your rival to push, and flick it each time a pulse running down your beam reaches the clash. Holding alone keeps you in it; catching pulses wins it. Go, or should pushing be something else?" *Recommended: go.* It keeps your ruling that timing beats mashing and gives a newcomer something obvious to do.
3. **Taking the fight to the city.** "When you launch someone, the world swings clearly toward the biggest thing you can see behind the fight, and aiming the launch up sends it there. No new button. Try that first, or do you want a way to choose the place yourself?" *Recommended: try it first.*

## Four things for the EP, not for Orb

- **The stamina spec and the flee complaint pull opposite ways** on one line (refill "only away from the fight"). Section 3, rule 2 changes it; Game Design should rule.
- **The struggle's widget sits between the fighters.** If it ships in Orb's build today it is against the rule of 2026-10-18 already.
- **`docs/camera/split-screen.md:9` still says the merge "ends in a dissolve".** Worth a check that the shipped merge does not.
- **The hold-break bonus of 2026-11-21** works against the grapple notes' own rule that grabs cannot be spammed. Brief 1 undoes it.

## What was not read

`grapple.gd`, `ai.gd` and `zip.gd` in full; the stamina spec past its first sections; the beam trial's later sections; the camera park patches; how the HUD draws the dodge cue. No number here has been played. Durations and percentages in the acceptance lists are targets to rule, not measurements.
