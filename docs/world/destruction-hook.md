# Destruction as the hook: smashing through buildings (World, 2026-10-12)

Owner: World and Environment. Status: paper with probe numbers; scratch experiments only, nothing in the tree. Asked by the EP for Orb (2026-10-12): "realistic building destruction is absolutely a priority, gaps between floors without realistic looking supports will make players lose their suspension of disbelief, so lets get some kind of compromise in there so smashing opponents through multiple buildings is climactic, catastrophic, visually appealing, and part of the gameplay hook." The rule against showing buildings fall is withdrawn (docs/ep/vision.md, 530afd4a).

Probes (all in `docs/world/scratch-build/destruction/`): `dm_match.gd` (a match log: events by type, how near the pair stands to a building, by match time), `dm_menu.gd` (the brunt menu: at sampled moments, which BUILDING SMASH plans exist at each tier and what each link of the chain does; pure lookahead through `WorldBrunt.aim`), `mk_dh.py` (the experiments below, and `WorldLanes.crossingAlong`). On HEAD 0dc942cf, the city of 118 buildings (83 below 5 floors, 35 towers of 5 floors or more: median 13 floors, up to 33; towers 405 to 6,581 hit points, median 1,463; the low ones median 124).

## 0. The short version

1. **The planet loses buildings, but not to bodies.** In 20 matches (480 s each) 40 to 44 of 118 buildings go down a match, 125 stage changes, nearly all of them blasts and beams from a distance (an intact building to a shell in one event, then rubble). A launched body hits a building **1.4 times a match** (2.5 with the crossing start) and punches **0.7 to 2.5 floors**. The hook Orb describes, a person through buildings, is about 5 to 9% of launches.
2. **The machinery for a chain already exists and is not the limit.** A plan through 2 to 4 buildings is available 44% of the time at the crossing start, at every tier; chain length is capped by tier (2, 2, 3, 4, finisher 5), and a chain of four kills about 23 people of 1,800 (1.3%) against a tier-4 window of 15%. What is missing is **escalation** (a tier-1 launch punches a tower exactly as a tier-4 one does: 94 to 99% of tower links punch at every tier), **structure** (a punch clears a whole floor across the building's width: that is the gap without supports) and **time** (a collapse happens in one tick).
3. **The fights are not where the buildings are.** At the default start the pair is within 1,500 units of a building 0% of the first two minutes and 15% of the match; at the crossing start 79% of the first 30 seconds, then 41%, 21%, 11%. The planner's own launches (SMASH ACROSS carries them 13,200 units to open ground) take the fight out of the city inside a minute.
4. **What I propose (sizes in section 7):** (a) the brunt's escalation and the lodge rule as data (`data/biomes/brunt.json`: tier factor, chain length, energy a building takes, the building that stops him); (b) local holes, so a punch leaves a floor plate with a hole of a body's width, and a great launch a breach, and floors clear only when the breach is most of the width (the compromise on supports); (c) a collapse that takes seconds (a failing state: the stack comes down floor by floor from the break, toppling toward the breach, a falling stack that hurts what stands under it); (d) three rules for Game Design to rule on, so a building is something to aim for, to hide behind and to bring down.

## 1. Through several buildings: what happens today, and what it would take

**What a launch does** (`sim/world/brunt.gd`, B2). A launch is aimed at one building; `aim` takes the first of four upward angles whose flight enters its footprint at 500 or more speed. On each hit `outcomeOf` reads the damage `spN * (0.55 + 0.25 * tier) * 1.8` against the strength of the two floors the body covers (`floorStr`: `maxhp / floors`, half again stronger for each floor above): a ratio of 1 or more **punches** (clears both floors, the body passes with `keep = clamp(0.8 - 0.45 * sumS / 3000, 0.35, 0.8)` of its speed), 0.4 to 1 **cracks** (floor damage, the body rebounds), under 0.4 **dents**. A building under 5 floors is whole: it **collapses** (a ratio of 1), a heavy wreck (0.6) passes at 0.7 of the kept speed, otherwise it stops him. `next` looks for the following building within 2,080 units of the far edge and 1,440 in depth; the chain stops at the tier's cap (2, 2, 3, 4; a finisher 5), at a speed under 500, with no building ahead, or at a building that holds. A building beside a hit takes a quarter of the damage once (`SPLASH`). The collateral module's window and ceiling apply to the deaths (a chain may borrow 12% at tier 3 and 20% at tier 4 of the population on top of the window).

**Measured, the brunt menu** (8 seeds from the crossing start, a sample every 3 s, both fighters as attacker, force 2000, the best chain at each moment, 640 samples a tier):

| Tier | A plan exists | Chain length (of those) | Links that punch a tower | Mean ratio | Mean speed kept | Floors punched, best chain | Deaths, best chain | Ended by |
| :--- | ---: | :--- | ---: | ---: | ---: | ---: | ---: | :--- |
| 1 | 44% | 2: 266, 1: 17 | 337 of 351 | 6.4 | 0.69 | 1.9 | 15.9 | the cap 255, a building 14, nothing ahead 14 |
| 2 | 46% | 2: 292, 1: 3 | 351 of 356 | 9.3 | 0.70 | 2.0 | 16.8 | the cap 287 |
| 3 | 44% | 3: 251, 2: 28 | 378 of 394 | 10.8 | 0.69 | 2.2 | 20.5 | the cap 236, nothing ahead 29 |
| 4 | 44% | 4: 206, 3: 55, 2: 19 | 385 of 408 | 13.9 | 0.71 | 2.3 | 22.9 | the cap 200, nothing ahead 58 |
| finisher | 44% | 5: 179, 3: 55, 4: 27 | 374 of 392 | 14.7 | 0.73 | 2.2 | 25.7 | the cap 179, nothing ahead 84 |

What the table says:
- **Chain length is the cap's, and it is almost always reached.** Whenever a plan exists the chain runs to the cap in 64% (the finisher) to 97% of them.
- **Nothing stops him but the cap.** A tower link keeps 0.7 of the speed; a mean ratio of 6 to 14 says every tower is punched. No tier "dents".
- **Bodies mostly burst low buildings.** 36 to 68% of the links of a chain are buildings under 5 floors, which turn into a heap in one tick at any tier. That is why the best chains punch only 2 floors: it is 2 floors in all, through the one or two towers in the line.
- **Budgets are not what binds.** Deaths of the best chain are 16 to 26 people (0.9 to 1.4% of 1,800) against windows of 36, 72, 144 and 270 and the chain allowances of 216 and 360 at tiers 3 and 4.

**What each tier should do** (rules and data). The proposal is the existing machinery with its numbers made data (`data/biomes/brunt.json`, schema for Tools: `tierFactor`, `chainMax`, `chainSpecial`, `keepHi`, `keepK`, `keepRef`, `keepMin`, `heavyKeep`, `bruntMul`, `hitFloors`, `tunnelMax`, `pancakeK`) and one new rule, the **lodge**:
- **Escalation by tier** is the tier factor. Today it is 0.8, 1.05, 1.3, 1.55 (a 1.9x spread between tier 1 and 4). Experiment V2 (a scratch change of the one expression, `tierFactor` [0.12, 0.27, 0.47, 0.73] with the same 1.8):

| Tier | Tower links: punch / crack / dent | Mean ratio | Chain (of plans) | Ended by |
| :--- | :--- | ---: | :--- | :--- |
| 1 | 40 / 112 / 54 | 1.3 | 1: 182, 2: 147 | a building 166, the cap 138 |
| 2 | 243 / 65 / 5 | 3.2 | 2: 282, 1: 59 | the cap 266, a building 70 |
| 3 | 362 / 14 / 25 | 5.8 | 3: 278, 2: 40 | the cap 263, a building 39 |
| 4 | 393 / 7 / 23 | 9.9 | 4: 248, 3: 46 | the cap 242, nothing ahead 55 |

  So tier 1 cracks or dents four towers in five and a launch there is a **wall**: the body rebounds, and the chain is one building; from tier 2 it punches; at tier 3 and 4 it goes through. In a 20-match run from the crossing start the match totals stayed: structures lost 40.1 (40.4), length 478 s (484), building hits 1.7 (2.5) and floors punched 1.0 (2.5), one third of the early punching, as the first minutes are tiers 1 and 2. Chain length by tier is data (2, 2, 3, 4, 5 today); I would make it 1, 2, 3, 4, 5, so tier 1 is one wall and no tunnel.
- **Energy lost a building** is `keep` and stays: 0.35 to 0.8 of the speed by what it breaks. Add a **cost for a house** (`houseKeep` 0.6 of the speed; today a house that collapses passes at `keepw`, 0.79 for a median one) so a long chain through shopfronts does not arrive at the tower with the speed it left with.
- **What a building must have left to stop a body** is already the ratio under 1. The new rule is **the lodge**: the last building of a chain (the cap reached, speed under the minimum or nothing ahead) **takes what is left**: the body ends inside the breach, lodged for `lodgeSeconds` (0.5 to 0.9 s, the existing embed state of the ground contact), and the remaining energy is dumped as one more hit on that building (it wears most). "The last one stops him" is then visible: the deepest breach, the dust, the body in the wall, a free window for the attacker. A rebound (today a quarter of the speed backward) stays for a building that holds him at the first hit (tier 1 and 2: the wall).
- **Down a street and across a block.** Down a street is the x line through the row-1 buildings: it works today (the chain follows the buildings within 2,080 units). Across a block needs depth: `next` already allows a building 1,440 units deeper, which the three-street layout puts in row 2; with L3 on and L4 sending a body into the row behind, the same code makes the chain.
- **Collateral stays in Game Design's budgets** by construction (the window and ceiling in `WorldCollateral.kill` are untouched; the chain allowance is theirs). With V2 the tier-1 deaths of the best chain fall from 15.9 to 14.3.

## 2. Structure that reads: what a building has, what it lacks

**State today** (`Building`, hashed in `hash.gd`): `hp`, `maxhp`, `alive`, `floors` and `fmask` (one bit a floor, whole floor), `fdmg` (damage a floor, lazily allocated), `wear` (shots' unshown wear), `stage` (derived from hp, floors and fdmg: 0 intact, 1 windows out, 2 a part gone or a damaged floor, 3 a shell, 4 rubble). Events carry the rest: `floor_hit` (floor, n, outcome, ratio, x, y, z, direction), `floors_fall`, `building_stage`, `building_fall`.

**What is wrong with the picture.** A punch clears **a floor across the building's whole width** (`fmask` has no width). A body is 0.6 bh wide and a downtown building is 6 to 9 bh wide, so a punch removes eight to fifteen bodies' worth of slab. Two floors high is a "tunnel" the sim says the columns carry (`TUNNEL_MAX`), and nothing is drawn in the gap: that is Orb's "gaps between floors without realistic supports". Past 2 floors the whole stack above falls in the same tick. A collapse is instant in the sim; Rendering animates a `building_fall` over about a second.

**What it needs, as sim state and what each costs** (the JS parity copy is the frozen oracle and stays untouched: the GDScript hash is the source of truth since ADR 0006):

| Look | State | Cost |
| :--- | :--- | :--- |
| A hole the size of the body (a slab with a hole, a core and the corner columns showing in a cleared floor) | A **breach** a floor: `fhole` (x of its middle, width) in a lazily allocated array like `fdmg`; the floor clears (`fmask`) only when the breach is 70% of the plate | 2 floats a damaged floor, lazily: a typical hit building 4 to 6 floors, 8 to 12 floats; the whole city under 1 KB. `hash.gd`: one array length and its values like `fdmg`. One field in `floor_hit` (`x0`, `x1`: the breach) |
| A breach that scales with the hit (tier 1 a body-sized hole, tier 4 most of the width) | Breach width is a function of the ratio: `clamp(0.8 + 0.6 * ratio, 0.8, w)` bh | none: a rule in `brunt.gd` |
| Core and columns that carry load, drawn | Nothing new: the core is `hp / maxhp`, the columns are always drawn in a cleared floor (Rendering); the core cracked below 35%, broken below 15% | none in the sim |
| A lean | Derived by Rendering from the breaches and the hp: the building leans toward the side with the larger breach once the core is under 50% (a few degrees) | none: a function of hashed state |
| A collapse that takes seconds: pancake from the break, topple toward the breach, partial collapse leaving a core | A **failing** state: `failT` (seconds into it), `failDir` (-1, 0, 1: the toward-the-breach side), `failK` (the floor the failure has reached); each 0.25 s a floor of the stack goes (pancake) or the stack tips (topple: the last third, 0.6 s a floor) | 3 fields a building (118 of them), only a failing one ticks. `hash.gd`: 3 names. Events: `floors_fall` per step (the field list exists), `building_fall` at the end |
| Falling stack as a thing that hurts | The stack's footprint is a hazard while it falls: damage to a fighter inside the footprint and 1 bh to the side, times floors in the step | a few lines in `brunt.gd`; Combat and Game Design set the number |
| Debris and dust | Events as today; `floor_hit` x0 and x1 let VFX place them at the breach | none |

**What I would not add:** per-face damage (a building has a front and a back in the 2.5D view, and an impact face is the event's `ux`), a physics rigid-body collapse (a deterministic hash on rigid bodies would be the largest cost in the project; the staged failure above is the compromise).

## 3. Why fights do not reach buildings

**Measured** (20 matches each, seeds 1 to 20, the default start and the crossing start of the small golden window):

| | Default start (START_X) | Crossing start |
| :--- | ---: | ---: |
| Length | 479 s | 484 s |
| Building hits (bodies) a match | 1.35 | 2.5 |
| Floors punched a match | 0.65 | 2.5 |
| BUILDING SMASH plans a match (of 48 launch decisions, 15 to 16 of them launches) | 0.8 | 1.4 |
| Matches with any building hit | 13 of 20 | 13 of 20 |
| First building hit, median | 300 s | 31 s |
| The pair within 150 / 1,500 / 12,000 units of a building (all match) | 8 / 15 / 40% | 16 / 26 / 53% |
| Within 1,500 units by match time: 0-30 s, 30-60, 1-2 min, 2-4, 4+ | 0, 0, 1, 13, 24% | 79, 41, 21, 11, 27% |
| The pair's middle roams in a match | 111,000 units | 95,000 units |
| Structures lost a match (blasts and beams) | 43.9 of 118 | 40.4 of 118 |

**The facts behind it.**
- **The districts are 28% of the planet** (Bellgate 15%; 43,600 units of 153,600). The pair starts at START_X 89,600, 28,000 units from downtown's middle and 17,900 from the nearest building (the workshop village). A 16,000-tick match (267 s) at the default start sees none: the first two minutes are 0%.
- **The planner carries the fight away.** SMASH ACROSS (5.5 to 6 a match, the commonest launch) aims to haul the target **13,200 units** to open ground (`HAUL_TARGET`), and a landing on open ground scores a distance bonus (`DIST_W`) and a new-biome bonus (`NEW_BIOME_W` 10); a landing in a town scores the care term against it. The pair roams about 100,000 units a match, most of it in one launch after another to empty land.
- **The hero's lure** (director/ai.gd) leads a fight out of town on purpose (it cut collateral from 60% to 39% and is why the city sees few fights).
- **BUILDING SMASH has to win a vote.** A plan exists at the sampled moments 44% of the time, but the score is 14 + 3 * tier + at most 14 of drama (+5 a skipped plan) against SMASH ACROSS's 8 plus its distance bonus, DRIVE DOWN's 18 + 4 * tier in the air and the knock-back; it is 5 to 9% of launches.
- **Bodies are a small part of the damage.** Beams and blasts account for ~125 stage changes a match; bodies for 1.4 to 2.5 building hits. The destruction a viewer sees is the blasts', from a distance.

**Levers that are World's.**
1. **Where a match starts** (done: `setup.start == "crossing"`; the web demo passes it). The first 30 seconds of a demo are at 79% building-near. Not enough alone: it is 21% a minute later.
2. **How much city a fight meets.** The settlements span about a fifth of the planet; widening a city (a longer downtown, a second district of mid-rise on each side) costs buildings (more draw, population and collateral share) and lengthens the time a hauled fight stays in town. I would rather not: Encounter's levers (below) do more for less.
3. **Where the buildings stand.** Row 1's near face is 2.5 bh from the fighter plane (the front street is 5 bh wide), the three-street grid put the crossings 11 to 15 bh apart. This is as close as buildings can stand without being in the street.
4. **How tall they are.** A downtown tower is 14 to 20 floors, the landmarks 23 to 33 (the shorter-and-broader ruling made a body's two floors a larger share).

**Levers that are Encounter's** (the same question "using the planet" the EP has asked them): `BRUNT_BASE` 14 and the drama cap 14; `DIST_W`, `NEW_BIOME_W`, `HAUL_TARGET`, `HAUL_MIN` of SMASH ACROSS (a haul that stays inside a town is not a haul); the care term in towns; the hero's lure; **sends along an avenue** (the next read below); a rule that a launch started with a building within `BR_MAX` (10,400 units) in the line **prefers** it when the attacker's tier is 3 or more.

## 4. What a building is for in a fight

**What exists today.**
- **A wall that wounds the body** that hits it: `FIGHTER_DMG` 0.012 per unit of speed (24 damage at 2,000), plus the stop: 0.35 s on the first hit, 0.12 s a further one.
- **An obstacle to shots:** a shot ends on a building (1.8 to 2.3 a match), damaging it through the floors path.
- **A target of beams:** a beam carves the structures along its path (no cover).
- **A source of menace and anguish:** every civilian death feeds the villain's menace and the hero's anguish (normalised, per-casualty), and the hero's care term avoids populated buildings.
- **A place to stand?** Not yet: a body lands on the ground (the roof read `WorldStructures.standingAt` exists for the shadow; no landing on roofs).

**Three rules for Game Design to rule on**, each small and each with its number a first guess.
1. **The wall slam.** A launched body that meets a building that holds him (a dent or a crack, ratio under 1) takes **x2 the building's damage as a wall slam** (about 50 damage at 2,000, against 24) and the attacker gets a free rush: the rebound leaves him inside the attacker's reach and stunned for 0.4 s. A tier-1 or 2 launch toward an intact tower is then a play, not a miss; aim at a tower you cannot punch to hurt him; a punched or cleared floor gives no slam. The player has a reason to aim at a **strong** building and to avoid a weak one (a house is a heap and no wall).
2. **Cover from a beam.** A standing building (stage 0 or 1) in the line between a beam and its target **absorbs** the beam: the beam is stopped for the share its energy cannot carry (tier 4 cuts through at full power), carving the building by the stages as it does. A defender who steps behind a tower is safe for the seconds the tower holds, and the attacker who wants the hit must bring it down: the civilians inside are the cost (the collateral window). This makes buildings **a thing to fight over**, and the beam clash is where the tier decides it.
3. **The falling stack.** The failing state in section 2 gives a collapse seconds, and the stack that comes down hurts what stands in its footprint and 1 bh beside it (first guess: 6 hit points a floor of the step, so a 14-floor stack onto a fighter is 80 to 100). A launch that cracks the core of a tower while the rival stands at its foot is a **trap**; a fighter who hears the groan and the dust (a 1.5 to 3 s warning, Rendering and Audio) can leave; one who does not takes it. The hero who cares has a reason to keep the fight from the foot of a tower; the villain a reason to seek it.

Roofs (stand on a roof, a fight on the roofs) are bigger than any of these: the physics of landing on a box top is L4's with depth and I would leave it until the depth windows are in.

## 5. What a new read for Encounter, and the question of feet and middle

- **`WorldLanes.crossingAlong(S, x, z, dirz, reach)`** (scratch, `mk_dh.py`): the next crossing along the avenue that holds x, deeper (`dirz` -1) or nearer the camera (+1), from depth z: `[cx, cz, hx, hz, dz]`, `[]` when the band ends first. From the front street at the three-street table: the middle street at 1,012 units deeper, then the back street, then nothing. A pure read (not timed: a scan of the crossings in reach, a few microseconds).
- **Feet or middle.** In the sim the fighter's `y` **is the feet**: standing is `f.y == groundY` and a landing is `f.y <= groundY` (`fighter.gd` lines 130 and 489). L3's `sweep` and `blocked` take the point as the body's **middle** (the box runs `y - ry` to `y + ry`), half a body (37.5 units) lower than the real body. **Settle it as feet**: change L3's convention to the sim's, one line in each of `sweep` and `blocked` (the box runs `y - margin` to `y + 2 * ry`), plus the callers that pass a body's point (`_checkHitSwept`, `_flightToSwept`), and `probe_collide`'s cases. Depth is off, so it is neutral. Simulation's core part then keeps feeding `f.y`. I will make it in the next World window on the EP's go.

## 6. Rendering's sides of the same picture

`docs/rendering/destruction-look.md` is Rendering's. Where my proposals meet it: breach events (`x0`, `x1` on `floor_hit`), the breach's width as a read from the state (`fhole`), the failing state's timeline (`failT`, `failDir`, `failK`) as the thing they animate instead of timing the fall by `delay`, and a lean as a function of the breaches and the core. The core and columns are theirs to draw from `hp / maxhp`. If they would rather have a different state, it is a negotiation; the costs above are small either way.

## 7. Windows and sizes (estimates)

| Window | What | Touches | Golden | Size |
| :--- | :--- | :--- | :--- | :--- |
| **A. The brunt as data** | `data/biomes/brunt.json`; `brunt.gd` reads it; the tier factor, chain length, house cost, the lodge | World (`brunt.gd`, data), schema by Tools | yes (matches change) | about one World day; a re-measure |
| **B. Breaches** | `fhole` per floor, breach width by ratio, floors clear at 70%, `floor_hit` x0 x1 | World, `state.gd` and `hash.gd` (Simulation's grant: a field and a name) | yes | one window |
| **C. The failing state** | `failT`, `failDir`, `failK`, the staged pancake and topple, the falling stack's damage | World, grants in `state.gd`, `hash.gd`, `fx.gd`; Combat's damage number | yes | one to two windows |
| **D. The rules of section 4** | wall slam, cover, falling stack as rules in `damage` and beams | Game Design rules, then Combat and World | yes | after rulings |
| **E. Encounter's side** | the planner's levers, sends down an avenue | Encounter | yes | their window |
| **F. L3's feet convention** | one line each | World | no (depth off) | a small slice |

Order I would take: **F with A** (a small window of code and data, the rules of tier and the lodge, one golden), then **B**, then **C** with Rendering's look landing alongside; D waits for Game Design.

What I need from the EP: Orb's or Game Design's ruling on V2 (does tier 1 dent?), the three rules of section 4, and the order above. No tree edits without your go.
