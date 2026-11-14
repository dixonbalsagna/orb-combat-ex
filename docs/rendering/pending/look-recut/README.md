# The look defaults, re-cut for the landing order (A-RENDER-01, A-RENDER-04)

Rendering, 2026-11-14. A correction to report 1. The diffs in `globe-default/` (54b06089) and `crater-look-default/` (1e3108a1) are cut on main as it was. In A1's landing order they don't apply:
- the order is Camera's A-CAMERA-01, then Tools' A-CODE-03 (the played build's patches, which the directive puts on main before the look), then the look;
- Camera's grant edits the same camera block in `render/core/main.gd` (lines 240 to 252) as globe-default;
- A-CODE-03 edits the same two launch-word lists as both.

My earlier stack run (`docs/rendering/runs/3039bdb1/camera-01-stack.txt`) applied my edit script on top of Camera, not the parked diff, so it didn't show this.

## The re-cuts

Cut by the same edit scripts on main + `a-camera-01.patch` + `planet-entry-and-probe.patch` + `report-hook.patch`:
- **`globe_default.after-camera-code03.diff`** (sha1 50f868f6, 180 lines);
- **`crater_look_default.after-camera-code03.diff`** (sha1 ea942e4d, 23 lines).

Their added and removed lines are the parked diffs' lines. The two launch-word lists are the exception: they carry A-CODE-03's `planet`, `touch` and `preview` too, while `notiles` and `nocraterlook` go in at the same places. **Land these, not the originals,** when Camera and A-CODE-03 land first.

## Proof

**The stack applies in order** (`render/core/main.gd`, checked with `git apply`):
1. `a-camera-01.patch`;
2. A-CODE-03's two patches;
3. these two re-cuts;
4. UI's `pause-clock.patch` and `rail-default.patch`;
5. World's `grant-rendering-main.patch`. UI reports that World's patch doesn't apply after its own quit-and-fighters grant. I'm merging World's and UI's for GW1b as the EP asked.

**The gates** on main e56d372c + Camera + A-CODE-03 + both re-cuts (`docs/rendering/runs/e56d372c/look-recut.txt`): it imports clean, `golden.json` is byte-identical, the tile, lake water, cover water, sweep and ground checks pass, Tools' `match_recorder_check` passes (16 checks, 0 failed), and the render gates pass 20 of 20.
