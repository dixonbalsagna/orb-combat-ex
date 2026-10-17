# Stored places for the canon planet (World, 2026-10-17): in scratch on main's HEAD, parked, not applied

The EP's GO (after Performance's audit): store the places list for the canon planet so a load does not place them. Built on main ff68e994 (planet window 1). **Not applied.** `sim/world/planet.gd`, `data/biomes/planet.json` and its schema are World's; nothing else is touched.

## What it is

- **`planet.json` `story.everhold`**: `{seed: 7, name: "Everhold", places: [...]}`: 42 places (11 cities then towns, as the generator makes them), each `{kind: 0 or 1, x, y, z, r}`. **A coordinate is stored as its float64 bits** (16 hex digits, high word first, read with `SimMathx.f64`), not as a decimal: a JSON number does not round-trip a float64 (it needs 17 significant digits), the bits do, exactly, on any platform.
- **`WorldPlanet.make(seed)`** loads a story planet's stored places (`storyFor(seed)` finds the entry whose seed it is) and skips the placement; any other seed is generated as before. `makeGenerated(seed)` always generates (the check's reference). `dataErrors()` validates the story entries (a kind of 0 or 1, 16 hex digits each).
- **The schema** (`biomes-planet.schema.json`) now types the story section: seed, name, and a non-empty places list whose items are exactly `{kind, x, y, z, r}`.

## Checks and numbers

- `planet_store_check.gd`: **0 failed**: the data loads clean; the story holds Everhold with 42 places; other seeds have no entry; **the stored places equal the generated ones bit for bit** (positions, kinds, radii and the people weights); a stored planet loads in **0.16 ms against 410 ms generated** (a floor of 20 times is asserted); a slice of the stored planet is the generated planet's slice (hash `d0f86ade`).
- `planet_check.gd`: **0 failed** with the story in place (its vectors file is unchanged: the places' hash is the same, so nothing the planet function reads has moved: **no golden moves**).
- `node tools/validate.js --self-test` 7545 of 7545; `node tools/validate.js` 0 errors, 0 warnings.
- **If the generator's numbers ever change** (`planet.json`'s places keys), the stored list does not: the check fails and says so. Regenerate with `planet_store_dump.gd -- 7 out.json` and `mk_stored.py`.

## With the time-sliced loader

`../planet-slicing/` is re-cut **on top of this** (apply this first): `PlaceJob` returns a story planet done at once, so Everhold's load is the pick (9 ms) and the slice only: **the coarse ground is ready after 64 to 86 ms and the whole load is about 130 to 150 frames of 4 ms (0.56 to 0.62 s of work)**, against 325 frames and 0.76 s to the coarse ground when the places were generated (planet 11, with no story entry, still takes 1.6 s of work). The re-cut chain (stored, then slicing) applies on HEAD and the three checks (`planet_check`, `planet_store_check`, `planet_job_check`) pass: 0 failed each.

## Files

| File | What |
| :--- | :--- |
| `planet-stored.diff` | The patch on HEAD: `planet.gd`, `planet.json`, the schema, the new check |
| `mk_stored.py` | The script that makes it from `everhold_places.json` |
| `everhold_places.json` | The generated places of planet 7 as bits (from `planet_store_dump.gd`) |
| `planet_store_dump.gd`, `planet_store_check.gd` (+ `.uid`) | The dump tool and the check |

**Lines in files that are not World's:** none. Tools' map rule for `planet.json` already exists; the new schema keys need no new fixture, but a case for a bad hex digit is optional.
