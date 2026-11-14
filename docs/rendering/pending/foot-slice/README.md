# A second pane's footings: the "Out of bounds" in _tile_foot_slice (for GW1a)

Parked by Rendering on 2026-11-14 at the EP's word: the foot-slice fix split out of `marks-baked/`, so GW1a gates the real ground with no pin. **It stacks on `look-recut/`.** `foot_slice.diff` (sha1 cf817a88, 8 lines, `render/core/planet_view.gd` only, cut on main 4f06e7a3) applies on main as it is too. Camera's, A-CODE-03's and the look's patches don't touch this file.

## The fault

With the globe ground on, a second pane (Camera's split view) runs `_tile_foot_slice` as well. A second pane's planet shares its source's `_foot` and `_falls` but not its `_bld_seen` list, so it reads past the end: "Out of bounds get index" at `planet_view.gd:1541`.
- Camera's digest run logged it about 280 times.
- VFX's `hash_check` fails from tick 60 on the GW1a look stack, in its split-screen run (`docs/vfx/runs/067baa03/planet-sizes-meteor-gates.txt`).
- VFX's strip pin (`docs/vfx/pending/hash-check-strip/`) is the fall-back.

## The change

`_tile_foot_slice` returns on a second pane (`source != null`). The first pane stands the buildings for both, as it stands their other footings. One guard; nothing drawn changes.

The same lines are in `marks-baked/`, which stacks after this. When this lands first, that park's `planet_view.gd` hunk is already on main, so `marks-baked/` is re-cut without it.

## What VFX's hash_check needs too: a grant

With the foot slice fixed, `hash_check` still fails from tick 60, in every scene run. The scene and the pure run play different matches:
- with the globe ground on by default, the host sends `RenderTileGround.setup_of({})`, which adds planet 7, touch 3, gen 3;
- the check's pure run starts `SimCore.newMatch(S, seed)` with no setup.

My determinism tool had the same fault, fixed in `globe-default/` (`_as_host`). **`grant-vfx-hash-check.patch`** (sha1 ed957411, one line of VFX's `render/vfx/tools/hash_check.gd`) makes the pure run start from the setup the host sends. It's VFX's file. With it, GW1a gates the real ground with no strip pin.

## Proof

`docs/rendering/runs/f61eb8c2/foot-slice.txt`, on main f61eb8c2 + Camera + A-CODE-03 + `look-recut/`:
- **VFX's `hash_check`** (its own seeds 12345, 4, 7, 1, 3600 ticks):
  - without this park (the control): 104 "Out of bounds" lines, and it fails;
  - with it: 0 "Out of bounds" lines, but it still fails from tick 60 in every scene run, on the setup (above).
- **With it:** `golden.json` is byte-identical, the five ground checks pass, the render gates pass 20 of 20, and no gate's log has an "Out of bounds" line.
- **With it and the grant** (`foot-slice-hash.txt`): `hash_check` passes on the real globe ground, no pin. All four seeds match the pure run at every checkpoint to tick 3,600, the effects ran (trail 1.00, 3,390 marks), and there's no "Out of bounds" line.
