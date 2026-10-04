# Lunges and far approaches: what the attacker controls, what the defender can read

Owner: Controls and Game Feel. Date: 2026-10-04. **A note only: no code, no data.** Source: Orb's playtest line, "the combat lunges should be a bit more controllable and easier to spot when they're being used against you, right now an opponent flying from very far away at max speed is very hard to judge." Numbers are proposals for `data/director/interrupts.json` `bands` (Encounter's `sim/director/bands.gd`); VFX, Camera, Animation, Audio and UI get the visual side from the "What each director needs" table. Units: a body height (bh) is 75 units; a tick is 1/60 s; 4000 units a second is 66.7 units a tick, 0.89 bh a tick.

## What the data does today, and why a far flight is unreadable

`bands`: close within 3 bh, mid to 12.5 bh, far beyond (`closeBh`, `midBh`). A mid press is a **lunge** (4000 u/s, 3 to 20 ticks). A far press taps to taunt (45 ticks) or, held (8 ticks light, 16 heavy), becomes a **charge**: light 4000 u/s clamped to 18 to 60 ticks, heavy 3000 u/s clamped to 30 to 84 ticks. The flight ends 2.5 bh from the rival and the wind-up follows (15 ticks light, 20 heavy).

The clamp is the problem. Past the distance the speed can cover in the maximum time, the sim does not slow the flight, it **speeds it up to arrive in the maximum time**:

| Distance | Light charge today | Speed it flies at | Heavy charge today | Speed it flies at |
| ---: | ---: | ---: | ---: | ---: |
| 12 bh | 14 ticks, clamped up to 18 | 3 000 u/s | 30 ticks (the minimum) | 1 800 u/s |
| 40 bh | 45 ticks | 4 000 u/s | 60 ticks | 3 000 u/s |
| 53 bh | 60 ticks (the maximum) | 4 000 u/s | 80 ticks | 3 000 u/s |
| 100 bh | 60 ticks | **7 500 u/s** | 84 ticks | 5 400 u/s |
| 200 bh | 60 ticks | **15 000 u/s** | 84 ticks | **10 700 u/s** |
| 600 bh (a 99th percentile exchange, slice 2) | 60 ticks | **45 000 u/s** | 84 ticks | **32 100 u/s** |

So a charge from across a planet crosses it in one second at up to eleven times its nominal speed. The defender cannot read how long it will take, the closing rate changes with the distance, and the only warning is the hold. Slice 3's own measurement is a charge flight median of 40 ticks with the fast tail at 19 (p10): a third of a second.

## What the attacker should control (all inputs already exist; no new intent field)

| Control | Rule | Input (every layout) | Numbers |
| :--- | :--- | :--- | :--- |
| **Cancel** (a feint) | Stops the approach for nothing. **Only before the commit point** | light charge: release the button (as today); lunge and any approach: Dodge tap, free (as today) | commit point below |
| **Commit point** | The last stretch of a flight cannot be cancelled for free. After it, only a Dodge stops it, at the dodge-cancel's full cost (15 ki and the 3 s cooldown), as a heavy charge is today | none: a rule | the last **15 ticks** of a light charge, **20** of a heavy, **4** of a mid lunge |
| **Brake** | Hold Guard during the flight: the attacker decelerates to a stop in 8 ticks and the approach ends with no exchange. Not free | Guard held (LB, B on Simple, Shift, the Guard button on touch): the same hold as the air-recovery brake, so one rule: "hold Guard to stop" | ki per tick at the air brake's rate (Game Design's number); not allowed after the commit point |
| **Steer** | The end point's height follows the stick's vertical axis, so a player can come in above or below the rival (a slam from above, an uppercut from below). The lateral side stays the attacker's own (the end point's current rule, so a crossup is not offered) | the stick up or down during the flight | up to **±4 bh** from the rival's height, at most **0.25 bh a tick**; none in a mid lunge (too short) |
| **Weight** | Light is the fast, feintable charge; heavy is slower, armoured and committed from takeoff (slice 3, unchanged) | which button was held | light 4 000 u/s, heavy 3 000 u/s nominal |

Why these: **cancel** and **weight** already exist, and Orb's complaint is that the *defender* cannot tell what will happen, so the first job of control is to make the attacker's choices **legible by when they can still change** (the commit point). **Brake** reuses the air-recovery brake so a player learns one verb. **Steer** is the one new freedom, small and vertical only, so the line is still a line the defender can read and it adds a real choice (where to arrive) without a crossup.

On touch: cancel is lifting the Attack finger (light) or the Dodge flick; brake is the Guard button held; steer is the floating stick. Simple layouts: the hold gesture already makes the charge; the Simple auto-charge assist never feints (slice 3), so Simple gets no cancel before the commit point except Dodge (A), and brake and steer are available on B and the stick.

## What the defender needs to read it

| Need | Rule | Numbers |
| :--- | :--- | :--- |
| **A tell before it starts** | The hold is the tell: a charge pose and glow from the first tick of the press, a distinct colour per weight (light blue-white, heavy amber), a rising tone, and an **off-screen arrowhead** at the screen edge pointing at the charger while he is beyond the camera's frame | already 8 ticks (light) and 16 (heavy) of hold; the takeoff flash on tick 8 and 16 |
| **A minimum travel time** | Any far charge flies at least this long, so the closing never pops | light **30** ticks (now 18), heavy **42** (now 30); a mid lunge **8** ticks with a **4-tick crouch** before it (now 3 ticks, no tell) |
| **A speed cap by distance** | The speed never rises above a cap, whatever the distance. Travel time is `distance / speed`, clamped between the minimum above and a longer maximum | light nominal 4 000 u/s rising to a cap of **6 000 u/s**, heavy 3 000 rising to **4 500**; maximum time **90** ticks light, **108** heavy |
| **A ceiling on charge range** | Beyond the range the cap and the maximum time can cover, a far press is the **taunt only** (the charge needs the player to close with free flight or boost first) | light: **120 bh** (90 ticks at 6 000 u/s); heavy: **108 bh** (108 ticks at 4 500 u/s) |
| **A smooth arrival** | The flight eases out over its last 12 ticks to half speed, so the engage never pops | speed ×1.0 down to ×0.5 across the last 12 ticks (the end point still follows the rival each tick) |
| **A marker and a countdown** | A ring appears on the **defender** at the engage point when the flight begins and closes toward it; it turns red at the commit point (the last 15 or 20 ticks) and the attacker's trail changes: from then on the attack is coming | ring from takeoff to engage; red at the commit point; a short lock-on click |
| **The wind-up as the second tell** | Unchanged: the exchange starts at the wind-up, 15 ticks light and 20 heavy, so a defender who read the flight also sees the blow wind up | no change |

**The reading budget (first visible cue to the first blow),** against a guard or dodge decision of about 12 to 15 ticks:

| | Today (median) | Proposed minimum |
| :--- | ---: | ---: |
| Mid lunge | 3 to 20 ticks plus 15 or 20 of wind-up | 4 crouch + 8 + 15 or 20 = **27 to 32** ticks |
| Far light charge | 8 hold + 19 to 60 flight + 15 = 42 to 83 | 8 + 30 + 15 = **53** ticks |
| Far heavy charge | 16 hold + 30 to 84 flight + 20 = 66 to 120 | 16 + 42 + 20 = **78** ticks |

Flights as proposed, for comparison with the table above (time `d / speed` clamped to the minimum and maximum, speed capped):

| Distance | Light flight | Light speed | Heavy flight | Heavy speed |
| ---: | ---: | ---: | ---: | ---: |
| 12 bh | 30 ticks | 1 800 u/s | 42 ticks | 1 290 u/s |
| 40 bh | 45 ticks | 4 000 u/s | 60 ticks | 3 000 u/s |
| 80 bh | 90 ticks | 4 000 u/s | 108 ticks | 3 330 u/s |
| 120 bh | 90 ticks | 6 000 u/s | 108 ticks (the heavy's range ends at 108 bh) | 4 500 u/s |
| beyond 120 bh | taunt only | | taunt only | |

Light and heavy now differ by weight and commitment, not by a different relation between distance and speed.

## Measures for QA and Encounter

- Far charge flight: **p10 at least 30 ticks** (light), **median at least 45**; no flight above the cap (6 000 u/s light, 4 500 heavy).
- **No far charge from beyond 120 bh (light) or 108 bh (heavy)**: those presses are taunts (count them).
- Approaches cancelled before the commit point vs after: **no free cancel after it** (zero).
- A defender's guard or dodge taken during an approach (the free time slice 3 gave him): **share of approaches answered** should rise from today's figure; report it, since Orb's complaint is that he cannot judge them.
- Match length and collateral move a little (flights are longer: slice 2 measured the approach at 11% of the time already); the budget is a median not more than 10 seconds longer.

## What each director needs

| Who | What |
| :--- | :--- |
| **Encounter** (`bands.gd`, `interrupts.json` `bands`) | the minimum, maximum and speed-cap keys above; the commit point (no free cancel after it); the brake (Guard held, ki per tick, ends the approach); the vertical steer; the charge ceiling (a press beyond it is the taunt); the ease-out; the AI obeys the same |
| **Animation** | the 4-tick crouch before a mid lunge; the charge pose and takeoff pose per weight |
| **VFX** | the engage-point ring on the defender, red at the commit point; the attacker's trail changing at the commit point; the takeoff flash |
| **Camera** | frame the attacker while a far approach is on (an inset or a zoom-out that keeps the charger on screen), and a shake of nothing: no shake, the flight is the read |
| **Audio** | the rising tone through the hold, the lock-on click at the commit point |
| **UI** | the off-screen arrowhead pointing at a charger beyond the frame, with the weight's colour |
| **Controls** | nothing new in the intent: the brake is Guard held (the air-recovery verb), the steer is the stick, the cancel is release or Dodge; touch and Simple as above |
| **Game Design** | the ki per tick of the brake (the air brake's rate), the free-cancel rule, the charge ceiling, and whether a longer approach is acceptable for matches of eight minutes |
