# Park: World's GW1c rows: the sizes' conditions and the level crater floor (World, 2026-11-14; EP briefs of 11-14)

Game Design ruled the sizes (`docs/design/planet-sizes.md`): the spawn pair within a launch's reach of a place at every size, and structures under the play height on the small ones. Rendering traced Orb's three humps in a crater to the sim (F-RENDER-03). The stand-in's planet design found a literal. All four are in this park, built on the stack (**globe-step2, a-world-01, planet-sizes, then this**; the four apply in that order and reproduce my scratch tree byte for byte, checked from a clean export of HEAD). Runs: `docs/world/runs/gw1c-world/`. Checks: `SIZES` (extended) and `CRATERFLATTEN` (new, in CI).

| File | What |
| :--- | :--- |
| `gw1c-world.diff` | `sim/world/{waterrec,size,settlements,planet,craters,store}.gd`, `data/biomes/{sizes,craters}.json` and their two schemas, `size_check.gd` extended, `crater_flatten_check.gd` (+ `.uid`), and its line in `tools/world-checks.json`. World's files and data only: no grant |

## What it does

1. **`waterrec.gd` no longer writes medium's 38,400 as a number** (the stand-in's finding). The lake's reach used `38400 / F.N` for a node's spacing; with the nodes scaled by size that was wrong at every size but medium. It is now `PLANET_NC x COL / 4 / F.N`: bit for bit the same number at medium, 128 units at every size.
2. **The spawn is within a launch's reach of a place, at every size but medium** (`sizes.json spawnReach` 6,600, a base send's reach). The touch point already tries up to 16 land points; on a size that asks, it takes the first one whose nearest place (its edge) is within the reach, else the nearest of the tries. Medium's touch points are as they were (no key). `SIZES` measures all 75 spawns (the five sizes x the quick match's five planets x three touches): before, **8 were over the reach, the farthest 20,398 (the fixed planet 7, touch 3, on huge)**; after, all within it, the farthest 6,476.
3. **Buildings stay under the play height on tiny and small** (`sizes.json maxBuildingShare` 0.3 of the radius: 1,956 on tiny, 3,911 on small; the tallest today is 4,875). Applied where a building's height is set (`WorldSettle`), so its floors and hit points follow. A proposal as data for Art's look call: a number, not a decision. `SIZES` asserts the cap against Game Design's 0.3, not against the data's word for it; medium and big are unchanged (the tallest is still 4,875).
4. **A crater is cut on a level floor** (`craters.json globe.flatten`, off): the ground inside the bowl is the ground at the crater's own centre, less the bowl's profile, instead of the hills under it. Fully level inside the lip, easing back to the ground by `flattenFade` (1.45) radii. It is a **read, not a record** (the store and its hash are the same on and off), done where the store's ground is read (`heightDelta` takes the field's height at the point and the crater centre's, a pure function), so the sim's feet, Rendering's tile bake and the camera all read the same flattened ground with no new call. `CRATERFLATTEN` on a place of planet 7 whose hills reach 1,230 units under a 1,991-radius bowl (Orb's was 1,992): **switch off 4 humps in the bowl, on 0**; the floor is within 1.3 units of the centre's ground less the profile; beyond the fade the ground is what it is with the switch off; a peer that read the ground before the dig reads the same 801 columns as one that did not. Negative control (the switch kept off): 2 FAIL.
5. **The lap table of the sizes page is at Orb's 3,500 a second** (12 s tiny, 44 s medium, 176 s huge).

## Gates

| Gate | Result |
| :--- | :--- |
| `SIZES` | 0 failed (with the cap, the spawn reach and the strict loader); negative control (no cap, no spawn reach): 3 FAIL |
| `CRATERFLATTEN` | 0 failed; negative control 2 FAIL |
| World checks (89 with these, shipped data, one Godot at a time) | all pass; two failed on the first run and passed on the re-run: `planet_check` (its lint banned a `clampf(` I had written in `planet.gd`: fixed) and `fill_check` (a timing line, 1,475 against 1,441 microseconds, under load) |
| parity | passes, golden unmoved (medium is unchanged) |

## NEEDS FROM EP

- **Art:** the cap (0.3 of the radius) as data: say a different number, or none, and it is one edit. The look of a tower cut to a third of its height (its shape is unchanged: only the height) is yours.
- **Rendering:** the flatten reads the field inside `heightDelta` near a crater (a cold field read about 90 microseconds, once a point), so the tile bake near a big crater costs more; flip it only after their look gate and a bake read. It changes where a fighter stands in every match with a crater (a different state hash where it plays), so it flips in a hash window (GW1c).
- **Game Design:** whether 6,600 (a base send) is the reach they meant, or a longer one for a bigger planet.
- **Netcode and Simulation:** none new: the cap and the spawn only touch sizes other than medium; the flatten adds no state.

## RISKS

- The flatten also fills a valley inside the bowl up to the centre's height (a level floor both ways): a crater dug beside a lake's shore can lift its floor above the water. The check does not cover water; B1's flood reads the same ground.
- The spawn rule moves the touch point on tiny, small, big and huge (a different place on the same planet number): any recorded play on a size other than medium is not comparable. Orb's build is medium.
- Not timed (shared machine): the flatten's cost is by count, a field read per read near a flatten crater.

## Fix, 2026-11-14 (Encounter found it on the GW1c stack; EP order): the building cap on the plan path

**Fault.** With a-world-01's GW1a data flips on, `size_check` failed on tiny and small: the tallest building was still 4,875 against caps of 1,956 and 3,911. The cap sits in `WorldSettle.generate`, and the places on the flipped data are laid by plan (`WorldPlan.geometry`, which calls `generate` and keeps the result). The plan's memo key and the **kept places' disk key** (`WorldPlan.placesKey`) did not carry the planet's size, so a tiny or small planet read the medium planet's places (the same seed, the same data) back, towers and all. Medium's matches before it in the same process or the same cache folder were enough.

**Fix** (`gw1c-world-fix.diff`, stacks after `gw1c-world.diff`; `plan.gd` and `size_check.gd`): both keys carry `|cols N` when the size is not medium (medium's keys are as they were, so its cache stays good). `size_check` gains rows on the plan path: a medium match first, then tiny and small with plans on: the tallest within 0.3 of the radius, the same setup playing the same match twice, and the two keys differing by size.

**Proof.** `SIZES` 0 failed on the shipped data and with the GW1a flips applied (before the fix, with the flips: 1 FAIL, `big` did not replay to the same hash); negative control (the keys as they were): 3 FAIL, the tallest 4,875 on tiny and small and the key row. Runs: `docs/world/runs/gw1c-world/size-check-fix-*.txt` and `size-check-flipped-before-fix.txt`.

**Note.** The same fault would show in any size-keyed value kept by seed alone; the others (planet memo, slice memo, store and water grid keys, the field disk cache) carry the size already (checked).

**Re-cut on main b0e20f9a, 2026-11-21** (`docs/world/planet-stack-recut.md`, records `docs/world/runs/planet-stack-recut/`): `gw1c-world-fix.diff` re-cut (the geometry key line merged with the landed cache-determinism form).
