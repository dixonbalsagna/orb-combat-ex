# meteor-power: the meteor keeps its bowl under the power model (World, 2026-11-02)

Encounter's `arc_check` with the energy model on (`"power": true` in its setups) fails one line: **"the meteor's own bowl (4571)"**, against its 5,000 floor. Not lines 348 and 349 (they work out the expected crater without the match, with and without the tier term alike, and pass either way): the real change is that under the power model the landing's energy has no tier term (`impactEnergy` is v squared, where tier 4 was 1.75 times that), so the meteor's nine times the energy gives a bowl of 4,571 where it was 6,046 (80 fighter heights). Game Design's page says the meteor needs no change, so it keeps its size: `craters.json` `meteor.eMultPower` 15.75 (9 x 1.75), used only when `S.powerOn` (`WorldCraters.meteorEMult(power)`, called from `WorldCrater._dig`). Off, nothing changes.

**Apply:** `meteor-power.diff` (`sim/world/crater.gd`, `sim/world/craters.gd`, `data/biomes/craters.json`, its schema: one line each and a key); stacks on `crater-collapse` and `power-world` (all three edit `crater.gd` and the craters files; plain `git apply` in that order on the stack tree).

**Proved:** `arc_check` with power on: 0 failed (the bowl is 6,046 deep 1,330, as before); with power off 0 failed; `METEORCRATER` 0 failed.
