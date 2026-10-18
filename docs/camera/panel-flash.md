# The record's camera-led clips: the signature strip under Reduce flashing, and one report fix (Camera, 2026-10-17)

Owner: Camera and Cinematography. Measured on main 2ef3ab5a with the fixed capture hook (Tools' 0654a2e2: a normal clip is Reduce flashing off, a reduced clip on). The EP's brief quoted the readings of the old hook, where both modes were the calm look; the mode that is over now is Reduce flashing on, the shipped default.

## 1. What the failing clips have in common

Two of the clips over the line in the re-read open a signature strip in the worst second, and the strip is what takes them over (a third, ai 39, has a strip in its worst second too, but it is not the cause, section 3):

| clip (reduced) | Tools' reading | strip | with no strip at all | with the signature strip off, the rest kept |
| :--- | :--- | :--- | :--- | :--- |
| ai PROTAGONIST,REFERENCE 8 (first 1,000 ticks) | 4 / 4.5 / 3.5 FAIL | signature at 859 | 3 / 3 / 2 (over the gate, not over 3) | 3 / 3 / 2 (the same: the one strip in the window is the signature) |
| ai 43 (2,750 ticks) | 3.5 / 3.5 / 2 FAIL | signature at 2607 | 2.5 / 2.5 / 1.5 PASS | the same, for the same reason |
| ai 39 (1,750 ticks) | Tools 3 / 3 / 3 at ff68e994; **4 / 4 / 4 FAIL on main 2ef3ab5a** (strips as before, lookahead off) | a clash strip at 1631 | 3.5 / 3.5 / 3.5 FAIL | 3.5 / 3.5 / 3.5 FAIL (a step better than main, still over 3) |

**Why a strip counts for so much.** The strip is 0.56 by 0.20 of the screen, four times the analyser's window threshold (21,824 px), and it opens and closes on a bright sky against a darker world: each is one counted whole-area change (24,000 px at 861, 1.10 of the threshold, the first). A signature strip opens on the fire beat, so its opening and its closing sit either side of the beam's own changes in the same second, and the counter pairs opposite signs: PR-8 with the strip reads 861+ 864- 869+ 882- 886+ 892- 898- 900+ 909- 920+; with no strip 860- 869+ 882- 886+ 892- 898- 900+ 907+ 920+: the strip's + and - sit in front of and behind the world's, and each opposite pair is another flash. The flash register sees the strip as one flash of weight 1 (and under Reduce flashing gives it the whole budget of 1.0); the pixels see two steps made to alternate with the world's. Frames of the opening: the strip's luminance goes 0.124 to 0.233 in three ticks (859 to 862) and back at 907 to 911; between them it is steady, so the content is not the cost.

**What did not help (measured).** A still strip (frozen, no wipe, no live content) on PR-8 reduced reads 4 / 4 / 3: FAIL, no better than the live one, because the appearance and the disappearance are the cost, not the strip's content. A strip made smaller would have to be under about 0.10 of the screen's height to leave a window threshold unreached, and then it is not a close-up.

## 2. The rule

While Reduce flashing is on, a **signature** strip does not open (`SplitRig.panel_flash_off`, default `["signature"]`; `SplitView.set_panel_flash_off(kinds)`; `[]` gives the player's setting alone). Every other strip (a clash won, a riposte, a finisher, a crippling blow, the KO, the double) and every strip with Reduce flashing off are as they were. The sweep row `panel reduced flashing` checks the four cases (a signature refused, a clash granted, the list emptied, the flag off).

Cost: the shipped default (Reduce flashing on, locked for the interim build) shows no signature close-up. The beam, the camera's own work and the HUD are unchanged. This is Orb's call to confirm; the switch is one line.

## 3. What is not fixed

- **ai 39 reduced** is still over 3 (3.5 / 3.5 / 3.5, from 4 / 4 / 4 on main). The worst second is 1631 to 1690, eight counted changes: 1631+ the launch chase beginning (60,000 px), 1637- 1641+ 1646- 1654+ the beam clash's flares (they are in the picture with every strip off, and half of them outside the strip's band), 1676- a cut (239,000 px, 31% of the frame: the launch hold ends in one cut, the probe has it at its tick 1669), 1679+ and 1689-. The strip is not the cause there (all strips off reads the same 3.5); the camera's part is the chase's start, the hold's cut and its return, about three of the eight. Not changed: the hold's cut is the launch rule's design (one cut, never a pan), and a travel-budget run of this clip (page flag budget=1) is the next thing to try, with Tools' pixel read.
- **ai 1009 reduced, blastdummy reduced** have no strip in their worst seconds (the probe lists none): their steps are the camera's and the world's (a blast, a cut after it). Not touched here.
- **The ring clips' red 0.5** (reproduced on main in the 3-body reduced clip at tick 196 and the 5-body normal clip at 223): one red transition each (23,000 and 22,000 px of the window, 1.06 and 1.16 of the threshold), no pair. In the 3-body clip it is the camera's cut (a 368,000-px frame step at 196: the sunset's orange-red band on the left leaves the picture and the green terrain replaces it); in the 5-body clip there is no cut at 223 (8,500 px a tick on either side), the band leaves the window as the picture drifts. Both are the camera moving the picture off a saturated glow, which no camera rule can promise not to do; a red gate of 0 asks the world's sunset to be tone-limited (Rendering or Art), not a cut to be removed. **ai RIVAL 107 normal** now reads 2.5 / 2.5 / 2 PASS on the fixed hook (Tools' re-read), and the camera is still (identical 80 ticks) at the old reading's tick 1719.

## 4. The merge lookahead and the other clips

The lookahead (febcc890, on by default) changes the camera of exactly one required clip, rushcity (94 ticks of 1,500 in normal, 107 in reduced, ticks 73 to 272). The camera of ai 1, 4, 5, 38, 39, 106, collapse, mashcity and signaturecity is the same tick for tick with it off and on, in both modes (`render/camera/tests/clip_digest.gd` plays the scenes through the real scene as flash_worst.gd does and hashes the camera's frame every tick; `clip_digest_diff.py` compares two runs). A clip with equal digests is the same picture, so a frame comparison of it can only show no change.

## 5. The sweep's real match 3 (a report fix, not a picture change)

`real match 3 pitch 49 full: pane 1's anchor moved 0.053 of the width in a tick at t=287.90 (solo/solo launch)`. Bisected: it passes on 9d0530dc's parent (2154cd5e) and fails on 9d0530dc itself, at the same tick (Encounter's window 1 moved the launch that lands in the last tick of a closing). The pictures are continuous (the pane's camera and the fighter's place on the screen change by nothing a player would see); what jumped is the nominal anchor the frame reports: in a closing the pane's anchor stays at its rest value (282 px) although its picture is already the shared one, and a launch taken at that moment (`_begin_solo`, sep under 0.5) snaps the shot's anchor to where the fighter is on the screen (666 px). Nothing outside the sweep reads `frame.anchor`. The frame now reports the anchor moved at most `CamParams.ANCHOR_REPORT_STEP` (0.15 of the width) a tick toward the true one (the cameras are built from the true one, as before): two ticks for the 384 px hand-over. The sweep passes (real match 3 included) on main 2ef3ab5a; the row `anchor report slew` checks the slew and the arrival.

## 6. What the rule changes, and what was checked

By camera digest (reduced mode, rule on against off) the rule changes the strips, and only the strips (the main view is the same), of 15 of the 19 clips tried: ai 4, 8 PR, 9, 39, 43, 104, 106, 107 RIVAL, clash, clashcity, collapse, launchai, rushcity, signature, signaturecity. Unchanged: ai 7, mash, mashcity, transform. Normal mode is unchanged for all (the rule acts only while Reduce flashing is on), so the normal readings of Tools' re-read stand. Tools' full set in reduced mode needs a re-read: only PR-8, ai 43, ai 39 and collapse have been captured here (collapse reduced 2 / 2.5 / 0.5 PASS with the rule and as before; ai 39 and PR-8 in section 1). Gates on main 2ef3ab5a with the change: split sweep (two new rows, real match 3 included), seam sweep, pane check, determinism plain and --intro: all pass.

The ai 39 baseline asked for (merge lookahead off, normal, 3,600 ticks) reads 2 / 2.5 / 2 PASS, the same as Tools' re-read with it on: the camera is the same tick for tick in both settings and both modes.

## 7. Round two (Legal's note, 2026-10-17): dissolves, a slower strip wipe, and switches for analysis

Parked as `docs/camera/pending/cut-dissolve.patch` (applies to e8d91dea) and `docs/camera/pending/flash-capture-camera-switches.patch` (the capture hook; Tools'/Rendering's file).

- **A cut under Reduce flashing or reduced motion is a cross-dissolve of 0.4 s** (`CamParams.CUT_DISSOLVE_S`; `SplitView.cut_dissolve`, `set_cut_dissolve(false)` keeps the old dip). The compositor copies the picture on the screen when the cut frame arrives (the root viewport's last drawn frame) once, and fades it out over the new one in the rig's sim time; the dip stays out of a dissolve. The old "dissolve" of reduced motion was only a longer dip (the picture still stepped from A to B in one tick). Normal mode is unchanged. A host that draws nothing (the headless tests) has no image and keeps the dip. Traps found: the copy must be converted to RGB8 (the root's alpha is not worth keeping) and the dissolve clock is the rig's `time`, not `host.ticks` plus the frame fraction (the latter read the same in a debug print and did not drive the fade).
- **The strips wipe open and shut over 0.3 s while Reduce flashing is on** (`PANEL_OPEN_REDUCED`, `PANEL_CLOSE_REDUCED`; 0.08 and 0.12 s otherwise). It applies to the strips that remain (clash, riposte, finisher, crippling, KO, double); the signature strip stays shut under Reduce flashing (section 2).
- **Switches** (page, in the hook patch): `nocam=1` (the compositor detached: one view from the reference camera, no dip, strip, cut or dissolve), `nopanel=1`, `nodissolve=1`, `pfo=none` or kinds joined by `+` (the strips shut under Reduce flashing), `mlookoff=1`; each is reported in `switches`.
- **The sweep of collapse, ticks 108 to 130, is left as it is.** The camera there is the pair's closing zoom, 0.5 e-folds a second with a travel of at most 0.015 a tick (half the reduced bound of 0.03); collapse reads 2 / 2.5 / 0.5 in both modes. The merge zoom limit would slow it (0.21 e-folds a second) but it was measured to cost ai 12345's re-merge (a pass to 3 / 4 / 2.5) and is the crawl Orb's playtest found; I did not turn it on.

Measured (main with e8d91dea, the dissolve and the 0.3 s wipe, reduced, tick-stepped captures on the fixed hook):

| clip | before (Tools, ff68e994, or main) | now |
| :--- | :--- | :--- |
| blastdummy RIVAL,REFERENCE (420 ticks) | 3 / 3.5 / 3 FAIL | 1.5 / 3 / 1.5 PASS (the 121,000-px cut at 301 is 13,000 a tick) |
| ai 43 (2,750 ticks) | 3.5 / 3.5 / 2 FAIL | 2.5 / 2.5 / 1.5 PASS |
| ai 39 (1,750 ticks) | 3 / 3 / 3 (4 / 4 / 4 on main) | 1.5 / 1.5 / 1.5 PASS |
| ai PROTAGONIST,REFERENCE 8 (1,000 ticks) | 4 / 4.5 / 3.5 FAIL | 3 / 3 / 2 over the gate, not over 3 |
| collapse (1,500 ticks) | 2 / 2.5 / 0.5 | 2 / 2.5 / 0.5 |
