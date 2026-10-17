# The chain inside a tower (World, 2026-10-17): in scratch on main's HEAD, parked, not applied

The EP's brief: the building chain's events for Animation (`interior_contact`, `interior_end`), with Game Design's chain values (buildings §7.3, ruled 2026-10-17), behind a switch, golden unchanged with it off. Built on main ff68e994. **Not applied.** The World files are `sim/world/brunt.gd`, `contact.gd`, `interior.gd` (new), `data/biomes/brunt.json` and its schema; the lines in **Simulation's** files are listed at the end.

## What it does

A power send that enters a **tower's** face at **15 to 60 degrees** up or down (the data's tangents) goes on inside along the floors, instead of the old pass-through / lodge / rebound. `WorldBrunt.hit` starts it (`WorldInterior.begin`, after the building took the hit and the fighter his); `WorldContact.stepFighter` calls `WorldInterior.step` each live tick while `f.interior` is set. Behind **`brunt.json` `interiorChain`** (0 by default; needs `S.contactOn`, which every shipped match has): off, none of it runs, no event or hash field exists.

- **The script of slabs is made at the face** (`WorldInterior.plan`, a pure function of the tower, the entry height and the effective tier), so a plan is its own outcome; the per-tick driver only walks it. Slab *j* is the floor of storey *j* (its bit in `fmask`), slab 0 the ground, slab *R* = top standing floor + 1 the roof. A slab already gone is passed freely; a storey the face itself cleared moves the entry's floor and ceiling.
- **By effective tier** (a finisher reads at least `specialTier`, as the rest of the brunt does):

| Tier | Down | Up |
| ---: | :--- | :--- |
| 1 | the floor under him holds: he lodges there | the ceiling holds: he lodges |
| 2 | through the floor (keep 0.7), the next holds: lodge | through the ceiling (0.7), the next holds: lodge |
| 3 | through the floor, **up off the ceiling of his storey** (keep 0.4, it breaks), down through the next floor, the one after holds: lodge | off the ceiling (0.4), down through the floor he was on, the next holds: lodge |
| 4, finisher | the tier-3 picture, then floors keep breaking down to the contact cap, the last holds | the same |

- **Ends** (`interior_end.end`): `lodge` (a held slab or the far wall: the lodge's own hold and event, the last of his speed one more hit on the building, as today), `exit` (through the far face from tier 3, or out through the roof), `fall_out` (the ground floor, or the tower came down under him: the ground's own events play), `capped` (150 ticks = 2.5 s from the face: held where he is, as a lodge). The ground and exit hand the flight back (`endFlight`), so the brake returns.
- **Each broken slab** goes through `WorldBrunt.applyFloors` as a punch (its people, the collateral budget and token, the pancake rule, the `floor_hit` event: all the brunt's own) and counts **half a link** (a `MARK_HOUSE` in `splashed`, so `houseLink` 0.5).
- **The motion** is straight legs at the speed the last contact left (no gravity, no drag: the brake is off), so a shallow send usually leaves by the far face before the next slab and a steep one meets slabs. After a floor he breaks with the ceiling next, and after a ceiling, `vy` turns (the burst throws him up; the ceiling turns him down).

## Game Design's values (all in `brunt.json`, none in code)

Ceiling keep **0.4**, floor-through keep **0.7**, at most **5 contacts** (the entry face is contact 0 and not counted: "up to five slabs"), at most **3 bounces**, the face's stop **15 ticks** (replaces the old 0.35 s on this path), cap **2.5 s**, the ceiling reached from effective tier **3**. Mine, first values: the angle's tangents (0.26795, 1.73205), `interiorExitTier` 3 (the far face breaks from tier 3, below it it is a wall and he lodges), `interiorHurt` 0.5 (a slab does him half the face's per-speed damage).

## The events (one per contact, in order, then one end; made with `SimFx.contactEvent`: actor, x, y, z, spd, n)

- **`interior_contact`**: `b`, `floor` (the slab's index, -1 for a face), `kind` (**face, floor, ceiling, wall**), `nx`, `ny` (the surface's unit normal on the body's side: a floor (0, 1), a ceiling (0, -1), a face (-dir, 0)), `vn` (the speed into it, negative into the surface), `vt` (along it), `keep` (the share he keeps, 0 when he stays), `punch` (the slab or face broke), `k` (0 for the entry face, then 1, 2 ...), `stop` (ticks: 15 on the entry face, else 0).
- **`interior_end`**: `b`, `end` (**lodge, exit, fall_out, capped**), `contacts` (after the face), `t` (seconds from the face).

## Proof (scratch export of HEAD plus this patch; below-normal priority)

- `interior_check.gd` (new, `sim/world/tools/`): **0 failed**. Switch off: no event and no state. Switch on, a 60-degree send at the middle of the tallest tower, down and up, at tiers 1 to 4: the face first (k 0, stop 15, nx -1), numbered in order, one end after the last contact, at most 5 contacts and 2.5 s, unit normals with vn < 0, keeps 0.4 and 0.7 where they should be, a ceiling from tier 3 and none below, tier 1 breaks no slab, every broken slab went through the floors machinery. The angle gate (tangent 0.15 and 2.5 take today's path), a house takes today's path, the same launch twice gives the same events and the same state hash, the state hashes mid-chain and moves with it, and 160 random chains (tower, tier, angle, speed, entry height, finishers): one end each, none left running, at most 5 contacts, longest 2.50 s; ends seen: lodge 73, exit 50, fall_out 35, capped 2.
- Sequences seen (the tallest tower, 60 degrees): tier 1 down `face floor END:lodge`; tier 2 down `face floor! floor END:lodge`; tier 3 down `face floor! ceiling! floor! floor END:lodge`; tier 4 down `face! floor! ceiling! face! END:exit`; tier 3 up `face ceiling! floor! floor END:lodge`; tier 4 up `face! ceiling! floor! floor! floor! END:capped` (`!` the slab broke).
- `brunt_check.gd` and `wall_check.gd`: **0 failed** with the patch. `node tools/validate.js` 0 errors, 0 warnings; `--self-test` 7545 of 7545.
- **The golden with the switch off:** `node sim/core/tools/run-all.js --only=godot,golden` on the patched tree (below-normal priority): **both stages passed** (`parity.gd` 278.8 s: the 9 golden matches' every per-tick digest and full-state checkpoint identical; the JS golden check passed): **no golden moves** with the switch off, even with the new keys in `brunt.json`.
- `git apply --check` of `interior-chain.diff` on HEAD ff68e994: ok; applied it equals the scratch tree byte for byte. **The full gate (run-all, the render gates) is run again in the one window when the owners say yes.**

## Decisions and traps (read before applying)

1. **The contact count leaves the face out** (the face is the entry, `k` 0): "at most 5 contacts" reads as Game Design's "up to five slabs". If the face is to count, set `interiorMaxContacts` to 6.
2. **Orb's picture is a role script, not a free simulation.** Going down, "up off the ceiling" after a floor he broke needs an upward throw that no gravity gives; the model has the burst throw him up to the ceiling of his storey (`turn`). It reads as the picture and its events are coherent (`vn` is the speed at the contact), but it is not physics.
3. **A slab that holds lodges him; it does not bounce him.** §7.3 says "a slab that holds is a bounce" and caps bounces at 3, but its own tier table has him lodge on the first and second floors, and the two do not meet without a rule for when a held slab bounces. No bounce is produced (`interiorMaxBounces` is stored and not used). One question for Game Design: at which tier and speed does a held slab bounce instead of lodging?
4. **The wall.** The far face is a `face` contact that breaks from `interiorExitTier` (3) and a `wall` below it (a lodge against it). The old tier-1 tower "wall" (rebound with the slam and stagger) still applies to sends outside 15 to 60 degrees; inside it, a tier-1 tower now lodges on the first floor (§7.3), which is a change of behaviour with the switch on.
5. **The planner does not know.** `chainPlan` / `aim` still assume a tower is passed and the flight carries on to the next building; with the switch on, a send at 15 to 60 degrees into a tower goes inside and ends there (or exits with no further link), so a planned second link will not happen. Encounter's launch planner should be told; nothing breaks (the chain only reads the state), the plan is just optimistic.
6. **Depth.** `f.z` eases back to the plane while he is inside (no aim), so Rendering sees him at depth 0 in front of the tower. The cutaway is Camera's and Rendering's; the event's `z` is where he is.
7. **The legacy flight path** (`S.contactOn` off) is not hooked: the switch does nothing there.
8. `interior_check.gd`'s random run uses finishers (`launchSpecial`) and entry heights from 15 to 85 percent of the height.

## Lines in files that are not World's (a grant from Simulation)

| File | Lines |
| :--- | :--- |
| `sim/core/state.gd` | **Fighter:** `var interior = null`. **FxEvent:** `var nx`, `var ny`, `var punch: bool`, `var end: String`, `var t: float` (5 lines; `k`, `b`, `floor`, `kind`, `keep`, `vn`, `vt`, `contacts`, `stop` exist) |
| `sim/core/hash.gd` | **FX_FIELDS:** `interior_contact` and `interior_end` (one line). **The fighter:** `if f.interior != null: _obj(out, f.interior, ["b", "dir", "E", "k", "bn", "t", "i"])` after `flightHits` (hashed only while set, so a match without the chain hashes as before) |
| `docs/architecture/fx-events.md` | the two events (the fields above) |

No emitter is added to `sim/core/fx.gd`: `interior.gd` uses `SimFx.contactEvent`, `SimFx.lodge` and the events it makes itself. The JS oracle's `hash.js` has no entry (the events never exist with the switch off).

## Files

| File | What |
| :--- | :--- |
| `interior-chain.diff` | The patch on HEAD: `brunt.gd`, `contact.gd`, `state.gd`, `hash.gd`, `brunt.json`, the schema, and the new `interior.gd`, `interior_check.gd` (+ `.uid`) |
| `mk_interior.py`, `mk_wbc_lib.py`, `interior.gd.txt` | The script that makes it (`python mk_interior.py <root> interior.gd.txt`) and the new module |
