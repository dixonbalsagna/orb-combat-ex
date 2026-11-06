# The beam's shove, and the catch (Animation, 2026-11-01)

## 1. The shove (built, parked: `docs/animation/pending/beam-shove.patch`)

Encounter's beam-hold park throws the other fighter back to the stand-off when a beam is fired from up close: a point rush of `shoveSec` (0.25 s), no damage, no stun, he keeps his hands, and the cue `beam_shove` on the one thrown. Until now he slid in a standing pose (`docs/director/img/shove-t*.png`).

What the body does now (`AnimFighter.on_beam_shove`, the fit sequence `sv.shove` in wave `shove1`, prefix `sv`, in `pair_live.json` `shared`): the cue handler in `RenderAnim.consume` reads the slide's length from the fighter's own rush (`rush.end - S.T`, 0.25 s when none) and fits three poses to it:

| Phase | Share | The body |
| :--- | ---: | :--- |
| `hit` | 0.2 (3 ticks) | the shock wave arriving: weight thrown back on the rear leg, chest and head pushed back, the fists lifting out of the guard |
| `dig` | 0.6 (9 ticks) | digging in: knees deep on a wide stance, leaning into the blast, head tucked behind the forearms, both fists up in front of the face with the elbows low |
| `settle` | 0.2 | up out of the dig into the aggressive stand, the guard still in front |

Both fighters, fists (Legal: no open palm, a forearm leads; nothing above the shoulder; no pose held 12 ticks: the dig is the slide's 9). Reduced motion scales it by 0.6. `--no-beam-shove` is the before. The position is the sim's: only the pose is drawn. It is inert on main until the beam-hold park lands (nothing sends the cue).

Test `_test_beam_shove` (both fighters, 15 and 9 ticks): sink 10.0 and 7.5 units, the pelvis back to the stand within 0.35 after the slide, no NaN, no violation. pose_lint 0 issues; `anim_check` 10,366 checks passed on a fresh HEAD export. Clips (local, `art/animation/review/beam-shove/shove-{antihero,protagonist}-AB.gif`): A is main, B this park, the shove staged on the fire tick of a point-blank signature (the real park is not in the tree), RT and B drawn at the frame edge. The flash gate: this changes a pose on a cue that nothing sends on main, so I did not run the clip; it needs one when the park lands.

## 2. The catch: what it needs (a sketch, nothing built)

Orb's marks (`docs/ep/vision.md`, "Beam answers"): holding a beam on a forearm, driven back, the ground cratering under planted feet (a beam from above) or a trench carved along the ground (even ground), still standing.

### Poses (one wave, prefix `sv`, fists, a forearm or shoulder takes it, no open palm)

| Pose | What it is |
| :--- | :--- |
| `catch.set` (3 to 4 ticks) | feet set wide, weight sunk; the lead forearm comes up across the chest toward the beam, the other fist braced behind its elbow |
| `catch.take` (the impact) | the shove's `hit` pose, the body thrown back a little, the lead forearm taking it |
| `catch.hold_level` (loop) | even ground: legs deep with the rear leg braced straight behind, lean into it 14 to 20 degrees, head tucked behind the lead forearm held at chest height, heels dragging |
| `catch.hold_down` (loop) | a beam from above (45 to 90 degrees): forearms angled up and forward at about 60 degrees, the lead fist no higher than 76, the other forearm under the elbow, the body hunched, the pelvis very low (about 22 under the stand), the knees taking it |
| `catch.give` | the lead arm buckling and the knees folding as the beam gets through: the shove's thrown-back pose and a fall |
| `catch.out` | the beam ends: a shrug out of the hold, the forearm lowering, the guard returning |

The hold is mixed between `hold_level` and `hold_down` by the beam's own angle, the way `_beam_layer` mixes `fire_up`, `fire_down` and `fire_back`. Six key sets, shared by both fighters.

### Layers and data

1. A `_catch_layer` that loops the hold with a strain tremble and the drawn body dragged back along the ground (the feet carving it). The struggle's dig-in (`_struggle_layer`: the squash pose, `_str_slide`, the tremble) already does that for a losing struggle; the catch reuses its slide and tremble and takes its own poses.
2. A cue from Encounter: `beam_catch`, text `start`, `hold`, `end` or `break`, with the beam's angle and the drive's length, on the one catching, and the position the sim gives him (the drive is the sim's; the pose never moves it).
3. The ground's answer (a crater under him, a trench along the ground) is World's and VFX's: World's crater, scorch and trench records exist; Animation draws the feet in the ground, not the ground.

### What it hits

- Legal's held-pose rule (no pose held 12 ticks, nothing above 76 in a held chamber) was written for blows and reactions. A catch holds for seconds: it needs a ruling on a held class that moves (a tremble and a drive), and a look at the forearm and the head cover.
- Whether the catch is a stance of the stick class (a held brace) or its own: Combat's and Game Design's.
- Size: one session for the six key sets, the layer, a test and clips with the stick drawn, after the cue and Legal's ruling exist.
