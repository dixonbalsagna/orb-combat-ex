# A fighter dropped into water surfaces (parked, re-cut 2026-10-26: drops only)

Owner: Encounter Systems Director. Game Design's `rulings-2026-10-26.md` row 6 (on `rulings-2026-10-23b.md` item 7): a drop into water (`SimFighter.drop`, the zip's knock-down) ends free in the water, in control, with no down state, **but he can't stay under: whatever he presses, he surfaces within 30 ticks, and the drop counts as landed when he surfaces** (for a rally's end; a drop has no 9a pay, since it "scores nothing").

**The split with World (the EP's call, 2026-10-26):** a launched body in water is World's surfacing rule (`docs/world/pending/surfacing/`, `WorldContact.moveAir`, `data/biomes/water.json` `surface`). This park was first cut for launched bodies too; that part is withdrawn, and it now does drops only. The two never touch the same fighter: World's acts in a launched body's flight, this one only on a drop.

It sits behind `data/director/interrupts.json` `water.enabled` (false), so the golden stays as it is.

## To build it

On main with World's rivers and surfacing applied (`DirWater` reads World's `WorldWater.surfaceAt` and `WorldFill.wading`, both on main already), after the chase (`DirWater`'s slots follow `DirChase`'s, and the rally's follow `DirWater`'s): `node ws.cjs <root>` from this folder. `--check` reads every anchor and writes nothing.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/water.gd` (new, `DirWater`) | Encounter | Two slots (`WT_IN`: the live tick his drop took him under; `WT_UP`: rising). `tick`, `_surface`, `_landed`, `top`, `under` |
| `sim/director/exchange.gd` | Encounter | `DirWater.tick(S)` in `dirUpdate`, after launch anywhere's tick |
| `data/director/interrupts.json` | Encounter | `water` {`enabled` false, `surfaceTicks` 30, `riseTicks` 10} |
| `tools/schemas/director-interrupts.schema.json` | **Tools** | `water` |

## The rules as built

- **Which falls:** a fighter whose drop takes him under the water's surface. The water is World's `surfaceAt` (the sea, lakes, rivers, a filled trench), and water that is waded (`WorldFill.wading`, under 75 units with water v2) is not under. A launched body is never touched (World's rule), nor a fighter who goes under by his own choice.
- **When:** `surfaceTicks` (30) live ticks after going under, he is at the surface. At `surfaceTicks - riseTicks` (20), if he is still under, his drop ends (`drop_end` kind `water`, if its ticks haven't already run out) and he rises to the surface over `riseTicks` (10), whatever he presses. If he comes up by himself first, that is his surfacing.
- **Landed:** his surfacing is his landing. `DirWater.under(f)` is true until then, and a rally's end waits for it.
- **Cues** (kind `water`, actor the fighter): `surface` as he is lifted (`n` the tick he is up, `y` the surface), `surfaced` when he is at it, lifted or by himself.

## What it reads

On 00607309 (2026-10-26; World's rivers, surfacing and w16 on main since d51c6757), in scratch with `../launch-answer/` and `../rally/` on top: the stack applies, 269 files, 0 errors, self-test 9,153 of 9,153; the import is clean.

**The probe** (`probes/wat.gd`, 5 drops a side; both fighters players with no input, the drop 200 units over the middle of the widest open water, 808 columns):

| | Under | `surface` cue | Set at the surface | Then |
| :--- | :--- | :--- | :--- | :--- |
| **Rule on** | live tick 12 | 32 | **42: 30 live ticks after going under** | at y 0, the surface |
| **Rule on, holding the stick down** (`--dive`) | 12 | 32 | **42: 30 ticks**, the same | at y 0 |
| Rule off (`--off`) | 12 | | never | free in the water where the drop left him, under or wherever he drifts |

- The drop's own ticks (24) ran out at 24 in three runs (`drop_end` kind `end`), so he was free in the water when the lift came at 32; in the other two the pair were in an exchange by then (the probe's two players stand 400 apart), and the lift came the same.
- The five runs are the same drop (the same planet, no input).

**Golden and gates** (the stack, switches off): the golden is HEAD's, byte for byte; 35 of 35 at 0 (the stack's gate run, which covers all three parks).

**The final read** (c3ca82e9, the three parks as they land): the probe on and with the stick held down reads 30 ticks from going under to set, all five drops each; the golden is HEAD's, byte for byte; 35 of 35 gates.

## State

- **Built, read, frozen.**
