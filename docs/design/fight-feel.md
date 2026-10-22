# The fight's feel: launch flight, recoil flips, ricochets and clashes

Owner: Game Design. Date: 2026-10-19. **Paper only.** Nothing here is built or run by me, and **every number is a first value.** It is aligned with Research's `docs/research/readable-speed.md` (rows 1 to 3) and Camera's `docs/camera/feel.md`.

**Orb** (2026-10-19, `docs/ep/vision.md`):
- on the camera: "rebalancing the speed on launches may be a way to handle it";
- in homework 6, in place of the launcher's rest: "more back and forth, impacts, dynamic clashing. both fighters should be backflipping out of strikes, ricocheting off of environmental elements."

The brawl's pacing comes from impacts, recoils, ricochets and clashes, not from timers.

## 1. A launch's flight: stop, kick, glide, arrival

A launched body no longer flies at one speed. Its speed follows a curve the camera can tell a story with: the hit, the explosive departure, a glide long enough to frame both fighters, and the arrival.

| Phase | What happens | First values |
| :--- | :--- | :--- |
| **1. The stop** | Hit-stop on the launching blow: everything holds, and the camera pushes in (Camera's 2%) | 14 ticks for a launch, 16 for a full one (the hit-stop table, `rulings-2026-10-19b.md` §4) |
| **2. The kick** | He leaves fast, but never in one tick (Research's recommendation 9). The camera's whip follows him out (Camera's) | A ramp up to the peak over 5 ticks, then the peak held for 3: the send's own speed, by power and tier |
| **3. The glide** | His speed eases down to a cruise and holds there. Long enough for the camera to frame him and his attacker, for the attacker to chase or zip, and for the brake to start | Eased from the peak to 0.4 of it over ticks 8 to 30, then held |
| **4. The arrival** | Into a building, the ground or the water: his speed rises again to 0.6 of the peak, ramped over the last 10 ticks, so the impact reads hard without a jump. Or he brakes, and the skid shows it (`buildings.md` §7.2) | |

**How far it travels:** about the peak for 8 ticks, plus the cruise for the rest of the flight.

| The send | Flight | Travel |
| :--- | :--- | :--- |
| A full launch (power 1) | 1.0 to 1.6 s | Across a street in town: 2,400 to 3,600 units (the town haul's 3,500 stays the target). Over open ground: up to 6,000 |
| A weak pop (power 0.55) | 0.5 to 0.8 s | 600 to 1,500 |
| A knock-back | Its own slide, as now (`balance-targets.md` §20) | |

- **In a smaller arena** (`rulings-2026-10-19b.md` §3: Whole, Half, Close), the glide's cruise is scaled by the arena's size, so a launch never carries more than a sixth of the loop: 6,400 units on Close.
- **The AI's free-flight approach** is capped near Camera's whip limit unless the camera rides with it (`rulings-2026-10-19b.md` §4d).
- **Who builds it.** Simulation: the curve as a speed profile on a sent body, deterministic. Encounter: the planner predicts with it. Camera: the push, the whip, the chase and the arrival's framing.
- **QA's rows:** a full launch's flight from 1.0 to 1.6 s; the sent body inside the frame (or its pane) for at least 95% of a flight's ticks.

## 2. Recoil exits and flips: backflipping out of strikes

Reconciled with Combat's `docs/combat/choreography-feel.md` §1 (`rulings-2026-10-22.md` §2a).

- **Separations knock him back.** A tapped heavy that lands clean recoils him 1.5 bh, as a slide of 8 ticks, where it used to stagger him in place. It was never an opening. If he doesn't flip, he reels 6 ticks at the slide's end. Charged blows, a blast's push, a meet's recoil (§4) and a wall's rebound knock him back by the data's distances by tier (`knockBack.distBh`, 3.5 to 8 bh).
- **Every separation has an exit: Combat's look, by weight.** A light gets the skip, a medium the back handspring (a tuck in the air), and a heavy the backflip. **The exit fits inside the reel or the knock-back as it is.** The distance and time are the sim's, and Combat's 10, 18 and 24 ticks are the animation's nominal lengths, scaled to fit.
- **The recoil flip is the player's cut of it.** A dodge tap (LT, or Simple's dodge) in the first 10 ticks of a knock-back ends the slide.
  - He lands set: on his feet, or steady in the air, 12 ticks later.
  - **His next blow within 20 ticks of the landing is a counter-rush:** it closes at rush speed and lands as a rush blow.
- **The flip costs nothing:** no ki and no cooldown. A press out of the window simply does nothing.
- A launch is never flipped out of. The brake and the skid are a launch's way back.
- **The AI** flips on 20, 45 or 70% of its knock-backs by level, and follows a flip with a counter-rush on 50, 70 or 90%.
- **QA's row:** flips a minute, both fighters, from 2 to 6.

## 3. Ricochets off the world: plants, glances and the wall kick

Reconciled with Combat's §2 (`rulings-2026-10-22.md` §2b). **The line is 1,500 units a second into the surface,** the speed along its normal. The surfaces are a building's face that holds, a slope, a ridge or a cliff, flat ground, a parked car, a post or a tree.

| Into the surface | What happens | The press |
| :--- | :--- | :--- |
| **Below the line** | **The plant** (Combat's): he plants on it (a 4-tick stop, a tell of at least 6 ticks) and springs back toward the rival, landing in range | **X, Y or B within 6 ticks of the plant** makes the rebound a blow of that strength: a flying knee, a driving medium, or a rebound heavy. **A dodge tap** aims the spring by the stick instead. No press: he springs back unarmed |
| **At or above it, glancing** (under 40° to the surface) | **The glance:** he keeps 0.7 of his speed, angle in equal to angle out, and doesn't stop | |
| **At or above it, steeper** | The wall slam, the lodge or the building chain, as ruled (`buildings.md` §2, §6 and §7.3) | **The wall kick:** a dodge tap within 4 ticks either side of the contact. He kicks off toward his stick at 0.6 of his speed, and the slam's damage is halved. If he reaches the rival, his first blow is a rush blow |

- **At most two ricochets in a row,** plants and glances together. Then the next surface is a plain stop.
- **A rebound heavy launches only into an opening,** as any B does. Otherwise it is a heavy, with its 1.5 bh recoil.
- **The rival sees it coming:** the plant is a tell, and the rebound blow can be guarded and perfect-blocked like any blow.
- **The choreographer's taste:** with a neutral stick, a send that ricochets off a building into open air, or back into the brawl, scores high in combat alchemy.
- **The AI:** the plant's counter press on 30, 55 or 80% of plants; the wall kick on 15, 35 or 55% of its chances.
- **QA's rows:** plants and glances a match, from 2 to 8; wall kicks a match, from 1 to 4.

## 4. Meets and the clash exchange: dynamic clashing

Reconciled with Combat's §3 (`rulings-2026-10-22.md` §2c).

- **The window is 3 ticks.** Two blows whose contacts land within 1 tick of each other **meet** between the bodies. 2 or 3 ticks apart, **the earlier breaks through** at half its worth.
- **Equal strengths meet:**
  - **X against X:** the wrists knock, and both bounce 0.5 bh. Pressing again meets again;
  - **Y against Y:** the elbows bump, and both slide 1 bh;
  - **B against B:** the heavy clash's ring, and both backflip 3 bh. The even mash's double hit is this family now.
- **Unequal: the heavier goes through** at full worth, and the lighter takes his exit. It is the brawl's triangle, made visible.
- **Neither is hurt by a meet** (an X meet gives chip), and the brawl's pull brings them straight back.
- **The third meet in a row escalates into the clash exchange.** The director stages 4 to 8 meetings, decided on the pulse by the rule of every timed contest (`rule-of-cool.md` §2). The one with more presses on the pulse breaks through with a free heavy, and a draw blows both out 4 bh.
- **A B meet** breaks glass near it from tier 2, and its shockwave damages structures from tier 3 (rule of cool item 15, the fist clash).
- **The AI:** the clash exchange's pulses at 40, 65 or 85%, as in every clash.
- **QA's rows:** meets a minute, from 3 to 8; clash exchanges a match, from 1 to 4.

## 4b. Turns: quick back and forth in place

Combat's §4, ruled (`rulings-2026-10-22.md` §2d).

- **The deflect.** A fresh guard press in the last 16 ticks of an incoming blow's wind-up that misses the perfect-block window turns the blow aside, with no damage and no stagger. Such a press never starts the perfect block's lockout.
- **The return.** His next press within 8 ticks is a quick blow from his stop and reversal pools.
- **A turn** is the deflect and the return, 12 to 16 ticks. **A run of 2 to 6 turns** ends when one misses a deflect (he takes the blow and his exit), or escalates: a heavy is a meet, and a launch is a link.
- **The perfect block stays the better read,** with its reversal and stagger. The deflect is its plain-timing cousin, as Combat puts it.
- **The AI:** deflects on 20, 40 or 60% of its chances, and returns after a deflect on 60, 75 or 90%, never sooner than its reaction time after the wind-up begins.
- **QA's rows:** turns a minute, from 2 to 8; a run of turns, 2 to 6 long.

**The build order is one piece at a time,** with QA's rows read between: exits and flips (built), ricochets, meets and the clash exchange, then turns.

## 5. What each owner builds

| Owner | What |
| :--- | :--- |
| Simulation | The launch's speed curve on a sent body; the ricochet's glance; the wall kick's push |
| Encounter | The recoil flip and its counter-rush; clash detection and the clash exchange; the AI's shares; the planner's prediction with the curve and the ricochets |
| Camera | The push, the whip at the kick, the glide's framing, the arrival |
| Animation | The backflip, the landing set, the wall kick, the clash recoils |
| VFX, Audio | Clash sparks and sounds; the kick's trail; the ricochet's scrape |
| Controls | Rumble on landed blows, launches, landings, buildings and clashes, as Orb picked |
| QA | The rows above |

## 6. Hit-stop by weight

(`rulings-2026-10-19b.md` §4, from Research's recommendation 10.)

| Blow | Ticks |
| :--- | ---: |
| A mashed or burst light | 2 to 3 |
| A tapped light | 4 |
| A medium | 7 |
| A heavy | 10 |
| A launch or a close; a full launch | 14; 16 |
| A decisive blow (a finisher's last, a duel of perfects' send, a blow that breaks a region) | 24, capped at 30 for the KO |

- **Both bodies freeze,** and the struck one shakes more.
- **The budget:** frozen time is at most 12% of a minute of fight. Overlapping stops merge. Over it, the mashed and burst lights go to 2 first.
- **No window shortens:** the perfect and parry windows end at least 5 live ticks after the freeze ends.
