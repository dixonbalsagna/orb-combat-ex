# The signature clip, bisected (Tools, 2026-10-27)

Owner: Tools. Asked by the EP after VFX read `signature` at normal 3.5 (area-15% 5) on 3d0c0860 while the dress rehearsal (docs/tools/rehearsal-f15d7de3.md) had 2 / 3 / 2. Nothing recorded; nothing applied.

## How

Scratch web exports of each commit (`git archive`, import, `--export-release "Web"`), then `tools/flash/check-clip.mjs --clip signature-normal,signature-reduced --site <export> --jobs 2` through the launcher (40% core budget, below-normal priority, MERIDIAN_SESSION=tools), one commit at a time, with the current tools/flash on every commit. The machine was never quiet (other sessions' QA and captures: load 33 to 52% before each run, 32 to 67% after; the threshold used was under 55%). The captures are tick-driven, and the runs agree with each other: f15d7de3 reproduced the rehearsal to the last digit, main (099f5f3b) reads identically to c9bd20d1 (every event, every pixel count), so load did not move a number.

## The table

Primary reading / area-15% / 2 s memory; combined rule (PASS is 2.5 or under on the primary and nothing over 3 elsewhere).

| commit | date | normal | reduced |
|---|---|---|---|
| f15d7de3 (the rehearsal; re-run today) | 10-17 | 2 / 3 / 2 PASS (identical to the rehearsal) | 1.5 / 2 / 1 PASS (identical) |
| 257a766c (the live pin) | 10-19 | 2.5 / 2.5 / 3 PASS | **3 / 3 / 3 OVER GATE** |
| 12d14f3b (parent of 22n/22o) | 10-26 | 2.5 / 2.5 / 2 PASS | 2.5 / 2.5 / 3 PASS |
| **c9bd20d1** (22n/22o, the ground look) | 10-26 | **3.5 / 5 / 3 FAIL** | 2.5 / 3 / 2 PASS |
| 9490ac21 (no flat varyings) | 10-27 | 3.5 / 5 / 3 FAIL (same as c9bd20d1) | 2.5 / 3 / 2 PASS |
| 099f5f3b (main today) | 10-27 | 3.5 / 5 / 3 FAIL (same) | 2.5 / 3 / 2 PASS |

VFX's reading on 3d0c0860 (normal 3.5 / 5, reduced 2.5) is what c9bd20d1 and everything after it gives.

## First failing commit

**Normal: c9bd20d1.** Its parent 12d14f3b passes at the edge (2.5 / 2.5), so there is nothing to bisect between them. The commit is one bundle (the ground look 22n, the cover 22o, the campaign's cross-back); a switch test on the same export separates the two a little: with `?flashcap=1&nocover` (cover off) normal reads 3 / 3 (OVER GATE) and reduced 3 / 4.5 (FAIL), so the cover is not the whole of it and turning it off does not bring the clip back; the ground look moves the clip too, and the two move it in different directions in the two modes. The clip sits on the gate: 12d14f3b already has it at 2.5 and each of these layers can add or take half a flash.

**Reduced** went the other way first: 1.5 at f15d7de3, 3 (OVER GATE) at 257a766c, 2.5 at 12d14f3b and after. Its worst second at 257a766c was the beam's (ticks 426 to 481); the 87 commits between f15d7de3 and 257a766c were not bisected (reduced passes today).

## The worst second (c9bd20d1, normal; main is identical)

Ticks 71 to 131 of the clip, the signature beam landing and the camera splitting. The counted changes: **+71** (44,275 px of the 87,296-pixel analysis frame turn brighter at once: the beam's impact lights the lower right of the picture orange and yellow), **-81** (it fades), +86 (marginal), **+89** (38,186 up), **-91** (38,979 down), **+95** (25,943 up), **-103** (22,384 down), +112 (marginal). The 12d14f3b clip has only +71, -81, +86, +88 in that second (2.5).

What the extra changes at 89 to 103 are: the camera opens the split view (frames 88 to 92: a dividing line, the right pane showing the struck fighter flying away). In 12d14f3b the right pane's ground is a soft sand gradient; from c9bd20d1 it is flat bands of pale yellow ochre over a darker ochre, with a lit mesa, so the pane's cut and the pan across it turn 25,000 to 50,000 pixels (windowByTick 89 to 100: 38k, 18k, 39k, 51k, 10k, 18k, 26k, 29k, 31k, 33k, 40k, 51k) where before they turned 10,000 to 25,000.

Frames (this PC): `<scratchpad>/bis/c9bd20d1/run-a/clips/signature-normal/frame-000041.png` to `frame-000161.png` (frame number = tick); the same ticks of 12d14f3b in `bis/12d14f3b/run-a/clips/signature-normal`. Compare 91 in each.

## Not done

No bisect of reduced between f15d7de3 and 257a766c; no layer-by-layer switch test of 22n (the ground look has no URL switch; `nocover` is the only one). Both are one capture each if wanted.
