# Throwables: Animation's figure (2026-10-18)

Owner: Animation. **Paper only.** Combat's ask (`docs/combat/throwable-cars.md` §3, §4): the figure for the nine poses a fighter, and whether the huge lift's two steps read at fight speed. Counts are poses, code slices and scan classes, as in `clinch-sizing.md`.

## 1. The figure: 21 poses a fighter, not 9

Combat counts one pose a piece. A piece is a short motion with a held body, and each needs its own beats. What I would pose a fighter, for the pieces in Combat's table:

| Piece | Beats (poses) | A fighter |
| :--- | :--- | ---: |
| The lift, light (a bike) | the reach (a hand under the frame), the swing up to the shoulder | 2 |
| The lift, heavy (a sedan, a van) | the grip (knees bent, hands or the plate under the chassis), the stand | 2 |
| The lift, huge (a bus, a ship) | the grip at the middle, the first step (chest height), the second (overhead or on the shoulder) | 3 |
| The hold | at the shoulder, and overhead or out on the plate | 2 |
| The toss (X) | the load, the release | 2 |
| The throw (Y) | the load, the turn, the release | 3 |
| The slam (B) | the raise, the bring-down, the follow | 3 |
| The catch | the receive, the give, the held | 3 |
| The swat | the palm or plate set on it, the follow | 2 |
| **Total** | | **22** |

One piece is shared: the light lift's swing up is the hold's shoulder pose, so **21 authored poses a fighter**, 42 for the two. At the bake's habit (wave 1 authored 23 poses and the pack made 117) the in-betweens come from the generator and the follow-through blends, not from more authoring.

- **Per fighter, as Combat's table has it:** the Protagonist's are open hands and turns (his throw is a full turn and a release); the Anti-hero's are the forearm plate and straight lines (his catch stops dead on the plate, with no give). The two sets share no pose, since the grip and the line differ in every piece, so there is no shared wave here as there is for the clinch.
- **Not counted:** the object (a prop body, Simulation's and World's), its wreck (Art), the catch's reuse of the perfect-block pose (it is the pose's start, then the receive).

## 2. What the code needs (four slices, one new scan class)

1. **T1, a grip on a prop.** The clinch's grip layer (C2) puts a hand on a *region of a fighter's body*. A prop has no regions: it needs **hold points** (a slot name to a point in the prop's own frame: `frame`, `underside_l`, `underside_r`, `top`, `end_a`, `end_b`) in World's prop data, read as a world point the way `_region_point` reads one. The same layer, a second kind of target. Needs from World: the hold points per object class, and the prop's position and turn every tick (a view read).
2. **T2, the lift follows the object.** The lift's pose weight comes from the object's own height off the ground (it is the sim's), so the two steps of the huge lift are the object rising past two heights, never a timer. Needs: the object's `y` and `hold` state in a read.
3. **T3, the release on the sim's tick.** The toss, the throw and the slam release on the tick the sim sends the object (an event with the object, the tick and the direction), and the arm follows through along that direction.
4. **T4, the catch.** The perfect block's pose then the receive: the hands meet the object at its contact point and give with it (the Protagonist) or stop (the Anti-hero). Reads the object's velocity at the catch.
5. **The scans:** `prop_clear` (the bone capsules of the fighter against the object's box: no interpenetration except at a hold point) joins `grip_gap` and the other six classes of `clinch-sizing.md` §5.

## 3. Joint limits

- **The overhead hold is the hard one:** both arms at about 170 degrees of shoulder swing, where the limit is 175 and the twist range narrows to the straight-arm band. I would pose it at 150 with the elbows bent and let the object sit on the hands, not above a straight-armed reach. The lift's end poses are scanned at the arm's limit like any pose.
- **The plate under a chassis** (the Anti-hero's lift) needs a forearm turned palm-up (supination) of about 80 degrees, under the 100 of the shoulder's twist range; the grip's wrist twist is the new check (`grip_twist`).
- **The held object is not a limit problem** for the body; it is a clearance one (T5).

## 4. Does the huge lift's two steps read at fight speed?

At 60 ticks a second, a pose reads when it holds about 8 ticks. The huge lift as two clean steps (the grip, chest height, overhead) needs **at least 30 ticks** from the grip to the held (about 8 for the grip, 10 for each step) and reads. Under 24 ticks the first step blurs into the second and it reads as one heave. So: **ask Combat for 30 to 36 ticks for the huge lift** (a tier-2 bus, a tier-3 ship), 18 to 24 for the heavy and 12 for the light. The sim can still let the fighter fly with it: the hold is a pose, not a stance.

## 5. Legal and the rest

- **Legal:** the object drawn whole and in view every tick (g03 by analogy: no hand or arm in front of the object may hide most of it); no person in it (Combat and Art already say so). Combat has asked for a row.
- **Order:** T1 follows the clinch's C2 (same layer), so the first slice here is the poses (21 a fighter) and the hold-point data; the layer is shared work.
- **What I can do before World and Simulation have a prop:** the 42 poses, the hold-point names, and a scripted test with a fake prop (a box moved by the scan), as the chain and the throws do.
