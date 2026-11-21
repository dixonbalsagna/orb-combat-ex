# Park: a fighter moving along a rising floor follows it (World, 2026-11-20; EP's order, with Encounter's gap)

Rule and reasoning: `docs/world/floor-rise-dash.md` (Simulation's finding: with the dash on, a free fighter flying low along a rising lake floor sat inside it for a tick or two). Encounter agreed the rule and found one gap: the director's rushes (`stepRush`) set `f.x` before they call `floorFor`, so their old place equals their new one and they got no climb term. This is built as a grant to Simulation's `sim/core/fighter.gd`, **GW1b-bound** (it moves the hash of any match where a fighter moves low along a climbing floor with the floor on). Runs: `docs/world/runs/floor-rise/`.

| File | What |
| :--- | :--- |
| `grant-simulation-floorfor.patch` | **Simulation's file, `sim/core/fighter.gd`**: `floorFor` takes the start-of-tick place (`xo`, `zo`, default NAN); `stepFighter` and `stepRush` pass it. Applies strictly on HEAD (`git -c core.autocrlf=false apply`) |
| `floor-rise.diff` | World's: `sim/world/tools/floor_rise_check.gd` (new, `FLOORRISE`, in CI) and its line in `tools/world-checks.json`. Applies on HEAD |

## What changes (the lines, all in `sim/core/fighter.gd`; NEEDS FROM EP lists the same)

1. **`floorFor` (line 16)**: signature gains `xo: float = NAN, zo: float = NAN`; the rise is `riseMax + max(0, floor(x, z) - floor(xo, zo))`. NAN: bit for bit today's rule (the climb is then exactly 0 and `y0 + riseMax + 0.0` is `y0 + riseMax`). The ease still covers a floor that changes in time at his own place.
2. **`stepFighter`, three call sites** (the free and dashing step at the floor clamp, the director's velocity step, and the depth clamp after `contact`): `floorFor(S, f, f.x, f.z, y0)` becomes `floorFor(S, f, f.x, f.z, y0, x0, z0)`. `x0, y0, z0` are what the function already keeps from the tick's start.
3. **`stepRush`, three call sites** (the rush's last step and its depth variant, and the field world's ride-up): the rush keeps its start place (`xs0, zs0`, taken before it moves `f.x`) and passes it. They keep `from` as it was (`NAN`, so `f.y`), so a rush's behaviour with no climb is unchanged.
4. **Not touched**: `_loopAt` and `rushAt`'s clamps (`floorFor(S, f, x, f.z)`), the placement at line 492, and every director caller (`brawl`, `zip`, `launch`, `recoil`, ...): they pass target places or positions they do not move, and the rule applies where the fighter's own step moves him.

## Result

| Gate | Result |
| :--- | :--- |
| Unfixed, parity's spawn-floor lake (planet 3, gen 2, `power` on, `dash` on) | a free fighter sits **7.5 inside the floor at tick 1** (the probe on the s422 tree); dash off: 0 |
| With the grant | dash on: **0.000 inside over 40 ticks**; dash off: 0.000 and **the state hash identical** to the old code (`154d823b72fe23ca`); dash on: the hash moves (as it must) |
| `FLOORRISE` | 0 failed (a bank of 14.9 units over 40: without the start place he is lifted 7.5, with it he lands on the floor, 534.143 of 534.143; the ease still lifts a body 30 under the floor by `riseMax` where it changes in time; no start place is today's rule bit for bit); negative control (no start place): the landing row fails |
| `floor_check` | 0 failed |
| golden (the s422 GW1a target) | **moves** (the dash on and fighters low along climbing floors): re-record in GW1b, not before |
| Encounter's `floorlift_check` | **1 FAIL: the "fight" row** (largest lift 144.54 a tick, 1,758 ticks over the 7.5 limit): see below |

## NEEDS FROM EP

- **Simulation (owner of `sim/core/fighter.gd`)**: the grant, lines as listed above (six call sites, the signature and the body of `floorFor`). Also `sim/core/tools/parity.gd` line 5828: the spawn-floor lake row's `"dash": false` pin can come off (the case it was pinned for is fixed); and the GW1b golden re-record.
- **Encounter (owner of `floorlift_check`)**: the "fight" row reads "largest lift a tick at or under `riseMax` (7.5)". The new rule lifts a fighter by the climb of the floor between where his tick began and where it ends, which is meant: 144.54 in one tick is what the check names: a RIVAL free at tick 49,914 who moved 53 units and went from 2207.4 to 2352. I read it as a floor 144 higher 53 units on (standing on the bank instead of 19 ticks inside it); I did not check the floor at that place. The row's limit should read `riseMax + the climb` (the rule's own ceiling), which is stricter than the old one where the floor is flat. The grant leaves the row to its owner; Encounter said they would re-run the director moves under it.
- **Game Design: ruled** (2026-11-20, `docs/design/buildings.md` section 9): **keep the sim's one-tick lift, uncapped.** Nobody ever stands inside terrain, and Orb's clipping complaint outranks a pop. The view covers it instead: a floor lift of more than 0.5 bh in one tick plays Animation's short step-up, and the camera's own ease absorbs the rest. Nothing here to change; the side-by-side of that step-up is Animation's (GW1b review B-08), and floor-rise (this park) and Simulation's `floor-rise-unpin` land together, steps 16 and 18, in the same batch.

## RISKS

- It moves the hash of every match with the floor on where a fighter's own step climbs a floor: GW1b, with the golden.
- A cliff in the lake floor (a pad, a bank) now lifts him in one tick; the old rule had him clip for ticks.

**Re-cut on main b0e20f9a, 2026-11-21** (`docs/world/planet-stack-recut.md`, records `docs/world/runs/planet-stack-recut/`): new `floor-walk-probe.diff`: `floor_walk_probe` measures the pop beyond what the floor itself rose (the floor rise's lift is uncapped by ruling); it lands with `floor-rise.diff`.
