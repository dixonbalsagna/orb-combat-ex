# A new planet every run: the name workshop, the naming rule and the four home areas

Owner: Narrative and Fighter Identity. Version 1, 2026-10-19. Orb (homework 31, `docs/ep/vision.md`): "I think a new planet should be generated every run, perhaps with the same name. I want to workshop more planet name ideas." And: "lets build the world with the idea in mind that each fighter at launch should have their own starting area on the planet, somewhere thematic and unique in the world." Paper only. **Everything is an option for Orb; nothing is canon.** Original; no orbs; every name is unscreened by Legal. The data is `pending/planet_names.json`; the short version for Orb is `voice-lab/homework/planet-names-and-homes.md`.

## 1. The planet's name workshop

If every run is a fresh planet, **the name stops being a place and becomes a title**: the thing the show calls the stage. That changes what a good name is. It must be easy to say a thousand times, sound right for any biome mix, and carry a little meaning without explaining itself. Eighteen candidates in four styles (earlier picks kept, so Orb can compare):

| Style | What it sounds like | Candidates |
|---|---|---|
| **1. Plain compound** | Like the places on it (stem + suffix), so the planet and its towns sound like one world | **Brindle** (my earlier pick: a patchwork coat, which is what a planet of mixed lands is), **Everhold** (World's working name), **Wayhold**, **Tallowmere** |
| **2. Short and invented** | Soft, two or three syllables, no meaning to argue with | **Tessane**, **Oarel**, **Kestrane**, **Ostrel**, **Marrowell** |
| **3. Old and weathered** | A name from earlier seasons, the kind people say without thinking | **Carrowdeep**, **Harrowfell**, **Thornmarch**, **Sallowgate** |
| **4. A title, or tied to the lore** | What the show calls it; the last three lean on Orb's lore pick (homework 37) | **The Round**, **The Long Way Round**, **Kindlewick** (the Furnace), **Ebbhold** (the Tide), **Gazemere** (the Regard) |

**My short list:** **Brindle** (it says "mixed" in a word), **The Long Way Round** (it is the planet's own trick: fly either way and come back), and **Tessane** (the easiest to say; the safest for a name used a thousand times). The lore-tied names wait for Orb's lore pick, and one of them only makes sense if that idea wins.

**Why the same name each run can make sense in the story** (two options):
- **"It means home."** In every language of the show, the word for the fighters' world is the same word, so each planet a run lands on is "Brindle" to the people on it. The planet changes; the word does not.
- **"The stage rebuilds itself."** The place the fights keep happening is a proving ground that remakes its land between seasons, so it is one world in the show's mind and a new face each time. (This one also supports a lore where the planet is a source, Option B.)

## 2. The rule for naming places on a fresh planet

Orb said he wants the world "consistent and recognizable" and a fresh planet each run. The two fit together if **the names of the roles stay and the names of the places change**.

1. **The planet keeps one name.** Whatever Orb picks is the same every run. The seed is shown as a small number beside it ("Brindle, no. 4417") for anyone who wants to share a planet.
2. **The role names recur on every planet.** The hub city is always **Bellgate**, the town nearest it **Kilnstead**, the farthest town **Farwatch**, the coastal town **Netmend**; the great sea is **Longwater**, the first plains **Furrowlea**, the great forest **Deepholt**, the desert **Sunwaste**, the high range **Anvilfell** (World's canon names, `docs/world/canon-planet.md`). Each goes to whichever place on the fresh planet fills that role. So the player meets Bellgate in every run and it is never in the same place. Roles with no match on a seed (a planet with no desert) simply do not appear.
3. **Everything else is named from the grammar** (`place-names.md`): a stem for what the land is like plus a suffix for what the place is, picked from a hash of the place's own seed, so the same planet gives the same names on every device and nothing is stored.
4. **Each fighter's home area has a fixed name too** (section 3), so a fighter's home is as recognisable as Bellgate.
5. **The rules hold:** one word of at most 12 letters, unique within the planet, no doubled letter at the join, nothing on Legal's blocklist (the 1,548-name table is checked), and never a school, hospital or place of worship. A fallen place keeps its name in the ledger and on the map.
6. **A planet repeats on request.** "Same planet again" (the results page) replays the run's seed, with the same names.

## 3. A home area for each of the four

**What a home area is** (my reading of Orb's rule of cool): a place on every fresh planet that belongs to one fighter and shows who they are. It is where a run begins when the player is that fighter, and the fighter's ground when they are the opponent (a home advantage in colour, never in numbers: cosmetics and set pieces only, nothing that changes balance). Each is a **set piece** with a fixed name, a biome class, a handful of landmarks and one thing the stage does that no other stage does. The generator places all four on every planet. **The polar outposts stay free**: they are reserved as a set piece for a later fighter (Orb: "this may be a set piece for a new fighter").

Each home is tied to the fighter's **power foundation**. The foundation depends on Orb's lore pick, so I have written every home to work under all three ideas and added one line for each (**A** the Furnace, **B** the Tide, **C** the Regard).

| | **The Protagonist: Mendquay** | **The Anti-hero: Rankhold** | **The Empress: Crownreach** | **The Cyborg: Slagholt** |
|---|---|---|---|---|
| **Land** | A working harbour town on a coast | A terraced town up a cold mountainside | A flat, ceremonial enclave on the plains | A scrap and breaking yard on a desert or dry coast |
| **Who they are at home** | Where things are always being mended: scaffolds, a workshop, a practice yard. The promise tags hang in the shop | Where everything is ranked and pressed: tiers of stairs, polished halls, a wall of standings | Her province, set down on someone else's world: an avenue of banners, a records tower, a guard barracks | Where wrecks go to be eaten: cranes, hulks, slag heaps, a rusting dock |
| **The set piece** | **The Mending Pier**: a half-rebuilt pier with scaffold you can break and a town that rebuilds it after the fight (the Fixer's promise, kept after the bell) | **The Rank Stair**: a huge stair of tiers; the fight climbs it, and each tier is a landing | **The Annex**: the tall records tower; banners and pages fall as it is struck; the guard lines the avenue in a 3v1 | **The Breaking Yard**: wrecks and cranes to throw people into; the wreckage is his fuel (not people: Legal) |
| **A** the Furnace | An old foundry on the quay: the open hearth, always lit | A pressure vault: cold stone, no windows | A kiln-hall that stamps each revision | Slag heaps and open furnaces; his damper is the cold |
| **B** the Tide | The pier, where the tide runs through: a shore | A breakwater fortress: the sea wall | An observatory that charts the tides | A wreck-strewn coast where the tide leaves its dead hulls |
| **C** the Regard | A sparring yard the whole town comes to watch | The League's ranking hall, his standing on the wall | A court of records, every petition filed | A closed arena nobody watches any more |
| **Why it fits** | The fighter who gives and repairs, and who made a promise to the town | The fighter who ranks and holds | The fighter of paperwork and the royal "we", who lands a province | The fighter of appetite, fed on wreckage and nothing alive |

**A line from each, at home** (4 to 12 words, in the voice bibles; the fighter says it at the start of a run or a fight on their ground):

## The Protagonist
> "Same crooked plank. Same pier. Good to be home!"

## The rival
> "Everyone here knows exactly where they rank."

## The Empress
> "Our province, rat. Do mind the banners!"

## The Cyborg
> "Smells like old steel. My favourite kind of lunch!"

**What it asks of others.** **World:** four fixed set-piece place classes with their names, placed on every seed in a suitable biome (coast, mountainside, plains, dry coast or desert), never inside a polar outpost. **Art:** a look for each (concept sheets, later). **Game Design:** whether a home is where a run begins as that fighter, and whether it appears as an opponent's ground (and in versus, as a stage option). **Legal:** no school, hospital or place of worship at any home; the Cyborg's yard feeds on wreckage and never on people; the Empress's guards stay in the 3v1.

## 4. Questions for Orb

1. Which planet name or names? Mark up to three; I write the story reason for the winner.
2. "Same name each run": **it means home**, **the stage rebuilds itself**, or your own?
3. Do the recurring role names (Bellgate, Longwater and the rest) stay on every planet? They are what keeps a fresh planet familiar.
4. Do the four homes feel right? Change any in a line.
5. Do the polar outposts stay free for a later fighter?
