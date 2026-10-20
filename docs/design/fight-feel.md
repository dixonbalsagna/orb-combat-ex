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

## 2. Recoil flips: backflipping out of strikes

- **Big blows knock him back.** A heavy that lands clean, a charged blow, a blast's push, a clash's recoil (§4) or a wall's rebound sends him back. That is 1.5 bh for a heavy and 3 bh for a charged heavy below full, as now.
- **The recoil flip.** A dodge tap (LT, or Simple's dodge) in the first 10 ticks of a knock-back turns it into a backflip.
  - It ends his slide.
  - He lands set: on his feet, or steady in the air, 12 ticks later.
  - **His next blow within 20 ticks is a counter-rush:** it closes the gap at rush speed and lands as a rush blow.
- **The flip costs nothing:** no ki and no cooldown. A press out of the window simply does nothing. Orb wants back and forth, not a resource to manage.
- **Without the press, a knock-back over 3 bh still ends in a flip** if he lands on his feet: Animation's flourish, with no counter-rush. A launch is never flipped out of. The brake and the skid are a launch's way back.
- **The AI** flips on 20, 45 or 70% of its chances, by level.
- **QA's row:** recoil flips a minute, both fighters, from 2 to 6.

## 3. Ricochets off the world

- **A glancing contact ricochets.** A sent body meeting a surface that holds (a building's face that holds, a cliff, a ridge, a slab inside a tower, a parked car) at under 40° to the surface glances off. He keeps 0.7 of his speed, angle in equal to angle out, and doesn't stop.
  - From 40 to 70° it is a bounce, as the knocked-about rules have it.
  - Steeper, it is the wall slam or the lodge (`buildings.md` §2 and §6).
- **The wall kick.** A dodge tap within 4 ticks either side of a contact with a wall or a cliff turns the contact into his own kick-off.
  - He pushes off it toward his stick (by default, back toward the rival) at 0.6 of his arrival speed.
  - The slam's damage is halved.
  - If he reaches the rival, his first blow is a rush blow.
  - So the hit fighter can turn the attacker's send into his return: "ricocheting off of environmental elements".
- **The choreographer's taste:** with a neutral stick, a send that ricochets off a building into open air, or back into the brawl, scores high in combat alchemy.
- **Bounds:** at most 3 ricochets a journey, inside the journey's 8 contacts and 4 s.
- **The AI** wall-kicks on 15, 35 or 55% of its chances, by level.
- **QA's rows:** ricochets a match, from 2 to 8; wall kicks a match, from 1 to 4.

## 4. Clashes: dynamic clashing

- **Two blows that meet clash.** When both fighters' blows land within 3 ticks of each other and are of the same strength, or one step apart, they clash instead of trading.
  - Neither takes damage: a light clash gives chip only.
  - Both recoil: a light 0.5 bh, a medium 1.5 bh, a heavy 3 bh with a backflip.
  - A clash spark and sound play.
  - The brawl's pull brings them straight back together.
- **The clash exchange.** Three clashes within 3 s become **a clash exchange.**
  - The director stages a short run of 4 to 8 meetings: the blur exchange of rule of cool item 20, now reachable at any tier.
  - It is decided on the pulse, by the rule of every timed contest (`rule-of-cool.md` §2). The one with more presses on the pulse breaks through with a free heavy, and a draw blows both out 4 bh.
- **Heavy against heavy** is still the fist clash of rule of cool item 15, with its shockwave from tier 3.
- **The even mash's double hit** is a light clash now.
- **QA's rows:** clashes a minute, from 3 to 8; clash exchanges a match, from 1 to 4.

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
