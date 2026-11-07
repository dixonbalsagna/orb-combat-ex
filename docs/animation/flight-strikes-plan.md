# Flight strikes: a look per path (Animation, 2026-11-07, plan)

For `docs/design/playable-build.md` section 1: **hold LT, point the left stick, press X, Y or B.** Five paths (zip, line, arc over, arc under, parting shot) by three blows (X quick 6-tick tell, Y heavy 10, B biggest 14), the same for every fighter, a fighter's style changing only the look. Paper only: which existing key sets cover each, what is new, and what it costs.

## What already exists

- **The zip's body** (`docs/animation/zip.md`, `data/anim/zip.json`, `AnimFighter` zip layer): tell, the way in, blows in reach, the way out, an orientation along the path (up to 1.2 rad), a far-side `pass` (`over`: an arc dive, `round`/`under`: a pivot) and `entry_in`/`entry_out`. It draws **the fighter's own key sets for the blow**: "no new strike poses". So the neutral zip already works for any X, Y or B piece.
- **The recoil layer** (`_recoil_layer`, `data/anim/recoil.json`): turns the whole body about its middle over a given number of ticks along an arc and lands it. A body flip is already a solved problem.
- **The pieces:** about 160 strike key sets across both fighters, the stick class and the three strengths, with `weight`, `limb` and `target` on each manifest row.

## Path by blow: what covers it

| Path | The body | X (quick) | Y (heavy) | B (biggest) |
| :--- | :--- | :--- | :--- | :--- |
| **Zip** (in, back) | existing zip | any light piece the fighter has: `cross`, `jab`, `palm_heel`, `short_elbow` | any medium: `roundhouse`, `uppercut`, `cross_arm_ram`, `driving_knee` | the super tier: `pu.su_drive`, `ru.su_ram` |
| **Line** (through him, ends 1.5 bh past) | the zip's `pass` straight on, the blow thrown as he goes through, turning round on the far side | passing ram: `shoulder_check` (both), `rz.short_ram`, `rm.plate_drop` | `body_ram`, `cross_arm_ram`, `rz.plate_ram` | `pu.su_drive`, `ru.su_ram` |
| **Arc over** (loop over his head, blow at the top) | **new: a half loop of the body** (below) | a downward light: `pr.knife_chop`, `pm.back_chop`, `rm.forearm_drop`, `pr.hammer_fist`, `rz.spike_knee`, `pz.spike_heel` | `pr.axe_kick`, `pr.hammer`, `pr.overhand`, `pr.dropping_elbow`, `rz.hammer_drop`, `pz.plunge_blade` | `pu.su_hammer_arm`, `ru.su_hammer` |
| **Arc under** (below him; a low sweep round him on the ground) | **new: the same loop mirrored**, skimming low | `pr.sweep`, `pz.scythe_sweep`, `rz.skid_kick`, `pr.low_kick`, `rm.fist_sweep` | **none that is a heavy low blow** (the only heavy legs targets are the super tier's `su_knee_legs`, `su_edge_legs`) | `pu.su_knee_legs`, `ru.su_edge_legs` |
| **Parting shot** (in, the blow, out further than he started) | the zip's back-step (`hop_back`) with the blow thrown as he turns away | a backhand on the way: `pr.backfist`, `rm.heel_backhand`, `pz.wheel_blade`. They are spins; **a light thrown while already moving away is new** | `pr.spinning_back_kick`, `pr.spinning_heel`, `pr.spinning_elbow`, `rm.heel_backhand` | `pu.su_turn`, `ru.su_hook` |

That covers 13 of the 15 cells with existing key sets (Y on an arc under and X on a parting shot are the two with none that reads right), but six of them (both arcs, three blows) also need the new loop below, whatever the key set. No path needs a different piece to be *legal*: the targets are chest, gut, arm and legs, and the high-landing arc over blows aim at the chest and arm, never the head (RL-218's rule for drops).

## What is new

1. **A loop layer** for arc over and arc under (the real work). The zip's tilt along its path stops at 1.2 rad; a half circle turns the body 3.1. It is the recoil layer's mechanism (whole-body turn about the middle over `n` ticks on a lifted arc) with the loop's own numbers: a half turn forward over the top for the arc over (head toward his far side), the mirror under, the blow's key set drawn at the top or the bottom with the turn paused for its contact ticks (so the blow reads as a blow, not a smear). The sim's path is the sim's, as the zip's is; the body only turns, and 24 ticks for a half circle up close is long enough to show it. A tuning row in `zip.json` (`loop`: turns, arc lift, pause ticks, fighter overrides).
2. **A heavy low blow for Y on arc under, one a fighter:** a scything heel or a sliding sweep as a heavy (about 3 key sets each, drawn). Until it exists, Y on an arc under would play a medium that does not read low.
3. **A light blow thrown while moving away, one a fighter, for the parting shot with X:** a back-fist or over-the-shoulder strike from the back-step (about 3 key sets each).
4. **The tells** (data): the flight strike's tell is X 6, Y 10, B 14. The pieces' own wind-ups are light 6, the mediums 12, the super tier 18, so Y and B need `flight` rows in the profiles (a shorter load with the pose carrying the first frames, as the stick class's 7 did) and chained strikes halve the tell (at least 4), a repeat on the third gets the full tell again.
5. **Orientation** at the end of a line and a parting shot: the body turns round on the far side or faces out, existing `pass` and `orient`.

Counts: 6 to 8 drawn key sets (items 2 and 3), the loop layer, six data rows (the three tells by flight and the loop numbers), the tests, and a clip for each path by blow.

## Tests and clips

An `anim_check` test per path: the blow's contact is reached on the real solve at each of the three tells, nothing past a joint limit through the loop, no pop at the turn's ends, and the sim's position is never moved. Clips with the pad's LT, the stick direction and X, Y or B drawn at the frame edge: 15 cells, but five paths by three blows read in three clips of five.

## Cost and order

Rough, in tokens: the loop layer with its test and tuning, about 100,000; 6 to 8 key sets with sheets and Legal stills, 120,000 to 180,000; the profile rows and tests, 40,000; clips for the 15 cells, 100,000. About 360,000 to 420,000 in all, one session's worth and a half. Order: the loop layer and the arc over first (it is what the vision shows), then the heavy low blow and the parting-shot light, then the data rows, then the clips.

## What I need

- **Encounter:** the cue for a flight strike carries the path and the button (`zip_light`/`zip_heavy` exist: a `path` field, the blow's `source`, the tell's ticks), and the sim's path for an arc is the loop the body turns on (the arc's centre, as `Rush.arc` gives a bow).
- **Legal:** a look at the arc over's top-of-loop pose (an inverted body with a blow thrown down) and the arc under's skim before they go live.
- **2v2:** a flight strike across fights is an outside blow, so it is drawn from the fight view (`RenderAnim.fight_view`) of the body that throws it.
