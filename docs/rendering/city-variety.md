# City variety up close (Rendering, 2026-10-16)

Orb, homework 4: from far off the skyline "looks great", but up close the towers are "a bunch of dark grid lines". The pitch was `homework4-pitch.md` (steps A to D). Art's palettes and facade types are `docs/art/city-facades.md`, with the data in `data/art/city-looks.json`. This page covers what is built: A, B and C, Art's lobby storey and set-back crown, and the crown tower's stubs. D (lit detail) is not built: "show me first" applies to lit windows.

**The crown tower's stubs are on. City variety is built, gated and switched off** (`RenderLook.CITY_VARIETY`), because the collapse clip in normal mode fails with it on. The reason is the analyser's pooling at a marginal event, not a busier picture (see "Measured"). The stills below show it switched on.

**Where it applies.** Downtown and mid-rise towers only: the looks with the contrast budget. Landmarks keep their own treatment, and houses, villages and industry are unchanged. Without Art's data file the towers draw exactly as before. The sim reads none of it. A tower's picks come from its own seed, so they are the same in every match and on every machine.

## What a tower wears

| Step | What | Where |
| --- | --- | --- |
| A | **Glass that takes the sky.** A tower's glass moves 40% toward the sky's colour in its direction, at the glass's own luminance, so no pane changes value. It goes blue at noon and warm under a sunset. A pane below the eye takes the sky half a screen over the horizon (the blue, not the pale band, and never the ground). | `building.gdshader` 7c; `RenderLook.GLASS_SKY` |
| B | **One of Art's six tints of its look**, picked by the district's weights: the wall's three tones, its glass, bright glass and trim. | `RenderShapes.city_look`, `city_uniforms` |
| C | **One of Art's facade types**, picked by the district's weights. Ribbon: wide panes in the upper 55% of a floor over a spandrel band. Punched: separate panes, 0.38 of a cell wide, over a darker band. Fins: tall glass between fins, one side of each fin lit. | `building.gdshader` 7c; `fac_a`, `fac_b`, `fac_c` |
| Base | **Art's lobby storey** on a tower of 5 floors or more: 1.6 floors of punched panes in a darker wall, a lintel in the trim tone, then plain wall up to the second floor's top. | `RenderLook.CITY_BASE_*`, `CITY_LINTEL` |
| Crown | **Art's set-back crown** on a shaft, slab or block of 9 floors or more. The top two floors are set back 6% each side: the core is the body and stands the full height, and the shaft around it stops under the crown, as a stepped tower's skirts do. The crown's panes are all bright glass, with a cornice line in the trim tone at the top of each floor. | `RenderShapes.parts`; `RenderLook.CITY_CORNICE` |
| Stubs | **The crown tower's four corner points become stubs** (Legal RL-127, Art's shape): square prisms with no taper, 0.12 of the tower's width and 0.9 of a floor tall (never taller than wide), in the tower's mid tone lifted by 0.05 of luminance. Seen from the front they read as a battlement. The gem between them stays, as the tower's crown. | `RenderShapes.CROWN_STUB_*` |

## How Art's palette meets the render's value structure

- **The render masses a tower in its look's shadow tone** (`building.gdshader` 7b: a street of whole and damaged towers stays one value under a fast camera). Art drew the facade on the mid tone.
- **So every facade colour of a tint is scaled by the shadow's luminance over the mid's, in linear light.** That covers the glass, the bright glass and the trim. The spandrels, fins and lobby wall are given as multiples of the wall, at the ratio Art set them against the mid tone. The result keeps Art's hues and ratios at the values the towers have today.
- **Downtown's dark glass lands where today's is.** It sits at 0.062 to 0.065 of relative luminance, against today's 0.063, and the walls are within 0.007 of today's.
- **Mid-rise glass lands 0.03 lighter** (0.090 to 0.093, against 0.063 on a 0.12 wall). That halves the step from pane to wall, a quieter grid by Art's design. Its bright glass is darker than today's: 0.15, against 0.21 once held to the wall.
- **Every tone is still held to its wall by the budget** (0.085 of relative luminance) in the shader.

## Where it differs from Art's page

1. **Facades are picked by the district's weights only.** Art's rule ("fins on shafts of 40 floors or more") never applies here: downtown towers have 10 to 20 floors, and the crown tower has 26. On seed 1 (the city's layout is the same in every match): downtown is 4 ribbon, 3 punched and 7 fins; mid-rise west is 1 ribbon and 6 punched; mid-rise east is 3 ribbon, 2 punched and 4 fins.
2. **A punched column is 1.5 times its look's** (`FACADE_PITCH`). At downtown's 46-unit column, a 0.38 pane is a slit.
3. **The lobby storey has two rows of panes, not one tall row.** One tall row made a lit pane 1.6 floors tall, which is new lit area. With two rows, a pane, lit or not, is the size of a shaft's, and the lit windows keep their share and their area.
4. **The base and crown need floors.** The base needs at least 5 floors, and the crown needs at least 9 and a straight shaft. A four-floor mid-rise would otherwise be all base and crown. Stepped, spire and crown towers keep their own tops.
5. **The crown tower's gem stays.** Art wrote "nothing taller than the stubs". Lowering the gem would cut the tower's top from Orb's skyline. The horns are gone either way.

## For Art

At the towers' dark mass tone, the warm tints (buff, clay, cream, sandstone) read as browns and olives (`img/city/street-midrise.png`). Lifting their chroma, or choosing cooler tints, is Art's call. Every number is in the data.

## Measured, and why it is switched off

**`RenderLook.CITY_VARIETY` is false.** Off, every tower draws exactly as it did without this code: no data is read, no tint or facade is picked, and the glass does not take the sky. All 16 render gates pass on the city build, both on and off.

**The city flash clips** on HEAD 8895f688 (Tools' `check-clip`, primary / area threshold 15% lower / two-second memory):

| Clip | HEAD | + crowd and crown stubs | + city variety on |
| --- | --- | --- | --- |
| collapse normal | 2 / 2.5 / 0.5 PASS | 2 / 2.5 / 0.5 PASS | **2.5 / 3.5 / 0.5 FAIL** |
| collapse reduced | 2 / 2.5 / 0.5 PASS | 2 / 2.5 / 0.5 PASS | 2.5 / 2.5 / 0.5 PASS |
| mashcity normal | 1 / 1 / 0 PASS | 1 / 1 / 0 PASS | 1 / 1 / 0 PASS |
| mashcity reduced | 1 / 1 / 0 PASS | 1 / 1 / 0 PASS | 1 / 1 / 0 PASS |
| signaturecity normal | 2 / 2 / 1 PASS | 2 / 2 / 1 PASS | 2 / 2 / 1 PASS |
| signaturecity reduced | 2 / 2 / 1 PASS | 2 / 2 / 1 PASS | 2 / 2.5 / 1 PASS |
| rushcity normal | 2.5 / 3.5 / 1 FAIL | 2.5 / 4 / 1 FAIL | 3 / 3 / 1 OVER GATE |
| rushcity reduced | 2.5 / 3.5 / 1 FAIL | 2.5 / 3.5 / 1 FAIL | 3 / 3 / 2 OVER GATE |

The crowd's spacing turns about 5% fewer pixels over rushcity's worst second (2.87 million over ticks 60 to 125, against HEAD's 3.03 million), and its area reading still rises from 3.5 to 4. That is the same pooling as below.

**Collapse in normal mode fails with city variety on, and the picture is not to blame.**
- **The failing count is one marginal event.** It is a run of VFX's debris streaking over the street in the right pane (ticks 124 to 130). Its fullest window is 22,479 pixels against a threshold of 21,824, 3% over, and it holds the same pixels on every build.
- **What the city changes is the balance of one frame.** The analyser pools only each frame's dominant direction. On tick 130 the whole frame turns 9,818 pixels darker and 8,638 brighter with the city on, and 8,925 darker and 9,106 brighter without it. So with the city on, tick 130 joins the dark run and the run pools past the threshold.
- **The city makes the picture calmer, not busier.** In the lead-up to the blast it turns about 40% fewer pixels each tick: at tick 66, 2,936 brighter and 3,975 darker, against 5,258 and 6,536. In rushcity's sprint it turns about 15% fewer.
- **A calmer frame lets a run last longer, and that is what moves the count.** The crowd's spacing did the same on rushcity (above), and on the commit before on signaturecity (1 to 2, still a pass).
- **Which commit.** The tick counts and the switches below were measured on e88efd24 (the lobby). The event, its ticks and its readings are the same on 8895f688.
- **Switching each piece off in one export** (collapse normal, first 200 ticks; the analyser is causal):
  - everything on: 2.5 / 3.5 FAIL
  - nothing on: 2 / 2.5 PASS
  - no sky glass, no lobby storey or no crown: 2.5 / 3.5 FAIL
  - no tints: 2.5 / 2.5 PASS
  - no facade types: 2.5 / 2.5 / 2.5 PASS

  No single piece is the cause. Any change to what the frame turns can tip this event either way.
- **Ways to turn it on** (the EP's call):
  1. VFX gives the first blast's debris run some margin under the window threshold.
  2. Tools decides whether a run that grows because the rest of the frame got quieter should count.
  3. Ship tints alone or facades alone. Each reads 2.5 on collapse normal: a pass, at the gate.

**rushcity** fails on HEAD too: the area reading counts 3.5 (4 with the crowd's spacing). Its counted changes are the lit panes on the tall towers, sweeping across the sprinting pane (`img/city/` has no picture of this; the per-tick maps are in Rendering's scratch). With the city on it reads 3 / 3 / 2: the area reading is better, the primary worse, over the gate either way.

**The bench** (the web build, software-rendered through Tools' wrapper, `dt_wide`: downtown from the street with its towers filling the view, 1,280 by 720, the median of 240 frames; one run each, with the machine at 23 to 60% load, so read about 13% either way as noise):
- **City variety on:** 726 ms against 605. About a fifth more a frame, from the facade tones and the sky's colour worked out per pixel on every tower; it would need a cheaper path before it ships on old laptops.
- **City variety off:** 635 ms against 682, nothing measurable. Off, the shader skips the sky's colour as well as the facades.

**Switched off is the same picture.** Collapse in both modes reads the same off as without the code. Two captures of one export differ the same way after tick 910 in reduced mode (a nondeterminism in the capture, for Tools), and the stills differ only in the street's crowd band, as two captures of one build do.

## Stills (uncommitted, `img/city/`; before on the left, after on the right)

| File | What |
| --- | --- |
| `street-downtown.png` | A downtown street at fight framing: a ribbon tower with its lobby storey and lintel |
| `street-midrise.png` | A mid-rise street: punched windows in Art's warm tints, a crown set back |
| `midrise-from-above.png` | The mid-rise district at dusk from above: tints, facades and crowns side by side |
| `skyline-high.png` | Orb's high view of the skyline: the same skyline, tinted, the facades banded |
| `crown-tower-stubs.png` | The crown tower's top: the pale points before, the stubs after |
| `crowd-spacing.png` | The crowd's spacing (World's proposal): before on the left |
