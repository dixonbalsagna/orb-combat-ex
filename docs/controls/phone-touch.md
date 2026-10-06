# Simple touch on a phone: what it measures, what a phone player feels, and the plan

Controls, 2026-10-06, for a friend's play notes from an iPhone (`docs/ep/vision.md`, "A friend's feedback from the mobile build"). Orb ruled phones **landscape only**. Whole ticks at 60 a second. Nothing here changes a file; the held files stay held.

## 1. Measurements: finger down to the intent's edge to the blow's contact

**Method.** A scripted finger through the real hub and `SimTouch` (Simple, the same call the host makes), into a live match against a rival that stands still, on the **live (HEAD) director**, with a brawl running or, for "fresh", no exchange (the first press from the close band). "Down" is the touch tick; "edge" is the tick the intent first carries the request; "contact" is the first damage to the rival. The browser and the phone are **not** in these numbers (below).

| Press (Simple touch, live director) | Down to edge | Edge to contact | **Down to contact** |
| :--- | ---: | ---: | ---: |
| Attack tap, finger down 3 ticks | 3 | 2 | **5** |
| Attack tap, 5 ticks | 5 | 2 | **7** |
| Attack tap, 8 ticks | 8 | 2 | **10** |
| Attack tap, 11 ticks | 11 | 2 | **13** |
| Attack tap, first press from rest (5 ticks) | 5 | 2 (the brawl starts on the edge) | **7** |
| Attack held (the heavy at the hold start) | 11 | 34 | **45** |
| Swipe up on Attack (signature), the swipe made 3 ticks in | 3 | 47 to the beam's fire, 67 to its hit | **70** |
| Power held, then Attack tap (`special_auto`) | 0 | no move reads it | **none** |
| For comparison, the pad's X | 0 | 2 | **2** |

**Where the delay is.**
1. **The touch layer (mine), and it is the biggest share.** A tap on Attack cannot be told from the start of a hold at the touch, so the light is sent **on the release**. A touch tap lasts 5 to 12 ticks, so the light starts 3 to 11 ticks late (50 to 180 ms), against 0 on a pad. The same is true of the layer press: with Power held, a tap on Attack is the director's special, and from today's plan it is decided on the release too.
2. **The old director adds almost nothing.** A light's contact is 2 ticks after its edge. Its queue only holds a press made while his own blow is still going, for up to 10 ticks (`heldPressTicks`). In an open brawl nothing was queued in these runs. So "like I'm queuing up moves" is the release-wait plus a body that shows nothing until the light is thrown.
3. **The browser and the phone (unmeasured).** From the code: an input event reaches the next fixed tick (0 to 1 ticks, about half on average), the sim runs, the frame is drawn and shown (about 1 to 2 more frames). iOS Safari delivers touch events at once (no 300 ms click delay). I have no phone and cannot measure the display path here. A fair measurement is a timestamped touch through the browser's own tools (CDP `Input.dispatchTouchEvent`) to the first changed pixel, which gives the web build's share but not the phone's screen; a high-speed camera on a real phone gives all of it. I would ask QA.

**On my tree (held) with today's director:** a hold released at 14 gives the medium edge at 14 and a heavy exchange at 48; released at 20, contact at 54; held past 28 it fires a `signature` edge, which on the old director is the 45 ki beam (the reason the commit is held for C2a).

## 2. What the phone player will feel with the three strengths (C2a)

- **Attack tap:** the light on the release, so tap length plus 2 (5 to 13 ticks from the touch). Unchanged from now.
- **Attack held:** the medium when let go at 12 or more (lands 2 ticks after the release, about 14 from the touch if let go at 12); the heavy at 28 or more (about 30). The ring shows which weight the finger has reached.
- **The heavy as Y:** a swipe up on Attack. The swipe itself takes the thumb 4 to 10 ticks, then the 28-tick wind-up, so about 32 to 38 ticks from the touch; held, it is the charged heavy. With Power held it is RT + Y, the signature's hold.
- **A modelled cost of deciding by hold length:** with a medium from 12 ticks and no grace, **3.66% of modelled touch taps (5 to 12 ticks, 3% lingering) read as a medium**, and 0.11% on a pad. A start of 16 would make that 2.03%. (Modelled lengths, not measured: QA's replace them.)

**Can any Simple touch press answer on the same frame? The blow cannot; something else can.**
- **The blow:** a contact is 2 ticks after its edge even on a pad. On touch the edge waits for the release because Attack carries three weights on one button. The only ways to a same-frame light are to fire it **on touch-down** (then a hold can only be a second blow, which breaks "one press, one attack"), or to give the light **its own button** (a second right-hand button for the slow strengths: Attack for the light, Heavy for the wind-ups). The second is the honest fix and a layout decision for Orb.
- **The answer that costs nothing:** on the touch's own tick the intent already carries **`lightHeld`**, so the director can begin a short **anticipation** in the fighter on touch-down (a gather of two or three frames that resolves into the light on a quick release or deepens into the wind-up on a hold). It needs no new intent field and no change here; it is Encounter's and Animation's. UI can add a pressed state and the ring at once. A haptic tick is not available on iOS Safari (no vibration API).
- **My recommendation:** the anticipation now (free), and the two-button attack as an option for Orb.

## 3. Mines

**A phone player cannot lay a mine today, and neither can a Simple pad player.** A mine needs a **context edge** with the **energy mode on** (`DirBlast.context`: outside an exchange, `f.act.mode == 1`). On Simple touch the fourth slot is Transform, so no `context` edge exists; and Simple sends `mode = -1` (the director's), which leaves `act.mode` at 0, so even a context edge would not lay one.
- **Smallest honest mapping:** a **tap on the Transform button is Context** (a hold of 30 ticks stays Transform, as now); the edge is sent on the release (a tap under 30 ticks), which is the same release-wait as Attack but fine for a mine, a shove or a taunt. And for a Simple slot the director treats **Context outside reach as "lay a mine"**, with no energy mode needed, since Simple has no RB. That second rule is Encounter's and Game Design's (and the same on the Simple pad's LB).
- **What UI must teach:** the Transform button's label **"TAP: MINE / HOLD: TRANSFORM"** on a phone (with the legend's "Context" line), and a first-fight hint when the player has not used it.
- **Safe on the live build?** The context edge with nothing held does nothing today, with Guard held it is the context deflect or the reversal, so adding the tap is safe. It is held with the other files.

## 4. The stick's nudge, and the flick

- **What a touch stick gives the nudge.** The floating stick has a radius of 56 dp, a dead zone of 0.2, and gives `mx`, `my` as the drag over the radius, 1.0 beyond it. `nudge_ramp` caps the rise at 7/127 a tick from 0.4, so full in 11 ticks. A thumb usually reaches full in 6 to 12 ticks, so the ramp only softens the first few ticks of a fast push. A gentle drag passes through unchanged.
- **Can the flick-to-dodge be misread as a nudge, or the reverse? The reverse is real.** A drag of 0.7 of the radius (39 dp) within 6 ticks of touching down is a flick: a `dodge` edge and a 12-tick dash, and in a brawl a dodge edge is the dodge-cancel (15 ki, the brawl ends). **A deliberate nudge begun with a quick push (39 dp in 100 ms, 6.5 dp a tick) is read as a flick**, which is plausibly "the player flies back" or leaves the brawl by accident. The flick read as a nudge is harmless: it holds full deflection for 12 ticks, which the nudge would ease over 11, and the dodge-cancel normally ends the brawl anyway; if it is refused (no ki) the dash direction nudges the pair for 12 ticks, which Encounter can avoid by ignoring the stick while the intent's `dash` is on.
- **The fix, if it shows:** a stricter flick: `touch.flickToDodgeTicks` 6 to 4 and `touch.flickThreshold` 0.7 to 0.85 (data), so only a fast, long flick is a dodge. That is a feel change with no tests with players behind it; I would try it with Orb before shipping.
- **"Flies back to the enemy":** that is the brawl's magnet (`pullBhPerSec`), which today's C1 lets a stick nudge and both players walk out of. It is Encounter's; the stick supplies the nudge.

## 5. Sizes, and Full touch on a phone

Checked with `SimTouch.layout` (Simple, 4 buttons and the move zone) and the Full preset with `top_limit` set to 30% of the height (a proxy for UI's plates), at dp 1:

| Screen | Simple: buttons | Simple: move zone | Full: fit |
| :--- | :--- | :--- | :--- |
| 844 x 390 | on screen, none overlap, radii 32 to 44 dp, top edge 142 px | left 354 px, from y 117 | fits, smallest radius 27 dp, top edge 118 px |
| 844 x 340 (Safari bars) | same, top edge 92 px | from y 102 | fits at the 24 dp floor (48 dp targets) |
| 667 x 375 | same, top edge 127 px | left 280 px, from y 112 | fits, 26 dp |
| 667 x 320 (bars) | same, top edge 72 px | from y 96 | fits at the 24 dp floor |
| 932 x 430, 852 x 393 | same | same shape | fits, 27 to 28 dp |

- **Simple is landscape-sound at every phone size:** all four buttons on screen, none overlap, none under 48 dp, the move zone 29% of the screen. All four sit on the right because **the left thumb owns the floating move stick**: the friend's "thumbs on each side" is already the layout (left thumb moves, right thumb acts). The left-handed setting mirrors it.
- **Full on a phone is possible but tight:** it fits at every size above (with the fit that scales the rows), but at the short sizes every button is at the 48 dp floor and nine buttons for one thumb is a lot. **Simple should be the phone default** (UI to choose by size, with Full as a setting).
- **The panels' side** does not matter to the touch layout; it depends on the screen size and the handedness only.

## 6. The move stick was found by accident

- **Hit area:** any touch in the left 42% of the width and below 30% of the height that is not on a button is the stick (a large target: 354 by 273 px at 844 x 390). It is **invisible until touched** (a floating stick), which is why it was found by accident; that is by design for the pad's feel but is a discoverability fault.
- **What UI should do (not mine):** an idle ring at the zone's lower left with "MOVE" and "flick to dodge" inside it at phone size (the screenshot has the words), kept on screen, brighter for the first fight, and a hint line on the first touch of the left side. The input layer gives UI the zone rectangle (`SimTouch.layout(...)["stick"]`) to draw against and the stick's state in `display_state()["stick"]`.

## Plan, and what is safe on the live build

**Safe now, small, live-visible (held with the other files):** the Transform tap as Context (section 3); `touch.flickToDodgeTicks` 4 and `flickThreshold` 0.85 (section 4), after Orb tries it.
**With C2a:** the anticipation on `lightHeld` (Encounter and Animation); the director's Context-outside-reach-is-a-mine rule for a Simple slot; the medium start (12 or 16) for Simple touch, decided against the 3.66% figure.
**For Orb:** a two-button attack on touch (Attack for the light, Heavy for the rest); Simple as the phone default; the stricter flick.
**For QA:** the web build's touch-to-pixel time through CDP, and measured tap lengths on a phone.
