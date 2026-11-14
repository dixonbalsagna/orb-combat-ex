# The calm tones: facades and mountainsides calmer in the flash register's reduced mode (for the look gate)

Rendering, 2026-11-14, on the EP's GO: build and measure (a) and (b), reduced mode only. Nothing lands without the EP's look gate. `calm_tones.diff` (sha1 315fb831, 86 lines, cut on main e56d372c + Camera + A-CODE-03 + `look-recut/`) touches:
- `render/core/look.gd`: `CALM_BANDS`, `CALM_FACE`;
- `render/core/planet_view.gd`: `set_calm` sends them;
- `render/shaders/terrain.gdshaderinc`;
- `render/shaders/building.gdshader`.

## Read this first: "reduced mode" is the default look

The calm tones follow `PaneWorld.flash_calm`, the flag the flash register's reduced mode already uses: reduced motion **or Reduce flashing**. **Reduce flashing defaults to on** (`ui/data/options.json`: `"default": true`), and the site and desktop exports lock it on (`tools/desktop-package.mjs lock`). So the clips' "reduced" mode is what a player sees unless they turn Reduce flashing off, and "normal" is the opt-in full-effects look. This park changes the look most players get. Whether that's still within the look Orb approved is the EP's and Orb's call.

## What it does, only under `flash_calm`

VFX's and Camera's attribution of the signature and collapse readings found two kinds of scenery sweeping past a moving camera.

- **(a) Large lit facades against the night sky** (`CALM_FACE` 0.3): a facade's colour goes 30% of the way toward the sky's colour behind it, through the same sky read the rows' haze uses.
- **(b) Mountainside bands during a zoom** (`CALM_BANDS`):
  - the rock meets the green in a slope instead of five hard steps;
  - the three depth steps go continuous;
  - the lit and shaded facets come halfway toward the middle tone;
  - the strata lines are fainter (85% instead of 62%).

In the normal mode every new uniform is 0, so nothing changes.

## The readings

`docs/rendering/runs/e56d372c/calm-tones-flash.txt`: Tools' pixel clips, standard address, one capture at a time. Primary reading, then the sensitivity runs:

| | before | after |
|---|---|---|
| signature, normal | 2.5 PASS | 2.5 PASS (unchanged) |
| signature, reduced | 3.5 (4, 3) | **3 (3.5, 3)** |
| collapse, normal | 4 | 4 (unchanged) |
| collapse, reduced | 4 (4, 4) | **3 (4, 3.5)** |

Both reduced clips improve, by 0.5 and 1, but neither passes: a sensitivity run still reads over 3. Camera's slower reduced-mode camera is the other half.

## The look (uncommitted, show fighters)

`docs/rendering/img/lookgate/calm-signature-reduced-*` (ticks 70 to 150, stills at 82, 114 and 138, the facade events) and `calm-collapse-reduced-*` (ticks 1,430 to 1,500, stills at 1,471, 1,491 and 1,495, the mountainside zoom). Left is before (e56d372c), right is after (315fb831).

- **Signature:** the strata lines are much fainter. The facades, the lit houses and the near buildings, read washed toward the sky, close to fogged. That's the most visible part, and it would be the default look.
- **Collapse:** the near terrain's bands step more softly; subtle.

## If the facade haze is too much

Two narrower versions, each measurable the same way:
- only at night (when the world's light is low);
- a smaller share (0.15), or only on faces that fill a large part of the pane.

The bands alone may carry most of collapse's gain. A run with `CALM_FACE` at 0 would show it.

## Proof

On ct (main e56d372c + Camera + A-CODE-03 + `look-recut/` + this), `docs/rendering/runs/e56d372c/calm-tones-gates.txt`: it imports clean, `golden.json` is byte-identical, the five ground checks pass, and the render gates pass 20 of 20.
