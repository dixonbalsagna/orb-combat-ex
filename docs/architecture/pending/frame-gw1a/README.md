# Parked: frame_check's rollback row waits for a swing that can run (a GW1a pin)

Simulation, 2026-11-15, sprint A1. On the GW1a stack (the EP's s422), `frame_check` failed "rollback: a swing runs". **It's the check's moment, not a fault.** The row plays a computer match for 240 ticks and then asks for a swing. With the 9 November data the computer has a beam in flight at tick 240, and a swing rightly waits out a beam (`SimSwing.ask`: no swing while `S.beams` isn't empty, or while the stage halts). The first tick a swing can run is 246.

**The pin:** from tick 240 the row steps on until no beam is in flight and the stage doesn't halt (at most 600 ticks), then asks. The row still tests a rollback across a running swing, three re-runs of 21 ticks, and that a re-run reads no node. On main's data there's no beam at 240, so the row is unchanged there.

## Apply

Test-only, one file; it applies on main as well as after the GW1a stack: `git -c core.autocrlf=false apply frame-gw1a.patch`.

| Patch | Files | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- |
| `frame-gw1a.patch` | `sim/core/tools/frame_check.gd` | d325e47cb0ba2436c0be724cb20e6991406bc49c | 7e1e24468dd6 |

## Proof

Records in `docs/sim/runs/f1-s422/fork-frame/`. On a copy of the EP's s422 (the GW1a stack): `frame_check` passes, and so does its negative control (`--negative-control`, every break caught).

## Not this pin: fork_check's planet 12 is a real fault (World's)

**Fixed by World (b1d9444e, `docs/world/pending/cache-determinism/`).** On the rebuilt GW1a stack (b09d705), `fork_check` passes from a cold cache, and planet 12 gives one state cold and warm (`docs/sim/runs/b09d705-s422/fork-confirm/`). What follows is the fault as found.

`fork_check` fails "planet 12: state differs" on the same tree. **That isn't the rollback:** it's World's field cache, and the check is right to fail.
- Run on the same tree, the real and the predicted processes give the same state whenever the field cache is in the same condition: both fresh, or both read back from `user://field-cache/`. A fresh bake and a read-back give different states. The EP's run had the real process bake fresh (a cold cache) and the predicted one read it back.
- After the swing re-lays part of the planet, the read-back world differs from the fresh one in the last bits: 72 ground columns by about 1e-13 (columns 2,372 to 2,714) and 5 building positions by about 3e-11. Each landing grows the difference, and the state hash parts at the fifth landing.
- It needs World's GW1a switch `field.everywhere: true`. In the bisect (`fork_bisect.txt`), putting `field.json` back to main's changed the cache's key, so the first run baked fresh and the second read it back, and the two still agreed. With any other file put back, the runs agreed only when both read the cache.
- **Why it matters beyond the check:** two PCs, or two CI runs, with different cache states play the same match differently. That's a LAN desync and a replay that won't verify on another PC, and the bake hash in the match key doesn't catch it, since the bake hash agrees.
