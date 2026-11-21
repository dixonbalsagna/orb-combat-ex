# Parked: Encounter's part of the energy model on by default (slam-and-pace section 2)

Encounter, 2026-11-07, item 4 of the EP's list: the energy model on by default, with Simulation. Orb's top note was readable launch speeds. Simulation flips the model on (`data/fight/power.json` `enabled`) and regenerates the golden. My part is three things:
1. **Every director check passes with the model on.** Two rows of mine didn't; both are fixed here.
2. **The held moment on a launch, by share** (`slam-and-pace.md` section 2, "Encounter: the held moment by share").
3. A grant for Simulation so it can be read.

**No switch of mine.**
- The held moment waits for Simulation's `readable` block (off).
- The two fixes change nothing with the model off. **The golden doesn't move**, and with the model on the golden is Simulation's to regenerate.

**How to apply:**
- Last in the stack on main 665f58d6, after `../stick-slam/`.
- `git -c core.autocrlf=false -c core.eol=lf apply power-on.diff`. My files only: `sim/director/arc.gd`, `melee.gd`, `tools/follow_check.gd`, and a new check, `tools/launch_hold_check.gd`.
- **The grant, for Simulation:** `grant-simulation-readable.patch`. It adds `SimPower.readable()` to `sim/core/power.gd`, Game Design's `readable` block to `data/fight/power.json` (off), and its schema. Without it the held moment reads nothing: the accessor is called only if it exists.

## 1. My checks with the model on

Every director check and the 4 core 2v2 checks were run with `power.json` `enabled` true, on the stack plus `../stick-slam/` (`docs/director/runs/665f58d6/power-on/sim_p1/`). The golden fails, as it must, until Simulation regenerates it. 42 passed. Two didn't, and both are fixed:

| Check | With the model on | The cause | The fix |
| :--- | :--- | :--- | :--- |
| `arc_check` "the meteor's own bowl" | radius 4,571 (World's spec: 6,046) | With the model on, `WorldCrater.impactEnergy` drops the tier factor, because a model speed already carries the tier. The meteor's landing speed (8,570) is authored data, not a model speed, so its bowl lost its tier | `DirArc` digs the meteor's bowl with the tiered formula in both models. 6,046 with the model on or off |
| `follow_check` "60 after the send" (3 rows) | the far tap did nothing, and no taunt either | With the model on, his landing holds the clock at that tick (0.4 s), and the check's one-tick press fell on a frozen tick. In play the host offers a press again until the first live tick (`sim_host.gd`) | The check presses through the hold, as the host does. The follow itself was right |

Rendering's 15 gates all pass with the model on (`render_p1/`).

## 2. The held moment, by share

With Simulation's `readable.enabled` on, an ordinary send (`DirMelee.holdSend`, the launch beat) holds its **held moment by its energy share**, at `heldTicks`:
- 14 for the lit launcher's share (0.5);
- up to 18 for a full send's (1.0);
- in proportion between them.

With `heldUncut` the clock is held straight, so the freeze budget never cuts it. A set piece keeps its decisive stop.

`launch_hold_check.gd`, 4 checks, all pass:
- 14 and 18;
- 14 at or under the launcher's share;
- not cut with the budget over;
- off, as before.

## Proof

- **The model on:** the runs above.
- **The fixes** (`h1_on_*`, `h1_off_*` in the run folder):
  - `arc_check` passes with the model off and on (the bowl 6,046);
  - `follow_check` passes off and on;
  - `launch_hold_check` passes (`hold1.txt`).
- **With this park on top of the stack and stick-slam:** validate 0 errors, self-test 10,091 of 10,091, ratchet 365.

- **The full lanes on the stack, stick-slam and this park** (`docs/director/runs/ba87218e/slam-power/`): switches off, the golden check, validate, self-test, the ratchet and all checks pass, including `launch_hold_check`. Render 15 of 15. The next page: determinism, rollback and two_states pass.

## NEEDS FROM EP

- **Simulation:**
  - flip `power.json` `enabled` on and regenerate the golden; my checks are ready for it;
  - take the grant, or build `readable` your own way and keep `SimPower.readable()`, `heldTicks` and `heldUncut`.
  - The pace cap, slow-in and slow-out are yours, on the same block.
- **World:** `impactEnergy` with the model on drops the tier factor for every caller. The meteor now passes its authored speed without `S`, so World's spec holds. Any other caller with an authored speed may want the same.
- **Tools:** the page's `?power=1` becomes the default with Simulation's flip.

## Grants

`grant-simulation-readable.patch`: `sim/core/power.gd`, `data/fight/power.json`, `tools/schemas/fight-power.schema.json` (Simulation's).
