# Spike S2, the gravity well trial: the director's half (scratch; never to land)

Encounter, 2026-11-15, sprint A1 (A-COMBAT-03; Simulation leads). This is the list in `docs/sim/s2/README.md` under "Encounter's half", built on the same tree: Simulation's base (4c284b84 + close-rows + energy-on + gates + GW1a's target data, with the model and the dash on) plus `s2-core.patch`.
- The design is `docs/ep/proposals/gravity-well-trial-design.html` (sections 5, 7, 8 and 11). The rulings are Game Design's five for S2, at the end of `docs/design/gravity-well-reading.md`.
- **A throwaway build: nothing here lands.** Simulation joins the halves and writes the page.

## What it does (`s2-dir.patch`)

1. **`DirBands.pressBand(S, A, D)`.** The close band stays the band's own. Outside it, with the well on, the press reads the middle band if A is inside D's well or on its edge (SimWell's zone; straight from the distance before the first write), else the far band. With the well off, it returns the band as it was.
   - It is read at the four places on a press's path: the exchange's gate (`exchange.gd`), `farPressNow`, `begin`'s own read, and the stick's light lunge (`stick.gd` `_lungeLight`).
   - The computer's choices, zips, the chase tap and the grab keep today's edges, as the design says.
2. **The snap in `begin`**, with the well on, `snap.enabled`, not a charge, not a counter-rush, and the press's band the middle.
   - Speed: the faster of `snap.floorSpeed` (4,000) and `SimPower.flatFor` (Game Design's ruling 1).
   - Ticks: line 205's own form without its 20-tick ceiling, then at least `maxStepBh` (3 bh) a tick.
   - The crouch and the return from a send are unchanged.
   - Feed: "SNAP" (the gap, the well, the ticks) and a cue `snap`. A press that reads outside the well gets the feed line "FAR KIT, outside the well".
3. **`SimWell.sent(f)`** at the two shoves with no rush: `DirRecoil.knocked` and `DirLaunch.knockBack`.
4. **`close.mode` "own"** (`S.wellOwn`), in place of the pair's shared movement, while a brawl lasts.
   - **Own bodies (`DirBrawl._moveOwn`):** each fighter's stick moves his own body at `close.ownMul` (0.4) of his flight, ramped over `rampTicks`. The speeds live in `f.wel.ovx`, `ovy`.
     - Kept per body: the live gate (zip, double hit, grab), a step-in carrying him (his stick waits, the other keeps his), the guard's and the stagger's factors, the step's cap, a building's face and a slope at his own place.
     - At the brawl's start each keeps half of his own speed, fading over `carryTicks`, in place of the pair's summed drift.
     - Inside the give leash, the giver's stick moves him by `_giveStep` as built. Past it, he walks at his own pace.
     - Every own step is counted on a winder's gap (`GAPV`), as giving ground is, so heavies don't land from too far.
   - **Nobody's stick moves the other player.** The pair's walk-out count is skipped.
     - `over` keeps each fighter's speed on "apart", "idle" and "broke", so a walker walks on.
     - The magnet works only while both sticks rest (`magnetAtRestOnly`).
   - **The walk-out (Game Design's ruling 3):** a blow that reaches a fighter holding away, landed or guarded, counts in `f.wel.lv`.
     - On the third (`leaveAfterBlows`), the brawl ends with the new reason "broke".
     - A stun, a stagger or a grab pauses the count. Letting go of away resets it, and so does his own attack.
     - "Held away" is the brawl's angle test, read from the stick as held. For the computer, only its own chosen walk-out (AI_PART).
   - **Solid bodies (ruling 4; `DirMelee.contactTick`):** inside 45 units, only the body whose own stick pushes in is moved back. With both pushing, or neither, it's half each as before.
   - **The computer's brawl stick** holds still where it used to push away. It was written to steer the pair, and its retune comes after the trial.

## The check: `sim/director/tools/well_dir_check.gd`, 25 of 25

| Part | Rows |
| :--- | :--- |
| The press's band | With the well off, the band as it was. Tier 1: 8 bh is middle; 14 bh (the edge) is middle, where today it's far; 17 bh is far; inside 3 bh is close. **The asymmetry:** a tier 4 well reaches a tier 1 fighter from 19 bh, and the tier 4 fighter has the far kit there |
| The snap | **At tier 1 it is today's lunge:** 9, 13 and 16 ticks from 6, 9 and 12 bh, with the well on and off. From 15 bh (the edge) it's a snap, 20 ticks, where today it's a taunt. From 17 bh: the far kit, a taunt, and the feed says so. Tier 4 with a full meter from 12 bh: 11 ticks against 16 (flat out 8,068), and never more than 3 bh a tick. The defender is free and unmoved by the snap while it flies |
| The latch | `DirRecoil.knocked` and `DirLaunch.knockBack` clear `wel.own` |
| Own bodies (and today's as the control) | Holding away from an idle rival: the rival isn't moved (0.0; today's pair drags him 42.5). The gap opens and the brawl lets go, as "idle" after a second, and he walks on. Walking into an idle rival: he stops against him at 45 and the rival isn't moved (0.0; today the pair slides 63.6). A stick pushed from rest moves its own body within 2 ticks, and the other isn't moved. Holding away from a rival throwing lights: "broke", 43 ticks after he turned away (today's pair never ends as "broke"). The magnet draws them in only with both sticks at rest; with one stick held, no magnet |
| Determinism | Both switches on: two runs give one hash (10 readings) |

## Proof

Records are in `docs/director/runs/4c284b84-s2/well-dir/`, and every output went through `tools/gate.mjs`.
- **With both switches off, the golden reproduces GW1a's target byte for byte** (`golden.gd`, compared with `docs/sim/runs/6a30b4c9/gw1a-target/golden-target.json`, as Simulation's run did).
- Simulation's `well_check` passes, and so do the core checks `two_states` and `load_split`.
- Validate: 0 errors. The determinism lint is clean. The two-fighter count is 365 of 365.
- **Every director check:** 36 of 42 pass on this tree. The six that fail fail with the same lines on the base without this half, so none of the six is this half's:
  - `arc_check` and `beam_ai_check` are the energy model's known faults; the energy-on pins and the GW1b riders fix them, and the base has neither.
  - `beam_front_check`, `floorlift_check`, `knock_wall_check` and `walk_check` are the base: GW1a's data on today's code.

## Apply

On Simulation's base plus `s2-core.patch`: `git -c core.autocrlf=false apply s2-dir.patch`.

| Patch | Files | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- |
| `s2-dir.patch` | `sim/director/{bands,brawl,exchange,launch,melee,recoil,stick}.gd`, `sim/director/tools/well_dir_check.gd` | f0a4f769fb02faf672334412a55806f3e029f897 | 9146ae5a00ac |

## For Simulation, joining the halves

- **The core's draw acts on a silent defender while the rival's snap flies:** an idle defender drifts in by the draw. Your silence rule reads "his own approach in hand", not his rival's. The design's agency table says the defender is free and unmoved while a snap flies; the snap itself doesn't move him (the check shows it, with the defender's hands on the guard). Whether the draw should also wait while the rival's approach is in hand is your call and Game Design's.
- **"idle" ends most walk-aways before 4.5 bh:** a second with no attack comes before the gap opens past `breakBh` at 0.4 of flight. That's the design's own table ("after a second the fight lets go; you are 3 body heights away and still walking"). The walker keeps his speed either way.
- **Not built:** the snap's outrun option (`snap.outrun`, off), and `_moveZ`'s depth (depth is off in the trial; it stays pair-wide).
- **The readings of the design's section 12** are yours, with the clips.
