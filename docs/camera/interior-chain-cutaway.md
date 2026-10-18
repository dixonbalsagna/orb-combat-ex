# The cutaway that follows a body inside a building chain (Camera, 2026-10-17, paper)

Owner: Camera and Cinematography. World's interior chain (docs/world/scratch-build/interior-chain, parked) puts a launched fighter inside a tower: `interior_contact {b, k, floor, kind, nx, ny, vn, stop, punch, ...}` for the face and each slab, `interior_end {b, end (lodge, exit, fall_out, capped), contacts, t}`, with `f.z` eased to the plane while he is inside, so Rendering draws him at depth 0 in front of the tower. Game Design's line (buildings.md 7.3): the camera cuts to the tower's cutaway or holds it from the street. The cutaway is Camera's request and Rendering's open floors. Nothing here can be built until the events are in main; this is the shot, ready to build then.

## 1. The shot

- **Hold from the street, never cut in.** While a chain runs (`interior_contact` k 0 to `interior_end`, at most 2.5 s of ragdolled time and the face's 15-tick stop), the camera keeps the framing it has and adds the tower to it: the focus eases (by a weight that moves at MANY_RATE a tick, as the many-body framing's does: no step) to the tower's centre column at the storey of the latest contact, and the zoom to the stage that puts the tower's near edges in with STAGE_MARGIN each side (the stage the building follow already sets, `_stage_set` and `_update_stage`). The body moves inside the picture; the picture does not cut to follow him. A cut into a tower is a whole-frame change, and Legal counts one a second whole-screen change after a blast.
- **The cutaway request.** `frame.cutaway[i]` for the pane that shows him: `{request: true, radius_px: the larger of 70 px and 1.6 times his drawn height, only: i}`, as today, but centred on the contact's storey and widened to the storey's height while he is inside (the hole is the open floors, Rendering's). It follows each contact (`interior_contact.k`) by easing 0.12 s, so the hole travels floor by floor with him and does not jump.
- **Depth.** The fighter is at depth 0, so no dolly: `focus_z` stays 0 for the pane (the building stays at its own depth and the body is in front of it, which is what the open floors show).
- **The end.** `lodge`: hold the stage 0.6 s (the lodge's hold), then ease back to the pair's framing at the ordinary rate. `exit` and `fall_out`: the launch rule takes over at the face he leaves by (his flight carries on: the existing hold-and-cut rule applies, under Reduce flashing as a dissolve). `capped`: as lodge.
- **Strips.** No strip opens while a chain runs (the inset and the cutaway are two answers to one question).

## 2. Reduce flashing and reduced motion

The hold needs no cut, so the only whole-frame change is the ordinary framing's. A slab that breaks sends a `punch` (a shake and a hit-stop the sim and Controls own); Camera adds nothing. Reduced motion: the focus eases at a quarter of the rate and the cutaway radius is fixed at its first value.

## 3. Rows (`split_sweep.gd`, synthetic events through `rig.step`)

| Row | Checks |
| :--- | :--- |
| `chain hold` | face, three slabs, lodge: no cut frame; the body inside the picture at every tick; the focus weight never moves over MANY_RATE a tick; the stage zoom within 5% of the building stage |
| `chain cutaway` | `cutaway[i].request` on the showing pane from the face to the end; its centre storey follows the contacts; no step over a quarter of a storey a tick |
| `chain exit` | `exit` hands over to the launch rule with one cut (or one dissolve under Reduce flashing), the body on screen throughout |
| `chain off` | with the switch off, frames equal a run without it to the bit |

## 4. What it needs

Simulation: the two events in `fx.gd` and `hash.gd` (World's grant). World: the tower's storey height and the contact's storey in the event (`floor` is there). Rendering: the open floors consume `cutaway[i]` with the storey centre (their side of the request exists). Build behind `SplitRig.interior_follow` (default off) once the events are applied.
