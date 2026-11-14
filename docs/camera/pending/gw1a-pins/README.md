# Parked: Camera's checks under GW1a's whole data (gw1a-pins)

Camera, 2026-11-15, for GW1a. The EP's brief: on the GW1a stack (s422, with the 9 November target data: the energy model, dash, kick and the rest), four camera checks went red. Each is classified below: a pin for a row off Orb's path, or a ceiling on real behaviour, with its fix owed for GW1b. **Checks only: no camera code changes.**

**Apply after own-pane** (it changes `launch_shots_check.gd` and `own_pane_check.gd` too; cut on main 6b7e0ca9 + own-pane): `git -c core.autocrlf=false apply gw1a-pins.patch` (sha1 e0302912). Five files, all mine, in `render/camera/tests/`.

## What went red, and why (`docs/camera/runs/6b7e0ca9/gw1a-pins/`)

Tested on a copy of s422 with own-pane applied. With all 20 changed data files put back to main's, every row passes, so the cause is the data.

| Check | Red | Cause | Class | What this does |
| :--- | :--- | :--- | :--- | :--- |
| `split_vision_check` | 1: "the split's distance moved with power: 1332 and 2100" | **World's `field.json`** (`plans.everywhere`) moves the ground under the row's staged flight. The row tests `split_ignores_power`, a rig switch that **no build turns on**; only this check sets it | **pin** (off path) | the power row plays on the field world as main lays it: `WorldPlan.everywhereOverride = 0`, World's hook for tools, then -1. Encounter's gw1a-pins use the same hook |
| `flight_shots_check` | 1 of 539: "reveal 6.0 s: a release's jolt of 0.307" (limit 0.30) | **The biome data.** The reveal rows drop the staged pair 900 units to the ground in one tick when the staged flight ends; that ground moved. Nothing in play drops a fighter 900 units in a tick | **pin** (off path) | the reveal rows play on the field world as main lays it (the same hook) |
| `launch_shots_check` | 3 of 843: AI fight 2 jolts 0.262 (limit 0.16, and 0.10 with the energy model); AI fight 3 0.110 (0.10) | A real AI fight with Orb's data. Fight 2, tick 3219: the one view's picture jumps 0.263 of the width in a tick, from 0.002, both fighters free, no cut, at a landmark | **real** | ceilings at today's jolts (`KNOWN_JOLT` {2: 0.263, 3: 0.111}) |
| `chase_rush_check` | 19 of 130 (the EP's run showed a few). Flaps (merged, opening, split); the meteor chases at top power stepping 0.064 (limit 0.06) and jolting 0.035 (0.03); the ordinary sends at top power stepping up to 0.288 (0.25), and seed 2 losing the player for **96 ticks** | **Several data groups together.** Main's biome files alone leave 10 red, the director and combat files 3, the fight and input files 24; the camera's `swing.json` changes nothing. So it's the energy model, dash, kick, World's settle (`contact.json` `settle.enabled`, on in the 9 November data) and the director's swing acting together | **real** | ceilings at today's numbers on the 11 red rows (`KNOWN`: step, jolt, player off, flaps); each row prints its numbers |
| `own_pane_check` (own-pane, joining GW1a) | 4 of 12, the signature scene: the one view loses player one for 26 ticks after his beam sends player two (ticks 125 to 150), and player two for 48 after a send (860 to 907) | The scene still fires its beams with this data (ticks 94 and 1183). The one view drops a fighter after a send | **real** | its ceilings take the two: `signature/0` 26, `signature/1` 48. The clash and launchai losses read 0 on this data; their ceilings stay for main's data until GW1a lands |

## Proof

| Run | Result |
| :--- | :--- |
| The stack + own-pane + this park | split_vision 11, flight_shots 539, launch_shots 843, chase_rush 130, own_pane 12: **all pass** |
| The same tree with main's data | split_vision 11, flight_shots 803, chase_rush 130, launch_shots 1,029, own_pane 12: **all pass** |

## Owed for GW1b (the fixes, then the ceilings come down)

1. **chase_rush with Orb's data**: the flaps; the top-power sends' steps (0.288); and seed 2 losing the player for 96 ticks. That one is the worst, and it's the same kind of loss own-pane exists to catch.
2. **launch_shots AI fight 2's one-view jump** (0.263 at tick 3219, at a landmark, with no cut): likely the landscape shot changing its aim. Find it and ease it, or name it as a cut.
3. **own_pane's signature losses** (26 and 48 ticks in the one view after a send). Also the three from own-pane's README.
