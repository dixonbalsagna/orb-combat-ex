# Game Design's rulings of 2026-10-18 and Animation's hold points (World, 2026-10-18): in scratch on main's HEAD, parked, not applied

The EP's brief after the interior chain (7f213f0c): the held slab, the next tower's link, Orb's "repeats escalate", and Animation's prop hold points, each behind a switch, with gates. Built on 77ca29a4 (the interior chain and the air brake are on main). **Not applied.** One patch, `repeats-props.diff` (20 files).

## What it does

| Ask | In the patch | Switch (data/biomes/brunt.json) |
| :--- | :--- | :--- |
| **A held slab bounces** at 900 or more and between 40 and 70 degrees to it, at any tier; slower or shallower he lodges. At most 3 bounces and 5 slab contacts a chain; the entry face counts toward the journey's 8 contacts, not the chain's 5 | `interior.gd` `_bounce`: the next slab is on the other side (a floor sends him up to the ceiling above, a ceiling down to the floor below) and holds the same way; keeps `interiorBounceKeep` 0.45 of the normal speed and `interiorBounceTangent` 0.8 of the along-slab speed (the ground's first `vertKeep` and `tangentKeep`, turned to the slab). The event is the same `interior_contact` with `keep` above 0 and `punch` false | `interiorChain` (as the chain): with it off, none of it runs |
| **The next tower's link** plays only if he leaves by the far face with 900 or more of speed left | `interior.gd` `_link`: after the `exit` end, within the launch's chain length, `WorldBrunt.next` finds the building and the aim fields and the `chain_link` event are set as `hit` sets them; the token stays. If he lodges, the first tower is the chain's last link | `interiorChain`; `interiorLinkSpeed` 900 |
| **The planner predicts the chain** before it plans any later link | `WorldBrunt.chainPlan`: a first-link tower that the chain inside takes (`WorldInterior.fits`) ends the plan there as a lodge. Not a prediction of the exit: a send that would leave by the far face into a next link is planned as a lodge | `interiorChain` |
| **Repeats escalate, buildings:** a send into a building already marked meets it one tier higher for each mark, up to two | `WorldBrunt.tierAt`; `Building.marks` is counted in `hit` (once per send); the hit's damage, chain-inside tier, lodge hold and the planner's `chainPlan` all read the marked tier (the chain's length stays the launcher's) | `repeatMarks` 0 off, 2 on (the most marks counted and the most repeats a crater grows) |
| **Repeats escalate, ground:** a send into ground already cratered deepens and widens that crater instead of digging one beside it | `WorldCrater._repeat` (in `dig`, impacts only): the dig moves to the old crater's centre and its energy rises so the radius is `repeatCraterGrow` 1.25 times the last one's; after two repeats it grows no more. No new state: the repeats are the records at that centre | `repeatMarks` |
| **Animation's hold points** for the throwables' T1 | `data/biomes/props.json` (new, with its schema): four classes (bike, sedan, van, bus: Art's boxes, mass classes and first tiers from `data/art/vehicles.json`) with six hold points each (`frame`, `underside_l`, `underside_r`, `top`, `end_a`, `end_b`) in the prop's own frame; `sim/world/props.gd` `WorldProps.holdPoint(class, slot, x, y, z, turn, facing)` gives the world point (and `holdPoints` all six for the view's read) | no switch: nothing in the sim calls it |

## Proof (scratch export of HEAD plus the patch; below-normal priority)

- `interior_check.gd`: **0 failed** (new cases: a fast steep send at tier 1 bounces off the held floor; under 900 he lodges; shallower than 40 degrees he lodges; in 160 random chains 38 bounces and 14 links to a next tower, still one end each, none left running, at most 5 contacts and 2.5 s). Tier 1 now breaks no slab but may bounce.
- `repeat_check.gd` (new): **0 failed**. Off: no mark and the launch's tier. On: four hits leave four marks, the tier is one higher per mark and capped at two (tier 2 meets 4); the same send does 1.74x then 2.70x the first one's damage (the ladder's); the planner's damage for the marked building equals the outcome's; a mark changes the state hash and none leaves it; an impact on cratered ground digs at the old centre and widens it 160 to 200 to 250 units, the third repeat no more, and the ground at its centre is lower (-62.5 against -35.2).
- `props_check.gd` (new): **0 failed**: the data loads clean; the four classes carry Art's boxes, mass classes and tiers; all 24 hold points lie inside their boxes; unknown class or slot gives `[]`; unturned it is the local point placed; facing -1 swaps the left and right holds; a turn about the middle of the box keeps each point's distance from it; a quarter turn puts the bus's front end at the top; the seam wraps; the same every call.
- `node tools/validate.js` 229 files, 0 errors, 0 warnings; `--self-test` 8395 of 8395 (with Tools' lines below).
- **The gates with every switch off** (clean export of 77ca29a4 plus the patch, below-normal priority): `node sim/core/tools/run-all.js` **all 5 stages passed** (unit 13.5 s, parity 93.2 s, soak 19.7 s, golden 0.6 s, godot 361.5 s: the golden is unchanged); **all 15 of Rendering's gates passed** (after, cue `--profile=spaced`, depth, flash, flash_reg, flight, ground, hud_words, lane, open, pane, patch, shape, sky, stage).
- **Every switch on** (`switchon_check.gd`, new: `interiorChain` 1, `repeatMarks` 2, six AI matches of 7,200 ticks, each played twice): the same hash and events both times, no malformed event. **Finding: the AI almost never starts a chain.** In those 43,200 ticks there were 0 interior contacts (and 2 marks, 1 chain link): the planner aims at uy 0.05 to 0.4 (3 to 22 degrees), and the chain's gate is 15 to 60, so only the steepest aim fits and the towers are hit at shallow angles. The chain will show up in play when the launcher aims steeper (launch anywhere's up and down sends are Encounter's) or the stick does.
- `git apply --check` of `repeats-props.diff` on HEAD (re-checked on the newest main): ok; applied it equals the scratch tree byte for byte (HEAD moved on other files between the cut and the check).

## Lines in files that are not World's

| File | Owner | Lines |
| :--- | :--- | :--- |
| `sim/core/state.gd` | Simulation | `Building.marks: int` (one line) |
| `sim/core/hash.gd` | Simulation | in the buildings loop after `fdmg`: `if b.marks != 0: out.append(float(b.marks))` (two lines; written only when set, so a match with `repeatMarks` 0 hashes as before) |
| `tools/schemas/map.json`, `tools/fixtures/cases.json` | Tools | a rule for `data/biomes/props.json` and three invalid cases (`props-schema-version`, `props-hold-short`, `props-length-zero`), **in the same commit as the schema** (the self-test needs three a schema) |

`mk_props_tools.py` makes Tools' lines alone. Nothing is needed in `sim/core/fx.gd` or `view/fx.gd`.

## Decisions and traps

1. **"Marked" is a hit by a send.** Each brunt (`WorldBrunt.hit`) marks the building once; blasts, beams and slides do not. The mark never decays and is kept for the match. If Game Design wants another source (a blast) or a decay, it is one line in `hit`.
2. **The crater's repeats are the records at one centre,** so they need no field; they are lost when the 400-record list drops the oldest. The crater logic uses the most recent impact crater within half its radius, so a send that lands beside (not on) the old bowl but inside half its radius is moved onto it.
3. **The bounce is measured from the slab:** the tangent of the angle between the velocity and the slab is |vy| over |vx|, 0.8391 to 2.7475 (40 to 70 degrees), the chain's own entry gate being 15 to 60. A 60-degree send bounces; a 20-degree one lodges.
4. **The planner's approximation.** A tower the chain takes ends the plan, so the second link of a plan through a tower is no longer planned; the runtime can still make it (`_link`) when he leaves with speed. The runtime link can reach a house or tower the plan did not name; the result is only more destruction than planned.
5. **Hold points are first values from the box.** `underside_l` and `underside_r` sit 0.28 of the length either side of the middle and at 0.9 of the wheel radius above the ground (a hand under the chassis); `top` is the roof's middle; `end_a`/`end_b` the rear and front at 0.45 of the height. Animation's poses decide the real ones; they are data. There is no prop in the sim yet (World's option B, `cars-plan.md`), so the prop's place and turn each tick (T1's "view read") is the function's input, not a sim field, and T2's `hold` state waits for that prop. A ship (tier 3) is not in Art's four silhouettes; add a class when Art draws one.
6. **The air brake** stays off through a chain's bounces for the same reason as before (the token).

## Files

| File | What |
| :--- | :--- |
| `repeats-props.diff` | The patch on HEAD 77ca29a4 |
| `mk_repeat.py`, `mk_props.py`, `mk_props_tools.py`, `mk_wbc_lib.py` | The scripts: `python mk_repeat.py <root> interior.gd.txt`, then `mk_props.py <root> props.gd.txt`, then `mk_props_tools.py <root>` |
| `interior.gd.txt`, `props.gd.txt` | The two modules as they stand (the interior chain with the bounce and the link) |
