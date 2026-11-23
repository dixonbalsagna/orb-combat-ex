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

## The EP's decision (2026-11-14): HOLD as built; the two narrow arms

Fogging near buildings in the default look is a taste reversal, not a fix. As built (0.3 facades) is on hold. Two narrower arms, both measured the same way (`docs/rendering/runs/e56d372c/calm-arms-flash.txt`, reduced mode, the default look):

| | signature, reduced | collapse, reduced |
|---|---|---|
| before | 3.5 (4, 3) FAIL | 4 (4, 4) FAIL |
| as built (0.3 facades) | 3 (3.5, 3) FAIL | 3 (4, 3.5) FAIL |
| **A: the bands alone** (`calm_tones_a.diff` 860bbeda) | **3 (3, 3)**, over our 2.5 gate, no sensitivity run over 3 | 4 (4, 4) FAIL, unchanged |
| **B: the bands + facades at 0.15 against a dark sky** (`calm_tones_b.diff` 0a5bcdd4) | 3 (3, 3), the same | 4 (4, 4) FAIL, unchanged |

- **The bands carry signature's gain:** the strata and the rock steps on the mountainside behind the facade events.
- **Collapse doesn't move with the bands alone,** nor with the facades at 0.15 against a dark sky. Its earlier drop to 3 came only with the 0.3 facade haze, so it came from facades in the collapse frames, or from the captures' run-to-run spread (tiles-on captures aren't byte-repeatable). The bands VFX and Camera named for collapse aren't, on their own, what reads there.
- **The look, arm A** (`docs/rendering/img/lookgate/calm-ca-*`, uncommitted): the facades keep their colours. The mountainside's strata lines are fainter, and the near rocky ground steps more softly, greyer. Arm B adds a slight darkening toward the night sky on lit faces (`calm-cb-*`).
- Arm A is the smallest change to the default look that buys signature its 0.5. It goes to Orb as a look question if the EP takes it, never framed around flashing.

## If the facade haze is too much (the first build's notes)

Two narrower versions, each measurable the same way:
- only at night (when the world's light is low);
- a smaller share (0.15), or only on faces that fill a large part of the pane.

The bands alone may carry most of collapse's gain. A run with `CALM_FACE` at 0 would show it.

## Proof

On ct (main e56d372c + Camera + A-CODE-03 + `look-recut/` + this), `docs/rendering/runs/e56d372c/calm-tones-gates.txt`: it imports clean, `golden.json` is byte-identical, the five ground checks pass, and the render gates pass 20 of 20.

## rushcity on the new world (2026-11-21, the EP and Camera): arm A for GW1b

Main after GW1a fails Tools' `rushcity` scene (seed 12345) in both modes. The cause is the sprint's camera, already at Camera's scroll budget, sweeping and dollying over planet 7's new ground: bright sand and lit facets against large dark shaded facets. Orb's 9 November build ran that scene in a flat city block. Records: `docs/rendering/runs/ed1591cb/b20-gw1b-energy.txt`.

| combined rule, primary (lower) | rushcity 12345 normal | rushcity 12345 reduced (the default look) | ai 12345, both modes |
|---|---|---|---|
| main ed1591cb | FAIL 3.5 (4.5) | FAIL 4.5 (4.5) | over the gate, 3 (3) |
| + GW1b steps 1 to 6 (flight 3,500) | over the gate, 3 (3) | over the gate, 3 (3) | PASS 1 |
| **+ arm A** (`calm_tones_a.diff`, unchanged, applies on that tree) | 3, unchanged: arm A is reduced mode only | **PASS 2** (3) | PASS 1 (reduced) |

- Other scenes on main: `rushcity` seed 7 passes (2); `ai` seed 12345 reads 3, over our gate. Both are fixed by GW1b's speed alone.
- **The look** (`docs/rendering/img/lookgate/b20/b20-rushcity-calmA-reduced-*`, not committed): the large dark facets on the sand go halfway toward the middle tone. The houses, the sand's colour and the fighters are unchanged. It's a modest change to the default look, so it goes to Orb as a look question, never framed around flashing.
- **Normal mode** (Reduce flashing off) stays at 3 with arm A. It needs Camera's sprint-arming piece (the onset peaks), or arm A in both modes, which would be Orb's look call.
- **Gates on the GW1b tree** (`docs/rendering/runs/ed1591cb/calm-a-gw1b-gates.txt`):
  - no import errors, and `golden.json` byte-identical to the GW1b tree's own;
  - the five ground checks pass;
  - the render gates pass 18 of 20. The two fails are the GW1b tree's own: `after_check`'s tally row (VFX's fix: read `host.fxv.parts`) and Camera's `split_sweep` (real match 10, 242 of 12,077 merged ticks; the same on the tree without arm A).
