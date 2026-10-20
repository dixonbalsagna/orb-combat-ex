# Arena sizes and the fighters' homes (World, 2026-10-19)

Owner: World and Environment. Orb (homework 31, `docs/ep/vision.md`): **smaller arenas** ("lets try to incorporate this in a meaningful way. every player might not like every fight to take place along the entire planet"); **a new planet every run** ("perhaps with the same name"); **a home for each launch fighter** ("each fighter at launch should have their own starting area on the planet, somewhere thematic and unique in the world"; the outposts "may be a set piece for a new fighter"). **A proposal and a measurement; nothing in `sim/` or `data/` changed.** It builds on `small-circles.md` (small-circle loops, K1 to K3), `arena-shift-research.md` (the shifting arena), `outposts.md` and `canon-planet.md`, and on Narrative's `docs/narrative/planet-and-homes.md` (the four homes' names and looks). It needs Game Design's review (section 4); the EP routes it.

## 1. The idea in one line

**The arena's size is a property of the stage, and a fighter's home is a close ring round their home.** A run opens small and close at the player's own home, widens as it goes, and ends on the whole planet; a versus match lets the players pick the size. That makes "a smaller arena" a different kind of fight, not a smaller version of the same one, and it makes each fighter's start a place with a face.

## 2. Three sizes, and what each is for

All three are loops on the one planet (a plane through the planet, `small-circles.md` §1), so names, cities, landmarks and wear are the same at every size.

| Size | Loop | A lap, flat out | A screen is | What it is |
| :--- | ---: | ---: | ---: | :--- |
| **Whole** | 153,600 units (the planet's great circle: today's arena) | 15 s | 2% | The epic: the whole planet to cross, a long chase, a skyline that changes biome. The boss, a showpiece, and today's default |
| **Half** | 76,800 | 7.5 s | 4% | A region: one or two cities, a coast, a range. About 35% settled, 1.4 cities and 2.4 towns held |
| **Close** | 38,400 | 3.8 s | 8% | A neighbourhood and a brawl: it loops round a centre you can see from everywhere (a city, a mountain, a bay, a pole). 48% settled, 1.0 cities and 1.5 towns, the same 1,800 people on fewer places |

**What a smaller arena changes in play** (these are the reasons to want one, and the questions for Game Design):
- **Nowhere to run.** The loop is the whole world: a chase is a lap in four seconds, and the escape stance has less to gamble on. Pursuit and blitz read more, a long separation reads less.
- **Collateral is the story.** The same people on fewer, bigger places means a tier ceiling's share falls on one town: a hero is pressured faster, a villain is fed faster. It is the arena where "who is hurting the city" is loudest.
- **The centre is always behind the fight.** A close ring round a harbour, a stair of mountain or a city shows its own middle from every point; that is the picture Orb asked for in homework 22 ("appear to circle around a center point").

## 3. Where each size is used (proposal)

| Where | Size |
| :--- | :--- |
| **A run, the player's first stage** | **Close, round their own home** (section 5). The run begins small and personal |
| **A run, the middle stages** | Half, centred on the next place on the way (the stage picker's candidates, scaled minimum) |
| **A run, the last stage and a boss** | Whole: the planet opens up |
| **A run, a polar stage** | Close, round a pole or an outpost (K2 of the small-circles pictures) |
| **A versus match** | A setup choice, **Whole by default**, and the size is part of a replay's setup |
| **The demo and today's matches** | Whole, unchanged (no setup key means today's) |

## 4. What it costs, and what is open

- **Simulation** (the one real change): the wrap and the column count are constants today (`SimConst.W`, `HALF`, `NC`, read in about 210 places). Make them static variables set once in `newMatch` from a setup key `arena` (the length in units; absent means today's); four compile-time `const`s built from them become functions. **The golden does not move** (the default is today's). A 1v1 golden byte-identical with `arena` absent is the proof. One window.
- **World** (no golden): the picker takes a **centre** (a home, a city, a landmark, a pole, a random point), a loop length and a bearing, with a minimum scaled to the length (data), and the centre place counts as held when the loop lies inside its disc. Planet window 1's module extended. Measured on planet 7: a loop meets the scaled minimum in 10 to 22% of cases, so the picker tries a seeded list, as now. One window after Simulation's.
- **Rendering and Camera**: the far land's fog and fade (`FOG_FAR` is 0.78 of the planet), the sky and the camera's zoom ceiling (a view up to 21,333 units wide is over half the smallest loop) read the wrap and need a look at 38,400. The far side of a loop can show the real opposite arc and the real centre (cosmetic, after). Theirs.
- **Game Design** (open): the collateral budget and tier ceilings per size (a close ring's share falls on fewer places); whether the escape stance, the AI's roaming and the match-length targets scale with the loop; whether a versus player picks the size or the stage does; and the run's size ladder in section 3.
- **Order:** Orb's call that this is worth building, then Simulation's `arena` key, World's centre picker, Rendering's far land for a loop. No step moves the golden.

## 5. A home for each launch fighter: World's side

Narrative has named four homes that **appear on every planet**: Mendquay (the Protagonist's harbour town, always being mended), Rankhold (the Anti-hero's terraced mountain town), Crownreach (the Empress's plains enclave with an avenue of banners) and Slagholt (the Cyborg's breaking yard in the desert). World's part is to put them there, the same four on every seed, and to build the start round them.

**A fourth kind of place.** `KIND_HOME` beside the city and the town (and the outposts of `outposts.md`): a disc of a town's size (2,440 units), its own fixed plan and landmarks (Art's looks, a place class like Bellgate's), a fixed name, and its people as any place's area weight. Placed by **another keyed pass** of `WorldPlanet`'s places, after the cities, towns and outposts, so **nothing already placed moves** and a planet without homes is the planet of today. Never within a place's disc and never in the polar caps.

**The placement rule, per home**, from the planet function (sampled at the site and at eight bearings 900 and 2,600 units out):

| Home | Site | Found, strict rule, on 24 planets (2,500 candidates) | Median candidate index |
| :--- | :--- | ---: | ---: |
| **Mendquay** (harbour) | land that is not mountain, the sea within 900 units on 2 to 5 of 8 bearings, land on at least 3 of 8 within 2,600 | 23 of 24 | 155 |
| **Rankhold** (mountainside) | mountain here, or on 3 or more of 8 bearings within 900; land on 6 of 8 | 21 of 24 | 35 |
| **Crownreach** (plains) | plains here and on 7 of 8 bearings within 900 and 6 of 8 within 2,600 (plains or forest) | 24 of 24 | 58 |
| **Slagholt** (desert) | desert here and on 6 of 8 bearings within 900 | 24 of 24 | 133 |

All four are found on **20 of 24** planets by the strict rule; the worst single search took 1,581 candidates (about 27,000 surface reads, roughly a second of work in the time-sliced loader's steps; the median is a few hundred reads). **For the other four planets**, a rule must not fail: score each candidate (how many of the conditions it meets) and take the best of the list, so a home always exists and sits on the best ground the planet has (a Rankhold on its steepest hill, a Mendquay on its best bay). Its look adapts (Art's plan is a set piece laid on the ground it finds). A planet with no real mountain gets a Rankhold on a hill; **the picture, not the rule, carries the fantasy**. Narrative: Rankhold is "cold", which this does not require; a latitude term is a data key if wanted.

**Where a run begins.** The player's fighter's home is the **touch-down of the first stage**: `WorldPlanet.pick` is given the home as the touch point (and, with section 2, a close ring round it), so the first fight is at their home and the home is the centre behind the fight. The same home is "the fighter's ground" when they are the opponent (Narrative: cosmetics and set pieces, never numbers).

**The polar outposts stay free** for a later fighter (Orb's note: they "may be a set piece for a new fighter"): they are a separate pass, after the homes, and never inside one.

**A new planet every run, the same name.** The run's seed is the planet's seed; the name rule is Narrative's (a fixed name, fresh names for the other places, nine roles keeping their names). The planet is built by the time-sliced loader during the previous stage's beats; a home's search is one more job in `PlaceJob`. Everhold (seed 7) stays the canon sample and a test planet; its stored list would gain its four homes (appended, so nothing moves).

**What World needs.** From Narrative: confirmation of the site rules above (especially Rankhold's cold). From Art: a plan and landmarks per home, as Bellgate has. From Game Design: whether a home is where a run begins as that fighter, and whether Close is the first stage's size (the proposal). From Simulation: the `arena` key (section 4), and the wear list's place ids already cover a home as a place.

## 6. The shifting arena (Orb's second question), in a line

Drawn in `homework/31b-shifting-arena.svg` (a plane through the fighters turning and drifting, the ring sweeping new ground, three moments). The cost, from `arena-shift-research.md`: a slow cosmetic drift of the far land is days; a real move at a calm moment (a finisher's cut, an act break) is worth building (re-read 0.6 s in the background, carried by place id and plan index, hashed as an epoch) and is a few weeks across World, Simulation and Rendering; a ring that moves every tick I would push against. **It combines with the sizes:** a Close ring that shrinks toward its centre at act breaks is the same move, and a run's stages are already the calm moments.
