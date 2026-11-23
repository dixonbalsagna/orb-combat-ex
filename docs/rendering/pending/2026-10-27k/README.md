# 2026-10-27k: the signature clip's desert, two attempts that do NOT pass (Rendering)

**Not a fix to land.** This folder keeps the work and the findings through the cloud move. Neither attempt meets the EP's acceptance; the next step is Art's call (below).

## The clip, measured (tools/flash/check-clip.mjs; primary / area-15% / 2 s memory)

| Build | signature-normal | signature-reduced | collapse, both modes |
| :--- | :--- | :--- | :--- |
| main (e1521ef5; the same on 09fff642) | 3.5 / 5 / 3 FAIL | 2.5 / 3 / 2 PASS | 2 / 2.5 / 1 PASS |
| A: lit and shade faces held (`h109_facethold.py`) | 3.5 / 3.5 / 3.5 FAIL | 2.5 / 3.5 / 2.5 FAIL | PASS, the same |
| B: the shade face held, the lit as Art drew it (`h109b_shadehold.py`) | 3 / 5 / 3 FAIL | 2.5 / 3.5 / 2 FAIL | PASS, the same |

- The 19 render gates and `split_sweep` pass on both A (main 09fff642) and B (main f60e7833).
- A side-by-side of the desert at the split view's opening (frames from the clip itself, tick 91; main on the left): `docs/rendering/img/lookgate/lookgate-sigdesert-faces-t91.png` (A), `-shade-t91.png` and `-shade-t95.png` (B).

## What flips, by tone

Measured with `flipmap.py`, which maps the pixels changing by 0.1 of relative luminance or more, darker side under 0.8, the analyser's counting rule.

**The split view's opening** (ticks 89 to 103; Tools' bisect):

| | main | B (shade held) |
| :--- | :--- | :--- |
| The commonest flip | the desert's mid face against its shade (0.62 against 0.33 at the front depth step) | lit against mid (0.81 against 0.62) |
| The count at tick 89 | +36k | +36k, the same |

The lit faces flip as much as the shade did.

**Holding the lit face (A)** pulls the desert's lit sand from 0.81 under 0.8 (to 0.70).
- WCAG counts a change only where its darker side is under 0.8, so the bright effects over lit sand now count: the swoosh arcs, the beam's glow.
- Its worst second moved to ticks 609 to 677, and reduced got worse.

**The beam's scar on sand** (ticks 609 to 634, the same on main): Art's glassy green-black (0.04) panned across the sand flips 90k to 110k pixels a tick. On main that second is already close to the limit.

## Why a render-side hold cannot do it, and what can

The desert's tones sit on both sides of the analyser's line:
- the lit face at 0.81, against the mid at 0.62 and the shade at 0.33;
- held within the 0.085 budget, the lit face falls under 0.8, where it starts to count.

A pass needs one of these:
- **Art re-cuts the desert ground ladder**, and the open biomes like it (savanna, beach, plains), as tone on tone. Either all three faces stay within the budget of each other, or the lit and mid both stay above 0.8. That is Art's palette, so it is Art's call.
- **The scar's fill on sand** is lifted toward the sand, or narrowed. That is also Art's (the damage language).
- **Camera's opening of the split** is slower, or framed off the dunes. That is Camera's.

The two patches here are the tool for checking any of these: `RenderBiomeLook.held` holds a face to the budget along its own colour.

## After Art's tone-on-tone ladders (2026-10-27 evening)

These runs used main 9c9251cc to 9631fc75 plus Art's uncommitted `data/art/biomes.json` (sha1 7967fd63; `docs/art/ground-ladders.md`). C adds Rendering's `DEPTH_STEP` 1.1 / 0.94 to 1.07 / 0.97 (`h112_depthstep.py`).

| Build | signature-normal | signature-reduced | collapse, both modes |
| :--- | :--- | :--- | :--- |
| Art's data | 2.5 / 3.5 / 3 FAIL | 2.5 / 2.5 / 2.5 PASS | PASS, the same |
| C: Art's data + depth steps | 2.5 / 3.5 / 2 FAIL | 2.5 / 2.5 / 2.5 PASS | PASS, the same |

- **Art's ladders clear the split's opening:** no counted flips at ticks 89 to 91.
- **The sea-glass scar reads by hue:** no near-black band at 609 to 634.
- **`sky_check`:** 35 ok, including the sunset key to the bit.
- **The depth steps** were the worst second's commonest flip on Art's data (0.52 against 0.62 at 1169). C takes the memory reading from 3 to 2.
- **What still counts:** normal's area-15% reading (3.5) stays at ticks 1140 to 1260. There the beam's impact crater flips against the sand as the right pane's camera jumps from tick to tick: its subsoil inside (about 0.25) and its rock walls (about 0.44, Art's desert rock unchanged) against the sand (0.58). That is Art's: the crater inside and the desert rock.
- **Stills:**
  - `lookgate-artladder-*` (main against Art's: the opening, the scar, savanna, beach, desert);
  - `lookgate-depthstep-t095.png` and `-t613.png` (Art's against C: the depth read near and far).
  - The plains could not be framed on gen 2: no open plains run, because the towns stand on them.

## Art's second pass (rock at sand value, the crater inside as three faces), 2026-10-27 night

These runs used main 9d367592 plus Art's `data/art/biomes.json` (sha1 e7a00ea0). `h113_subsoil.py` is three changes:
- (a) Art's grant into `biome_look.gd`, accepted as written;
- (b) the strata lines darken the desert's rock to 0.9 (`STRATA_DARK`; 0.62 elsewhere);
- (c) the crater's inside steps by depth.

| Build | signature-normal | signature-reduced | collapse, both modes |
| :--- | :--- | :--- | :--- |
| main 9d367592 | 3.5 / 5 / 3 FAIL | 2.5 / 3 / 2 PASS | |
| Art's second pass + h113 (nx) | 3.5 / 3.5 / 2.5 FAIL | 2.5 / 3.5 / 2.5 FAIL | |
| nx + DEPTH_STEP 1.07 / 0.97 (ny) | **2.5 / 2.5 / 2 PASS** | **3 / 3 / 3 OVER GATE** | 2 / 2.5 / 1.5 PASS |

- **Reduced's worst second on ny** is ticks 611 to 671, at a camera cut between ticks 615 and 618. Before the cut, the near ground is Art's new crater inside (0.64 to 0.69, brighter than the sand). After it, a dune's shade face on the back depth step (`#ebac51` × 0.97, 0.45), a 65k-pixel darkening.
- **On main** the same cut brightened 37k pixels: its crater inside was dark (0.22).
- **What this shows:** a cut swaps any of the desert's surfaces for any other. On screen they now span about 0.45 (shade, back step) to 0.69 (crater lit, front step). Each surface keeps tone on tone within its own step, but the whole spread is about 0.24.
- **To pass both modes,** the desert's whole on-screen range must narrow, roughly to within 0.1 to 0.15. Either:
  - flatter depth steps (1.04 / 0.98, a step of about 0.04), which is Rendering's;
  - or the crater's faces at the ground's mid rather than above its lit face, which is Art's;
  - or both.
- **Look note:** Art's rock cover at sand value reads salmon pink next to the sand (the boulders): `lookgate-artpass2-mesa-t095.png`.
- **Stills** (main against ny): `lookgate-artpass2-t00089` to `t01230` (the opening, the scar, the crater at 1150 to 1230).

## The last combined check (the EP's order; stop either way)

Main cb75ecac plus Art's third data (`data/art/biomes.json` sha1 956c3b06: the crater faces at the ground's own value, the rock warmer), with h113 and h112b (`DEPTH_STEP` 1.04 / 0.98).

| Build | signature-normal | signature-reduced | collapse-normal | collapse-reduced |
| :--- | :--- | :--- | :--- | :--- |
| main cb75ecac | 3.5 / 5 / 3 FAIL | 2.5 / 3 / 2 PASS | | |
| all of it | 3 / 3 / 2.5 OVER GATE | 3.5 / 3.5 / 2.5 FAIL | 2.5 / 2.5 / 1 PASS | 2 / 2.5 / 2.5 PASS |

- **Both modes' worst second** is ticks 611 to 675, the camera's cut at 615 to 618 and the pans after it.
- **The commonest flip at 618** is 0.52 to 0.57 going down to a single 0.42 tone, over 59k to 63k pixels.
- **Stopped there,** as ordered. The rows go to Orb with the options.
- **Stills** (main against all of it): `lookgate-artpass3-t00089` to `t01230`.

## Files

- `h109_facethold.py`: A, the lit and shade faces held. `--nofacethold` turns it off. The ices are skipped: their white over slate would turn bright blue.
- `h109b_shadehold.py`: B, the shade face only.
- `h109_doc.py`: the biomes.md lines for A.
- `flipmap.py`: which pixels flip between two ticks, and between which tones (`python flipmap.py <clip frames dir> <out.png> tick...`).
- `h113_subsoil.py`: Art's grant (a), the desert strata at 0.9 (b), and the crater inside by depth (c), for Art's second pass.
- `h112b_depthstep.py`: the depth steps at 1.04 / 0.98 (the last combined check).
- `h112_depthstep.py`: C, the band's depth steps at 1.07 / 0.97 (look.gd, the terrain shader's default, biomes.md). It is ready to park once the signature clip passes with it.
- Each script applies to main as of 2026-10-27 (09fff642 to 9c9251cc). The base was checked with each run; it is not a park.
