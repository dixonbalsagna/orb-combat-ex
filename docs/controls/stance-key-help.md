# Stances on touch, and the specials: answers for the key-help legend

Controls, 2026-10-05, answering UI's two questions from `docs/ui/key-help-plan.md`. Built and tested in `sim/input` (`layout.gd`, `touch.gd`, `stance_test.gd`); the scheme itself is `lunge-control.md` Part A.

## 1. Full touch: the stance buttons, the labels and what a tap does

**It is four buttons, not two.** Full touch has one button for each shoulder stance, and **all four arm on a tap** (the one-shot is on by default there, because one thumb cannot hold a stance and fly):

| Widget id (`FULL_LAND` / `FULL_PORT` in `touch.gd`) | Pad equivalent | Stance (`stanceMask` bit) | A tap | A hold (12 ticks or more) |
| :--- | :--- | :--- | :--- | :--- |
| `guard` | LB | defensive (1) | **arms** it for the next blow | true hold: the stance while the finger is down |
| `mode` | RB | energy (2) | **latches** it (tap again to unlatch) | true hold: momentary, back to martial on release |
| `power` | RT | charging (4) | **arms** it for the next blow; it is also the `powerTap` burst when he is not threatened | true hold: the channel, the stance while the finger is down |
| `dodge` | LT | manoeuvre (8) | **arms** it for the next blow; the dodge still fires on the press itself | true hold: the stance while down, a sprint after 12 ticks |

The labels are UI's to choose; the data ids above are what the layout calls them (`data/input/layouts.json`, the `touch-full` preset). Mode is the one that is not a one-shot: its latch **is** the arming (the hybrid style: a tap latches, a hold is momentary), so a blow does not spend it and the second tap puts it away. I removed a stacking of the two in this window (a second tap used to unlatch energy and then arm it again for one blow).

**What "arm" means:** the stance applies to the next blow (the next light, heavy, signature, context or special press), then it is spent. It also lapses unspent after **90 ticks (1.5 s)**, and a second tap on the same button cancels it. A hold is never armed: it is only the stance while the finger is down. A player can switch the arming off (an accessibility setting, per player); then a tap does nothing but its own action (the dodge, the burst, the latch) and only a hold makes a stance. One thing for the legend: **an armed stance is not a latch**; it is "next blow only", and the state to show is the armed one until the blow or the 90 ticks.

**Simple touch (not Full) has no arming.** Its stances are holds only: **Guard** (defensive), **Power** (charging; a tap is the burst), and **the stick's outer ring** (manoeuvre and the sprint). Energy is the director's on Simple (`mode` -1), so there is no Mode button. The face moves are the attack button and the signature swipe; the director picks the stance for a blow unless a button is held.

## 2. The power layer is the charging stance, and the specials

**Yes: the old power layer is now exactly the charging stance, so the Specials row can go, with one caveat below.** A special is reached **only** as "the charging stance, then a face button". The layer is the stance: **held** (RT down) or, since this window, **armed** (a tap on RT with the one-shot on: the next face press is the special, not a light). Before this window an armed charging stance made the mask 4 but the face press was still a plain blow; that was a bug, fixed with a test in `stance_test.gd`.

Every layout, with the charging stance written as RT:

| Layout | RT + X | RT + Y | RT + A or its cell | RT + B |
| :--- | :--- | :--- | :--- | :--- |
| Arena (pad) | special 1 | special 2 | special 3 (the utility one) | the signature, **the ultimate** (hold 45 ticks) |
| Keyboards (solo, shared P1, P2) | special 1 | special 2 | special 3 | the signature (the ultimate) |
| Touch Full | special 1 | special 2 | special 3 | the signature (the ultimate) |
| Simple (pad) | **special auto** (the director picks one of the three) | the signature (the ultimate) | **RT + LB is the utility special** (special 3; Simple's LB is its A) | (no B: Y is the signature) |
| Simple (touch) | **special auto** (Power held and the attack button) | the signature swipe | **none** | none |

So no special is reached any other way on any layout. Two things the legend should still show because they are not "RT then a face button" in the same way:

1. **The ultimate** is B in the charging stance, held 45 ticks. It is a signature, not a numbered special, and sits in the same cell; the row for B in the charging stance can say "Ultimate (hold)".
2. **Touch Simple has no utility special** (special 3). It reaches only special auto (the director's pick, which may be the utility one). If UI wants all three kinds reachable on touch Simple, that is a layout change for Orb to approve (a context button under Power would do it); I have not made it.

## 3. For the sim readers

`stanceMask` is the one truth for "which stance": an armed stance is in the mask (including armed charging), and `special` is nonzero only on the tick a special is pressed. Encounter should read the mask, not `guard`, `power` or `special`, to know the stance.

## 4. Full touch under the nameplates: `top_limit`

`SimTouch.layout(vw, vh, dp, portrait, left_handed, margin, full, top_limit)` takes an optional **`top_limit`**, in pixels from the top of the screen (Full only; -1, the default, is none). UI passes its plates' lower edge, and the host passes the same value to the same call so the hit test uses the same circles. With no limit, or when the preset already clears it, **nothing changes** (tested against the old offsets at 15 sizes, both hands). Otherwise the vertical offsets and the radii scale together, in 1% steps, to the largest scale that keeps every button's top edge at or under the limit, no radius under 24 dp (the 48 dp target), no two buttons closer than the 2 dp gap and none past the bottom corner; the stick zone also starts no higher than the limit. At 1560 x 720, density 2, limit 213 px: radii 32 to 29 dp, DODGE's top 168 to 217 px, POWER's 172 to 221, ENERGY's 176 to 224. A screen too short for any fit gets the tightest layout (50%), still at the radius floor. The hit radius stays the drawn radius plus 8 dp, as before; UI's plates take their own touches first.

## Status of `lunge-control.md`

It is ready to commit: the intent version 4 build note, the zip-away re-rule (35 and 40 ki, 4 and 6 tick tells, the counter marks) and the hold-key correction are in, and nothing in it is pending. This file and the `layout.gd` and `stance_test.gd` edits are new in the tree and also ready.
