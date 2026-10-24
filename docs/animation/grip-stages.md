# The grip as five stages in the bodies (Animation, 2026-10-23)

Owner: Animation. Parked as `docs/animation/pending/grip-stages.patch` (render side only; apply after `shiver-by-weight.patch`, `press-ack.patch` and `struggle-dig-in.patch`). One of the six "readable poses" of the EP's taste brief: the grip in the bodies as five stages, with the leader setting his hips before a throw. It replaces the grip steps the UI is removing (nothing drawn on, over or between the fighters: docs/ep/taste.md).

## What was missing

The grip layer (`grip-layer.patch`, on main since b36f5fe6) mixes poses and solves each hand onto its region, but it waited for a read that nothing sent: only the tests called `on_hold`. Encounter's grapple (`sim/director/grapple.gd`, off in `interrupts.json` `grapple.enabled`) exposes the state (`DirGrapple.now`: mode tell or clinch, role catcher or caught, `grip` the grade this fighter holds, -2 to 2) and the cues `grapple_pummel` and `grapple_end`. This patch is the feed, and the two poses the top of each end needed.

## The five stages

The contest has five steps: two behind, one behind, even, one ahead, two ahead. The bodies show them:

| Grip | What the body does |
| :--- | :--- |
| **the tell** (a catch reaching) | the catcher reaches for the collar (`cl.hold.tie_reach`); the caught shows nothing, because a blow can still beat the grab |
| **even** | the tie-up seat (`cl.hold.seat`): a hand at the collar, the other at the elbow, the heads apart |
| **one ahead / one behind** | the seat mixed half toward `ahead` (the weight forward, the shoulders over the hands) or `behind` (on the heels, pushed back) |
| **two ahead: the leader sets his hips** | `ahead` in full, and `cs.hold.set` mixed in over it: sunk and wide under the other's weight, the feet set to lift or turn him. **The throw can only come from here** (Game Design's grapple.md), so it reads as a warning |
| **two behind: the cave** | `behind` in full, and `cs.hold.cave`: up on the heels, the shoulders rolled back, the head back, the hands holding on as he is walked back |
| **a pummel** | the free hand swims in under the other arm over the seat (`cl.hold.pummel_l`, `_r`, the hand alternating), in over 4 ticks, held 3, out over 6 |
| **the end** | the hold lets go over 10 ticks as the throw, the push-off or the parting plays |

The grade the sim gives moves a step at a time and the bodies ease to it over 12 ticks a step, so they walk from one stage to the next; a kind that changes (the reach into the tie-up) crossfades over 10. Ramps are 10 or 12 ticks, not 6, because the snappy profile solves on twos and a short ramp reads as a snap. In measure on a 34-unit pair: the leader's hips sink 1 unit at one ahead and 4 at two ahead against the even stand, the one behind rises 2; no pelvis moves more than 2.5 units in a tick through the reach, the steps, the pummel and the end.

## Files

`render/anim/tools/waves/cl2.mjs` (wave `cl2`, prefix `cs`, 2 poses, held lint class `rest`), `data/anim/grip_feed.json` (new key set: **Tools' closed schema needs an entry**, below), `render/anim/anim_data.gd`, `render_anim.gd` (the cue `grapple_pummel`, the switch), `anim_fighter.gd` (`_hold_feed` reading `DirGrapple`, `_feed_from`, `on_grip_pummel`, the layer's crossfade, eased grade, set, cave and pummel; a fed hold's release), `tools/anim_check.gd` (`_test_grip_feed`), `tools/flurry_study.gd` (scenario `gp_stages`; `window.__nogf = 1` is the before; with `window.__near = 1; window.__offset = -26` the pair is 34 apart). `RenderAnim.grip_feed`, `--no-grip-feed`.

With the grapple off (as shipped) there is no read and nothing plays: the feed is inert until Encounter's switch is on.

## Tests and gates

`_test_grip_feed`: the caught shows nothing in the tell, the leader's hips go down a stage at a time (even, one ahead, set) and the one behind rises, the hands stay within 4 units of their regions (3 is the budget; the top stage reads 3.63 and the shortfall is counted, never drawn through a limit), no pelvis moves more than 2.5 units in a tick, the hold lets go to the stand, no NaN, no joint past a limit, the sim's position never moves. Gates on a scratch export of main with the three parks above applied: `anim_check` with no arguments, the scans `--strict`, the 4-body scans, determinism plain and `--intro`.

## The schema request (Tools)

`data/anim/grip_feed.json`, schema `anim.grip_feed/1`, closed except `_` keys, all required: `grade_ticks`, `kind_ticks`, `release_ticks`, `throw_release_ticks` (integers 1 to 30); `pummel`: `in_ticks`, `hold_ticks`, `out_ticks` (integers 0 to 30), `w` (number 0 to 1); `set_pose`, `cave_pose` (pose ids, `cs.hold.<name>`); `grips`: `reach` and `tie`, each an object of hand (`hand_r`, `hand_l`) to a region of `data/anim/sockets.json`. Cross-references: both poses exist in a wave, every region exists.

## The throws (second patch: `grip-throws.patch`, after `grip-stages.patch`)

The end of the grapple as a throw. Encounter's cue `grapple_end` (text `throw_across`, `thrown_up`, `thrown_down` or `reversal`; the actor is the thrower) plays the thrower's own side of the throw from `data/anim/throws.json` and the wave `pair3` (prefix `zq`, built in C1): `across_toward` `hurl` (the Protagonist) or `sling` (the Anti-hero), `across_away` `turn_throw` or `back_throw` (a send that went behind him, read from the other body's velocity against the line), `down` `drive_down` or `spike`, `up` `lift` or `jolt`; a reversal is the reverser's throw across. The sim has already sent the other body on that tick, so the sequence is started so that its release lands on it (`t0` earlier by the load), and the set the hold was in stands behind it, fading with the hold, which lets go over 6 ticks (`throw_release_ticks`) with its hands no longer chasing the body that has left. The thrown body is the sim's and the ragdoll's. The push-off, the time and a lapse are not throws and play nothing. `RenderAnim.grip_feed` switches it with the feed; `data/anim/throws.json` and the wave `pair3` now load with it (they were tools-only before). `_test_grip_throw`: both fighters, all four sends and the send past him, clean, ending on the stand, no pelvis moving over 8 units in a tick (a throw is a quick blow, and the snappy profile solves on twos). `homework/grip-stages/grip-throws-before-after.gif`: the leader sets his hips, then lifts, drives down and sends across (the study does not throw the other body, so he is not drawn after the release).

## Not done

The pin, the carry and the brace of the other holds wait for the sim to send those kinds, and the feed needs the grapple switched on (`interrupts.json` `grapple.enabled`) to be watched in play: I have only watched it in the study, with the read sent by hand.
