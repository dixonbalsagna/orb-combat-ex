# VFX in depth: an audit of every layer for a fight off the plane (2026-10-12)

Owner: VFX. For the EP, on Orb's ask that fighters travel the depth band and the next public build be "a huge step". Reads `docs/design/depth.md` (Game Design), `docs/rendering/fighters-in-depth.md` and `docs/rendering/open-floors.md` (Rendering). Render only: nothing here reads or writes anything the sim hashes. **Nothing here changes a pixel with depth off:** every change below is inert at depth 0 and is proved so by `effects_check` ("depth") and the determinism runs.

## In short

- **Most layers already draw at the depth of what made them.** A press, a ghost, an echo, a reach effect, a zip's body, an aura, a transformation, a trail, a pressure ring, a rock and a shot all read the fighter's depth (`host.fighter_z`, interpolated) or the event's. The earth effects, the stage effects and the glass read the event's or the building's.
- **Five things drew on the plane whatever depth said, and are built now (inert with depth off):** scorch embers, the sea's spray and rings, the head of a beam's wake, a zip's ground tell, and the ground a bit bounces on.
- **Two things still need other owners:** `crater` carries no depth, so a crater's dust, bowl, shock ring and the cracks stay on the plane (nothing digs in depth until L4); and the camera's distance is needed for sizes (see the register).
- **What must not draw through an opened floor or the patch is one rule and one read from Rendering** (section 4): `hub.clear_query`, built and inert until Rendering sets it.
- **The flash register must account for size.** A flash at 54% size covers 0.29 of the pixels. The weights fall with it (section 5), once Rendering gives `cam_dist`.

## 1. Sizes: what an effect is on screen at each depth

Close brawl, 720p, zoom 1.15 (fighters-in-depth.md section 1): a 75-unit fighter is 86 px, so a world unit is 1.15 px on the plane. The camera stands 1,168 units from the plane. Area is the square of size.

| Where | Size | Area | A unit is |
| :-- | ---: | ---: | ---: |
| The front street's near kerb (+187) | 119% | 1.42 | 1.37 px |
| The plane | 100% | 1.00 | 1.15 px |
| The middle of the middle street (-1,012) | 54% | 0.29 | 0.62 px |
| The middle of the back street (-2,025) | 37% | 0.14 | 0.42 px |

| Effect (world units) | Plane | Front street | Middle street | Back street |
| :-- | ---: | ---: | ---: | ---: |
| Press contact ring, 80 across | 92 px | 109 | 50 | 34 |
| Heavy wind-up ring, 68 across | 78 | 93 | 42 | 29 |
| Zip band, 16 wide | 18 | 22 | 10 | 7 |
| A thin line, 2 wide | 2.3 | 2.8 | 1.2 (floor 1.6) | 0.9 (floor 1.6) |
| Shot's hit flash, 45 to 130 across | 52 to 149 | 61 to 177 | 28 to 81 | 19 to 55 |
| Explosion, 37 to 225 across | 43 to 258 | 51 to 307 | 23 to 139 | 16 to 95 |
| Debris chunk, 20 to 60 | 23 to 69 | 27 to 82 | 12 to 37 | 8 to 25 |
| Glass sliver, 20 to 40 long | 23 to 46 | 27 to 55 | 12 to 25 | 8 to 17 |
| Ember needle, 42 to 112 by 9 | 48 to 128 by 10 | 57 to 153 by 12 | 26 to 69 by 6 | 18 to 47 by 4 |
| Dust puff at its widest, 34 to 82 | 39 to 94 | 46 to 112 | 21 to 51 | 14 to 35 |
| Beam head ring, 70 across | 80 | 95 | 43 | 30 |

- **Lines have a pixel floor** (`minpx`, 1.6 px): a thin line stays a thin line at 54%, so it reads relatively heavier in the back. Everything else scales by perspective, which is right: nothing is rescaled against the world (Rendering's rule for fighters).
- **Budgets are in pixels, not units.** The ember and puff area budgets (`EMBER_AREA_SHARE`, `PUFF_AREA_SHARE`) divide by `px_per_unit` squared, so a pair in the middle street, at 0.29 of the area a unit, may have about three times as many needles and puffs as at the plane before the same share of the register's threshold. The count caps (`EMBER_CAP`, `PUFF_CAP`) are unchanged.

## 2. The audit

"Reads" means the layer places what it draws at the depth of the fighter or event, interpolated where it moves.

| Layer (file) | Reads depth today? | What it needs | Now |
| :-- | :-- | :-- | :-- |
| Press styles: speed smear, tech echoes, heavy ghosts, block shield, glint, contact marks (`press.gd`, `shots_view._press`) | **Yes.** Attacker's `fighter_z`; marks on the victim at the victim's | Nothing for a pair a few units apart in depth. The path and the old poses are drawn at his present depth (a drift of 1.5 bh a second moves it 2 units a tick) | Fine |
| Ghosts, echoes, after-image budget (`ghost_tally.gd`) | Yes (the fighter's) | Rendering's after-images are placed by Rendering | Fine |
| Reach: energy blasts, wind-up rings, launcher chevrons, charge and double-hit flashes (`reach.gd`) | **Yes.** Slot's or victim's `fighter_z` | The register asked with the plane's pixels | Asks at the fighter's depth (section 5) |
| Zip: tell, bands, ghosts, echoes, marks (`zip.gd`, `_zip`) | Partly: **the whole travel at his present depth.** The ground tell ran from his place to the arrival point at one depth; a zip homes in depth too | The depth he starts at and the target's | **Built:** `Zip.oz`, `Zip.pz`; the tell runs from one to the other, on the ground at each depth (`groundY(S, x, z)`) |
| Aura, standing mark, transformation: gather, break, flash, dim (`transform_view.gd`, held) | **Yes.** `fighter_z` | Untouched: the held view stays. Its break flash asks at the fighter's depth through the hub | Fine |
| Trails, ribbons, marks (`trail_state.gd`, `trail_view.gd`) | **Yes.** History of `f.z`; marks at `f.z` plus a range | Nothing | Fine |
| Pressure rings, rocks, speed lines | Yes (`f.z`, launch z) | Nothing | Fine |
| Shots: bolts, arcs, mines, hits, deflects, explosions (`shots.gd`, `_shots`) | **Yes.** `shot.z` and the event's | The flash asked at the shot's depth | Section 5 |
| Beam play: wedges, wakes, launch (`beamplay.gd`) | Partly: **the head's wake was placed at the beam's origin depth.** A beam in depth changes depth along its length (`zs`) | The depth at the head | **Built:** `oz + zs x distance` |
| Scorch embers (`debris.embers`) | **No.** Plane constant (`Z_BEAMS + 8`) whatever the event's `z` | The event's depth | **Built:** `z_shift` by the hub |
| Puffs, dust, debris, flames, contact chunks (`earth.gd`, `debris.gd`) | **Yes.** `dust`, `debris`, `fire` and the contact events carry `z` and it is read | The ground a bit bounces on is the plane's | **Built:** `groundY(S, x, z)` for a bit at its depth (the plane's with depth off) |
| Crater: the bowl's skirt, the shock ring, ejecta, the rim (`blast.gd`, `earth.on_crater_ejecta`) | **No.** The `crater` event has no `z` (it has x, y, radius, depth, energy...) | `z` on `crater` (Simulation), when anything digs in depth (L4) | Reads `e.z` if it comes; plane today |
| Cracks: crater, slide and standing (`crack_view.gd`, `react._stand`) | **No.** Meshes are at depth 0 (`Vector3(x, 0, 0)`) | The same `z` on the record, and on a standing set the fighter's | **Not built:** wait for the field |
| Wakes, plunges, skims, beam spray over the sea (`water.gd`) | **No.** `Z_BEAMS` constants | The event's depth (`splash`, `skim`, `beamSplash` carry `z`) | **Built:** `z_shift`, and a job keeps the shift it was made with |
| Window glass, cladding, stage dust, floors (`react.gd`, `stages.gd`, `debris.window_row`, `floor_hit`) | **Yes.** The building's own facade depth (`front_z`, `b.z + d/2`) | Not to start in an opened floor or across the patch (section 4) | **Built:** `clear_query` guard |
| Building holes (`hole_view.gd`) | Yes (the building's facade depth) | Same as glass | Fine |
| Explosions (`explode.gd`) | Yes (`z` from the event) | Same register change | Section 5 |
| Glasses glare (`glare.gd`) | Yes (drawn at the head by `shots_view`) | Nothing | Fine |

## 3. What is built (inert at depth 0)

- `VfxDebris.z_shift`: added to every bit as it is made. The hub sets it to a `scorch`, `splash`, `skim` or `beamSplash` event's `z` round the handler and resets it; a job made under it keeps it (`Job.zs`), so the sea's second column comes at the right depth. Zero: no change.
- The head of a beam's wake at `oz + zs x p x len`.
- `Zip.oz`, `Zip.pz`, and the tell's line and end tick placed at each depth, with the ground read at that depth.
- Bits bounce on `groundY(S, x, z)`. With depth off, or at `z == 0`, `groundY` is the plane's.
- `VfxHub.cam_dist` and `VfxFlashRegistry.ppu_at(z)` (section 5).
- `VfxHub.clear_query` and its three uses (section 4).
- Tests: `effects_check` "depth" (embers and skim at the event's depth, `ppu_at`, the weights, the zip's depth, the query), and the existing groups unchanged; `hash_check` and both determinism runs.

## 4. What must not draw inside an opened floor or through the patch

Rendering's rule (open-floors.md): an opened floor has no wall, so there is no glass, no debris and no dust *from it*; the patch is a window cut through what stands in front of the fight so the fight can be seen. The one rule for VFX:

**Nothing the building makes is drawn in front of the fight inside the see-through region; the fight's own effects always are.**

- **At spawn:** no window glass, cladding or stage dust from a point where the building has no wall (an opened floor's band). Built as `debris._visible_at(x, y, z)` before each sliver and each shed, asking `hub.clear_query`.
- **At draw:** a bit whose world point (x, y, z) lies inside the patch or an opened band, nearer the camera than the fight, is faded by the query's answer (0 hides it). Built in `shard_view` per pane (`cq.call(Vector3(b.x, b.y, b.z))`, 0 to 1, multiplied into its alpha, dropped under 0.004). Sparks, rings, hit flashes and everything at the fighters' own depth must answer 1.
- **The contract with Rendering:** `host.vfx.clear_query = Callable` taking a world `Vector3` and returning 0 to 1: the share left visible. It is the pane's own patch capsule and open bands (they differ by pane); the hub keeps one callable, so for two panes Rendering either sets it per pane before the layer draws or gives a callable that reads the pane being drawn. **Invalid (the default): everything is visible, as today.**
- **What I did not do:** no per-building open-band read. The query covers it: a point on an opened floor's facade answers 0.

## 5. The flash register and size

**Answer: the weights must fall with size.** The analyser counts pixels. A flash at 54% size covers 0.29 of the pixels and weighs 0.29 of what the same flash on the plane weighs; one in the front street weighs 1.42 times. Keeping the plane's size would refuse flashes that cannot be seen as flashes, and the budget is the only thing that keeps a mash readable.

- Built: `VfxFlashRegistry.ppu_at(z)` = `ppu x D / max(D - z, 0.2 D)`, clamped to 0.25 to 3, with `D = hub.cam_dist`, the camera's distance to the fighters' plane in units. Without `cam_dist` (0: depth off, or not yet set) it is the plane's, so nothing moves. Every VFX ask now passes its fighter's or event's depth: explosion, shot hit, energy, charge-full, double hit, block, zip break, transformation.
- **Needs Rendering, one line:** `host.vfx.cam_dist = <camera distance to the plane>` each frame, beside `px_per_unit` (it is known to the camera: 1,168 at a close brawl, 2,240 at zoom 0.6).
- **The honest limit:** flashes Rendering draws itself (the body's white, the head, the guard arc, the beam's core) take the size from `SimHost.flash_px`; they need the same `ppu_at(z)` of their fighter. I have not touched `render/core`.
- Camera's cuts and a panel are whole-frame; they do not scale.

## 6. The pair's ground mark (item 3: look)

What Rendering drew: a pale stroke between the two fighters' feet in a dark rim, about 5 px at its middle, broader under the nearer one, only with depth on, in 0.2 s and out in 0.5 s. Stills `docs/rendering/img/lanes/depth-pair-mark*.png`. What I would change so the direction reads at a glance without becoming a flash source or a second HUD:

1. **Read the value, not only the width.** Make it a wedge: brighter and wider at the nearer fighter's foot, darker and narrower at the far one, by a static luminance gradient of 0.06 to 0.08 end to end. Width alone is 3 degrees on screen; a gradient reads in the periphery. It is static, so it adds no change.
2. **Never more than 0.10 of relative luminance against its ground, anywhere.** A 5 px stroke 300 px long is 1,500 px, a seventh of the register's area threshold, so it is not a flash by area; but a stroke that is 0.4 against a dark road is a bright line a camera pan moves every edge of (the ember lesson). Choose its core by the local ground's luminance: ground plus 0.09, rim minus 0.05, bounded. On a pale sidewalk it comes out as a darker stroke, which is right.
3. **No fighter's hue.** Neutral, as built. The lane cues already carry each fighter's colour; a mark in either's hue would tell the player who owns the ground.
4. **Fade by tick time over at least 0.5 s both ways, and hold at least 1 s once up.** A drift that crosses the 6-unit threshold and back would otherwise blink it. Under reduced motion or reduced flashing: no fade-in at all, steady at 60%.
5. **Quiet at rest, louder on a change.** Hold it at 45% of full while the line is steady, and bring it to full for 0.6 s only when the line's angle changes by 5 degrees or more (a sidestep, a push that turns it). That is the "second HUD" worry answered: a steady fight shows a faint line, a turn announces itself, and the brightening is a 0.05 step.
6. **One mark, never two.** Where the lane cues' stripes are up as well (more than 80 units apart in depth), draw the stroke at 30% so the three do not read as three marks.
7. **Width in pixels, as built, but scaled by the nearer fighter's size** (4 px at 54%, 6 px at 119%), so it never reads wider than the fighter's own boots.
8. **No motion along it.** An animated dash or an arrow running along the line would be the second HUD, and a flicker source under a pan.

Not mine to build (it is Rendering's ground shader); numbers for Rendering and Art to take or leave.

## 7. What I need from others

| From | What |
| :-- | :-- |
| Rendering | `host.vfx.cam_dist` each frame; `host.vfx.clear_query` (the patch and opened bands, 0 to 1); the same depth scaling for its own flash asks; a `RenderShapes.pane_present(b, column, row)` if glass should skip blank cells |
| Simulation | `z` on the `crater` event and on the crater record, with the first dig in depth (L4); until then cracks and crater dust stay on the plane |
| Camera | Nothing for VFX. The size problem in the middle street is theirs (fighters-in-depth.md) |
| World | Water effects fire 0 times in real matches now (the fights have left the ocean): worth a line, and `hash_check` says so |

## Limits

- Not seen in depth: no scenario puts a fight off the plane in a real match yet, so the layers are proved by their numbers (effects_check "depth") and not by a picture. The first still of a pair in the middle street with a beam, a blast and a zip is the check that is missing.
- The sizes in section 1 are for the one-view camera at a close brawl; a split's panes were not measured.
- Cracks at depth, crater dust at depth and the ground under a fighter on a roof wait for the sim.
