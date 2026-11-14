# Parked: the travel budget's cut on a beam's rise goes where the rise ends

Camera, 2026-11-07, for the EP's brief: World's `beam-grid` made split_sweep fail at "real match 3 pitch 49 full: fighter 1 has been out of its pane for 1.20 s". **It's a camera fault that the new fight path exposed, not an impossible state from beam-grid.**

**Apply on main** (cut on d5582dbd; `git apply --check --cached` passes on 7e74b8e9): `git -c core.autocrlf=false apply travel-point.patch` (sha1 48ac1b90). One file, `render/camera/split_rig.gd`, all mine.

## What happened

- beam-grid changes which buildings fall, so match 3 runs differently from about 5 minutes in.
- At t = 345.6 s fighter 1 is flying flat out at about 8,000 units a second, faster than the travel budget lets his pane follow (0.045 of the width a tick). He leaves his pane.
- After `TRAVEL_WAIT` (0.6 s) the budget cuts to him (346.23).
- On that same tick he starts a signature from 63,000 units away. `DirBeam.opBeamCharge` is a point rush up to the rival's height, 4,900 units in about half a second. He is out of the pane again at once.
- `TRAVEL_COOL` holds the next cut for a second, so he's out from 345.65 to 346.85. The limit is 1.2 s.
- At pitch 49 it is worse: the pane's camera stands only about 1,400 units above its aim, so a body rising past that can't be seen at all.
- Flat, the same match keeps him nearly in, and passes.

**Why it's legitimate:** a beam fired at any distance, and the shooter rising to the rival's height before it, are the rules as written (beam plays). The state is one play can reach.

**The fix:** when the budget's safety cut lands on a pane's fighter who is on a point rush (no fighter target, still running), the cut goes to where the rush ends. The rush pin then holds the pane there until it ends, as it already does for a rush at a fighter. He rises into a still frame from below, and the cut is the budget's own `travel_safety`, so no new cut and nothing new for the flash count.

## Scope

**The travel budget is off in the shipped game** (`travel_budget = false`). Only split_sweep (its default) and the flash capture's `budget=1` turn it on. So this never reached play; it keeps the sweep honest. With the budget off, the patch changes nothing.

## Proof

| Run | Result |
| :--- | :--- |
| split_sweep, main + beam-grid + this | **passes** (fails without this) |
| split_sweep, main + this | passes |
| clip_digest, main before and after | byte-identical |
| The match itself (pitch 49 and flat, beam-grid on) | 0 fails. The cut at 346.23 lands at the rise's end (pane y 4,945, fighter rising from 683), and he enters the frame by 346.55 |

## Not done

- `_rush_far`, which decides the rush pin for a rush at a fighter, measures along the line only. A mostly vertical rush at a fighter is never pinned. Nothing fails on it today, so it is noted here rather than changed.
