# 2026-10-30i: civilians' feet stay on the ground (Rendering). UNFINISHED: do not land yet

`bend.diff`, sha1 bab73abb, cut on 12966cf4. Paused by Orb's quiet time on 2026-10-30.

**Bug.** Orb, playing the preview on planet 7: citizens seem to float off the ground when you move away from them.

**Cause, from the code.** `render/shaders/crowd.gdshader` is the one shader for standing world geometry that doesn't take the planet's bend. The ground, buildings and cover sag by `bend * x^2`, weighted by depth behind the focus plane (`bend.gdshaderinc`). The crowd stayed flat, so a figure lifted off the ground the farther it stood from the screen's centre and the wider the zoom. The sim isn't involved.

**Worlds.** The shader and the bend are the same on every world. A count of figures by depth on gen 2 planets 7 and 21, gen 1 planet 7 and the hand-made world found almost all more than 60 units behind the plane, where the bend applies. None stand in front of the plane, so the foreground rule isn't the cause, and none stand past the band. All worlds should have it.

**Fix.** The shader includes `bend.gdshaderinc` and sets `POSITION` from `bent_world`, as `cover.gdshader` does. `PlanetView.set_crowd_bend` sends each pane's bend to its chunks. `pane_check` checks each pane's crowd takes its bend. `docs/rendering/tools/crowd-hook.mjs` is new: scratch words `crowdfar`, `crowdz`, `crowdsep`, `crowdhand` for the pb scene.

**Passed** on 12966cf4 with `2026-10-30j` stacked: `pane_check` (62 checks), the other 19 of the 20 render gates, sweep, props, lake water and cover water checks, package self-test, golden byte-identical.

**Not done.**
- **The picture doesn't prove it yet.** `docs/rendering/img/lookgate/crowd-g2-near-sbs.png`, `crowd-g2-mid-sbs.png`, `crowd-g2-far-sbs.png`, `crowd-g1-far-sbs.png` and `crowd-hand-far-sbs.png` were taken at a close camera, where the bend is small. In the two I looked at (g2-far, hand-far), feet look on the ground on both builds; the near, mid and g1 stills haven't been looked at. So the float isn't yet reproduced on HEAD. The scene needs Orb's view: a wide zoom, as in the far still of the report (`...\58be913b-344b-4261-8aee-5312524b990e\images\29.webp`), with the crowd towards a pane's edge. Then redo the three-distance side-by-sides.
- **Collapse clip in both modes:** not run.
- HEAD has moved since the cut: check the diff still applies.

Stacks under `2026-10-30j`, which touches the same shader.
