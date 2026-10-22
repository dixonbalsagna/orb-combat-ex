# The energy look: beams with a real width and a flavour, and explosions with flames (2026-10-16)

Owner: VFX. Built in scratch on HEAD 32029623 and parked (`docs/vfx/pending/beam-look/`), not applied. Orb's words after the live demo (`docs/ep/vision.md`, last section): "the beams are too thin right now. it would be cool if a particular beam attack for one fighter in the roster was thin, but for all of them to be tiny doesn't look right. I really want the beams and energy attacks to have cool, rippling, glowing, fluid-looking shaders, each character should have their own flavor of energy attack. the explosions from the small energy attacks should be more explosive, flames and smoke." Legal's conditions are `docs/legal/movegen-banned.json` fx03 (RL-140); both go into the flash set before they ship.

## Why the demo's beams read as thin lines

Reduce flashing is on by default, so the flash register is never asked for a beam's bright form: every beam was drawn **calm**, which was "a thin line where the white core was and the glow at 0.18". The same refusal also turned every small blast's flame burst into sparks and smoke. So what Orb saw was the fallback form, in every fight. The new look has no thin fallback: the same beam, a little dimmer (0.86) and a slower rise (0.3 s), in either setting; and the blast keeps its flames either way.

## The beam

Rendering's `BeamView` still draws three nested prisms from the tail to the head; what changes is each prism's material and size (`render/vfx/beam_look.gd`, `render/vfx/shaders/beam*.gdshader`, `data/vfx/energy.json`) and a small hook in `beam_view.gd` and `sim_host.gd` (Rendering's two files; the patch is parked with the rest).

| Layer | Width (times the sim's beam width) | Blend | Alpha | What it is |
| :-- | ---: | :-- | ---: | :-- |
| Sheath | 4.0 | additive | 0.30 | a soft deep-saturated glow, the widest swell and the most edge turbulence |
| Body | 2.2 | alpha-blended | 0.80 | the lane colour at a deeper saturation |
| Core | 0.9 | alpha-blended | 0.95 | the lane colour itself, lightened by a tenth at most: **never white** (Art's aura rule: the core at most L* 86) |

The old look was 2.4, 1.3 and 0.5 in three additive layers, which add up to white. A tier-2 beam (width 42) is now 168, 92 and 38 units across, against 101, 55 and 21; times the fighter's `width_k` (1.15 for the Protagonist, 1.3 for the Rival, 0.42 for the Anti-hero's particular thin one).

**The shader** (one include, two thin files: the sheath adds, the others blend):
- **Shimmer, in hue.** Two tints of the same luminance (the second is the first's hue turned by `hue_shift`, found by a search so the luminance matches) and a slow ripple that travels along the beam between them. Its alpha moves by at most `lum_amp` (the core 4%, the body 7%, the sheath 16% of a 0.30 layer): hue and shape move, brightness stays.
- **Filaments.** Long thin streaks along the beam, again in hue and saturation.
- **Edge.** The width swells and thins slowly along the beam (the prism has 24 rings now) and the soft edge breaks up with value noise: the outline flows, the axis is a straight line.
- **Ends and heel.** The ends are rounded off over 40 units; the firer's end swells while the beam is still attached to him (the Protagonist's, from the heel of the palm: 0.7).
- **Never a strobe.** The ripple rate is `hz` times the wavelength, at most 2 Hz at any point (1.1 for the Protagonist, 0.8 for the Rival, 1.4 for the Anti-hero); nothing goes round the axis.

## Each fighter's own energy (data/vfx/energy.json, keyed by roster id; corrected 2026-10-16: the Anti-hero IS the roster's RIVAL)

The colour is the fighter's lane colour (so the colour-vision presets follow), the second tint a hue shift of it at the same luminance. Art confirms the families (the EP is asking).

| Roster id | Who | Family (Art's lane) | Second tint | Width | Motion character |
| :-- | :-- | :-- | :-- | ---: | :-- |
| PROTAGONIST | the hero | cool cyan to azure (#8fd6ff) | +30° (-30° under the tritan preset) | 1.15 | **flowing**: a long soft wavelength (150 units), a soft edge that swells and thins, a strong heel swell (0.7); a bolt's tail swims a little |
| RIVAL | the Anti-hero | violet to magenta (#9a80d8) | +34° (capped so it stays at 320° or less) | 1.1 | **exact and cold**: a short wavelength (80), long hard-edged filaments (0.9) in place of swell, almost no edge turbulence (0.05) and a crisper edge (1.35), a small heel; a bolt's tail is a straight ribbon |
| RIVAL, a short beam | the Anti-hero's particular thin beam | the same | +34° | **0.4** | a needle of light: no swell, no turbulence, no filaments, the crisp edge |
| REFERENCE | the training dummy | a quiet neutral (+12°) | +12° | 0.8 | **quiet**: 0.5 Hz, a long wavelength (160), almost no swell, turbulence or filaments |
| anyone else | | their lane colour | +28° | 1.0 | the default |

**The thin beam, and why it is that one.** Orb: "it would be cool if a particular beam attack for one fighter in the roster was thin, but for all of them to be tiny doesn't look right." I picked **the Anti-hero's short beam** (the energy stance's beam of about half a second, held past a charged blast's full charge, 20 ki: `agency-pass.md`):
- **It fits him.** His identity is exactness (a blade of light, the barrage's thin shards, "regal and cold"); a needle is what precision looks like, and it separates him from the Protagonist's broad flowing beam.
- **It is the right attack to be thin.** A poke of half a second reads as a thrust of a needle; the signature, the beam Orb found too thin, stays thick for both fighters.
- **It is cheap on the register**, so a fighter can throw it often.
- **Not built yet in the sim:** today only the signature beam exists (0.95 s). The look is keyed `rival_short` and applies to a beam of 0.7 s or less, or one that carries a `short` field, the moment Simulation adds it; until then nothing is thin in the demo.

The bolts and blasts (`shots_view.gd`) take the same two tints and character: a tail of five segments that swims a little (not in reduced motion), stepping between the tints.

**Art's colour fix (docs/art/beam-colours.md, 2026-10-16):** the Rival's second tint turns **+34**, not -34: -34 made `#9a80d8` into a blue (`#768cc8`) inside the Protagonist's azure and outside Legal's 260 to 320, +34 gives an orchid-magenta (`#be77c9`, 292°). It is capped at `min(34, 320 - hue)` (`hue_max` in the data) for a magenta-forward aura. The Protagonist's +30 stands, but under the **tritan** preset it is **-30** (`hue_shift_tritan`): +30 would land his tritan lane `#9c90d5` on a violet, the Anti-hero's family; -30 gives `#8498c3`. The dummy's +12 is confirmed. The preset is read from `VfxAura.vision_mode`, which the hub sets with the lane table. Equal luminance holds to three decimals; under protan and deutan the Rival's shimmer is a texture and the lane colour carries the beam.

## The explosions of the small energy attacks

- **Flames always.** The blast was a "burst" only if the register granted a flash; refused, which is every time under Reduce flashing, it was sparks and smoke. A refused blast is now `calm`: its flames still go off, with 0.7 of the cinders.
- **More of them.** The scale of a small blast never falls under 0.62 (a bolt's was 0.33), the flame count base is 7.5 (was 5), a body hit keeps 0.75 of it (was 0.55), the smoke is 1.35 times the puffs and bigger, and a third of the sparks are cinders of the shooter's own colour.
- **Staggered and growing, so none of it is one frame's flash** (fx03): the flames go off in three waves (45%, then 30% at 4 ticks, then the rest at 8, each wave spread wider and a little bigger, with two puffs of smoke rising with the late ones), and each flame grows in over its first 0.1 s (a third of its size to full, its alpha with it) before it burns down.
- **What it does not add:** no rubble ring, crack or lightning on a body; no red flash (the flame is the cel orange, R/(R+G+B) 0.56); a guard's or a deflect's blast is still sparks and smoke.

## Against Legal's fx03

| Condition | How it is met |
| :-- | :-- |
| a plain straight line | the axis is a straight prism; the width swells and thins and the edge breaks up in shape only; nothing spirals, drills or twists |
| a ripple of 2 Hz or slower, under 10% luminance step | `hz` capped at 2 in code and 1.4 at most in the data; the tints have the same luminance (asserted), the alpha moves by 4% to 16% of a layer |
| never a strobing core | the core's alpha moves 4%, its colour the lane colour; no white in any layer (asserted) |
| start and end flashes through the registry | unchanged: `SimHost.beam_flash` and the clash's ask; the area they weigh is now the real body width (`beam_px` takes the owner) |
| an explosion's fire is not a red flash, grows over several ticks, no white or gold full-screen flash, not combined with a rubble ring, cracks and lightning on bodies | the orange cel flame, three waves and a grow-in; no ring, crack or lightning on a body |
| no franchise echo: no twin helix, no two-colour twist, no ball charging in the hand | the two tints alternate **along** the beam and never around it (the ripple's phase is the distance from the firer's end only), nothing is wound about the axis; the firing hand has no charge ball (the gather ring is the wind-up's, thin and hollow, e01) |
| fx01, fx02 (the shine, the cash-in) | the shine: two thin edge lines and a small hollow ring, steady, one hand at a time, only on a light's window, gone at the close, `perfect_made` or `perfect_broken`; the cash-in: a thin line and four closing brackets, then a double ring, a crossed crack, one thin cut and two puffs, 10 ticks or fewer |
| **the calm form** (a beam the register refused, and every beam under Reduce flashing, the shipped default) | written up here for Legal: it is **the full beam** (the same width, layers, flavour and shimmer) at **0.86 of its strength** (the data's `calm.strength`; 0.78 in the first build) **with a slower rise** (0.3 s against 0.1 s, `calm.rise_s`), never a thin line and never a white core. Its brightness steps are the bright form's times 0.86, spread over three times the rise, so it is the form with the lower counted change; the clips below are all read in it (the demo's "normal" clips already run with Reduce flashing on) and with it off |
| both go into the required flash set | measured below, both modes |

## Why two of Rendering's checks loosen (`render/tools/flash_reg_check.gd`)

The register weighs a beam by the width it is drawn at, and the beam's body layer is now 2.2 times the sim's width (the old look's was 1.3), times the fighter's `width_k`. So the same beam weighs about 1.7 times more: **a beam seen from far goes from "under 0.3" to "under 0.5" and the short beam (the "5th" figure) from "under 0.2" to "under 0.3"**; the tier-4 beam still weighs 1.0 (capped) and a new beam still asks the register with its own weight (the check now passes the beam's owner to `beam_px`). The register's budget is unchanged: the wider beam asks for more of it, and is refused sooner, in which case it is drawn calm.

## Also in the build: point-blank bolts and blasts

The energy arts in reach (RB with X or Y, `VfxReach._land`) had a crack, a ring and sparks and no fire at all. A hit now also calls the same explosion on the body (`VfxExplode.at(..., "fighter", "calm")`): flame tongues in waves, smoke, short cinders; a guard's is sparks and smoke only. Legal e06 and e08 still hold: the flash at the hand is the register's one ask, the rim and the thin edge are unchanged, and nothing here is a flash over the body.

## Measured (re-run 2026-10-16 on HEAD 0ca6f670, same-commit baseline; Tools' path, 1024 by 768, session vfx, one capture at a time, both modes)

Primary / area-15% / area+15% / 2-second memory. Every clip passes in both modes and reads the same as HEAD or within 0.5 of it.

| Clip | HEAD normal / reduced | This work, normal / reduced |
| :-- | :-- | :-- |
| **collapse** (run first: the brief) | 2/2/2/1.5 and 2/2.5/1.5/1.5 | 2/2/2/1.5 and 2/2/2/1.5 |
| **choreo** (scratch: the clash scene with the beam struggle's cues scripted into every clash, an opening, a shine, a cash-in, a chase, a tech and an interjection on a 400-tick cycle, 700 ticks) | with the hub off: 2/2/2/2 both modes | 2/2/2/2 and 2/2/1/2, Reduce flashing off 1/1/1/1 |
| ai windows round beams, clashes, bolts, mines and charged shots (12345 x2, 4 x3, 5, 39 x2; 130 to 340 ticks each) | 0.5 to 2.5 | 0.5 to 2.5, equal in 15 of 16, one window +0.5 (ai 4 ticks 1691 to 1820, normal: 1 against 0.5) |
| ai 39 ticks 41 to 240 (the deflected beam on screen) | 2.5, 2.5 | 2.5, 2.5: HEAD itself reads 2.5 here now; the earlier "+1" against the previous HEAD is gone |
| clash, signature, signaturecity, a bolts scene (previous round, on 32029623) | | the same as that HEAD (2, 1.5, 2, 0.5) |

Gates in the scratch copy: effects_check, hash_check (plain and press styles; the register in real matches 408 granted, 8,748 refused, at most 3 in any second, weight 1.00), determinism (plain and `--intro`), the negative control FAILED as it must, `node tools/validate.js` (190 files, 0 errors, 0 warnings), `flash_reg_check`, `depth_check`.

**Web build cost** (previous round, `tools/bench-web.mjs` seed 4, 2400 frames): HEAD 6.60 and 6.08 ms a frame (CPU x4: 34.6 and 32.9), the beam look 6.63 and 6.64 (CPU x4: 33.9 and 32.8). Nothing here since adds a draw call or a shader; the struggle's marks are a handful of rings. Not measured: an old laptop, a software floor, a beam-heavy scene.

## Legal's RL-141 to RL-143 (docs/legal/energy-and-pieces-screen.md): fx04 and fx05

- **fx04, the struggle's marks:** steady or 1.5 Hz or slower under Reduce flashing and Reduced motion, strokes only: done in the apply (`docs/vfx/multi-fight-plan.md`, the end of "the beam struggle"), with the rates in `data/vfx/energy.json` "rates".
- **fx05, the calm form** reads at or under the primary limit in both modes on the release set: every clip above is read in it (the demo's "normal" clips run with Reduce flashing on) and with it off, primary 2.5 at most; the release set is Tools' to run on the commit.
- **fx05, red:** the analyser's red reading on the clips with the explosions in (the bolts scene, eight ai windows both modes, the struggle scene, collapse: 28 analyses of this work, and 314 of everything I measured this week): **red flashes 0, qualifying changes 0, 0 even with the threshold lower, and the largest window at 0.11 of the area threshold**. The fire's gamma-encoded red ratio is 0.56; on linear values a cel orange sits higher, which is why it is read by the analyser and not by the colour code.

## Crisp, not a block (2026-10-18; Orb on the build of pin 5c46feca: "wide, soft-edged, blurry blue block")

At tick 1739 of the seed-4 AI match a point-blank beam (about 110 units long) was drawn at its sim width times 4.0 (sheath), 2.2 (body) and 0.9 (core): wider than it was long, with soft edges and an additive halo round it. That reads as a block of haze, not as a beam. Three causes, three fixes:

1. **A beam is never wider than a share of its own length.** `VfxBeamLook.thickness(..., length)` caps each layer (sheath 0.30, body 0.26, core 0.14 of the length, `len_k` in data/vfx/energy.json). BeamView passes its own length `l` (one token in render/core/beam_view.gd, Rendering's file). A long beam is untouched.
2. **The halo is thin and faint, the edges are crisp.** Sheath 4.0 to 1.8 times the width at alpha 0.12 (was 0.36), body 2.2 to 1.4 at edge falloff 0.4 (was 1.4), core 0.9 to 0.6 at 0.3 (was 0.9). The body is about the old look's 1.3 times the width; the lane colour, the hue ripple and the flavours stay.
3. **The rounded ends never take more than 14% of the beam each** (a short beam keeps a solid middle).

Side by side against d3f1ca0e under Reduce flashing (Tools' path, seed 4): the block is gone at tick 1739, the first beam at 1100 to 1240 is a clean lane-coloured shaft. effects_check (two new checks: the cap on a short beam, a long beam keeps its width; the "real width" check loosens from 1.6 to 1.05 times the old look's) and depth_check pass. Not a Legal clearance: the beam is plainer than before, so fx03's conditions are met with more margin, but the flash readings are reported, not chased.

## Open for Art, Legal and Orb

- **Art:** confirmed and corrected (docs/art/beam-colours.md): the Protagonist +30 (-30 under tritan), the Rival +34 capped at 320, the dummy +12.
- **Legal:** fx03 asks for the set drawn; this is it, with the flash clips above. The two new things to read are the beam's width and its start and end events (1.6 times the threshold in one clip), and the flames at a point-blank hit.
- **Orb:** the Protagonist's beam "from the heel of the palm" is a swell of the beam's firing end (0.7), not a drawn gather at the hand: the gather needs Animation's palm pose at the beam's origin.

## Distinct patterns: each fighter's beam unmistakable (Orb, 2026-10-18)

Orb: "I just want beams and energy attacks to have distinct, visually appealing, robust shader effects." The flavours above differed by knobs (wavelength, filaments, swell); they read as two beams of different colour. This adds a **pattern** to the Protagonist's and the Anti-hero's, the same inversion their auras have (`docs/vfx/aura3d.md`), told apart by **shape and hue, never by a step in brightness**:

| | **Protagonist: the boil** (`pat` 1) | **Anti-hero: the facets** (`pat` 2) |
| :--- | :--- | :--- |
| Edge | rounded **scallops** along the whole beam (semicircular bulges with sharp troughs, 95 units apart, cutting in 18% of the radius): a billowing, bubbling outline | a straight **zigzag** (a crisp chevron every 64 units, cutting in 20%): a cut-crystal outline |
| Inside | **bubble rings** in the second tint on the lane colour, in the same cells that travel slowly toward the head | a **mosaic** of flat cells, each a fixed mix of the two close hues (a stained-glass of azure-violet to orchid), seams a hair darker |
| Everything else | unchanged: his colours, wavelength, heel swell, the hue ripple | unchanged |

How it stays inside Legal's fx03: the pattern is on the body and the core only (the sheath's glow has none); its brightness moves the alpha by **3% at most** (`pat_k`; the shimmer is 7% on the body, so together under a tenth, checked), and the calm form (every beam under Reduce flashing, the default) halves even that and keeps the silhouette; the hue patterns are between **two tints of the same luminance**, so they add no brightness step at all; everything travels slowly toward the head at a quarter of the flow (a point sees about one scallop a second or slower); the axis stays a straight line and nothing goes round it, so it is still a plain straight beam. His thin needle (`rival_short`) and every other fighter stay plain. Numbers: `data/vfx/energy.json` (`pat`, `pat_k`, `pat_a`, `pat_scale` per flavour; `pat_w` per layer); checks: `effects_check.gd` `_beam_pattern`.

**For Legal:** the scalloped and zigzag silhouettes are new shapes for a beam (a bubbling and a crystalline edge). Neither is a helix, a drill, a twin colour or a ball; both are the beam's own edge. They have not been screened.

**Measured** (Tools' path, 1024 by 768, one capture at a time, both modes; primary / area-15% / memory): on the build with the deeper cut (30% and 34%): collapse normal 2 / 2.5 / 1 and reduced 2 / 2 / 0.5, clash reduced 2 / 2.5 / 2, signature reduced 1.5 / 1.5 / 1, signaturecity 2 / 2 / 2 and 2 / 2.5 / 1.5, signature normal 2 / 3 / 2 (as without it), **and clash normal 2 / 3.5 / 2: FAIL, against 2 / 3 / 1.5 without the pattern** (same-commit baseline). The windows are the same events within 1 to 2 thousand pixels (ticks 1147 to 1173), but the baseline already sat on the line at 3, so the extra pixels of the edge cut tipped it. **Built at 18% and 20%** (the final numbers), clash normal reads 2 / 3 / 2 and signature normal 2 / 3 / 2, **equal to the baseline**; the other clips were measured at the deeper cut and a shallower cut only moves fewer pixels, but they were not re-run. clash at 3 and signature at 3 are over the 2.5 gate on this commit **with or without** the pattern: they are not this work's.
