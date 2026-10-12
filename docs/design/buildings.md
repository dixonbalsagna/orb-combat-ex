# Buildings in a fight

Owner: Game Design. Date: 2026-10-12. **Paper only.** Nothing here is built or run by me, and **every number is a first value.** The measures are World's (`docs/world/destruction-hook.md`). Co-op is not designed here.

**Orb,** 2026-10-12: "realistic building destruction is absolutely a priority... smashing opponents through multiple buildings is climactic, catastrophic, visually appealing, and part of the gameplay hook."

**What World found.** A body hits a building 1.35 times a match, though 40 of 118 buildings fall, nearly all to blasts and beams. Three things are missing: escalation (a tower is punched at every tier), structure (a body clears a whole floor) and time (a collapse is one tick). And fights leave town inside a minute, because the commonest launch hauls the target to open ground.

## 1. The ladder: what each tier does to a building

World's second experiment, taken, with one addition for houses.

| Tier | A house, under five floors | A tower | The chain |
| ---: | :--- | :--- | :--- |
| 1 | **He goes through it** | **It holds him.** The face breaks and he comes back off it: the wall slam (§2) | One tower, or two houses |
| 2 | Through | He punches one tower. The next holds him | 2 |
| 3 | Through | Through | 3 |
| 4 | Through | Through, and the breach is most of the building's width | 4 |
| A finisher | | | 5 |

- **So the first minute already breaks buildings.** A house comes apart at tier 1, and a tower shows the hit. "Through several towers" is what the late tiers and the finisher are for, which is where Orb puts it: the climax.
- **A house counts as half a link** of a chain.
- **The lodge.** The last building of a chain takes what is left of the launch. He ends inside the breach, held for 0.5 s at tiers 1 and 2, 0.7 s at tier 3 and 0.9 s at tier 4 and in a finisher. That building takes the rest of the launch as one more hit. The hold is part of the launch, so it is inside "except in knock-backs".

**What a tier-1 hit on a tower must show,** since it doesn't go through:
1. The face breaks over the floors he covers, and glass goes from the floor above and the floor below: three or four floors of damage, readable at the fight's zoom.
2. He is seen to stop in the wall, for about 15 ticks, before he comes off it.
3. Debris and dust fall to the street for at least a second.
4. **The mark stays** for the match, and the building is weaker for it. Three walls on one tower and the fourth launch goes through.
5. The building is heard to take it.

## 2. Three rules for buildings

| Rule | Ruling | First values |
| :--- | :--- | :--- |
| **The wall slam.** A launched body that meets a building which holds him | **Yes.** It turns a launch at tier 1 or 2 into a play: aim at what you can't break. A floor that is punched gives no slam | He takes twice the building's hit. He is staggered at the wall for 24 ticks. And the attacker has the first move: he can't start an approach until 45 ticks after he is free (`brawl-second-pass.md` §14). World's "free rush" is that first move, and not a blow given for nothing |
| **The falling stack.** A collapse takes seconds, and what stands under it is hurt | **Yes.** It is the largest single step toward what Orb describes | A tower comes down over at least 2 s. It warns for at least 1.5 s first, by sound and dust, and always for 0.6 s longer than any hold a fighter there is in. Under it: 6 damage for each floor that lands on him, 100 at most, and he is buried for 0.5 to 1 s. It hurts either fighter |
| **Cover from a beam.** A standing building in a beam's line takes it for him | **Yes, with beams in depth, and not before.** Along a street a beam's line is clear, so there is no cover to take until a beam can be aimed across the band. And it must never make a fighter safe for good | A beam of tier 1 or 2 is stopped while the building stands, and carves it stage by stage. At tier 3 it cuts through after 1 s. At tier 4 it cuts through at once, at 0.7 of its power. The people inside are on the firer's account |

- **The fighter who cares pays for all three.** A wall slam into a full tower, a stack brought down, a beam through cover: the people inside feed his anguish. He can still do each one. That is the Protagonist as Orb wrote him: he fights to protect, and his fixation on the fight breaks things.
- **A drifting brawl still never damages a building** (`depth.md` §2). Flights do: a launch, a throw, a rush that ploughs.

## 3. Aiming for it, and staying in town

**What a launch through buildings is worth.**
- **Damage.** Each building he goes through hits him, the lodge takes the rest, and a wall hits him twice over. The band: a launch through one building is worth at least half again a launch across open ground, and a full chain at least double.
- **The mood,** which already takes more for a building launch and a chain.
- **Nothing toward the finisher** beyond what any launch gives. The pay is damage and the sight of it.
- **For the Anti-hero,** his Pride for a building levelled, as planned.

**The player's stick is a vote that wins.** When he launches with the stick toward a side, and a building stands on that side inside the launch's reach, the planner takes the building if a plan to it exists. The planner's own taste decides only when the stick is neutral. So a player sets a launch up by where he drags the brawl first, which is what the nudge and the depth rules are for.

**The AI votes by its care.** A fighter who cares takes a building only when nobody is in it, or late and behind. A fighter who doesn't takes it when it is there.

**What keeps a fight in town, without pinning it.**

| Today | The rule | Whose lever |
| :--- | :--- | :--- |
| The commonest launch hauls him 13,200 units to open ground, and is paid for distance and for a new biome | **A launch along a street stays in the street.** In a settlement it lands inside it, 3,000 to 4,000 units on, while a street runs that way. The distance bonus is halved in a settlement, and the new-biome bonus is paid once in 60 s | Encounter |
| A building launch is 5 to 9% of launches | With a building on the line and no stick held, it is preferred from tier 2. With the stick toward it, it wins | Encounter |
| The hero's lure leads every fight out | It stays, since it is his care. It pulls by the people near, and not by the buildings. The Anti-hero's care pulls the other way. **Where the fight is becomes a tug between the two,** and a player takes it either way with his nudge | Encounter, with the care values |
| A fight that starts in open country never sees a building | Nothing forces it to. The planet is the arena | |

## 4. QA's rows

| Row | Today | Bound |
| :--- | :--- | :--- |
| Bodies into buildings a match, from a start in town | 1.35; 2.5 from a crossing | 4 to 8 |
| Launches that take a building, in a settlement | 5 to 9% | 15 to 30% |
| Fight time within 1,500 units of a building, from a start in town | 15%, or 41% and falling | 30 to 50% |
| Fight time outside every settlement | | At least 25%: the fight isn't pinned |
| A tier-1 body through a tower | | Never (hard) |
| A tower hit at tier 3 or 4 with the strength to punch it | | He goes through (hard) |
| Every chain ends in a lodge, held 0.5 to 0.9 s | | Every time (hard) |
| Wall slams a match | | 1 to 3 |
| Chains of two buildings or more a match | | 0.5 to 2, at tier 3 and up |
| A tower's collapse | One tick | At least 2 s, after at least 1.5 s of warning (hard) |
| A fighter hurt by a falling stack | | 0.2 to 1 a match. It should be rare and remembered |
| A launch through one building against one across open ground; a full chain | | At least 1.5 times the damage; at least 2 times |
| With the stick toward a building in reach, the launch takes it | | At least 90% of the times a plan exists |
| The collateral budgets, the people lost in a match, the match's length | In band | Their bands. More fighting in town will press all three, and they are read first |

## 5. The order, and what it asks

1. **The ladder and the lodge** as data (World's first window), with the wall slam, which is a rule on the same hit.
2. **Holes the size of the hit,** so a punch leaves a floor with a hole and not a missing floor (World).
3. **The collapse that takes seconds, and the falling stack** (World, with Rendering's and Audio's warning).
4. **The planner's side,** with Encounter's work on using the planet: the haul, the bonuses, the stick's vote.
5. **Cover from a beam,** with beams in depth.

| Who | What |
| :--- | :--- |
| World | Steps 1 to 3; the house's half link; a building that remembers its walls |
| Encounter | Step 4; the first move after a wall slam; the AI's vote by care |
| Combat | The stack's damage number, and the wall slam's |
| Rendering, VFX, Audio | The five things a tier-1 hit shows; the warning before a collapse; the lodge |
| Camera | A chain through buildings, and a collapse, held in frame |
| Legal | The collapse through the flash check |
| QA | §4 |
