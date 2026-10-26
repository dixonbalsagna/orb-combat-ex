# Park: the fine biomes (Audio and Music, rebased on HEAD 2026-10-26)

World's generation 2 biome ids (`data/biomes/climate.json` "fine": 0 ocean, 1 plains, 2 forest, 3 desert, 4 mountains, 5 ice_sheet, 6 sea_ice, 7 jungle, 8 savanna, 9 tundra, 10 taiga, 11 wetland, 12 beach, 13 highland, 14 volcanic) are on main (4dc06456, 630dcbad). This extends the biome sound that is on main (b4c1d3dc, off) to read them. Parked **off** like it: nothing changes in play until the switch, and the fine ids only matter on a generation 2 planet.

**Audio's own files, plus Tools' closed schema and cross-reference rule for the one new data key (`grant_tools.py`).** The water v2 park (`docs/audio/pending/water-v2/`) stacks on this one.

## What it does

- **Which biome.** `AudioWorld.biome_at(x)` is World's own `WorldBiomes.fineNameAt(x)`: a village or a city first (the settlement's own ground), then the fine biome on a generation 2 planet, else the stored biome's name (the alias), so a hand-made world or a generation 1 planet is the seven it always was. `warm_beds(S)` reads `WorldBiomes.fineCols` and `planetCols` the same way. (The first version of this park read the column by reflection because main had none yet; it is simplified to World's own API now.)
- **Seven new beds**, each its own place, all under 450 Hz heard: `icefield` (ice_sheet), `seaice` (sea_ice), `savanna`, `taiga`, `highland`, `volcanic`, `shore` (beach); and the three spares built earlier are mapped: `tundra`, `marsh` (wetland), `jungle`. 17 beds; `biomes` is keyed by the fine names plus `village` and `city`. A name with no row takes `default_biome` (plains).
- **The ground** gets the fine biome's own override (`ground`, new): ice_sheet, sea_ice and tundra are snow, wetland and jungle mud, beach sand, highland and volcanic rock; soil of the others by `soil` (savanna and taiga grass). It applies to the sim's soil, rock and sand classes (the sim reads an ice sheet as the stored biome 5, which is rock, so the override is needed); paving, rubble and water stand as the sim says.

## Apply

From a scratch export first, the repo root only for the EP's apply (and then commit). Tools' files first, then Audio's:

```
python docs/audio/pending/biomes-fine/grant_tools.py <root> --check
python docs/audio/pending/biomes-fine/grant_tools.py <root>
python docs/audio/pending/biomes-fine/apply.py <root> --check
python docs/audio/pending/biomes-fine/apply.py <root>
```

`grant_tools.py` is **Tools' own `docs/tools/pending/audio-ground.patch` rebased on HEAD**: its schema and cross-reference hunks applied as they were, but both `tools/fixtures/cases.json` hunks were rejected (World's lakes case and the neighbours of the insertion moved), so the five cases are inserted by text before the `fight-ricochet-angle-zero` case (`ground_cases.txt`, from Tools' patch), and the patch's one reformatting hunk (the lakes `/refuse` array written out over lines) is left out. Tools' patch file can be retired once this lands.

`apply.py` replaces five files by path (`src/`), only where each is what the park was made from (`old_hashes.json`): `audio/audio_world.gd`, `audio/data/world_cues.json`, `audio/tools/world_check.gd`, `audio/tools/render_biome_demo.gd`, `docs/audio/biomes.md`.

`audio/preview/biomes/` (14 clips and the README.txt addendum) is already in the tree.

## Checks

- `world_check`: all 15 fine biomes have a row and a bed; every ground and soil is a ground with sounds; each of the ten fine biomes reads as itself with the right ground and bed (the fine columns set by hand on the hand-made world); a settlement keeps its own bed over the fine column; stale columns are ignored; `warm_beds` names the fine beds; **a real generation 2 ring (planet 7) reads as 10 biomes, each with a row, and two real generation 2 matches with the set on leave the sim's hash unchanged and give the same cue log twice** (beds heard in them: savanna, mountains, highland, city). Every new bed renders clean, loops without a seam and is under its heard-spectrum limit.
- The other eight audio gates pass, and `host_check`'s sim hashes and cue logs are identical to HEAD's without the park.
- `node tools/validate.js` and `--self-test` pass with the grant (without it validate fails on the unknown `/ground` key).

## Needs

1. Tools: the grant (above).
2. Orb: the ten new beds and two new fights in `audio/preview/biomes/` (README.txt says which).
