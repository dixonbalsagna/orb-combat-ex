# A leaner SplitRig.step (director-20, on main in d235af1c)

Camera, 2026-10-27, from the EP's phone frame-time brief. Rendering's gen 2 coast profile put `split_rig.step` at 1.1 ms a tick at x4. The goal is to cut it with the camera's output unchanged.

It touches render/camera/split_rig.gd and split_frame.gd only. Everything sits behind one switch, `SplitRig.lean_step` (default true). False is the old path, kept for timing on one build.

## What it skips

1. **The landscape shot's landmark scan.** `_scape_tick` read every building in the world every tick to find landmarks near the pair. It now reads a list of the match's landmarks (`_landmarks`). The list is built again when `S.buildings` is another array or size, or has other buildings at its ends, as after a new match or a relocation. World sets buildings and their landmark flag only when it generates them. A building that falls stays in the list with `alive` false, as before. The order is the same as S.buildings, so the same landmark wins.
2. **Visibility alone.** The incoming read (`_incoming_for`) and the many-body marks asked `SplitFrame.hud_anchor` for a whole record and used only its `visible`. That meant two extra projections for the height and a dictionary, twice per fighter. `SplitFrame.sees()` is the same test without the rest. `or` still short-circuits the same way.
3. **A pane's own camera in one view.** `_outputs` built both panes' cameras every tick (a Newton refine under a pitch). In one view (w = 1), `_blend_cam` returns the shared camera whole, so a pane's camera is now built only while a split shows (w < 1) or for a shot's subject (`solo_w > 0`). Nothing else reads `_owns`.

## Proof (scratch: 3d0c0860, then the patch)

- **clip_digest, default set:** all nine clips in both modes, 48,600 lines, byte-identical to HEAD.
- **split_sweep:** the whole log byte-identical to HEAD, including every scenario's digest. The sim hash with and without the rig is e39beb6963ecbff0 on both.
- **Native profile at HEAD** (clip_digest ai 2, 4, 39 at 3,600 ticks): step costs 255 µs a tick. The skipped work, measured with the timers' own overhead, was:
  - the landmark scan, 17 µs a tick;
  - hud_anchor's unused parts, about 8;
  - the pane cameras in one view, about 6.

  That is roughly 12% of step in a fight. On a gen 2 planet, with more buildings, the scan is a larger share.
- **Web timings:** none valid. The four runs (Rendering's prof-hook, pb coast scene, lean on and off at x1 and x4) were on a saturated machine and marked invalid, and the bench did not record whether the switch took.

## What it does not touch

The rest of step's cost is spread across stateful filters: the pane loop, the zoom targets, the clear zones and the merged target. Each tick's state feeds the next, so skipping a pane while merged would change the frames after a split opens. Cutting that further means changing the order of float work, which cannot stay byte-identical. That would be a separate brief with a tolerance.
