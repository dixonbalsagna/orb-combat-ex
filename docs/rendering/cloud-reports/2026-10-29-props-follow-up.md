# The props follow-up: Art's sizes and the foot (Rendering, 2026-10-29)

Brief: the EP's follow-up to broken props (on main as aa300177), from Art's rulings in `docs/art/props-review.md`. It is one park, all behind `biome.enabled`, which is off on main. Run locally in the shared tree, with no branch and no commit.

## SUMMARY

`RenderProps` now sizes the props as Art ruled:
- The small dense kinds are capped.
- The flat kinds take World's size as their width.
- `tall_grass` draws as `tuft`.
- On a slope, a prop's foot sinks to the lowest ground under it, by at most `FOOT_SINK`, a share of its height.

With the switch off, the picture is unchanged. The desert and forest stills are byte-identical to HEAD's, and the collapse clip reads as HEAD's in both modes.

## CHANGES

- `render/core/prop_view.gd`:
  - `KINDS`: `tall_grass` now maps to `tuft`.
  - `CAPS`: tuft and dunegrass 0.45, scrub 0.7. A World kind is scaled so that its largest size in `ground.json` draws at the cap.
  - `FLAT`: snowpatch, pool, lavaflow and driftwood.
  - `FOOT_SINK` is 0.25 (Art's call after the stills; the report first went with 0.06, Art's "a few percent").
  - New functions: `drawn_scale`, `cap_scale`, `foot_half`.
  - A prop's custom `a` is now 1 plus its foot's half-width in units.
- `render/shaders/cover.gdshader`: a new `prop_sink` uniform. For a prop (`a` above 1.5, not floating), the shader reads the ground at the two ends of its foot. The cover and the trees write `a` = 0, so they take the old path unchanged.
- `render/core/planet_view.gd`: one line, which sets `prop_sink` on the cover material.
- `render/tools/props_check.gd`: a new part, **sized**.
- `docs/rendering/tools/props-hook.mjs`: two new scratch page words, `?propbowl=1` (Art's crater scene) and `?propsink=<s>`.
- `docs/rendering/props.md` and the README's row.

## DECISIONS

- **Caps scale each kind instead of clamping it,** so the clumps keep their variety:
  - grass draws at 0.23 to 0.45 fighter heights;
  - tall grass at 0.24 to 0.45;
  - scrub at 0.35 to 0.7.
- **Driftwood is a flat kind.** This follows Art's "any flat kind": it is 17 units tall on the sheet. Sized by its height, a log drew 6 to 13 fighter heights long. These are the brown planks floating in the old forest still. Now it is 0.7 to 1.6 heights long. This is the one call beyond the brief's list; it's Art's to undo.
- **The foot.** The shader reads the ground at the two ends of the shape's outline at its ground line, then lowers the prop by up to `FOOT_SINK` × its height.
  - The value is 0.25, Art's ruling on the table below (raise it to 0.35 if the 70 boulders that still hang show in play). The first version of this park used 0.06, Art's "a few percent".
  - Measured on five rings (sim ground, plane row), many hangs are larger than that. These are boulders whose edge is more than 4 units in the air:

    | Sink cap | 0 | 0.06 | 0.25 | 0.5 | none |
    | :--- | :--- | :--- | :--- | :--- | :--- |
    | Boulders left hanging (of 269) | 220 | 173 | 70 | 36 | 0 |

  - Tufts and scrub follow the same pattern.
  - In the stills the near ground hides most feet. Uncapped, boulders on a slope are half buried (`props2-mountains-foot-crops.png`).
  - The cap is one constant, so Art can raise it.
- **The volcanic "scrub":** World lays no scrub on volcanic ground. The green shapes were the cover's shrub, already removed by Art in c6cff5b4.

## Proof

**props_check passes.** New part, **sized**:
- On planet 7, 23 flat props match World's widths. 30 capped props sit under their caps (tallest: tuft 0.448, scrub 0.681). The other 73 props match World's heights.
- On planet 47: 73 flat props and 83 others, all correct.
- Negative control: with `drawn_scale` sizing by height alone, sized FAILS on both planets. For example, a log drew 823 units wide and a snow drift 652 units wide, against World's 71.

**Gates (each gate's last line, exit 0):**
- props_check;
- flighthooks probe;
- sweep check;
- the golden, byte-identical to HEAD's;
- determinism, plain and with `--intro`;
- seam sweep and split sweep;
- the open, depth, shape, patch, pane, stage, lane, ground, after, sky, flash register, hud words, flight, city, cue and flash checks.

**Collapse clip** (this build's export, switch off as on main): normal PASS 2 / 2.5 / 1, reduced PASS 2 / 2.5 / 1. HEAD (aa300177, `--head`) reads the same in both modes.

**Switch off:** the desert and forest stills (planet 7, tick 121) are byte-identical to HEAD's.

## Stills for Art (switch on, planet 7 unless noted, tick 121; uncommitted, in `docs/rendering/img/lookgate/props2-*`)

Each scene has a `-head` and an `-after` still:
- `savanna`: tall grass at its cap, beside the acacia;
- `tundra`: snow drifts lying flat;
- `forest`: the floating log planks and the standing snow slab are gone;
- `highland` (planet 21): scrub at 0.7;
- `mountains` (planet 21): boulders on a slope;
- `bowl`: a power-up bowl beside a desert boulder.

There are also two sink variants each for `mountains` and `bowl`: `-sink25` and `-sinkall`. The two `-foot-crops` images show HEAD, 0.06, 0.25 and no cap side by side. Reeds are still unseen: no pb ring has a wetland run of 30 columns.

## NEEDS FROM EP

1. Art's look at the stills, and the sink cap. Answered: the look is approved, driftwood stays flat, and the cap is 0.25 (the EP set the constant).
2. Art: whether driftwood stays a flat kind. Answered: yes.

## RISKS

- The foot costs a prop two more ground reads per vertex. There are about 400 props, with small meshes, and the cover and trees skip the branch.
- The foot follows the ground at the prop's own depth, not the plane row. The measured table is an estimate.

## NEXT

Frozen. Then the shell, as its own park (stacked on this one, as a patch).
