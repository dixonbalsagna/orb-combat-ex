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

The banks give **588 city names, 504 town names and 588 landmark names**: 1,680 in all. Tools can print the whole table. Legal searches it once for real places, franchise places and unwanted readings, and anything it finds goes on the blocklist (which already holds ten starting entries, a list Legal will extend). That is a one-off screen of a fixed table, not a screen of every planet.

## 6. What it needs

- **World:** a place's name from its seed at the place's creation; the planet's blocklist.
- **Tools:** print the combination table; a check that every name is unique per planet and within the length.
- **UI:** the name on the offer card and the beat screen, and `{place}` in line text.
- **Simulation:** nothing (a name is presentation).

## 7. Questions for Orb

1. Do **plain compound names** (Brinehold, Larkwick) suit the planet, or do you want them stranger?
2. Should a **city** ever be named for its trade (Lamphold, Kilnhold), or only for its land?
3. Do you want the **fixed planet's** old names kept (Longwater, Netmend, Bellgate), as the first planet's names?
