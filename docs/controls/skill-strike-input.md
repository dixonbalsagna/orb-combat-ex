# Brawl slice B2, the skill strike: what the input layer says

Controls, 2026-10-05, answering Encounter's three questions (through the EP) on `melee-press-feel.md` section 4. Docs only; nothing changed in `sim/input`. Whole ticks, 60 a second.

## (a) The window, and perfect against good inside it

**Confirmed: the skill strike's window is `read.beatHalf` = 4**, so a press whose graded tick is within 4 ticks of the beat point, either side, inclusive (an 8-tick window, 9 ticks counting both ends). On touch it is `read.touchBeatHalf` = 5, with the accessibility factor `assistFactor` 2 it doubles (8, or 10 on touch), and the player's device `offset` moves the centre of it (`SimPressRead._half` and `grade_of` already do all of that).

**The split inside it is not what `grade_of` gives today, and you need to know that.** `grade_of` says perfect within `beatHalf` and good within twice that, so on the same `beatHalf` 4, everything inside the skill strike's window is "perfect" and "good" falls at 5 to 8, outside it. That is right for the combo's timed press (a good one is a weaker timed press). It is not a split for a window that is itself the skill strike. **So the rule for B2 is: the skill strike is graded within the window at the blur's tolerance, `read.blurBeatHalf` = 2:**

| Distance from the beat point | Grade | What it is |
| :--- | :--- | :--- |
| 0 to 2 ticks either side | **perfect** | a skill strike |
| 3 to 4 ticks either side | **good** | a skill strike |
| 5 or more early | none | a flurry blow, thrown at once |
| 5 or more late | none | a fresh light |

On touch the window is 5 (perfect still 2, good 3 to 5, because `blurBeatBonus` is 0 by ruling); with the assist factor both double (window 8, perfect 4). The grade is **for the streak and the show, not the damage:** a skill strike is ×1.25 whether perfect or good (no change to section 4), and only a perfect one counts toward `perfectStreak` (3, the timed-string reading) and gets the brighter glint and tick. If Game Design wants good to pay less, that is a number for them; nothing in the input depends on it. In code it is two data keys already there (`beatHalf`, `blurBeatHalf`) and one comparison in the brawl: `d <= blur_half` perfect, `d <= half` good.

## (b) A press made inside a hit-stop

**Yes: grade at the press's own tick, `S.tick - waited`, is the rule, and it is built and live, not parked.** Orb chose it on 2026-10-04 (option B of `agency-input.md`'s freeze note); it shipped as intent version 3: the layouts fill `waited` (0 to 15 host ticks the oldest unconsumed edge waited because the sim was frozen), and the director grades a human press at `S.tick - waited`. Nothing is waiting on my side, and nothing about it changes for B2. (If the EP is thinking of the QA scripted players, that is `docs/controls/players-waited.patch`, a QA file QA applies; it matters only to scripts, not to a person.) Specifics for the slice:

- **`S.tick` runs through hit-stop**, so a beat point 24 ticks after contact is a tick count that a freeze can sit across; a press made in the freeze has its true tick and is graded against it. A masher's 2-tick freezes are fine; a longer freeze (a heavy's, 4 to 9) costs the timed player nothing, as the freeze is part of the 24.
- **AI presses keep their own rule** (their beat is where the planner put it; `waited` is 0 for them).
- **Early in a freeze is early.** A press whose own tick is more than 4 before the beat point is a flurry blow, thrown at once on the first live tick, even though it arrives after the beat point in real time.
- **One real limit, rare:** the layout turns a button into one edge a build (`light` is a flag), so **two light presses inside a single freeze merge into one edge carrying the first press's wait**, and the second is lost. The debounce (2 ticks) means a 2-tick freeze can't hold two presses, so a masher's lights are safe; only a freeze of about 4 or more ticks can take two (a heavy or a skill strike's own hit-stop), and a player who taps twice there loses the second tap. If Encounter's QA sees a timed player's second press go missing in a long freeze, tell me and I will make the layout keep the newer press's wait for a repeat of the same button (a layout-only change, no intent bit). Not needed for B2 as it stands.
- The grade of a **release** is unchanged (it keeps the old freeze rule; a release is a level, not an edge).

## (c) The intent

**Confirmed: no change for B2. No new bit, no version bump.** The skill strike needs the press edge (`light`), its true tick (`waited`) and the stance (`stanceMask`), all of which are in version 4, and everything else, the beat point and the grade, is the brawl's own bookkeeping against the press log (`SimPressRead`'s `beat`, from the blows' contacts). The 10 spare bits (53 to 62) are untouched. If the hold-to-flurry option goes ahead as option A it stays that way; only option B of that note would need a version 5.

## How a timed player finds the beat without the ring

The beat's cue is the one the design gives: **the limb sets with a glint at the beat point, and a short tick sounds.** The input layer adds no latency to that; what each layout does with the press:

| Layout | The press that is graded | What a timed player needs |
| :--- | :--- | :--- |
| Arena (pad), the keyboards | The light's **press edge on the tick it goes down** (no wait; the 2-tick debounce only drops a re-press of the same button 2 ticks after a release) | The glint and the tick; nothing else is needed. Their own device lag is the **offset** calibration (a per-player setting, shifts the window) |
| Full touch | The press edge on touch-down, same as the pad | The same, plus the touch screen's own latency, which the offset covers; the window is one tick wider (5) |
| **Simple (pad and touch)** | **Not the press: the release.** The attack button is a tap that makes a light (and a hold that makes the heavy), so the light is delivered when the finger comes up (the bridge). A tap lasts 3 to 6 ticks | See below |

**Can Simple's Attack tap earn a skill strike? Yes, but it times the release, not the press.** The graded tick is the release tick, so a player who presses on the beat is 3 to 6 ticks late by the length of their own tap, which is inside a window of 4 on a short tap and outside it on a long one. A Simple player learns it quickly (time the lift, not the touch), but it is a different skill from the other layouts and the cue is the same glint and tick. Two things make it fair: the **offset** setting can absorb a typical tap length, and the **assist factor** (accessibility, window ×2) makes it comfortable. Moving Simple's light to the press edge would fix it, but a hold on that button is how Simple reaches the heavy, so it would fire a light before every heavy; that is a design change for Orb, not a B2 matter, and I have not touched it. I would not give Simple a different window in B2.

**Without the ring, rumble, or the sound:** a timed player has the sound and the glint, which cover most players and fail a player who cannot see the limb (low vision) or hear the tick (deaf or hard of hearing). **A short rumble pulse at the beat point (the same tick as the sound) would cover both**, on a pad (the host's `Input.start_joy_vibration`) and as a haptic tap on a phone. It is output, so it is the host's and Rendering's to build, not the input layer's; the input layer would carry the per-player on/off with the offset. It is on Orb's questionnaire unanswered; my recommendation is **yes, default on for the pad and the phone, a setting to turn it off**, since it costs the player nothing and is the accessible cue for the skill strike. The beat ring (off by default, an option) covers a seeing player who wants a larger cue.

## For the other directors

- **Encounter:** the grade is `|press tick - beat point| <= blurBeatHalf` perfect, `<= beatHalf` good (both in `read`; touch and assist as `SimPressRead._half` does), the press tick being `S.tick - waited` as the brawl already does.
- **QA:** the timed script should press on a Simple layout at the release, and report two lights lost in one freeze if it ever sees it.
- **Orb (queued):** rumble on the beat point (yes, recommended); whether Simple's attack should move to the press edge (not recommended now).
