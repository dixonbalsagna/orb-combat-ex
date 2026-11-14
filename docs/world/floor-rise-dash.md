# A dashing fighter inside a rising lake floor: the rule I propose (World, 2026-11-14; A1 clipping, from Simulation's finding in `docs/architecture/pending/energy-on/README.md`)

**Finding (Simulation):** with the dash on, a computer fighter flying low along a rising lake floor sat 2.259 units inside it at tick 2 (parity's spawn-floor lake: planet 3, gen 2, the floor on). It happens in the 9 November build too.

**Cause, read from `SimFighter.floorFor` (`sim/core/fighter.gd:16`).** With the lake floor on, a fighter who begins a tick below the floor he moves onto is lifted by at most `WorldWater.riseMax` (wade.below 75 over the surfacing's 7.5 rise ticks: **10 units a tick**), whatever the floor does. That ease is there for the floor that *changes in time* at his own place (a fill window rising, a wave, a surfacing): it must never snap him up. But the same cap also meets a floor that only *climbs along his path*, which is continuous in space and needs no ease. At plain flight speeds one tick's climb fits inside 10. At the dash's 25 to 83 units a tick the floor under his next position can be 12 units above his old height, so he sits 2.26 inside it, then eases out over a tick or two.

**The rule.** The ease covers the time change only. Let `xo` be where he stood (`f.x`, `f.z`) and `x`, `z` where this tick puts him:
`rise = riseMax + max(0, floorAt(x, z) - floorAt(xo, zo))`
that is: 10 units a tick of the water's own movement, **plus** all of the floor's climb between where he was and where he is. If the floor at his old place equals his height (he stood on it) he lands on the floor at the new place exactly, whatever his speed; if the water rose under him, the first 10 units of that still ease. A caller that passes his own place (`floorFor(S, f, f.x, f.z, y0)`) gets today's behaviour bit for bit (no spatial term).

**What it changes:** a fighter moving under his own power along a rising floor follows it; nothing else. The hash moves only in matches where a fighter flies low over a rising lake floor (the floor on, gen 2 or later). The parity row that Simulation pinned `"dash": false` for this would be unpinned.

**Check.** `floor_probe` (Simulation's, `sim/core/tools`) and parity's spawn-floor lake: his height at ticks 1 to 10 against the floor under him, dash on and off, over the rising floor of planet 3: never more than 0.001 inside. Plus a unit row: a floor 12 units higher one tick ahead, a fighter moving 30 units: he ends on it, not 2 below.

**Owners.** The function is Simulation's (`sim/core/fighter.gd`), the rule is World's, the dash is Encounter's: this is a proposal for the three of us, not a patch. I will build and gate it as a grant once Simulation and Encounter agree the rule (and say whether the parity row stays pinned until then).
