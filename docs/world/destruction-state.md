# The destruction state: what the sim holds, what each look reads (World's proposal to agree with Rendering)

Owner: World and Environment. 2026-10-12. Proposal, scratch only: nothing here is built except what is marked **in the tree**. It is the state half of `docs/world/destruction-hook.md` sections 2 and 6, for Rendering's `docs/rendering/destruction-look.md`; the numbers are first values and live in data.

## 1. In the tree (window A)

| What | Where | Read by |
| :--- | :--- | :--- |
| `hp`, `maxhp`, `alive`, `floors`, `fmask` (one bit a floor standing), `fdmg` (damage a floor has taken, lazily allocated; **it now weakens the floor**, so it is the building's memory of its walls), `wear` | `Building`, hashed | stage, floors, cracks |
| `WorldStructures.stage(b)` 0 to 4, `curH(b)`, `baseY` | pure functions of the above | the picture, every frame |
| A held hit | `building_hit` with `outcome` crack or dent (the body rebounds), and `floor_hit` with the same outcome and the `ratio` | a face that breaks without a hole |
| **A lodge** | `building_hit` with `outcome` punch, collapse or pancake and **`keep` 0**: the body goes through the building and ends inside it; a hit-stop of `lodgeSeconds` (0.5 to 0.9) follows | the body in the breach, the stop |
| A house gone through | `building_hit` outcome collapse, `kind` house | the burst |

Every held hit adds the hit's damage to `fdmg` of the floors it covered; three walls on one tower (a median one, at speed 1,400) and a tier-1 body goes through.

## 2. Breaches: a hole on a floor that keeps its plate (window B)

- **State:** `Building.fhole: PackedFloat32Array`, two numbers a floor, allocated with `fdmg` on the first local hit: `[2k]` the centre of the breach as a fraction of the building's half width (-1 to 1, seen along x), `[2k + 1]` its width as a share of the plate (0 to 1; 0 is whole). Two breaches on one floor merge into the interval that holds both.
- **Rule:** a punch makes a breach of `clamp(0.8 + 0.6 * ratio, 0.8, w)` fighter heights centred on the body's x; the floor's `fmask` bit clears only when the width reaches `clearAt` (0.7 of the plate) or a pancake takes it. The cleared floor then reads as today (the tunnel and the pancake rule are unchanged).
- **Event:** `floor_hit` gains `x0` and `x1` (the breach's world x at the floor, the face the body entered by is `z`), so VFX can put dust and glass at the hole.
- **Cost:** 2 floats a damaged floor (a hit tower of 13 floors: 26 floats), the whole city under 1 KB; hash: the array's length and values like `fdmg`; the JS parity copy is frozen and untouched.
- **A look reads:** the slab with a hole of that width at that x (the plate drawn on both sides of it), the core and the corner columns showing in the hole, the floors above on their plate. A tier-1 hit: a body-sized hole and cracks on the neighbours; tier 4: most of the plate gone and the columns left.

## 3. The failing state: a collapse that takes seconds (window C)

- **State:** three fields a building: `failT: float` (0 standing; counts from `-warn` up: **negative is the warning**, the building groans, dust and glass; zero and above is the failure), `failDir: int` (-1, 0, +1: the way it tips along x; 0 is a pancake), `failK: int` (the floor the front has reached). All three are 0 for a standing building and hashed.
- **What starts it:** the core under `failAt` (35% of its hit points) after a hit that cleared a span longer than the tunnel, or the existing pancake. Today both resolve in the tick; they would set the state instead.
- **The timeline:** warning `warn` (1.5 s plus 0.6 s over any hold a fighter there is in), then 2 s at least: the stack comes down one floor per 0.25 s from `failK` upward (a pancake: the floors above the break drop onto the ones below, breaking each in turn while the stack's weight beats its strength), or, for a tip, the part above the breach turns about its hinge to `tipAngle` (up to 25 degrees) in 1 s and then falls. `floors_fall` goes once a step (the event exists); `building_fall` when the last floor is down.
- **What falls hurts:** while a floor of the stack lands, a fighter inside the footprint and 1 bh beside it takes 6 damage a floor, 100 at most, and is buried 0.5 to 1 s (Combat's numbers).
- **A look reads:** `failT` and `failDir` and `failK` (a pure function of hashed state, so a seek or a late join shows the same fall). The lean of a damaged but standing building is derived from the breaches and `hp / maxhp`, not stored.
- **Cost:** 3 fields a building (118 of them), only a failing building ticks; hash: 3 names. Events: `floors_fall` per step, `building_fall` at the end (exist).

## 4. What each look needs

| Look | State it reads | New in the sim |
| :--- | :--- | :--- |
| Face breaks, glass from the floors above and below, a mark that stays | `fdmg`, `stage`, the `floor_hit` event | nothing (window A) |
| The body seen to stop in the wall; the stop | `building_hit` held or lodge; the hit-stop | nothing (window A) |
| A hole the size of the hit; the core and columns showing | `fhole` | breaches (B) |
| A building that leans | `fhole`, `hp / maxhp` | nothing beyond B |
| A tower that groans before it goes; pancake; tip | `failT`, `failDir`, `failK` | failing state (C) |
| Dust and debris at the breach and the landing floors | `floor_hit` x0 x1; `floors_fall` per step | B and C |
| The warning sound and the stack landing | the same events | C |

Costs in time: B is one World window (a field, a rule, a golden); C is one to two (a state, a per-tick step, the falling stack's damage by Combat's number, a golden). Both are neutral for a match that never touches a building and move the ones that do.

## 5. What I need to agree with Rendering

1. The breach as an interval of the plate in x (centre, width): is one interval a floor enough for the picture, or does a floor need two (a hole each side)? Two doubles the state; I would take one.
2. Whether Rendering would rather time the fall itself from the existing events (no failing state) and keep the sim instant. It is simpler for me, but the fall then cannot hurt a fighter: the falling stack is Game Design's ruling, so the sim has to hold the time.
3. The warning: 1.5 s minimum is Game Design's. What it shows (dust, glass, a shake), Audio's groan; I only supply `failT < 0`.
