# Which row of the 9 November data fails which test (bisect, 2026-11-14)

Method: the seven test functions that hold the 13 failing rows were run together on the GW1a copy (HEAD plus every GW1a park; 99 files differ from main, 20 of them the data rows), once with every data file at GW1a's value, then with one group, one file, or one row put back to main's value. A row that goes green when one row is put back is that row's. Each run is the seven tests only; the full `anim_check` was run before and after the pins.

| Rows that failed | Cause found by the revert | Put back to main's value and the rows pass | What the rows assumed |
| :--- | :--- | :--- | :--- |
| the grip as five stages; the grapple's end as a throw | `data/director/interrupts.json` `grapple.enabled` true | `grapple/enabled` alone | the test hands a hold to `AnimFighter._feed_from` and the sim holds no grapple; the live feed (`_feed`) runs every frame when the director is on, reads "no grapple" and ends the hold the test just fed |
| zip view: the three exits, the heavy exit's way in and out, the far-side pass, countered, caught (8 rows) | `interrupts.json` `zip/flightStrikes/enabled` true | `zip/flightStrikes/enabled` alone | the test starts a plain zip and an AI exit; with flight strikes on the zip is the grammar of paths read from the stick and every exit comes out "home" |
| slope test; follow-through su_heel; solve carry su_hammer | the water floor: `data/biomes/water.json` `floor.enabled`, with `interrupts.json` `water.enabled` and `water.json` `enabled` (any one of the three back to off puts them right) | `floor/enabled` alone | a crater the fill floods and a hover at y = 0 over deep sea; with the floor on the body stands on the water |
| standing on the water | NOT a data row: with every data file at main's value it still fails. The cause is the globe ground (`RenderTileGround.on`, the default since Orb's decision 3): the match is a planet slice and `S.water` is all zero (0 cells of 4,800, against 1,514 on the strip ground), so the row finds no sea cell | `RenderTileGround.on = false` before the match starts | it picks its water out of `S.water` |

Other findings:
- With every row of `interrupts.json` at main's value and the rest at GW1a's, one extra zip row failed ("a home exit tilts 0.78 and is drawn 24.0 in front"). That is the energy model's dash on with the slip's ease (`bands/arrive`) off, a mixed state GW1a does not have; not a finding.
- The three water rows were green with any single one of the water switches back at off; the floor needs all three on.
- On main (HEAD b12fd311) all seven tests pass before the patch and after it; the pins change nothing there.
