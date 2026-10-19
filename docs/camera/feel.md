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

## Next

3. Fewer, better-placed cuts (count them a minute; cut only on an impact, 2 s apart at least; anything else eases).
4. Speed: the lead already exists in several places (a chased launch's lead room, the rush lead, the lunge lean, the building lead). The work is to make the merged view lead the brawl's motion, and to widen smoothly with speed and come back without a pump.
5. The beam struggle's framing (built, behind its switch): a clip for Orb, then on.
