# Schemas for the lanes window: the proposal for Tools (2026-10-11)

Owner: World and Environment. Tools owns `tools/schemas/`; this is what the validator needs once L1 with D1 is in the tree (`node tools/validate.js` on it: 27 errors and one warning, all of them below).

## `data/biomes/settlements.json` (`biomes-settlements.schema.json`, schema string `biomes.settlements/1`)

Top level, add:
- `enabled`: boolean. The re-laid city is used when true; false keeps today's layout (the generator is not called, the light digests are today's).
- `foreground`: boolean (default true). false leaves row 0, the foreground row, empty: it stands between the camera and the fight until Camera frames it.
- `pop_refs`: object, additionalProperties false, required `near_share` and `building_share`, both numbers above 0 and at most 1. The population references of the planner and the lure as shares of the starting population: `near_share` 0.09 (the share of the planet's people within a radius that reads "populated"), `building_share` 0.02 (a building's own cap for the planner's care term).
- `looks`: array of unique non-empty strings (the look names in index order; every district's `look` is one of them; `S.lanes` carries the index).

District (`$defs/district`):
- remove `depth_aspect` from `properties` and from `required`;
- add `depth_fill`: array of exactly two numbers, each from 0.1 to 1 (the share of a lane's depth a footprint fills, low and high), required;
- add optional `traffic`: number from 0 to 1 (the lane strips' vehicle density the props will read; unused until P1).

Everything else in the file is as the schema has it (`kinds`, `landmarks`, `row_h`, `rows`, ...).

## `data/biomes/lanes.json` (new: `biomes-lanes.schema.json`, schema string `biomes.lanes/1`, a line in `tools/schemas/map.json`)

Top level, additionalProperties false: `schema` (const `biomes.lanes/1`), `_about` (string), `z_front` and `z_back` (numbers in fighter heights, `z_front` above `z_back`), `d_min_bh` (number above 0), `lanes` (array of at least 2 objects: `name` string, `kind` enum `street`, `block`, `scenery`, `ridge`, `top` and `bottom` numbers with `top` above `bottom`, `row` integer from -1 to 3: -1 for a street), `strips` (array of objects: `lane` string naming a lane of kind `street`, `kind` enum `sidewalk`, `kerb`, `carriageway`, `top` and `bottom` numbers with `top` above `bottom`). Cross-checks for the validator's xref pass: lanes do not overlap and are ordered from front to back; each strip lies inside its lane; the lanes of kind `block` carry rows 1 and 2, the `scenery` lanes rows 0 and 3.

## `data/biomes/stages.json` (`biomes-stages.schema.json`)

Add `coreCapShare`: number from 0.05 to 1 (1 is off). One floors hit (a brunt or a shot through a skyscraper) wears a building's core by at most this share of its hit points. First value 0.5. The loader clamps to this range.

## Events and the data hash

No new event type. `building_fall` gains the field `landmark` (bool; true when the fallen building is a landmark) in `FX_FIELDS` (done in `hash.gd`) and in `docs/architecture/fx-events.md`. The replay's data hash gains `WorldSettle.dataHash()` (settlements and lanes data: done in `replay.gd`).
