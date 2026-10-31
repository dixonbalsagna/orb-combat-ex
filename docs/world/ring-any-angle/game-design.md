# The ring at any angle: what a swing does in play

Owner: Game Design, by the EP's brief. Rulings for the turntable, 2026-10-31; nothing is built or measured by me. Every number is a first value, and the arithmetic is mine for World and Camera to check. Orb's words: "the angle the fighters fight along the surface of the planet should be ready to dynamically adjust and change determined by the fight choreographer and any other necessary game system", with the fighters "always on the same relative band". After trying the prototype: "the turntable approach in E and E2 seems to be closest to my vision." So **the world visibly swings round the fighters.**

**This replaces my page of 2026-10-30,** which ruled a large step hidden at a launch and asked whether a visible swing was Orb's picture. It is. What stays from it: a launch is the best moment, every big move should arrive at something, and a player steers through the fight, never by a control.

## The rules in short

1. **A swing changes what the fight is in front of, and nothing in the fight.** Fighters, gaps, velocities and the stick all work along the line exactly as they do now. The world turns behind them.
2. **It never refuses, it slows.** A swing's rate falls with the gap, so no gap needs a limit: `rate = min(rate for its cause, sweep limit / distance from the pivot)`.
3. **The pivot is the fighter on the ground.** Only a standing fighter can feel the ground move, so he's the one kept still.
4. **It runs in a launch, a chase, a form's pause and, slowly, a brawl. It stops for a beam.**

## 1. The six hard tests, against a visible swing

| # | The test (2026-10-30) | Now | Why |
| :--- | :--- | :--- | :--- |
| 1 | The rival stays on the same side of the screen | **Kept** | It needs no effort: the order along the line is untouched at any angle. A swing past 180° doesn't flip anyone |
| 2 | Everything in reach unchanged | **Amended: the rival and his reach are exact. The ground moves, at a walking pace at most, and a face never arrives.** | Written for an instant step, where the ground would jump. A swing can't keep the ground the same, because a turn is new ground, but it can make it slow. In numbers: a standing fighter's ground moves at most 75 units a second (1 bh a second, §3), and a swing eases to rest before a building's face reaches him |
| 3 | Attacks close as before | **Kept** | The gap is along the line, and a swing doesn't touch it. Pillar 3 holds with no new rule |
| 4 | A visible cause; never in a brawl | **Split. "A visible cause" is withdrawn, and "never in a brawl" becomes "slowly in a brawl".** | A swing is its own visible cause. The reason for the brawl ban was surroundings jumping under a pressing player, and a swing doesn't jump. What's left is distraction, which is a matter of rate (§2). **Kept from it: a swing never starts from a press, so it can't be used as a dodge** |
| 5 | No marker, dissolve or fade; instant change justified | **Kept, and tightened: no instant change at all.** A swing eases in and out, per Orb's rule on the camera | The whole point is that it's seen |
| 6 | The world remembers | **Kept, and it's now on screen.** The crater he just dug has to swing away with the ground, and a tower has to keep its damage as it goes | A mark that changes in view is a bug the player sees at once |
| 7 | **New: the world turns as a solid thing** | **Added** | The prototype re-lays the ground from a field each tick, and its pop figure is large (356 units on E, 115 on E2). Ground that morphs instead of rotating fails this, whatever the numbers. The look gate decides, and Rendering and World own it |

## 2. What fires it, how fast, how far, how often

Rates are at the peak, on Camera's smootherstep (§9). The prototype's 30°/s is a starting number; a launch needs more.

| Moment | Runs? | Fires on | Peak rate | How far | How often in a 6 to 8 minute match |
| :--- | :--- | :--- | ---: | :--- | ---: |
| **A launch** | **Yes, the main use** | The kick, once the hit-stop ends, when the planner's arrival is off to one side. **It rests at least 0.35 s before contact** (Camera's `LAND_HOLD`), so he meets a still world and the planner's aim holds | **100°/s, waiting on Orb's slider (§9)** | Up to 180°, as far as his flight has time for: about 53° per second of flight at 100°/s | 2 to 5 |
| **A chase, a flee, a zip away** | **Yes** | The chase's or the flee's start. The hero leads toward interesting empty ground, the villain hunts toward towns. Later small corrections are fine, as both are in the air | 45°/s | Any | 1 to 3 |
| **A form's pause** | **Yes** | The pause, as the camera's orbit. Nothing moves, so it's the easiest place | 30°/s | Up to 90° | 1 to 3 |
| **A brawl, a rally, a knock-back** | **Yes, slowly** | Nothing else has fired for about 45 s and something worth seeing lies within 60°. A swing running when a chase catches up eases down to this rate rather than stopping | **10°/s** | Up to 60° | 2 to 4 |
| **A beam** | **No** | A swing eases to rest in the beam's tell (about 33 ticks, so the ease fits) and stays there until the beam is gone. Otherwise the groove curves, the blast misses what the plan aimed at, and the damage inset can't credit it. Shots and mines are unaffected | 0 | | |
| **A beam struggle** | **Not at first** | It's an obvious set piece for a slow orbit, for Orb's look later. The rooted pair may stand far apart, so it would hardly turn anyway | 0 | | |
| **The hit-stop, a finisher, a KO, the intro, a grab's set piece** | **No** | Frozen in a hit-stop (live ticks only), and the camera owns the others | 0 | | |

- **How often, in total: 6 to 12 swings a match, about 10 to 15% of fight time.** This comes from a score that falls with how recent the last swing was, not a cap, and Orb's "bigger or more often" after seeing it moves the score. **If Performance's budget can't carry that, the order to cut is brawls first, then form pauses, then chases.** A launch's swing is the last to go.
- **Every launch or chase swing arrives at something:** the planner scores the arrival. A brawl's swing brings something into view. A swing to nothing isn't taken.
- **The ceilings are Camera's (§9):** 150°/s with a launch, 60°/s otherwise.
- **Reduced motion:** a setup flag, closed in §9.
- **Long trips are its best home.** A swing during a long flight is also the cheapest answer I have to Orb's "experience of speed and power": the far land wheeling past as he crosses it.

**The pivot.** A standing fighter if exactly one is standing: his ground sweeps nothing. The midpoint if both or neither are. A change of pivot leaves everything where it is and only changes how it moves next, so it eases over 20 ticks and never pops. **A swing with an arrival keeps its pivot on one planet point until it rests (§8).**

## 3. A far fighter's ground

A fighter at distance `r` from the pivot sees ground move at `r × rate` (over a whole turn, the chord `s sin(θ/2)` for a pair turning about their midpoint). **So I replace a limit on the angle with a limit on that speed:**

| | Sweep limit | Why |
| :--- | ---: | :--- |
| **Standing:** on the ground, on the water's floor, down, buried, skidding | **75 units a second (1 bh a second)** | About what a fighter's feet can hide. Faster reads as him skating sideways |
| **Airborne** | **10,000 units a second (133 bh a second)** | Flat out, the fastest a fighter is ever seen to cross ground, so the world adds no new speed to the picture. Raised from 6,000 for §9: at launch speed it would have cut the swing just as it peaks |

**So what gap allows a swing? Any. It just slows:**

| Both standing, gap | Fastest rate | | One standing, gap to the other | Fastest rate |
| ---: | ---: | | ---: | ---: |
| 150 | 57°/s | | up to 5,700 | 100°/s |
| 300 | 29°/s | | 15,000 | 38°/s |
| 1,000 | 8.6°/s | | 30,000 | 19°/s |
| 3,000 | 2.9°/s | | | |
| 6,000 | 1.4°/s | | | |

- **Under 2°/s it holds still,** since it wouldn't read as a swing: two standing fighters over about 4,300 apart. That's a held swing rather than a refused one, and it carries on once one takes off. It's also why a launch's swing has to finish before he lands.
- **This withdraws the 300 and 450-unit ground rules:** those limited a jump, and nothing jumps now.
- **Ground that rises under a standing fighter** is handled by the rule for a waded body (`rulings-2026-10-30.md` row 9): at most 7.5 units a tick, and he keeps the stick. At 75 units a second of sweep, that only bites on a cliff.
- **A building's face and a standing fighter, or a locked pair in the air (§8):** the swing eases to rest 0.5 bh short (`depth.md` §2's clearance). The director should pick a bearing that avoids it, and this is the backstop.
- **A building's face and an airborne fighter who isn't in an exchange:** it passes through him with no damage and no stop, shown with the existing see-through. **A sweep is never a contact, and only his own flight makes one.** At up to 6,000 units a second it would otherwise be a free slam from nobody's blow. QA counts these, because that's what would make this look wrong.

## 4. A held stick

**It means exactly what it meant.** Stick right is screen right, along the line. **The rival stays on the same side of the screen,** always. A swing adds no velocity, no push and no drift, and his velocity along the line is untouched, so holding right through a swing carries him along a curve on the planet without his doing anything or feeling a tug. Altitude, the right stick and every aim read as before. **No control steers a swing:** the stick's kind still wins for a launch (`stickWins`), and where he drags or flees a fight still leans it.

## 5. The relative band, and the depth ruling

**Option A stands** (`rulings-2026-10-30f.md` row 9), and **it should land before any of this.** With depth off, a fighter eases back to the plane after every flight at 20 units a tick, eased in and out, so 60 ticks for the largest gap of 1,200 and 15 for 300. Burials, holds and set pieces delay it. No snap: an attacker's close takes him to an off-plane target's depth. He passes through a face with no damage, with the existing see-through. QA's row: gaps over 30 under 0.5% of strikes, the largest at most 75, no standing face in the gap as a hard test, eases through faces reported.

**The relative band under a swing:** the line through the pair is the band's centre, and the band turns with it. A fighter's depth is relative to that line, so a swing never changes it, and the ease in row 9 runs through a swing unchanged.

**What a swing later makes unnecessary.** The hits came from building-aimed flights moving a fighter 1,200 in depth. A swing can bring the building onto the line instead, with no depth move at all. Encounter should plan to retire those depth moves once swings are on. Option A stays as the safety net, and it's needed now.

## 6. Pillars, and what I withdraw

**Pillar 1, the planet is the arena:** truer. It's now visibly a planet. Flying on returns you to where you started only if nothing swung in between, and I accept that. **Pillar 3, never out of range:** untouched, because the gap is along the line and the pair are always on one line. It must never become a dodge, hence test 4.

| `rulings-2026-10-19b.md` | Now |
| :--- | :--- |
| 1a, calm ticks only, never in a brawl, under a hard cut | **Withdrawn,** for swings. No cut at all. Never under a dissolve or wipe stays |
| 1b, at most 10°, 4 a fight, 60 s apart, 40° of drift | **Withdrawn:** the falling score and §3's sweep limit replace them |
| 1c, leans the way the fight was pushed; no button | **Kept** |
| 1d, off until built and played | **Kept** |
| 1e, the hero may bring a city into view | **Overturned:** a swing decides where the fight goes, so his care counts in full |
| 1f, 1h, the ground rules | **Withdrawn** (§3) |
| 2d, prefers the opponent's ground | **Kept** |
| 3d, a launch carries at most a sixth of the loop | **Kept** |

**Still bounded by bands that exist:** civilians lost at the KO 12 to 30%, and structures levelled by tier. No reward for reaching people. **Legal still owes a read,** because the choreographer takes a fight toward people on purpose.

## 7. What this rests on

- **The cost.** Research has the turntable an order of magnitude dearer than the ribbon, and over budget on the laptop while turning (E2's p99 is 46 ms against a 50 ms frame limit and a 0.2 ms read budget; E is 270 ms). My 10 to 15% of fight time assumes that gets solved. **If it can't, launches only, at about 12 s a match, is the smallest version that's still Orb's picture.**
- **Places by plan.** A swing through a town needs buildings that stay themselves at any angle. Until then swings are honest only over open ground, and buildings are the thing Orb likes most.
- **Netcode's lead.** Research's 20-tick lead makes a bend final before it's laid, and a launch's stop is only 12 to 16 ticks, so a swing's ask may have to come a few ticks before the blow lands. Netcode's to say.
- **Nobody has seen real fighters in a swing.** The prototype has bars in scripted fights.

**For Orb, one question, once a swing can be seen with real fighters:** should the world swing while you're fighting up close, or only when the fight is flying? It decides the most cost: a pressing player's brawls are about half of fight time. My first value is slowly, at 10°/s, and it's the first thing I'd cut.

## 8. Addendum: Encounter's questions (`encounter.md`), 2026-10-31

**The largest finding: once the line tilts, walls have to be real.** No code stops a body at a building with depth off, which is safe only because World builds nothing on the plane. A tilted line reaches a block within 187 to 1,080 units, and Encounter's rough estimate is 10 to 26 strikes a match with a wall in the way, against 0 now. Orb has already objected to exactly that picture, and a villain hunting towns makes it worse on purpose. **So the rules I wrote for depth (`depth.md` §2 and §4) apply on any swung line, with depth on or off, in this order:**

1. **Rest on a street where there's a street** (question 3), so that most of the time the plane is clear again.
2. **What's left meets a wall as a wall.** Drift stops and slides (question 4). A flight makes contact, which is Encounter's `_checkHitSwept` on a swung line, and the planner reads it through the chain limits by tier.
3. **An attack with a wall between still closes,** in its own time and never misses (`depth.md` §4). It ploughs through where the launch ladder says that fighter's power can, and otherwise goes over the top. A blow lands with both on the same side.
4. **"No standing face in the gap" stays a hard test** for every blow, and QA's row now reads with swings on.

This costs collateral, which the existing bands bound, and a real collision path with depth off, which is L3's work in scratch. It also gives the fight what Orb asked for from the streets: a brawl that has to work with the buildings it's among. **The fallback, if that cost can't be met at first:** inside a place, a swing must rest on a street's bearing, as a hard rule rather than a score, which keeps the wall count near 0 but limits how a city can be approached.

| # | The question | The ruling | Owner |
| :--- | :--- | :--- | :--- |
| 1 | **Should an arrival's pivot stay on its planet point until the swing rests?** | **Yes,** for any swing with an arrival, whoever leaves that point. The arithmetic is decisive: 718 to 3,708 units off at 6,000 can't be corrected once the force is spent, and "the swing arrives at something" is the rule the page rests on. The point starts where §2 says: the standing fighter's feet, or the midpoint. **The sweep limits still win.** If someone standing ends up far from the pivot, the rate falls, the arrival is late, and he lands somewhere ordinary. Nothing pops to save an aim. A swing with no arrival keeps §2's easing pivot. Whether a launcher chasing away from a fixed pivot looks right is for the look gate | Encounter, World |
| 2 | **Row 9's hard test against §3's pass-through, in an aired brawl** | **Encounter's fix: a locked pair counts as standing, for faces only.** Locked means they're exchanging blows: a brawl, a rally or a grab. The swing eases to rest 0.5 bh short of them. The sweep limit stays by whether they're on the ground, which at a brawl's radius makes little difference. The pass-through in §3 is now only for a body not in an exchange: a launched fighter, or a chaser who hasn't closed | Encounter, World |
| 3 | **A street-alignment score inside places** | **Yes, and weighted to usually win inside a place.** It's the cheapest way to keep the plane clear, and a city approached along its own streets looks directed. It applies only inside a place, and it's a score, so a great arrival can still beat it. It needs World's street query | Encounter, World |
| 4 | **Brawl drift into a wall** | **It stops, as `depth.md` §2 already says:** the part of the motion running into the face stops, the rest slides on, and in a corner the pair go up and over. It does no damage, and gives no bonus or pin. Passing through is what Orb objected to | Encounter, Simulation |
| 5 | **Is distance from the pivot along the line, or in three axes?** | **On the ground plan: along the line and in depth, never altitude.** The turn is about a vertical axis, so height changes nothing about how fast the ground moves under him. With Option A landed, depth is near 0 and this is nearly the same as along the line. Option A remains first: a fighter left 1,200 off the line is exactly the 3.6°/s case Encounter found | World |

## 9. Addendum: Camera's section (`camera.md`), 2026-10-31

| # | The conflict | The ruling | Owner |
| :--- | :--- | :--- | :--- |
| 1 | **Rate: Camera's 150°/s with a launch, against my 60** | **My 60 is withdrawn. 150°/s is the ceiling, and the launch's peak waits for Orb's answer on the slider** (`proto-v2`, which offers 15, 45 and 120). **Until then, builds use 100°/s.** My 60 rested on a guessed lens, and Camera has the real one: far land moves 1.05 widths a second per radian a second. So 100°/s is about 0.03 of the width a tick, which is the limit the camera keeps under Reduce flashing. That matters because **the rate is the sim's and shared, so a Reduce flashing player can't be given a slower one.** Anything over about 100 needs a flash reading for them, reported rather than chased while flash work is paused. Anything else stays at my rates, under Camera's ceiling of 60. **Also adopted from Camera:** smootherstep as the shape, so the peak is `1.875 × θ / T`; dead still through the hit-stop; rest at least 0.35 s before contact. **"A swing can't outlast its flight" stands,** as I'd ruled: about 53° per second of flight at 100°/s, 80° at 150. **My airborne sweep limit rises to 10,000 units a second (§3),** or it would cap the swing just as it peaks: with the launcher as pivot, a body at 3,400 units is already over 100°/s at 6,000. Research's re-run of E2 at these rates decides whether any of it is affordable | Encounter, World, Camera, Research |
| 2 | **Both grounded in a split; strips and insets; a 6 s gap** | **Both grounded in a split: adopted, as no swing.** My sweep limit nearly gives this anyway, and a plain rule is easier to read. **It doesn't touch brawls,** which are close and in one pane, so a brawl's 10°/s stands. **Strips and insets: one at a time, but the swing wins and it isn't the sim's rule.** The sim must not read the camera, so a swing can't wait for a strip. Instead the camera closes a strip or inset with its usual wipe when a swing starts, and opens neither during one. The inset's rate has to be read again with this. **The 6 s: a score, not a cap, as Camera itself asks.** The recency term is set so that within about 6 s only a launch with a strong arrival can beat "stay", and a brawl's swing never can, since it still wants 45 s of quiet. QA reads the gap between swings. It's a band, not a rule | Camera, Encounter, QA |
| 3 | **Reduced motion** | **Closed.** A setup flag, `swingReduced`, yes or no. On, every peak is capped at 30°/s, the number in data, which replaces my "half the rates": a half of a rate that's still moving is no promise. So launches swing less, and some arrivals won't fit. **Online:** each player's setting crosses in the lobby before the match key is made, and it's on if either has it on. It's fixed for the match and read fresh at `newMatch` (Netcode's conditions). **Disclosure:** the other player sees slower swings and isn't told why or who, and I don't count that as disclosing anything. Orb can overrule. **Spectators and replays play at the recorded rate, so they need a render-side answer,** and this flag can't provide one. Camera's near-cut at the whip (a cut on action) is the candidate, opt-in for that viewer, if the field can show the end bearing early. **Owner Rendering and Camera, due before a replay viewer or spectator mode ships** | Netcode, Rendering, Camera |
| 4 | **Weigh destinations behind the fighter plane higher?** | **Yes.** It's what lets a player see it coming, and Camera's "it arrives" depends on it. A place on the near side arrives late from the frame's edge. It's one score term, smaller than the story terms, so a rival's home on the near side can still win | Encounter |

**One thing §8 and Camera must settle together.** Camera wants nothing standing in front of the fighter plane, and §8 makes walls real on a tilted line. So a building that stops a fighter must be drawn where it stops him, even if part of it stands in front of the plane, or he'd be stopped by nothing. Camera and Rendering should treat this as part of clip 3.
