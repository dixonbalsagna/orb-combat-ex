# Broken props leave the view (Rendering, 2026-10-29)

Brief: `docs/ep/cloud-briefs/rendering-broken-props.md`, and the EP's go (2026-10-29) to build World's W5 NEEDS 2 first: the view never drew the sim's props. Run locally in the shared tree (no branch, no commit). Base: main 40d5ee92 with the pane sweep (reported, being gated).

## SUMMARY

`render/core/prop_view.gd` draws the match's props from `WorldGround.matchProps` as Art's cover silhouettes, behind Combat's biome block (`biome.enabled`, off on main).
- **Laid:** the whole ring once a world (126 to 434 props on gen 2 rings).
- **Updated:** only when `SimDir.brokenProps` changes, and then only the changed columns.
- **A break** is a hard cut: the prop is gone on the frame its column is broken.
- **Switch off:** nothing is laid and no copy carries a prop, so the picture is unchanged at every frame. The collapse clip is HEAD's in both modes.
- **Not committed:** the seven hook lines in `planet_view.gd` are parked as 2026-10-29a, because that file is frozen with the pane sweep.

## CHANGES

- New `render/core/prop_view.gd` (`RenderProps`): the props pass. It also holds the provisional kind map (Art's), the depth `Z`, and a tools-only `ctl_frozen`.
- `render/shaders/cover.gdshader`: a shape whose custom `a` is 1 (a prop) stands in a crater, as it does in the sim. The cover and the trees write `a` 0, so they are unchanged.
- New `render/tools/props_check.gd`: the proof.
- New `docs/rendering/tools/props-hook.mjs`: a scratch export takes `?biomeon=1` and `?propsmash=1` (a staged PROP SMASH), for Art's stills.
- `docs/rendering/props.md` (new), and the README's checks table.
- The park `docs/rendering/pending/2026-10-29a/` (`planet-view-props.diff`, sha1 fd1cf5ba): `RenderProps` built with the trees, shared with a second pane, its meshes in every prop copy with the cover's material, updated after the trees.

## DECISIONS

- **The whole ring once.** The query takes about 25 ms natively on a 4,800-column ring, at the build. A frame only reads the director's broken columns (two fighters, four each).
- **A change is applied by column.** A column that came in or went out of the broken list is asked again alone (about 0.02 ms). So a fighter's fifth break, which lets his oldest stand again, is drawn too.
- **Depth:** `RenderProps.Z`, just behind the fighter plane, where a launch meets the prop.
- **Shapes:** Art's silhouettes by the kind map. A lone tree is the biome's tree. Berg cells are not drawn: the terrain is the berg. Shells are not drawn: Art has no shape.
- **Frustum:** one MultiMesh per kind in each of the cover's 4 spans, so the frustum leaves out the spans off the screen.
- **A prop stands in a crater,** as it does in the sim. World may want a blast to break props; that is World's sim.

## The proof

**`props_check.gd`** (scratch: HEAD 40d5ee92 + the pane sweep + all of this):
- **off:** with the block off, gen 2 planet 7 lays no props and no copy carries any, through 600 ticks of AI play. With it on, the hand-made world lays none.
- **laid:** with it on, planet 7 lays all 126 of the ring's props, and planet 47 lays 156 of 184 (28 shells). All stand, in all 5 prop copies.
- **broken:** PROP SMASH is staged at 6 gen 2 spots (planets 7, 3 and 11, two each), as World's `flighthooks_probe` stages it, and played through the game's own frames.
  - All 6 launches broke a prop.
  - On the frame each broke, the prop was gone from the view, and its column drew exactly what `matchProps` says stands there.
  - No other prop changed.
  - Frames compared: every frame of every launch, from the launch to the flight's end.
- **control:** with the update switched off, 0 of 6 broken props were gone, so the check sees it.

**Headless pixels** can't be compared: headless Godot draws nothing and keeps no MultiMesh data. The proof is the drawn state above. The web pictures are the collapse clip and Art's stills (below).

## Gates (each gate's last line, exit 0)

- **props check:** "props check passed".
- **World's flighthooks probe:** "flighthooks probe passed".
- **sweep check:** "sweep check passed".
- **golden:** written in the scratch tree, byte-identical to HEAD's.
- **determinism:** "determinism passed", plain and with `--intro`.
- **seam_sweep:** "seam sweep passed".
- **split_sweep:** "split sweep passed".
- **The other 15 render gates:** each prints "... passed". City's last line lists its switches.
- **The collapse clip** (this build's export, switch off as on main): normal PASS 2 / 2.5 / 1, reduced PASS 2 / 2.5 / 1. HEAD reads the same.

## Look evidence for Art (switch on: `props-hook.mjs`)

Stills taken (uncommitted, in `docs/rendering/img/lookgate/`; the pb scene on gen 2 planet 7, tick 121):
- **Props beside the cover:**
  - `props-desert-on-t121.png` against `props-desert-off-t121.png`: the sim's boulders and cacti, the largest about two fighter heights (World's desert sizes);
  - `props-forest-on-t121.png`;
  - `props-coast-on-t121.png`.
- **A PROP SMASH break** (`?propsmash=1`; the split opens on the launch):
  - `props-smash-t00089.png`: before the launch;
  - `t00097`: in flight, the second pane close on the tundra boulder he is flying at;
  - `t00101`: the boulder gone on its frame, the debris and dust flying;
  - `t00129`: after.

Still to capture, for the EP's look gate:
- a prop in a crater (a slam beside a boulder);
- savanna, tundra and volcanic stretches (another ring).

Art's calls: the kind map, `Z`, and whether the densest small kinds (grass, tall grass, ferns, reeds) belong on the fighter plane at all.

## NEEDS FROM EP

1. **Apply 2026-10-29a** after the pane sweep's commit. Without it the new files draw nothing.
2. **Add `props_check.gd`** to the render gates and CI, once applied. It takes about 40 s.
3. **Art:** the look with the switch on, before `biome.enabled` turns on (the scenes above).
4. **World (FYI):** a blast does not break a prop in the sim, so a prop stands in a crater, and it is drawn so.

## RISKS

- The densest kinds put many small shapes on the fighter plane. That is Art's to judge before the switch turns on.
- The ring's query at the build costs about 25 ms natively (about 100 ms at x4) in one build step.
- A prop given back by a fighter's ring of four is drawn again on that frame. This is covered by the code, not by a staged test.

## NEXT

Frozen. Waiting for the EP's commits: the pane sweep, then 2026-10-29a.
