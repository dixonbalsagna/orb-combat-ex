# Is the phone control scheme feasible? (for Orb)

Controls, 2026-10-23, for the EP's brief on Orb's standing worry. Paper only; nothing is built or changed here. Everything below was read from the code and docs on main today (`sim/input/touch.gd`, `data/input/layouts.json`, `input-scheme.md` section 6, `phone-touch.md`), except where it says **not measured**: nobody has played this on a real phone and measured it. That is the honest gap, and section 4 closes it in five minutes.

**Short answer.** The scheme is sound on paper for what a phone player does most (fly, attack, guard, dodge, charge) and it is built so that one thumb does little. Four things are real risks on a glass screen: **the right thumb has four buttons and sometimes needs two fingers; attack waits for the finger to lift; there is no air brake on a phone yet; and there is no feel for a press until the blow lands.** None is fatal. Two cheap changes (section 5) take most of the risk out.

## 1. What the touch layout does today

**Simple touch** (the phone default, landscape only, Orb's ruling; mirrored for left-handed):

| Where | Control | What it does |
| :--- | :--- | :--- |
| Left 42% of the screen, lower 70% | **Floating move stick** (appears under the left thumb, 56 dp radius) | drag flies; a fast flick is the dodge; holding past the outer ring sprints |
| Right thumb's rest point | **Attack** (88 dp) | tap = light, hold = the heavier blows (the weight is the length of the hold), swipe up = signature |
| Left of Attack | **Guard** (72 dp) | hold to guard; a timed tap is a perfect block |
| Above Attack | **Power** (72 dp) | hold to charge; with Power held, a tap on Attack is the director's chosen special |
| Up-left of Attack | **Context / Transform** (64 dp, only when something is available) | tap, or hold 30 ticks to transform |

The director owns the rest for a Simple player: the mode (energy or not), the burst, which special, the combos. The player owns when and where. **Full touch** (nine buttons) exists for tablets and fits a phone only at the 48 dp floor, so it is a setting, not the default. Palm rejection is 8 dp at the screen edge; the layout needs at least four simultaneous touches. 1 dp is about 0.16 mm, so Attack is about 14 mm across, the smaller buttons about 11 mm, and no hit target is under 7.7 mm.

## 2. What is risky on a phone

| Risk | What could go wrong | How bad, and what is known |
| :--- | :--- | :--- |
| **Thumb reach** | Guard (3.2 cm in from the right edge) and Power (3.2 cm up) are the far buttons; a small hand or a phone case may not reach them without re-gripping | Moderate. All four sit within roughly a thumb's arc and none overlaps another (checked on five phone sizes), but reach is a hand, not a layout. **Not measured.** |
| **Simultaneous presses** | Guard and Attack are 1.7 cm apart, so one thumb cannot hold Guard and tap Attack: it needs the index finger on the right as well. The same for Power + Attack (the special) | **The biggest design risk.** Move + attack works (two thumbs). Guard-while-attacking and charge-while-attacking need a second right-hand finger, which a phone grip does not give you comfortably |
| **Stances** | A phone has no stance buttons, so this is mostly *fine*: the stance follows what is held (Guard = defensive, a flick = evasive, charge = charging) | Low. The cost: the only defensive input is a held button on the crowded side |
| **Held charges** | Power and the heavy blows are holds. A thumb that drifts, or lifts for a moment, ends the charge | Moderate. There is a latched-charge setting that turns every hold into press-on, press-off, but it is a hub setting and I have not checked that the touch options screen exposes it |
| **The air brake** | Brake is the Manoeuvre hold on a pad; on Simple touch it is Guard held while sent, but that is **switched off and its host line is not applied**, so a launched phone player cannot brake at all today | A real gap for the "never out of reach" feel. It is already built behind a switch (`airBrakeGuard`) |
| **Attack waits for the lift** | A tap cannot be told from the start of a hold until the finger lifts, so the light goes out on the release, 3 to 12 ticks (50 to 200 ms) after the touch | Real and **measured in the sim** (`phone-touch.md`). The pad's light is on the press. After Encounter's press-tick fix the sim is now fast, so this wait is the biggest remaining delay on a phone |
| **No press feedback** | With the blow late, nothing moves on the fighter at touch-down | Moderate. UI can show a pressed state at once; the fighter's anticipation is not built |
| **Flick read as dodge** | A quick deliberate push on the stick can read as a flick (a dodge, or a brawl-ending dodge-cancel) | Low to moderate, from `phone-touch.md` section 4; a stricter flick is a data change |

## 3. What the game already does that helps

- **You do not do combos.** One tap is one attack; the director composes the exchange, closes the gap ("never out of range") and carries the string. A phone player never has to hit a precise sequence.
- **Presses are remembered.** A press made while the last blow is still going joins a queue of three that waits 36 ticks, so an early tap is not lost. Mashing is welcome.
- **Every press is acknowledged.** The brawl sends a press-ack for each press (queued, refused, lapsed, empty), which UI shows on the HUD, so a tap that did nothing says why. With Encounter's 7a (in progress) the acknowledgement and the start both land on the press tick.
- **The touch assists are already in:** the perfect-block window gets +2 ticks on touch, the director picks the mode, the burst and the special (Simple), and a touch near the screen edge is ignored.
- **Rumble and phones:** Android phones get short vibrations for the cues; iOS Safari has none, so nothing depends on it.

## 4. A five-minute test for Orb, on their own phone

Open the demo link from `phone-test-checklist.md` in landscape. Start a fight and play it for a minute first. Then, one line each:

| # | Do this (time) | Good if | If not, it means |
| :--- | :--- | :--- | :--- |
| 1 | **Reach (30 s).** Without moving your grip, touch the stick area, then Attack, Guard, Power, Context in turn | every one reached without re-gripping | a button is too far for your hand: move the anchors in (the cheapest fix) |
| 2 | **Fly and strike (45 s).** Fly in circles with the left thumb and tap Attack ten times | no stick jump, at least 9 of 10 taps land | the stick or Attack is losing touches: an arbitration or hit-target bug, not a design problem |
| 3 | **Guard and strike (45 s).** Hold Guard with a second right-hand finger and tap Attack with the thumb | you can do it without covering the fighters or dropping Guard | guard-while-attacking is not practical: the one-handed guard change (section 5) matters more than anything |
| 4 | **Charge while flying (45 s).** Hold Power for three seconds while flying | the CHARGE bar fills and holds | holds are unreliable on glass: the latched charge setting (or an auto-latch) is needed |
| 5 | **Does it feel instant? (60 s).** Tap Attack ten times and a quick tap-and-hold; say "instant", "a little late" or "clearly late" for each | tap "instant" or "a little late" | "clearly late" is the release wait: the second change in section 5, not the engine |
| 6 | **Hands and eyes (60 s).** Play a full minute | your thumbs do not hide the fighters, nothing cramps, nothing fires by accident | the layout is too big or crowded: shrink or move buttons, or switch the Full preset's size |
| 7 | **Getting thrown (30 s).** Let the computer launch you across the screen and try to stop yourself | you can read what happened | expected: you cannot brake on a phone yet (section 2). Note whether it *matters* to you |

Write down the phone model, the grip you used, and one word per row (good, awkward, bad). Rows 3 and 5 decide the changes below.

## 5. The one or two changes I would make first

1. **Give the light its own button, or at least a pressed response on touch-down.** Splitting Attack into a **Light** button (fires on the press, like the pad) and a second button for the heavier blows makes touch meet the same-tick rule the pad and keyboard now meet, and frees the thumb from deciding by hold length. If a second button costs too much room (at 667 x 320 it does), the free alternative is the fighter's anticipation on touch-down (Encounter's and Animation's, no input change) plus UI's pressed state. This is a layout decision for Orb. Row 5 of the test says which.
2. **Make Guard one-handed.** Either turn on the already-built `airBrakeGuard` (Guard held while sent is the brake: one switch and one host line, `docs/controls/sent-host.patch`) and give Guard a *toggle* option (tap to guard, tap to drop) so the right thumb is free to attack, or move Guard to the left thumb's side (the stick's lower edge) as a held button. The toggle is the smaller change. Row 3 and row 7 say which.

What I would **not** change yet: the stances (a phone needs none), the combos (the director's), or the Full preset (keep it for tablets).
