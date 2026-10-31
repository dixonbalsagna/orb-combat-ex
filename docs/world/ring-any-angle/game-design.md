# The ring at any angle: what it should do for play

Owner: Game Design, by the EP's brief. Research page, 2026-10-30. Nothing here is built or measured by me; rates are first values, and the geometry is my arithmetic for World to check. Orb: "push this idea to the limit, the angle the fighters fight along the surface of the planet should be ready to dynamically adjust and change determined by the fight choreographer and any other necessary game system." The relative band stays the same always.

## The plain answer

**No play goal I can find needs a ring that changes every tick. All of them need one thing today's turn can't do: a large step, at any angle up to 180°, while things are moving. Above all, at a launch's first tick.**

- **Must build:** any angle, at a launch's stop, with beams and shots possibly in flight, about 2 to 5 times a match.
- **Shouldn't build yet:** frequent small steps. A hunt can use one large step instead, and at today's cost (38 to 60 ms a swap, a quarter of a second on the old-laptop CPU: `docs/performance/arena-turn-2026-10-23.md`) frequent steps would break Orb's no-frame-drop rule. They come back only if Orb plays it and misses them.
- **Orb's call:** if what Orb pictures is a flight visibly curving round the planet, that is a look rather than a play goal. It may be had from the far land's render-only drift (World's window 2) and never touch the sim. This is the one question that could change the answer, so it's worth asking.

## Why the launch's first tick

**My calm-moment rulings chose the worst moment for this.** A turn about the pair's midpoint moves the ground under each fighter by `s × sin(θ / 2)`, where `s` is the gap between them.

| Gap between them | When | Largest turn inside the 450-unit ground rule |
| ---: | :--- | ---: |
| 150 to 450 units | **In reach: a launch's stop** | **Any angle** |
| 3,000 | Part-way through a chase | 17° |
| 6,000 | **After a long launch has landed: the moment I ruled** | 8.6° |

So I asked for turns when the pair is furthest apart and nothing is moving. Calm moments almost never come: six Half-ring matches gave 0 asks, and 2 asks and 0 turns with Encounter's parked fix. At a launch's stop the pair is together, the camera already owns the moment (push, then whip), and the hit-stop holds the picture still for 12 to 16 ticks, which is about as long as the swap's quarter-second hitch on the slow machine. The launch also explains the change: he was hit, and now he's flying somewhere new.

**The catch, for World and Performance:** the rings have to be read before the swap (75 to 140 ticks today), so the pick has to come about 2 s before the blow. The director would keep the likeliest destination warm during a brawl, which costs 5 to 8 ms a frame on the slow CPU. And the surroundings beside the pair change at the swap, so whether that reads as force or as a glitch is the look gate's question.

## What each use needs

| Use | The step | When | How often (first values) | Needs any-tick change? |
| :--- | :--- | :--- | ---: | :--- |
| **Destination launch:** into a city, a landmark, a mountain | Any angle | The launch's stop | 1 to 3 a match, about one launch in four | **No:** large, while moving |
| **The villain hunts toward towns** | Any angle | His launches; his chase's start | 0 to 2 a match | **No:** large, while moving |
| **The hero flees or leads away** | Up to about 90° | His launches; the start of his zip away or escape | 0 to 2 a match | **No:** large, while moving |
| **Home ground in a fight** | Any angle | A launch's stop, or a form step's pause | 0 to 1 a match | **No:** large, moving or calm |
| **Story stages** | None: the ring is chosen at setup (`rulings-2026-10-19b.md` §2b) | Setup | Once | **No:** already designed |
| **A set piece bringing a landmark into view** | Small | A set piece's end, as ruled | 0 to 2 a match | **No:** today's machinery |
| **Mid-course correction on a long flight** | Small, frequent | During a flight | Not proposed | **No goal needs it.** Frequent small steps, if ever |
| **Stealth, later** | None | | | **No.** Hiding needs each player to see differently, and a ring is shared, so it can't come from this |

**In all, 2 to 5 large steps a match.** This should come from a score that falls with how recent the last one was, not a cap, as Orb prefers soft costs.

## What's fun, and at what rate

- **Every step must arrive at something.** A step toward nothing isn't taken: the planner scores the arrival, as it scores a building today. This goes straight at what Orb liked (building destruction, biome variety) and at what QA found: 67 to 84% of avoided beams have no building in reach, and most long trips are unexamined (`rulings-2026-10-30f.md` row 6).
- **Most launches stay ordinary.** If every launch finds a city, a city stops meaning anything, and cities run out.
- **The hero steers toward interesting empty places, not just away.** Mountains, forest and ice, not the nearest ocean: his lure's old side effect was most fights ending over water, and that's the trap to avoid.
- **The villain's steering is bounded by bands that already exist:** civilians lost at the KO 12 to 30%, structures levelled by tier, the budget ("the people got away"). No new reward for reaching people, which keeps Legal's c08 where it was. **It should still have a Legal read,** because the choreographer now takes a fight toward people on purpose.
- **It never decides a match.** Steering carries no damage bonus. QA's win-rate rows hold.

## What a player must always be able to read

These are hard tests, not aims:

1. **The rival stays on the same side of the screen across a step,** so a held stick still means what it meant. At 180° the ring's direction is flipped to keep this.
2. **Everything in reach is unchanged:** the ground under him within the ground rule, the rival, the band and his place in it.
3. **Attacks close as before.** The gap across a step is the gap before it, within the ground rule.
4. **A step has a visible cause,** a launch or a set piece, and never happens in a brawl. A brawl's surroundings don't rearrange while he's pressing.
5. **No marker, arrow or prompt** (`minimal-hud.md`), no dissolve, no fade (Orb, 2026-10-18), and the camera's move is the whip it already makes. Any instant change must be justified, per Orb's rule on the camera.
6. **The world remembers.** A fallen tower is still fallen, on any ring that passes it.

**The destination should be readable before it arrives where possible:** the far land already shows the planet's own ground (`farColumn`), so a city on the horizon can be where he's then sent. This is only scenery and promises nothing.

## May a player steer it?

**Through the fight, yes. By a control, no.** The stick still picks a launch's kind (up, down, across), and a held stick still wins (`launch_biome.json` `stickWins`). The direction he drags a fight and flees still lean the side (`rulings-2026-10-19b.md` 1c). The bearing itself is the choreographer's, which fits "the player nudges, the director stages" and Orb's "rule of cool takes precedence". There's no spare control (ADR 0009, the right hand now full), and aiming at places a player can't see isn't a skill.

**A fighter's own trait could change this later:** one who chooses their ground is good roster material. That's a fighter idea, not a base rule.

## The earlier limits this reopens

| Ruling | Today | Now |
| :--- | :--- | :--- |
| 1a, calm ticks only, nothing in flight | The only moments | **Reopened.** A launch's stop is added and comes first. What's in flight gets carried across. **Kept:** never in a brawl, never under a dissolve or wipe |
| 1b, at most 10°, 4 a fight, 60 s apart, 40° of drift | Hard caps | **Withdrawn.** The ground rule and the falling score replace them |
| 1c, leans the way the fight was pushed; no button | Stands | **Kept** |
| 1d, off until built and played | Stands | **Kept** |
| 1e, "a turn changes what is seen, not where the fight is" | The hero may bring a city into view | **Overturned:** a step now decides where the fight goes, so the hero's care counts against it in full |
| 1f and 1h, the ground rule, 300 and 450 units | Applies to both fighters | **Kept, at 450, and only for a fighter on the ground.** One in flight has nothing at his feet to notice. World's measure |
| 2d, prefers the opponent's ground | Stands | **Kept, and now it can actually happen** |
| 3d, a launch carries at most a sixth of the loop | Stands | **Kept** |

## Pillars 1 and 3

**Pillar 1, the planet is the arena: this makes it truer.** Today a fight is a loop on a planet. With this, it's the planet. Every ring still wraps, with no walls or corners. **What changes:** flying on returns you to where you started only if no step happened in between. I accept that. A player's map becomes a planet rather than a loop, and "fly either way" stays true.

**Pillar 3, never out of range: it holds because the ring is shared.** Both fighters are always on the one ring, and distance is always read along it, so no step can put the rival somewhere an attack can't reach, and the escape stays a gamble rather than a way off the map. **It must never become a dodge:** a step comes from a launch or set piece, and never from a press that would escape a blow.

## What I need measured before these numbers mean anything

1. **World:** for each launch in a match, is there a place worth arriving at within launch range (6,000 units) at any bearing, against on the ring as it is? This is what sets the payoff and the 1 to 3 a match, and it's cheap to read from planet data. Also check the geometry above.
2. **World and Performance:** the swap's cost at a launch's stop with things in flight, and whether a hit-stop can hide it on the laptop budget. If it can't, the rate above comes down.
3. **Orb, once it can be seen:** does a large step at a launch read as force, or as the world jumping? Nothing else on this page matters if it's the second.
