# Four of my checks and VFX's ghost tally on the GW1a stack: check parks for GW1a

Rendering, 2026-11-14, at the EP's word, ahead of the queue. The checks are flash_reg_check, flight_check, sweep_check and props_check. Simulation attributed the first two and props_check on the GW1a stack (main + every GW1a park, the EP's scratch tree s422), and VFX found the ghost tally. I ran them on a copy.

## 1. flash_reg_check, two camera rows: re-read (`flashreg_settle.diff`, sha1 83860a10, 47 lines, `render/tools/flash_reg_check.gd`)

They pass without Simulation's `data-fight-gw1a` and fail with it. Both read the camera in a match's first frames, and GW1a's opening (the 9 November switches: kick, brake, slip, budget) pulls the zoom faster than their 5% in a frame:
- **the scale row:** the register got 0.48 (the camera at the frame's interpolation point) against the tick's camera at 0.4766 (× 768 / 720 = 0.51);
- **the depth row:** the register's distance, a frame old, was 2,819 against 2,650 this frame.

The code is right; the rows measured too early. The re-read:
- **`_settle`:** step one tick a frame until the zoom moves less than 0.2% in a frame (at most 240 frames), then read.
- **The scale row:** a frame consumes its tick's events, where the register takes the scale, before its render sets this frame's scale. So the register holds the scale the frame before set. The row notes that value and checks the register holds exactly it one frame later; it used to compare against the current value, which only matched while the camera stood still.

Result: 34 of 34 rows pass on the GW1a stack and on main + `look-recut/` (without GW1a's data).

## 2. flight_check: a fix (`flight_zone.diff`, sha1 4bde6a95, 11 lines, `render/core/planet_view.gd`)

It fails both ways, so it predates the grant. With it, 20 rows: building 239 shows 5 standing with 4 people. Without, building 236 shows 1 standing with 0 people.

- **The cause:** the sim's gradual flight (`WorldCollateral`, near the heavy fighting) lowers a building's people by fractions every tick, and sends its event only once a lot has gathered. The planet view re-reads those buildings through the sweep's flight zone. That zone was read through `_along`, the sweep's index of each building's x at build. On a field world that doesn't follow the swing's pose (`S.bX`), so after the line swung, the view stopped re-reading buildings the sim was emptying.
- I noted on 6 November that the zone still used `_along` when I moved the startle to `_near_x`; GW1a's data (its scatter radius, its swings) brings it out.
- **The fix:** the zone reads `_near_x`, the poses as the sim has them. One line. It isn't World's people: World's numbers are right, and the view read the wrong buildings.
- **Result:** `flight_check` passes on the GW1a stack and on main + `look-recut/`.

## 3. sweep_check's control A: re-read (`sweep_ctl.diff`, sha1 1460a871, 39 lines, `render/tools/sweep_check.gd`), found by this park's own gate run

On the GW1a stack, control A fails before any park of mine too (checked with the flight-zone line taken out).
- Control A cuts the sweep to its slice and must find what that misses, so it needs a match whose buildings change.
- Under GW1a's fight data, the city at tier 3 on seed 4 changes no building in 1,800 ticks.
- **The re-read:** it tries a further seed at a time, up to six, until one has something to miss. A seed with nothing prints a "note", and only the last can fail.
- **Result:** on the GW1a stack seeds 4 and 5 have nothing, and seed 6 finds 186 differences; on main + `look-recut/`, seed 4 finds them as before. `sweep_check` passes on both.

## 4. props_check, three rows: a pin (`props_strip.diff`, sha1 716dca7a, 10 lines, `render/tools/props_check.gd`)

It isn't GW1a's fight data. It's the globe ground being on by default, from `look-recut/`, which GW1a lands.
- **The cause:** with the globe ground on, `RenderTileGround.setup_of` gives every match that names no planet planet 7 at gen 3, so there is no hand-made world any more.
  - props_check stages gen 2 spots and a hand-made world (`_start(4, ...)` with no planet), so all three rows read the wrong world.
  - **The "off" row:** the "hand-made" world is a planet, so it lays props.
  - **The "broken" row:** of the gen 2 PROP SMASH spots, 1 launch played and it broke no prop.
  - **The control row:** with nothing broken, it has nothing to compare.
- **Why it was missed:** `look-recut/` pinned the old strip ground in the 11 checks whose rules are the strip world's. props_check isn't in my gate set, so it wasn't one of them.
- **The pin:** `main.strip_ground = true` before main enters the tree. It's the same line and the same reason as those 11.
- **Order:** it uses look-recut's `strip_ground`, so it lands with or after `look-recut/`. On main alone the property doesn't exist yet. It applies on HEAD 41768933.
- **Result:**
  - On the GW1a stack, 9 of 9 rows pass (3 of 9 fail without the pin).
  - Planet 7's ring has 126 props on the strip ground (312 on the globe).
  - 6 PROP SMASH launches played, 2 broke a prop, and each was gone from the view on its frame. The control misses both.
  - On main + `look-recut/` (without GW1a's data), the "off" row fails without the pin and all 9 pass with it (6 launches, 6 broken).
- **Owed:** props_check has no globe-ground version yet: gen 3 planets with spots for PROP SMASH and a planet with props switched off. It is now a pinned strip check, like the 11. I'll write one if the EP wants it.

## 5. VFX's hash_check ghost tally: VFX's limb echoes, not my after-images (`grant-vfx-ghost-limb.patch`, sha1 b96a9be0, 16 lines, `render/vfx/ghost_tally.gd`, VFX's path)

VFX's hash_check fails on 25 ticks over a limb limit (f01: at most 2 limb-ghosts of one limb). The worst whole-figure tick, five of my after-images on one fighter, isn't over anything.
- **Not mine:** the tally counts my after-images as whole-figure ghosts (m12, at most 5 round one fighter). They peak at 5, Rendering's alone are over it on 0 ticks, and the budget as drawn is over it on 0 ticks.
  - Limb ghosts come from VFX alone: a tech blow's echoes (the press) and a tech zip leg's echoes, both counted on the limb `slot * 2`.
- **What each failing tick holds** (`ghost_probe.gd`, scratch: hash_check's real match at 60 Hz, seeds 4, 12345 and 7):
  - Every one is one fighter's tech blow echoes (1 or 2) plus that fighter's zip leg echoes (1 or 2), on the same limb: 3 or 4. That's 10 ticks at high quality, in four short runs of 2 to 3 ticks (seed 4 ticks 2460 to 2463, seed 7 ticks 414 to 417 and 619 to 622).
  - The press's counter grants a blow's echoes up to 2 a limb without the zip's. The zip's echoes were held only to the five-ghost budget, never to the limb's two.
  - At low quality with reduced motion: 0 ticks.
- **Which park:** it isn't the energy model. With power and the dash off it's still 9 ticks. It's GW1a's fight data putting a tech blow and a tech zip leg on the same ticks. VFX's code is identical on main and on the stack, and main's data never lines them up, which is why VFX's own look stack passed.
- **The fix (VFX's call, a grant):** the tally holds a zip leg's echoes to what's left of that limb's two and the screen's four, after the blow's echoes. That's the order the tally already uses for the budget ("echoes first, they are the blow itself"). shots_view already draws at most `zecho_n` of a leg's echoes, so the cap reaches the picture.
  - **On screen:** on those ticks (about 3 in a minute of AI play), a zip leg shows 0 or 1 of its 2 wire echoes while the blow's 2 show.
  - It's visible at high quality, which the default look uses: Reduce flashing doesn't turn on reduced motion.
  - The look gate and the choice are VFX's. They may prefer to grant in the press's counter or key the zip's echoes elsewhere.
- **Result** (the GW1a stack copy with VFX's `gw1a-pins/` and this grant):
  - VFX's effects_check: 1,169 ok, 0 failing, as VFX's own record.
  - The probe: 0 ticks over at every seed.
  - hash_check passes. All 24 runs are the same as the sim alone. Of one limb 2 (2 at most); ticks over a limb limit 0; the budget is held as before.

## Proof

On the GW1a stack with the first two (`docs/rendering/runs/809e93e5/gw1a-checks.txt`):
- `golden.json` is byte-identical to the stack's own;
- the tile, lake water, cover water and ground checks pass; `sweep_check` passes with the third (the same record);
- the render gates pass 19 of 20, with `flash_reg_check` and `flight_check` passing.

The one that fails is Camera's `split_sweep`, the energy-on failure already routed to Camera (`docs/rendering/runs/611c1c2b/split-sweep-energy-on.txt`).
