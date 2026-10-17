# Place names for the stored planet: a grammar

Owner: Narrative and Fighter Identity. Version 1, 2026-10-16. Asked by Game Design (`docs/design/run-mode.md` section 2): "a name grammar for the planet's places (12 cities, about 31 towns, landmarks), generated from each place's seed, original and Legal-screened." The banks and examples are `pending/place_names.json`. Everything is an option for Orb. Original; no real place, no franchise place; Legal screens the table once (section 5).

## 1. The idea

Every place on a procedural planet has a seed (World's `planet-slice.md`). **A name is a stem plus a suffix, picked from a hash of that seed**, so the same planet always gives the same names, nothing is stored, and a shared seed shares its map. The stems come from the place's biome (what the land is like) and, for a city, from the trades of a city; the suffix comes from the place's kind (what it is).

## 2. The grammar

| Kind | Shape | Example | Letters |
|---|---|---|---|
| **City** | a city stem or a biome stem, plus a city suffix | Brinehold, Lamphold, Anvilgate | up to 12 |
| **Town** | a biome stem plus a town suffix | Larkwick, Deepmere, Shoalby | up to 12 |
| **Landmark** | a stem plus a landmark noun (two words) | Chime Bridge, Bell Stair | up to 13 |

**The banks** (12 stems for each biome; 12 city stems; seven suffixes for each kind):

| Bank | Words |
|---|---|
| **Ocean** | long, salt, tide, gull, net, reef, drift, brine, kelp, wake, shoal, cove |
| **Plains** | furrow, wind, grain, hay, clover, barley, lark, fallow, hedge, wheel, mill, thresh |
| **Forest** | deep, oak, wren, fern, moss, bramble, holly, elm, alder, birch, hazel, thorn |
| **Desert** | sun, dust, ember, dry, bleach, cinder, brass, scorch, flint, dune, rust, amber |
| **Mountains** | anvil, crag, slate, flint, tor, pike, high, stone, tarn, raven, cloud, ridge |
| **Ice** | rime, floe, glass, pale, thaw, berg, sleet, hoar, white, sheet, gleam, shard |
| **City stems** (any biome) | bell, lamp, kiln, forge, brass, signal, quay, mill, loom, anvil, chime, spool |
| **City suffixes** | gate, hold, reach, rise, haven, cross, ford |
| **Town suffixes** | stead, lea, holt, wick, by, field, mere |
| **Landmark nouns** | Tower, Spire, Bridge, Falls, Stair, Light, Rock |

**How a name is picked.** The hash is FNV-1a over the text `seed:kind:salt` (a pure function; no draw from the sim's random stream). The first number picks the stem and the next bits pick the suffix. A city draws half its stems from the city bank and half from its biome. If the name breaks a rule, the salt moves on by one and tries again.

**The rules.**
1. One word of **at most 12 letters** (a landmark is two words, 13 letters at most).
2. **Unique within a planet.**
3. **No doubled letter** where the stem meets the suffix (so no "Screemere"), and no "-by" after a stem ending in y or b.
4. **Never on the blocklist,** and never a real place Legal finds (section 5).
5. **No school, hospital or place of worship**, and no such word in any bank (Legal c08). A landmark is a tower, a bridge, a light: never a building a person goes to for help or prayer.
6. **Nothing that reads as a slur** in English or in the languages Legal checks.

## 3. How a name is shown

- **In the HUD** in capitals, as the places already are (LONGWATER, BELLGATE): a card says **BRINEHOLD**, with its kind and state.
- **In a line** as `{place}`, in ordinary case: "{place} has fallen. The people got out." becomes "Brinehold has fallen. The people got out."
- **A fallen place keeps its name** in the ledger and on the map, with the state beside it. Ruins are crossed, not fought in.

## 4. Thirty-two examples

Made with the banks above and these seeds. The biomes cycle, as an illustration; the real biome comes from the place.

| Kind | Biome | Seed | Name |
|---|---|---:|---|
| city | ocean | 20261016 | **Brinehold** |
| city | plains | 20261017 | **Lamphold** |
| city | forest | 20261018 | **Bramblereach** |
| city | desert | 20261019 | **Anvilgate** |
| city | mountains | 20261020 | **Spoolrise** |
| city | ice | 20261021 | **Shardhold** |
| city | ocean | 20261022 | **Spoolgate** |
| city | plains | 20261023 | **Hedgerise** |
| city | forest | 20261024 | **Quaygate** |
| city | desert | 20261025 | **Cindergate** |
| city | mountains | 20261026 | **Quayrise** |
| city | ice | 20261027 | **Rimehaven** |
| town | forest | 20261100 | **Deepmere** |
| town | desert | 20261101 | **Rustholt** |
| town | mountains | 20261102 | **Tormere** |
| town | ice | 20261103 | **Floemere** |
| town | ocean | 20261104 | **Shoalby** |
| town | plains | 20261105 | **Larkwick** |
| town | forest | 20261106 | **Bramblelea** |
| town | desert | 20261107 | **Rustlea** |
| town | mountains | 20261108 | **Stonewick** |
| town | ice | 20261109 | **Sheetmere** |
| town | ocean | 20261110 | **Brineholt** |
| town | plains | 20261111 | **Larkmere** |
| town | forest | 20261112 | **Deepby** |
| town | desert | 20261113 | **Brassmere** |
| landmark | mountains | 20261200 | **Tarn Tower** |
| landmark | ice | 20261201 | **Spool Tower** |
| landmark | ocean | 20261202 | **Chime Tower** |
| landmark | plains | 20261203 | **Hay Light** |
| landmark | forest | 20261204 | **Bell Stair** |
| landmark | desert | 20261205 | **Chime Bridge** |

A few of these will not be liked (Spoolgate, Shardhold). A name is a coin Orb can flip: the stems are cheap to change, and one edit to a bank renames every planet that uses it.

## 5. What Legal screens, once

**Corrected 2026-10-16.** The first count (588 + 504 + 588 = 1,680) was a product of bank sizes, and it counted a name twice whenever two banks share a stem (flint, mill, anvil, brass). Legal counted 1,569 distinct on that table (532 city, 477 town, 560 landmark). I re-ran the check on the table's own list, with the join rule and the 12-letter limit: **532 city, 473 town and 560 landmark names before the blocklist (1,565 in all; the four short of Legal's count are in the join rule, which I will compare with Tools' printout)**.

Legal's w06 then removes eleven real towns (bellhaven, larkfield, longfield, stonebridge, stonegate, sunrise, wakefield, whitefield, whiteford, whitehaven, whiterock), and the ten starting blocklist entries add six more that the banks could make. **After both, the table holds 525 city, 465 town and 558 landmark names: 1,548 distinct.** The eleven are on the blocklist (`blocklist_start` in the data; the table is `pending/place_names_table.json`). A scan of every name for slurs, vulgar roots, and school, hospital or worship words finds none. Legal reads the blocklist again if a bank changes; and a destroyed place is never named for a recognisable real city.

## 6. What it needs

- **World:** a place's name from its seed at the place's creation; the planet's blocklist.
- **Tools:** print the combination table; a check that every name is unique per planet and within the length.
- **UI:** the name on the offer card and the beat screen, and `{place}` in line text.
- **Simulation:** nothing (a name is presentation).

## 7. Questions for Orb

1. Do **plain compound names** (Brinehold, Larkwick) suit the planet, or do you want them stranger?
2. Should a **city** ever be named for its trade (Lamphold, Kilnhold), or only for its land?
3. Do you want the **fixed planet's** old names kept (Longwater, Netmend, Bellgate), as the first planet's names?


## 8. The canon planet (added 2026-10-16)

Orb: "lets work towards crafting a representative fictional planet with consistent names and landmarks." World proposes the canon seed; **its map has not reached me yet**, so these names are made from the grammar and wait for World to say which place is which. Because every name is a stem plus a suffix, a name does not depend on the seed's shape: World can hand each canon place a number and I can name it. Nothing below is final; every name is an option for Orb, and Legal has not screened any of it.

**The decision.** For the canon seed the names are an **authored table** (`pending/canon_planet_names.json`), not generated; every other seed still gets generated names. So the canon planet reads the same in every build and every screenshot, and Orb can change one name without moving the others. Each canon name comes from the screened table of section 5 (checked), and **no two canon places share a stem**, so no two names rhyme by accident.

**The planet's own name.** Six options, each a coinage: none is a real place or a word from a franchise, and Legal has not screened them.

| Name | Why |
|---|---|
| **Brindle** | a patchwork coat of many colours: the planet is made of very different lands |
| **Marrowell** | marrow, the core, and a well: deep and old |
| **Tessane** | soft and invented; no meaning to argue with |
| **Kestrane** | a kestrel's height: the planet seen from the sky |
| **Oarel** | short; an oar and a shore |
| **Vesperin** | evening, for a world the fight keeps darkening |

I would pick **Brindle**. It says "a patchwork" in one word, and it sounds like the other names without being built the same way.

**Twelve cities** (suffixes gate, hold, reach, rise, haven, cross, ford):

| Biome | Names |
|---|---|
| Ocean | Shoalgate, Saltreach |
| Plains | Grainreach, Threshreach, Lamphaven |
| Forest | Loomreach, Hazelhaven |
| Mountains | Highgate, Signalhold |
| Desert | Anvilhold, Brassford |
| Ice | Paleford |

**Thirty-one towns** (suffixes stead, lea, holt, wick, by, field, mere):

| Biome | Names |
|---|---|
| Ocean | Wakeholt, Longby, Covemere, Netwick, Driftlea, Brinemere |
| Plains | Millmere, Barleyfield, Wheelwick, Fallowlea, Hedgeholt, Windby, Haywick, Furrowlea |
| Forest | Birchstead, Hollylea, Alderlea, Mossholt, Fernby |
| Desert | Flintlea, Rustwick, Dustmere, Scorchmere |
| Mountains | Craglea, Ridgelea, Slateby, Torfield, Tarnby |
| Ice | Hoarmere, Glassmere, Bergholt |

**Twelve landmarks** (never a school, hospital or place of worship; each one is something you can see from far away or fight beside):

| Biome | Names |
|---|---|
| Ocean | Gull Light, Reef Rock |
| Plains | Clover Bridge, Lark Tower |
| Forest | Wren Bridge, Oak Falls |
| Mountains | Pike Stair, Slate Falls, Raven Rock |
| Desert | Dune Spire |
| Ice | Shard Spire, Rime Falls |

**How they are used.** A fallen place keeps its name. A line says it as `{place}`. A landmark can be a set piece (a fight at Gull Light, a bridge to cross, a stair to throw someone down) and a beat can name it ("Slate Falls is gone." is a better line than "a waterfall is gone"). Once World places the twelve cities, I will match a city to a landmark in sight of it and note which names sit where.

**Checks run.** Every canon name is in the table that has no blocked town and passes c10 (`python docs/narrative/line-lint.py --names docs/narrative/pending/place_names_table.json` prints 1,548 names, 0 failing). Legal should still read the canon list once, because a name that is fine in a grammar can be a real town on its own: I have not searched the web for these.

**Questions for Orb.** 1. Do you like **Brindle**, or another of the six? 2. Do you want a **twelve-city** planet named in full, or only the places the run visits?
