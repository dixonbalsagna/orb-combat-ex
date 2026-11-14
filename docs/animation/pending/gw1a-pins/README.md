# GW1a pins: anim_check on the 9 November data (Animation, 2026-11-14, parked)

For GW1a (main becomes Orb's 9 November game). On the GW1a stack (HEAD plus every GW1a park, with Tools' re-cut report hook) `anim_check` failed 13 rows. This park pins the seven tests that hold them to the switch they were written before, says why in the code, and leaves everything else as it was.

**Result:** `anim_check` 0 failed, 10,538 checks, on the GW1a copy (with the pins) and on a fresh export of main with them; no SCRIPT ERROR in the run (Tools' hook). `records/`: before, after, main, and the attribution of each row to its data.

## The patch

`gw1a-pins.patch` (sha1 efa8ae34): one file, `render/anim/tools/anim_check.gd`, +71 -7 lines. Applies on HEAD 41768933 (checked) and on the GW1a stack (the file is identical in both). Seven tests are renamed `<name>_run` and wrapped; the callers are unchanged. Each wrapper puts one switch OFF for its own run and puts it back after, by an in-place edit of the loaded row or the tools' own setter, never a data file.

| Pin | Tests | What it holds, and why |
| :--- | :--- | :--- |
| water floor off (`WorldFill.setFloor`) | slope, follow-through (su_heel), solve carry (su_hammer) | they measure a body on dry ground or in the air (a crater, a hover at y = 0 over deep sea); with the floor on that body stands on the water |
| grapple director off (`DirGrapple.cfg().enabled`) | grip feed (five stages), grip throw | they hand a hold to `_feed_from` while the sim holds no grapple; the live feed, on with the director, ends it |
| flight strikes off (`DirZip.setFsForce(0)`) | zip view (8 rows) | they start a plain zip and an AI exit; with flight strikes on every exit comes out "home" |
| strip ground (`RenderTileGround.on = false`) | standing on the water | it picks its water out of `S.water`, which is empty on the globe ground (the default) |

The pins are not hidden: the block comment above `_pin_floor_off` says all of this in the file.

## What a pin does NOT cover (reported, not hidden)

1. **The globe ground has no stance-on-water row.** On it the match is a planet slice and `S.water` is all zero (0 of 4,800 cells; 1,514 on the strip ground), so the row cannot stand anyone on water, and the other seven-test stagings never meet water there. Whether a fighter reads as standing on the sea on the globe ground in play is unproven by a test; a probe on the tile field is the increment (it is Rendering's ground; Animation reads the stance). Orb's play did not report it.
2. **The grapple director ON is read by no row.** The grip rows hand-feed the seam by design; the director's own holds are seen in live matches and the grip clips, not in `anim_check`.
3. **Flight strikes ON** are covered by the flight-strikes park's own rows (`_test_flight_loop`, `_test_flight_blows`) once it lands; until then no row plays the zip with them on (the zip-view rows are pinned off).
4. **A mixed state is not a fault:** every `interrupts.json` row at main's value with the energy model's dash left on fails one extra zip row (the dash needs the slip's ease); GW1a has both on.

## Checks, how to read them

- `records/attribution.md`: the bisect (which data row fails which test).
- `records/gw1a-before-pins.txt`: the 13 failing rows on the unpinned stack. `records/gw1a-after-pins.txt`, `records/main-after-pins.txt`: 0 failed, 10,538 checks.
- `records/main-seven-tests-before.txt`: the seven tests alone on main before the patch pass (so the pins change nothing on main).
- Not run here: the GW1a stack's other gates (World's, Simulation's, Rendering's); only `anim_check` and the anim tools it holds.

## Nothing else changes

No data file, schema or sim file is touched; no look changes (the look gate does not apply: the patch changes only a test).
