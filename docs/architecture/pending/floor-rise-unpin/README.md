# Parked: parity's lake row takes the dash again (the companion to World's floor rise, GW1b)

Simulation, 2026-11-20, sprint A1. **World's grant `docs/world/pending/floor-rise/grant-simulation-floorfor.patch` (to my `sim/core/fighter.gd`) is approved.** It lands in GW1b with this companion.

## The grant, reviewed

- `floorFor` takes the place the tick began at (`xo`, `zo`), and the rise becomes `riseMax` plus the floor's climb between that place and the new one. **With no start place given (NAN), the climb is exactly 0, so the result is today's bit for bit.** The floor still caps the rise, and the ground still bounds it. `WorldWater.floorAt` never reads below the ground, so the climb is always finite.
- `stepFighter`'s three sites pass the tick's own start (`x0`, `z0`). `stepRush` keeps its start place before it moves the fighter and passes it at its three sites, which is Encounter's gap: a rush used to set `f.x` first and got no climb. The director's other callers, which place a body without stepping it, are unchanged.
- It's a pure function of the state: nothing new is kept or hashed.

## This companion

Parity's spawn-floor lake row (planet 3, gen 2, the lake touch-down) was pinned `"dash": false` in A-ENERGY-04's park, because at the dash's speed a free fighter low along a rising lake floor sat inside it for a tick or two. The grant fixes that case, so the pin comes off.

| Patch | Files | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- |
| `parity-lake-unpin.patch` | `sim/core/tools/parity.gd` | 528d264356b2f8e6cb5a881cabe2d914839d9fef | b37fd4cb4738 |

Apply after the GW1a stack (its parity edits sit around this row) and with World's grant: `git -c core.autocrlf=false apply parity-lake-unpin.patch`.

## Proof

Records in `docs/sim/runs/b09d705-s422/floor-rise-review/`. On copies of the final GW1a stack (the EP's s422 at b09d705):
- **With the grant, World's `floor-rise.diff` and this companion:**
  - World's `floor_rise_check` 0 failed. Its negative control (no start place) fails the landing row, as it should.
  - World's `floor_check` 0 failed.
  - The golden **moves** (the dash on and fighters low along climbing floors): it re-records in GW1b.
  - **Parity against the regenerated golden through `gate.mjs`: exit 0**, the unpinned lake row ok.
  - `power_check` (through `gate.mjs`), `kick_check`, `two_states`: pass.
  - Rendering's 15: all pass.
- **The control, this companion without the grant:** parity's lake row fails ("he is 19.175 under his floor" at tick 0). So the grant is what makes the row pass.
- **Not mine:** Encounter's `floorlift_check` fails its "fight" row (a lift of 144.54 in one tick, 1,758 ticks over the old 7.5 limit). That's the rule working: a RIVAL who was already 21 units inside a rising floor moved 53 units onto a steeper part and was lifted by the floor's own climb, and is still 14 under it. The row's limit should read `riseMax` plus the climb, as World says. Whether a 144-unit pop on a bank that steep reads well is a look call for Game Design.
