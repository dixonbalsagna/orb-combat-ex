# The riposte and the sure blow: what VFX will draw (plan, 2026-10-07; docs only, no build)

Reads (Animation, docs/animation/press-styles.md section 12): `AnimFighter.riposte {kind, reversal, sure, ticks_to_contact}` and `press.sure` / `press.riposte` on a styled blow. Encounter's cues: `riposte` (actor the blocker, target the rival, `text` light or heavy, `n` the contact tick), the stagger cue's `perfect_block` and `reversal` texts, and strike beats carrying `riposte`, `reversal` and `sure`. A **sure** blow cannot be blocked or dodged.

## What it already gets for free

A riposte is an ordinary strike beat with a perfect timing: by default `style: tech`, `grade: perfect` for a light (3 wire echoes, the hard diamond, the thin line) and `heavy` for a heavy. So its after-image and contact mark are the press styles' own, identical to any other tech or heavy blow (Orb's rule). Nothing new is needed for a riposte that is not sure.

## What a sure blow adds (one mark, brief, no aura)

A sure blow is marked in two places for the beats it is committed, and nowhere else:

| Where | What | Ticks | Quads |
| :-- | :-- | :-- | :-- |
| **The striker, at the start** | A thin hard line along the limb's path from where the limb is to where it will land (Animation's `press_path` when the riposte starts, else guard to contact), in his lane colour: the committed path, drawn over the last 6 ticks before the contact (`ticks_to_contact`) | 6 | 1 |
| **The target, at the contact** | Four short corner brackets closing on his chest (the caught mark's brackets, hollow, 18 units to 10 over 6 ticks) in the striker's lane colour: nothing to block, nothing to dodge | 6 | 4 |

Then the contact is the strike's own (the diamond for tech, the double ring for a heavy). 5 quads a sure blow, no debris, no flash.

## A reversal

The sidestep out of a block is the body's (`s3.reversal`, 8 ticks). VFX adds one wire echo of him left on the line of the step, popping off over 3 ticks (the tech echo, one only), so the sidestep reads as a drawn move and not a blink: it trails the body and never stands ahead of it (Legal m03). 5 quads, then the riposte after it as above.

## Legal and the stacking rule

Nothing here is one of the seven marks (a thin line and brackets in a lane colour, hollow, no flash, no aura, no scream, no crouch). On the **striker** it adds at most one mark at a time (the committed line), and on the **target** at most one (the brackets); both are gone within 6 ticks and neither runs with a tell's aura, so at any tick a fighter has at most one more mark than he had (k01). Lane colour only, never white, gold or red; nothing on the face (the brackets sit at the chest, as the zip's caught ring does, m08); no text or numbers.

## Quality, reduced motion, budget

Reduced motion: the line and the brackets stay (they are short and still); the reversal's echo is dropped. Quality low: the same (5 quads). 5 quads per sure blow or reversal on top of the strike's own (tech 17, or 38 with real poses), so six sure blows a second from each fighter would still stay under 150 quads.

## What I need when it lands

- Animation: `press.sure`, `press.riposte`, `riposte.ticks_to_contact`, and `press_path` at the riposte's start (the committed line follows the real limb); the reversal's previous poses (`press_pose`) if the echo should be a real pose.
- Encounter: `sure` on the strike beat (read from the beat the way `style` is, `VfxPress.beat_args`), and the `riposte` cue (kind, contact tick).
- Tests when built: a sure blow draws the line and the brackets and nothing at a non-sure riposte; the marks are gone in 6 ticks; the reversal's echo trails the body; the counts above.

## Built (2026-10-06)

Cue `riposte` (actor the blocker, target the rival, text light or heavy, `n` the contact tick) with the riposte beat read from `S.dirS.ex.beats` (`args.riposte`, `sure`, `reversal`). A sure riposte starts a thin committed line (style `sureline`) that waits and draws only in the last 6 ticks before the contact; on the blow itself (`_blow`) a sure beat adds the four `brackets`; a reversal adds one wire `revecho` at where he stood 6 ticks ago (dropped in reduced motion). A riposte that is not sure adds nothing. `render/vfx/press.gd` `_riposte`, `render/vfx/shots_view.gd` `_press` arms; `effects_check.gd` `_riposte()` (the line waits, 1 quad then, 22 at the contact with the blow's own look, gone in its ticks; a non-sure riposte adds nothing; the reversal echo 5 quads). Not yet drawn from a live fight: no web still.
