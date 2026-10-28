# A slam's crater by material (World, biomes W4, 2026-10-28)

Combat's crater table (`docs/combat/biomes.md` section 4.3, its park's `ground_atoms.json` `craters`, ruled by Game Design 2026-10-23b item 3) as World's own data: `data/biomes/craters.json` (**`enabled` false**, `touchBuilt` false), read by `sim/world/craters.gd` (`WorldCraters`), checked by `sim/world/tools/craters_check.gd`. With the switch off the slam digs today's bowl to the bit and nothing is allocated. W4 also adds the floe's break-through and the props rows (below).

## How a slam uses it

`contact.gd`'s slam (the `slam` contact of a launch journey; not the wall stop-impact or `bump`):

1. `WorldCraters.shapeAt(S, x)` **before the dig** (the dig takes a heap away and digs through paving): the row of the look class at x (`WorldContact.lookAt`: a gen 2 world's look, a beam's strip, or today's surface). Empty (today's bowl) with the switch off, for a class without a row (`water`), and for today's five classes (paving, rock, soil, sand, rubble) while `touchBuilt` is off. So a gen 1 or hand-made world digs today's bowls even with the switch on.
2. `WorldCrater.dig(..., shape)`: today's bowl times the row.
   - **radius**: the bowl's radius (still under today's caps);
   - **depth**: the depth and its relief cap, from today's radius (so sand is 1.3 wide and 0.7 deep, not 0.91);
   - **rim**: today's crest (from today's depth);
   - **steep**: the wall's shape, `bowl = (1 - u^(2 steep))^2` inside the lip (1 is today's `(1 - u^2)^2`, exactly): above 1 a flatter floor and steeper walls (rock, ice, snow, crust), below 1 a slacker bowl (sand, ash, shingle). The rim and apron are today's.
   - A repeat (brunt.json `repeatMarks`) still grows the old bowl by `repeatCraterGrow`: the radius factor is divided out of the repeat's energy.
   - The `crater` fx event carries the material in its `surface` field (not one of its hashed fields).
3. `WorldCraters.after(S, rec, shape, z)`: what the material does next, in this order:
   - **breakThrough** (ice): on sea ice, if any of the bowl's floe columns (sea ice whose ground, `S.base`, was above the sea) now has its floor below the sea, the floe breaks: a slot that many columns wide at the crater's centre, cut and filled exactly as the FLOE SPLIT aftermath cuts (`WorldCraters.breakThrough`, which `after.gd` `split` now calls too). The rest is water, so no fill or refill, and **contact does not embed him**: the water rules take him.
   - **fill**: `water` (mud) fills the bowl to the biome's water table (`water.json` `table`, 6 below the original ground in a wetland), `waterNearSea` (shingle) fills the columns whose floor is below the sea to the open water within `seaCols` (30): `after.gd`'s flood rule, so the bowl reads `flooded` (look `water`).
   - **refill** (sand, snow, mud, ash, shingle): an aftermath job (`J_REFILL`) raises the bowl by `refill` of its depth over `refillTicks`, in the bowl's own shape, never above the deform ceiling; standing water keeps its level (the rise comes off its depth). The jobs run on `S.waterTick` with after.gd's, are hashed with them, and end with the calm turn's swap like them.
4. **The embed.** The threshold is `contact.json` `embed.minDepthBh` (and the special one) **times the row's depth** (`embedThresholdScales`, ruling 3), so the rate is today's on every surface. `embedMul` is how deep he sits: the `embed` event's `depth` is the bowl's depth times it (a look; the fighter's state is today's).

## The crater_shape event

Combat's `crater_shape` (biomes.md section 4.3) is the director's to send (no `hash.gd` line for World). World makes it one call: on a `crater` event whose `surface` is not empty, `WorldCraters.eventFor(e, e.surface)` gives `{x, y, r, depth, rim, owner, surface, shape}`, the bowl as dug and its row (factors, refill, embedMul, fill, breakThrough and the looks: `cracks`, `ejecta`, `rimKind`, `treesLean`, `glowTicks`). The sim never reads the looks.

## State

None of its own. The refill jobs, the slot (`SPLIT`) and the flooded bowl (`FLOODED`) are `after.gd`'s state; a match sizes it when either switch is on (`terrain.gd`, `planet_world.gd`), so with this switch on a hand-made or gen 1 match hashes as with it off plus after.gd's two zeros. With the switch on `contact.json`'s data hash carries `craters.json` (parsed, without the notes).

## The props (ground.json, `provisionalProps` false)

Three rows for Combat's PROP SMASH, sizes World's own, marked `provisional` for Art, laid by `WorldGround.propsIn` only with `provisionalProps` on (each row keeps its own keyed draw, so the others lay the same either way):

| Biome | Kind | per 1,000 units | Size | Gap |
| :--- | :--- | ---: | :--- | :--- |
| sea ice | `berg` | 0.25 | 0.6 to 2.9 of a fighter height (45 to 215 units, as planet-ice.md's bergs) | |
| savanna | `lone_tree` | 0.4 | 0.9 to 1.5 | 40 to 100 (W5; was 120 to 300) |
| beach | `lone_tree` | 0.2 | 0.8 to 1.3 | 50 to 120 (W5; was 160 to 400) |

`gap` is the clear ground a lone tree keeps from any other tree, in feature units. W5 places them (`docs/world/props-w5.md`): the gap rule, the bergs on the planet's own cells, and `propsNear` for PROP SMASH.

## Not done here

- Rendering's `ground_field.gd` rebuilds a bowl from its record with `WorldCrater.profile(u, depth, rim)`: the factors are in the record, the wall's `steep` is not. Until Rendering passes it (from the crater event's `surface`), a steep or slack bowl draws with today's wall.
- `WorldCrater.deepen` (a blow into the crater he lies in) lowers with today's bowl shape.
- With depth rows on, the refill and the fill work the slam's own row; the neighbouring rows keep the dug bowl.
- MARSH SWALLOW's sure embed, the surface terms and the events are Encounter's.
