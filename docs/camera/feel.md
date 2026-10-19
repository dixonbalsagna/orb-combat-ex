# The camera's feel (Camera, 2026-10-19)

Owner: Camera and Cinematography. Orb's brief after playing the live demo: start from the smooth camera and split screen of d3f1ca0e, improve how it captures speed and tracks the fight, with no fades and no dissolves. References: docs/ep/taste.md, docs/research/readable-speed.md (rows 1, 2 and 8), docs/design/minimal-hud.md (a perfect's small punch, the struggle's tightening).

## Step 1: the baseline (no change)

With the dissolve and the slow wipes off (728596d0), main's camera behaves like d3f1ca0e's. Per scene, under Reduce flashing, the cuts, layout changes, strips and brightness dips (`clip_digest.gd` STATS) are within a cut or two of each other. Clips: homework/camera/1-before-after/.

## Step 2: hard cuts, and a push on each blow (parked: docs/camera/pending/feel-1-blow-push.patch)

- **No dip.** A cut is a plain hard cut: the 0.08 s brightness dip (a fade down and back, under both modes) is gone (`SplitView.cut_dip`, default false). Readable-speed row 2: "cuts only hard, never a dissolve".
- **The blow push.** Every landed blow above a light pushes the whole picture in a little by its weight, then lets go: medium 0.8%, heavy and guard break 1.6%, a launch 2%, a perfect block 1% (minimal-hud.md's "small camera punch on perfects"). Up over 0.05 s, held for the blow's own hit-stop (the `stop` ticks the damage event carries, at most 12), back over 0.25 s. It is drawn after the filters, so it is crisp, and a bigger push replaces a smaller one; a smaller one does not interrupt a bigger one. None in reduced motion or during the intro. `SplitRig.blow_push` (default on), the weights in `CamParams.BLOW_PUSH`. Readable-speed row 1's "1 to 2% camera push", which the sim's hit-stop by weight completes.
- About 14 pushes a minute in an AI match, about 2 a second in a both-human mash.
- Gates (scratch export of the patch on 161b1eef): split sweep, seam sweep, pane check, determinism plain and --intro: pass.
- Clips: homework/camera/2-blow-push-no-dip/ (left main, right the patch, Reduce flashing on: a mash and an AI match).

## Step 3: chase, not hold (parked: docs/camera/pending/feel-2-chase-not-hold.patch)

The flash bundle (bf966c57, after d3f1ca0e) was on under Reduce flashing, the shipped default: a launched body was held off (the frame stopped while he flew) and then cut to, the launch hold and its eager engage, and the rush's divider slam was off. It was there for the flash count. Off now (`SplitRig.flash_bundle` false): under Reduce flashing a launched body is chased, as in d3f1ca0e, and the slam plays. The signature strip opens under Reduce flashing again (`panel_flash_off` []), as in d3f1ca0e.

Counted by source (`clip_digest.gd`, the cut flag per frame by the line that set it, reduced mode): main's cuts were the hold's end cut and the follow's lag cut; with the bundle off the hold's cuts are gone, and per scene the cuts, layout changes, strips and the time a fighter is outside the picture come back to d3f1ca0e's (ai 4: cuts 1 against d3f1ca0e's 0 and main's 3; fighter-ticks outside the picture 298 against 297 and 349; clash: 0 cuts against 0 and 2). The cuts left are the layout's side swap while the pair is one view (unseen) and the follow's lag cut for a body far off.

The sweep's `panel reduced flashing` row now sets the switch it tests. Gates on the patch over 4dc42eb4: split sweep, seam sweep, pane check, determinism plain and --intro: pass. Clips: homework/camera/3-chase-not-hold/ (a launch in ai 39: held then cut on main, chased with the patch; the signature strip back in the city).

## Step 4: the one view leads the motion (parked: docs/camera/pending/feel-3-lead.patch)

The camera already leads in several places (a chased launch's lead room, the rush follow, the lunge lean, the building lead, and the follow filters' velocity feed-forward, which cancels lag but does not lead). The one view did not: it framed the pair's midpoint. Now, when the pair moves the same way, the focus sits ahead of them by their shared speed times 0.3 s, at most 0.12 of the width, faded in between 300 and 1,200 units a second and eased over 0.35 s; it is kept so both fighters stay inside the middle 80% of the width, and it is off in a launch, a zip, the fold, the struggle and reduced motion (`SplitRig.merged_lead`, `CamParams.MERGED_LEAD_*`).

Measured (`clip_digest.gd` SMOOTH, reduced mode): the room ahead of a pair moving together, as a share of the width, rushcity 0.221 to 0.275, ai 7 0.183 to 0.203; cuts, layout changes and the time a fighter is outside the picture unchanged.

Tried and dropped: tightening 2.5 times slower than widening (fewer zoom reversals: ai 39 18 to 14, signaturecity 16 to 12), because it left the zipper off the screen for 12 ticks in the 49-degree zip row (Legal's floor).

Gates on the patch over 10267f51: split sweep, seam sweep, pane check, determinism plain and --intro: pass. Clips: homework/camera/4-lead-the-motion/ (left step 3, right step 4: a rush in the city, an AI match).

## Next

5. The beam struggle's framing (built, behind its switch): a clip for Orb, then on.
