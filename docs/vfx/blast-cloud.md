# The blast cloud (catastrophe tier, step 3)

Owner: VFX Director. 2026-10-18. Step 3 of `docs/vfx/catastrophe-plan.md` (§2), built in scratch and parked (`docs/vfx/pending/blast-cloud/`), on top of `fbfdf182` (the `cat` class, the tremor's dust). Legal c01 to c07 and run-mode §3.2 bind it. **Inert until a `blast_cloud` cue exists** (Audio's list: `x`, `y`, `amount` the blast's size, 3,000, and `n` the tick it lands); a scratch scene injects it for the measurements below. Not a clearance.

## What it is

A tier-5 detonation's stem-and-cap cloud, with a fireball inside it that is **the one catastrophe light event** (the `cat` class). Our own blast cloud (c07): no word, sign, siren or countdown; **no ring** leaving the blast (the ground wave is a dark dust wall); **no dome of light** (the glow is a lumpy cluster of noise-broken blobs inside the stem and cap); the boss never charges a sphere, and nothing here has a pose to: the wind-up is the fighter's own detonation cue.

| Piece | File | What |
| :--- | :--- | :--- |
| Rules and state | `render/vfx/blast_cloud.gd` (`VfxBlastCloud`) | the cue's runs (at most 2), the landing, the one ask of the register, the light envelope, the CPU mirrors of the curves and the ramp |
| The body | `render/vfx/cloud_view.gd` (`VfxCloudView`) + `shaders/cloud.gdshader` | **stateless**: one MultiMesh of up to 400 billboards, all identity transforms, every position a closed-form curve of the cloud's age in the vertex shader (`cloud_curves.gdshaderinc`); the CPU writes a handful of uniforms a frame and rewrites the buffer only when the sprite budget steps |
| The fireball | the view's `core` MultiMesh + `shaders/cloud_core.gdshader` | 12 pieces and 4 crater-floor glows, additive, one draw call; brightness is the granted envelope |
| Numbers | `data/vfx/catastrophe.json` (`blast_cloud`) + `tools/schemas/vfx-catastrophe.schema.json` | every number below; the built-in defaults are held equal by a check |
| Wiring | `vfx_hub.gd` (`blastcloud`, `ash`), `trail_view.gd` (`cloud_view`), `render/core/warmup.gd` (two lines) | the hub steps it inside `catastrophe_enabled`; two draw calls per pane |

## The curves (the plan's)

`t` seconds after landing; `scale` is the blast's size over 3,000.

- **Stem:** its top rises to `14,000 x scale` units, `1 - e^(-t/6.5)` of it (95% at 20 s). Its sprites stand along 80% of that height, a flared base (260 to 760 units wide), a sway of at most 6% of the width.
- **Cap:** a rolling torus seen from the side: ring `2,600 x scale (1 - e^(-t/8))`, thickness `1,500 x scale x min(1, t/5)`, turning at -0.35 rad/s, its far side 15% darker.
- **Ground wall, not a ring:** `4,500 x scale (1 - e^(-t/3.2))` each way, 300 to 600 units high, a dust wall with a ragged top.
- **Colour:** fire into smoke by heat (white-amber, amber, ember brown, smoke) with `heat = e^(-t/tau)`, tau 4 s in the cap's core and 2.2 s in the stem; **no colour of the ramp is red: the largest R/(R+G+B) is 0.65, on the stored values or the linear ones** (the analyser's line is 0.8).
- **Body opacity:** in over 1 s, held at 0.85, out over the last 8 s of its 40 s life; the steepest tick is 0.021.

## The light (c01, c02, c04, c05)

The fireball is **asked once, at landing**, as `cat_blast` through `ask_cat`, with its glow's area at peak (the core radius, at most 0.35 of the cap's ring, 910 units at 3,000, against the 21,824 px threshold: weight 1 at fight framing). The registry gives it a rise of **0.6 s (calm 1.0 s)**, a fall of **2.4 s (calm 3.6 s)**, one per 2 s across the screen, a peak scaled by `1 - 0.35 ash` (`hub.ash`, the sim's darkening when it exists), and in the calm form (Reduce flashing, the game's default) a peak x0.6. A second cloud inside the gap **keeps its smoke and loses its light** (logged `cat_gap`), and the ramp is held at amber, never white. The light's steepest tick is 0.052 of its peak, a flash needing 0.1.

## The ladder (the fill rate is the cost)

| Level | Sprites | When |
| :--- | ---: | :--- |
| High | 400 (120 stem, 200 cap, 80 wall) | quality high |
| Medium | 260 | quality medium |
| Low | 140 | quality low (VFX's governor) |
| Far | 24 larger sprites (x2.4) | the cloud more than 9,000 units from the camera: an impostor of its silhouette |

Not built, from the plan: **the half-resolution pass** at low quality (the sprite count is the lever instead), the 8-tick hush before the blast, the ash-fall flecks (they read the sim's `ash`, which does not exist yet; `hub.ash` is the hook), and Camera's rule against a cut within 0.5 s of the peak (`cat_peak_near` is the query, Camera's to call). Only the latest landed cloud draws; an older one is retired at the second.

## Measured (main e4e259cb + the parked patches, native checks and web clips, one capture at a time)

- `effects_check` `_blast_cloud` passes: the data file against the defaults, the ladder, the layouts, the ramp (no red), the curves (monotone, arriving at their sizes), the body's fade, **no cue = nothing runs and the register is never asked**, no ask before landing, one ask at landing, the light's envelope and steepest tick, the refused second cloud (`cat_gap`), the cap on clouds, the calm form (peak 0.60, rise 62, fall 216 ticks), the ash scaling (0.65) and determinism.
- **Flash clips** (a scratch scene: the city mash with a blast cloud cue at ticks 90, 140 (inside the gap) and 900, 1,200 ticks, 1024 by 768, the official analyser): **both modes PASS, primary 1, area-15% 1, higher threshold 1, stricter cross-check 1.5, red 0.**
- **Collapse, both modes, with the code in and inert:** see the report (the numbers are in the EP's message).
- **Look:** the cloud is huge. At fight framing, 700 units from the blast, the smoke wall crosses the screen from the right in about a second after landing, an ember-orange haze that cools to grey-brown over ten seconds and darkens the street and towers to a flat dusk; the fighters stay clear (the cloud stands behind their plane). It is a first version for Art and Camera to judge: from a wide framing it should read as a stem and cap, and nothing here sets a camera.
- Cost: counts and estimates only (no timing was taken, the machine is shared): two draw calls per pane; at most 400 plus 16 instances; the fill rate of a close view is the known risk (the plan's estimate was 1.5 million blended fragments at 720p at high; unmeasured).

## For the others

- **Simulation:** the `blast_cloud` cue with `x`, `y`, `amount` and `n` (the tick it lands), and the world's `ash` (read-only); `hub.ash` is where I read it.
- **Camera:** the cloud never needs a cut; a cut within 0.5 s of the light's peak is the registry's `cat_peak_near`.
- **Rendering:** the two new shaders are in `RenderWarmup.SHADERS` in this patch (two lines in `render/core/warmup.gd`).
- **Tools:** `vfx-catastrophe.schema.json` has a `blast_cloud` block now; its fixtures (one valid, three invalid: an `alpha_max` of 0.95, a `sprites` entry of 500, a `core_radius_k` of 0.5) are Tools'.
