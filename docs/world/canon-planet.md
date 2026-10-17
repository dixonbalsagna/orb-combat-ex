# A canon planet: Everhold (World, proposal, 2026-10-16)

Owner: World and Environment, with Narrative's place-name grammar (`docs/narrative/place-names.md`) and Legal's blocklist. Orb (homework 22): "lets work towards crafting a representative fictional planet with consistent names and landmarks. I'm not sure if the story mode should have randomly generated planets for each run, or to keep the world consistent and recognizable for the protagonists." **A proposal and a prototype table; nothing in the game.** The map is [L1](planet-slice/l1-canon-planet-map.svg); the data is `scratch-build/small-circles/canon/everhold.json` (made by `canon_names.py`). Every name is a proposal for Legal to screen and Orb to change.

## 1. The proposal

**One canon planet: planet seed 7** (the planet of pictures A to F, the one Orb said he was "very pleased" with: 11 cities, 31 towns, a south pole under an ice sheet, a north pole of sea ice), **called Everhold** (Narrative's pick for the world, `places.md`: "the Round" in speech).

- **The old fixed planet's names are kept where the geography matches** (Orb's earlier question 3 in the place-name note): **Bellgate** is the hub city (the one nearest all the others), **Kilnstead** the town nearest it, **Farwatch** the town farthest from it, **Netmend** the town on the coast; **Longwater** the great sea, **Furrowlea** the first plains, **Deepholt** the great forest, **Sunwaste** the desert, **Anvilfell** the high range. Nine of the old ten names live again (all but Windlea), each still on the kind of ground it was named for.
- **Everything else comes from Narrative's grammar** (a stem for what the land is like plus a suffix for what the place is; a city half from the trades), picked from a hash of the place's own seed, so the same planet always gives the same names and nothing is stored but the table. The rules are theirs (one word of at most 12 letters, unique, no doubled letter at the join, never a school, hospital or place of worship); the blocklist is Legal's 10 starting entries and the 11 real towns of RL-149; I checked every name against it.
- **Landmarks:** one for each city, two words (a stem and a noun: tower, spire, bridge, falls, stair, light, rock; never a building people go to for help or prayer: c08). Bellgate keeps its **Bell Tower**.
- **Three outposts** (Orb: "I like the idea of a remote research station"; section 4): **Glasswatch** on the south shelf, **Rimewatch** high on the ice sheet, **Thawwatch** on a floe at the north pole.

| City | Land | Landmark |
| :--- | :--- | :--- |
| **Bellgate** (the hub) | desert edge | Bell Tower |
| Mosshold | forest | Wren Light |
| Hazelgate | forest | Elm Tower |
| Larkford | plains | Loom Falls |
| Spoolford | desert | Signal Light |
| Loomhaven | forest | Quay Falls |
| Lamprise | plains | Mill Rock |
| Quayford | forest | Brass Spire |
| Fallowhold | plains | Barley Bridge |
| Barleyhaven | plains | Spool Stair |
| Spoolhaven | coast | Fallow Bridge |

**Towns (31):** Millmere, Amberwick, Alderfield, Windstead, Barleymere, Thornstead, **Farwatch**, Grainfield, Cindermere, Cloverwick, Alderby, Wheelstead, Barleyholt, Hedgestead, Fallowstead, Birchfield, Bramblewick, Threshby, Threshwick, **Netmend**, Flintholt, Bramblestead, Brassby, Hayfield, **Kilnstead**, Oakwick, Wrenfield, Amberfield, Threshfield, Wheelfield, Thornwick.
**Regions:** Longwater and Reefwater (seas); Furrowlea and Larklea (plains); Deepholt and Thornholt (forests); Sunwaste and Bleachwaste (deserts); Anvilfell, Cragfell and Torfell (ranges); Sheetwaste (the south ice) and Glasswater (the north pack).

Things the draft shows that a first read will not like: several names share a stem (three Thresh-, three Barley-: the bank has 12 stems a biome), "Spoolhaven" and "Quayford" are not obviously places, and nothing here has a story yet. **A name is a coin Orb can flip**: one edit to a bank renames every planet that uses it, and a single place can be given a hand name in the table.

## 2. How it is held

The planet's `story` section (`data/biomes/planet.json`, empty today) holds story planets by id: `{"everhold": {"seed": 7, "names": {...}, "landmarks": {...}, "outposts": [...]}}`. The sim reads only the seed (the planet is a function of it); the names, the landmarks' words and the outposts' names are presentation (Narrative's; not in any hash). A hand name is an override in that table. Places need a seed to be named by the grammar; planet 7's places already have a fixed order in `WorldPlanet`, and the table keys on a place's id. Legal screens the final table once.

## 3. Canon or random for the story? Both options

| | **A canon planet for the story** | **A random planet for each run** |
| :--- | :--- | :--- |
| **What the player gets** | The same world every campaign: Bellgate is always the hub, the Bell Tower always stands in it, a fallen city is a loss the player remembers, and the protagonists know the map | A different map every run: new neighbours, new geography, new names |
| **For the story** | Narrative can write about places (a rival who grew up in Farwatch, a fall of Bellgate) and the story beats can name them. Consistent and recognisable is Orb's word | Beats are generic ("{place} has fallen"); a story about a place cannot exist before the planet does |
| **Replay value** | From which slices a stage touches down at (the picker is random), from the run's choices and the branching fights, not from the map | Higher from the map itself, lower from the story |
| **Risks** | Familiarity: after a few campaigns the map is known. Mitigation: five fights and a boss over a planet with 42 places and arenas of different sizes (small circles); the damage a campaign leaves is itself new each time | Cities and landmarks are not a character; a seed could produce a poor planet (the minimum guards the slices, not the planet) |
| **Work** | The table above, Legal's screen, Narrative's lines | None beyond the grammar (already needed for any planet) |

**Recommendation: canon for the story, random for everything else.** The story mode uses Everhold, so the world is "consistent and recognisable for the protagonists" and the damage a campaign does to it is the story's memory. **Versus with a planet, the endless mode, shared and daily seeds** use random planets (seed in, planet and names out: the grammar and the same module), which is what makes a seed shareable. It costs nothing extra: the planet module takes any seed, and Everhold is seed 7 with a name table.

## 4. Damage in a story campaign (Orb: "starting a new story should begin everything anew")

The wear list belongs to the campaign. A **new story starts with an empty wear list** (every place whole, every person present); a **continued story** reads its own. Versus, and a run in the endless mode, start whole every time unless the run says otherwise. The planet module needs nothing new (`wearNew()` is the empty list; the run state, Simulation's, holds the campaign's); the save is the campaign's file, not the planet's. A canon planet that is damaged in one campaign is untouched in another.

## 5. Questions for Orb

1. **Canon for the story, random for everything else** (recommended), or random for the story too?
2. Do you like the **names**: the compound grammar (Brinehold, Larkwick), and the keeping of Bellgate, Kilnstead, Farwatch and Netmend? Which would you rename?
3. The **outposts**: three (shelf, high, floe), or fewer?
