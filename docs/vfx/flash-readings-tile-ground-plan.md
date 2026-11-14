# The flash readings on the tile ground: VFX's part (A-LEGAL-01, A-CAMERA-02; a plan, 2026-11-14)

For the outside-tester chain. Results go to the EP only. Nothing here is for Orb's page. Nothing has been captured: no quiet window has been given yet, and every capture is made through Tools' launcher, one at a time, at below-normal priority with a time limit, and never with more than 3 Godot processes.

## Where it stands
- **The last reading on the globe (tile) ground** (`docs/rendering/runs/d985eb15/crater-look-default.txt:24-25`): the beam clash read **5.5 (normal) and 6.5 (reduced)** against a limit of 3; the collapse read 3 in both modes (over our gate of 2.5). Each clip took about 11 minutes.
- The standard flash clips never ran with the tile ground, and no pixel reading exists for the played commit 6a30b4c9.
- Camera leads the reading. Tools' repaired chain (A-LEGAL-08) takes it. My part is the effects: say which effect causes a failing reading, and fix that effect.

## The readings handed over 2026-11-14 (Tools' pixel clips, EP; `docs/rendering/runs/fcd6706c/look-defaults-flash.txt`)
Normal / reduced, primary reading, limit 3 (our gate 2.5):
- **Main as built** (the old ground): clash 4.5 / 4.5, collapse 5 / 4. All four are over the limit already, before any of the default changes.
- **With the globe ground:** clash 5.5 / 6.5 (collapse 2.5 / 3).
- **With the globe ground and the crater look:** collapse 4 / 3.5 (clash 5.5 / 6.5).

**The stack that counts is GW1a's: the 9 November build, which has the globe ground, the crater look and the meteor trail on.** Every reading and every fix works against that stack (the meteor default is `docs/vfx/pending/meteor-default/`). Outside-tester builds stay blocked by gate G21 until these pass, and never by degrading the look: no dissolves, fades or blur. So the plan below changes in two ways: the controls include the **meteor trail off** as well as the clash, collapse and blast switches, and the clash is over on all three stacks including the old ground, so the first control to run is the clash **effect-off on main as built**: if it still reads 4.5, the clash's number is mostly the scene, and the globe ground only makes it worse.

## The method: measure, then attribute
A reading on its own says a clip fails. It does not say what to change. I learned this on 2026-11-07 with the 2v2 clips: seven of eight failed, and a control (the same scene with the effect switched off) read the same, so the cause was the scene and not the effect. So for each clip I want read:

1. **As played** (Camera's reading, or mine if Camera's is not ready): both modes.
2. **A control with my effect off** (the effect's own switch, set by a scratch page word that is not in the repo): both modes. If the control reads the same, the effect is not the cause and I do nothing to it; the cause goes to Camera or Rendering with the two readings. If the control reads lower, the difference is the effect's share.
3. **The fix on** (only for an effect that is a cause), both modes, then the look gate: a side-by-side against the reference build in both modes, stills plus a short GIF. If it looks worse it goes back whatever the reading says (ADR 0010).

Each reading is also read against the register's own log (the clip's `register web/headless max` column), so a gap between what the register thinks it granted and what the analyser sees is named: that gap is the non-asking sources (scenery past a moving camera, a hard cut, the ground), which are Camera's and Rendering's and, for the cuts, covered by `flashes.ask_cut` once Camera wires it.

## My clips
The ones whose pictures are mine: **clash** (the failing one), **signature**, **transform**, **collapse** (the debris, dust and the crater flash), **blastdummy** (the blast and the catastrophe tier's cloud). Five clips, two modes, as played and with the effect off: **20 captures**, about 11 minutes each, about **3.7 hours** one at a time. If Camera's reading shows only the clash over the limit, I run the clash clips alone first (4 captures, about 45 minutes) and the others only if their readings are over.

The effect's off switch for each (to be set up as a scratch page word in a copy, as before): clash look and its press (clash), the signature's variant looks (signature), the transformation's break flash (transform), the earth pieces and the collapse debris (collapse), the blast cloud and its fireball light (blastdummy).

## What a fix may be (A2, criterion 1)
- **Reduced mode:** brought inside the limits by what it switches off, slows or holds steady.
- **Normal mode:** brought inside by timing and brightness steps (a rise of at least 0.3 s, a fall of at least 1 s, one event per 2 s, the register's budget), **not** by haze, blur, a fade, a dissolve or a steady ring.
- **Any change to the ordinary look of the beam clash by timing and brightness** goes to Orb through the EP as two clips and one look question with no numbers (the A2 amendment, ORB-02); the EP's side-by-side is not the last word.

## Order
1. Camera's first reading on the tile ground (needs Tools' repaired chain).
2. My controls on whichever clips read over.
3. Fixes in `render/vfx/` per clip, each with the look gate.
4. Tools' chain re-reads each fixed clip in both modes; outputs under `docs/vfx/runs/<sha>/`.

The shared-register park has landed (the EP's batch); the hard-cut asks (`flashes.ask_cut`) wait for Camera's cd04 park. My own order for A-CAMERA-02, criterion 3: the register came first, Camera's cd04 lands on it, and a cut that is refused eases (no dissolve).

## Cost
Reading and attribution: about 0.1M tokens (mostly waiting on captures). The fixes: between S (0.25M, one clip, the clash alone) and M (1.2M, several clips), as the A2 brief says; I will know which after the first reading.

## What I need
- **From Camera (through the EP):** the first reading on the tile ground for the clips above, in both modes, and which scenery or cut is in each clip's worst second.
- **From Tools:** the repaired chain, and a clip set that runs with `tiles=1`.
- **From the EP:** a quiet window of about 45 minutes first (the clash alone), and a longer one if the others read over. I will not capture before it is given.
