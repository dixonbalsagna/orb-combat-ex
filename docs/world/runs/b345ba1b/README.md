# Runs: review of Simulation's cd05-witness grants to World's files (World, 2026-11-08), on main b345ba1b (includes no-casualty-feed, 4890bdd9)

A clean `git archive` of b345ba1b (no working-tree changes), then `cd05-sim.patch`, `grant-world-witness.patch`, `grant-tools-forms.patch` applied with `git apply` (all three checked clean first), the project imported, one Godot job at a time and never more than three.

| File | What |
| :--- | :--- |
| `ground_check-stack-WITHOUT-the-pins-fails-2.txt` | the stack without `grant-world-ground-pins.patch`: `GROUND: 2 check(s) failed` (the gen 1 planets and the hand-made world/turn hashes moved; the turn hash it prints, `n=1 988ea85fd0ae96f6`, is the grant's new turn pin) |
| `ground_check-stack-with-the-pins-passes.txt` | with the pins applied: `GROUND: 0 check(s) failed`. The check compares each of the six pins to the hash the stack computes, so a pin that did not come from this stack would fail |
| `probe`, `casualty_feed_check`, `wrecks_check`, `collateral_check`, `far_people_check`, `brunt_check` | each 0 failed on the stack |

Why the lines are right: `structures.gd:481` (`b.hp <= 0.0` in `damageBuilding`) is the only place a building is marked fallen in a fight (the other `alive = false`, `campaign.gd:626`, is a stage's setup, not a fall); the call sits before `kill` so a building brought down fills Witness once, with `b` still readable and `cause` possibly null (guarded in `wrecked`); `collateral.gd`'s hunk removes the only caller of `SimForms.casualty` (kill's `granted > 0` branch), which is dead with no deaths.
