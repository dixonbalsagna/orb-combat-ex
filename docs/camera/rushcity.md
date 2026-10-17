# rushcity reduced: the standing area failure (Camera, 2026-10-16)

Owner: Camera and Cinematography. The EP's brief: rushcity (seed 12345, the city start, P1 sprinting with the AI after him) reads 2.5 / 3.5 / 2.5 under Reduce flashing with the flash bundle and 3 / 3.5 / 2.5 without, in the record's required set under an interim waiver. Find the source and fix it.

## 1. The clip I had been reading was the wrong length

Tools' rushcity is 1,500 ticks (`tools/flash/sources.json`). My earlier captures of it ran 3,600 (my capture script's default for any clip it did not name). The first readings in this brief were therefore of ticks the record does not read. Re-captured at 1,500 on a clean export of main 68ac7839 (so the same commit for the baseline): **2.5 / 3.5 / 1 FAIL in both modes** (the two readings are equal, which I take to mean the capture hook's ordinary run also has Reduce flashing at its default; I have not checked the hook). The failing reading is the area -15% one.

## 2. The events

The analyser with the area threshold lowered 15% (`--area-share 0.2125`) lists 58 counted changes in the clip; the worst second starts at tick 64 and holds 3.5 flashes. The ticks 64 to 121 carry ten alternating changes: +64, +74, -93, -97, +100, +105, -115, +117, -118, +121 (the first at 1.8 of the threshold, +74 at 4.7). The rest of the clip's worst seconds are lower.

## 3. What the camera does there

`render/camera/tests/clip_probe.gd --scenario=rushcity` (new: P1 human sprinting along the front street, the AI after him; the same writes as `flash_capture.gd`) printed the cameras for ticks 40 to 190:

| Ticks | Mode | What happens |
| :--- | :--- | :--- |
| 40 to 72 | split | the pair 600 to 1,350 units apart and parting at 23 units a tick (1,400 u/s), both panes steady (0.0148) |
| **73 to 105** | **closing** | **the layout merges the pair at 1,358 units while the gap is still growing**; the shared view zooms out from 0.816 to 0.384 in 30 ticks (travel 0.027 to 0.043 per tick at 82 to 91) |
| 106 to 130 | merged | the gap grows from 2,413 to 3,660 and the zoom reaches its floor (0.307) |
| **133 to 148** | **opening** | **the split opens again** with the cameras panning 2,000 units in 15 ticks (travel 0.04, **0.09 at tick 136**, 0.066 to 0.059 after), the zoom coming back from 0.32 to 0.54 |

So the source is **the layout's merge rule, not the world or the effects**: a pair parting fast is merged (its present separation is under the merge line), the shared view zooms out for the separation it will have, crosses the split line again within a second and a half, and the panes reopen with a pan between them. Two whole-picture changes of 0.03 to 0.09 of the width a tick inside 1.2 s are what the analyser counts there, over a street of lit windows.

## 4. The fix: the merge looks ahead

`SplitRig.merge_lookahead` (`SplitView.set_merge_lookahead`): in the merge condition (`_update_trigger`) a pair whose separation is growing is judged on the separation it will have `MERGE_LOOKAHEAD` (1.0 s) on, at the smoothed separation rate: `r_merge_now = min(r_now, metric(ad + sep_rate x 1.0))`. A closing pair, or one at rest, is judged as before. **On by default** (the clip is in the required set; the switch is one line to put back).

**Measured** (scratch exports of main 68ac7839 plus the files, Tools' path, 1,024 x 768, the clips' own lengths; primary / area -15% / 2 s memory):

| Clip | Lookahead off | Lookahead on |
| :--- | :--- | :--- |
| **rushcity reduced** | 2.5 / 3.5 / 1 FAIL | **2 / 2 / 1 PASS** |
| **rushcity** | 2.5 / 3.5 / 1 FAIL | **2 / 2 / 1 PASS** |
| collapse | (2 / 2 / 1, 0.1 tail commit) | 2 / 2.5 / 0.5 PASS |
| collapse reduced | (2 / 2.5 / 2) | 2 / 2.5 / 0.5 PASS |
| mashcity, both modes | not measured | 1 / 1 / 0 PASS, PASS |
| signaturecity | 2 / 2 / 2, 1 / 2 / 2 (older base) | 2 / 2 / 1 PASS; reduced 2 / 2 / 1 PASS |
| ai 12345 reduced | 2.5 / 2.5 / 2 (older base) | 2 / 2.5 / 2.5 PASS |
| **ai 39 reduced** | not measured on 68ac7839 | **3 / 3 / 3 OVER GATE** |

**ai 39 reduced is not the lookahead's.** I ran the probe through the whole 3,600 ticks with the lookahead off and on: the two outputs are **byte for byte identical** (the same 3,601 lines, the same eleven mode changes, the same worst travel), so the camera's frames cannot differ between the arms. What reads 3 / 3 / 3 on this commit is what main brought since my last reading (2 / 2 / 2 on the commit with the 0.1 s tail): VFX's new beams (47f402cb, 68ac7839) or the sim. A baseline capture of ai 39 reduced on 68ac7839 with the lookahead off will say; I stopped it for the quiet window.

## 5. What is checked and what is not yet

- `split_sweep` with `--merge-lookahead` (every row run with it on, seeds 10 and 17): passes.
- `depth_inert` digests with it on by default equal the previous (2421871723535137368 and 3078283600976660394): the scripted pair does not part fast.
- **Not yet run (the quiet window):** a comparison of the camera's frames, lookahead off against on, over the other clips and seeds (ai 1, 4, 5, 38, 106, collapse, mashcity, signaturecity) to list exactly which of them the rule changes at all (a probe pair per clip, single Godot process); the ai 39 baseline capture; the default `split_sweep`, seam, pane and determinism gates on the final tree.

## 6. Files

`render/camera/split_rig.gd`, `camera_params.gd` (`MERGE_LOOKAHEAD`), `split_view.gd`, `render/camera/tests/split_sweep.gd` (`--merge-lookahead`), `clip_probe.gd` (`rushcity`, `exo` scenarios; `--mlook`, `--exoy`).
