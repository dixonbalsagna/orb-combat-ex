# Bolus's stoke, Loupe's On the Chin, and the universal release on a real pad (Controls, 2026-11-01; paper plus probes, nothing landed)

For Combat's `docs/combat/signatures-on-stick.md` and the EP's three questions. Counts only from Orb's first-play stick samples (`homework/Files/orb-first-play-20261101-2130.json`, private). Readers: `docs/controls/clips/read-orb-release.cjs` (the thumb numbers) and `sim/input/tools/stoke_probe.gd` (the law, run on the real layout).

## Answers

| Question | Answer |
| :--- | :--- |
| **Does pumping the stick fight the claw law?** | **No, with one gap to close.** The law gates a face press against a stick request; a stoke is RT plus the stick, no face button, so it has nothing to gate and gives a claw nothing. But the reader as it stands cannot see a pump that goes **rim to rim** without passing the centre (section 1), and in that case a face press lands mid-pump. The stoke's reader must count reversals and hold the law across the run. |
| **Is there room for a fresh RT press beside RT + stick (On the Chin)?** | **Yes**, at zero ticks, with one rule: it is an edge, taken once per window, and it beats a signature started in the same window (section 2). |
| **Does a release direction read reliably on a real pad?** | **Yes, once the aim is latched; no, as the reader stands.** Orb's last rim tick is within 2.7° of the hold's direction (median), 15.5° (ninetieth); 41 of 43 holds land in the same quarter-turn. The sample on the throw tick, which is what is read today, is a different quarter-turn in 24 of 43 (section 3). |

## 1. The stoke

**What the stick does under RT today.** Nothing: with RT held the strike stick is inert (pure 4a, `strike.inertMasks`), and the probe starts **0 requests** in 80 ticks of pumping at periods 6 to 16 ticks, through the centre or not. So the stoke is a new read in that layer, not a change to the strike.

**The law, measured** (`stoke_probe.gd`, the real layout, RT held, a face press in the middle of a pump run; "lands" is ticks after the press):

| Pump period (ticks) | 6 | 8 | 10 | 12 | 16 |
| :--- | ---: | ---: | ---: | ---: | ---: |
| Pump **through the centre** (the stick falls under the release line each cycle): the press lands | 26 | 26 | 26 | 2.5 | 1.9 |
| Pump **rim to rim** (never under the release line): the press lands | 0 | 0 | 0 | 0 | 0 |

(26 means held until the pumping stops and the law's 6-tick floor passes; a press alone lands at 0.) So a through-the-centre pump at 10 ticks or faster holds the faces completely, and from 12 ticks (5 pumps a second) they find a gap: exactly the law's L = 6. **A rim-to-rim pump holds nothing**, because the reader only knows a stick is "out" or "back", and a reversal that never comes back is one long hold. For a stoke done fast, a claw's face press would land mid-pump, which is the claw gain the law exists to prevent.

**Does a real thumb pass the centre?** Orb never pumped, so the pump rate is not measured. What the file shows: in 11,873 samples, one pair of consecutive frames flips more than 120° while both stay above 0.5 (a pass through the centre between frames): so the single-frame reversal exists. The fastest reversal Orb made on purpose was a 135° turn with 71 ms (4 ticks) between letting go and pushing again; the fastest start-to-start of any two pushes was 234 ms.

**What the stoke needs from the input side** (a small park when Combat settles the move):
1. A pump counter in the RT layer: a pump is a **direction reversal of more than 120° with the stick above 0.5 on both sides**, or a fall under the release line and a new push, whichever comes first.
2. The run holds the faces: while pumps keep coming (the next one inside the pump timeout), the law treats the stick as busy; L = 6 after the last one.
3. A rate floor for "pumping": a gap above about 20 ticks ends the run, and the "sputter" starts.
4. The accessibility fallback Combat already named: with the repetition assist on, a plain hold with the sputter timed.

**On "hard on thumbs and pads".** Not Controls' to measure from this file. The pad's side: a stick has no wear count a game should design around at 5 pumps a second for a few seconds; a pump run is bounded by the sputter either way.

## 2. Loupe's On the Chin: a fresh RT press

- **The edge exists today**: `powerPress` is on the tick RT goes down, and the layout already reports it with no delay. In Orb's match RT went down 12 times (held 3 to 105 ticks), so it is a common press and a window will see it.
- **A fresh press only.** If RT is already held when the beam is in the window, there is no edge; a player charging then gets nothing from the press and fires back with RB, which is the plain fire-back anyway. A release and a re-press inside the window counts (that is a new edge).
- **The collision is with the signature on RT + stick.** The RT press comes before the stick push, so on the press tick the layout cannot know a stick will follow. Rule: **in the beam-answer window, for a fighter who has the Chin, the RT edge is the Chin, taken at once; the stick after it does nothing in that window.** This costs Loupe his signature as a fire-back inside the window (he still has RB + stick, level 1 to 3), and costs everyone else nothing, because the edge only means the Chin for him. If Combat wants both, the only other reading is the tap form (`powerTap`, released within the hold threshold), which adds 3 to 12 ticks before it can resolve; I would not use it in a 20-tick window.
- **Once per window.** The edge is spent by the Chin; a second press in the same window is the ordinary power press.
- **Nothing else on RT changes**: RT held is still the power charge, RT + stick still the signature, RT + a face press still the special (off in the first-play build).

## 3. The universal release (hold, then let go in a direction)

Numbers are for the 43 holds of Orb's file with a steady rim (the stick at 85% of its peak or more for at least 5 ticks). "Rim mean" is the mean direction of those ticks; the error is the angle of each candidate against it.

| What is read as "the direction you let go in" | Error, degrees (median / ninetieth / worst) | In a different quarter-turn (up, down, left, right) |
| :--- | :--- | :--- |
| The stick **on the tick it falls under the release line** (what the throw reads today) | 94 / 177 / 180 | **24 of 43** |
| The last sample still down | 3.2 / 15.5 / 44.1 | 2 of 43 |
| The last rim tick | 2.7 / 15.5 / 44.1 | 2 of 43 |
| **The mean of the last 3 rim ticks** (the beam-aim park) | **2.2 / 10.9 / 45.1** | **2 of 43** |

What happens to the direction in the last frames before the release:
- **It does not slide.** The direction of the last 4 rim ticks against the 4 before differs by 0.9° (median), 7.8° (ninetieth); more than 20° in 1 of 39 holds. The thumb is still when it lets go.
- **It does not sag.** The magnitude holds (lowest dip 93% of the rim at the tenth percentile) until the lift; 39 of 47 holds go from the rim to under the release line with no tick between, 6 with one tick.
- **The fall is where it goes wrong.** The first sample under the release line is a stick sprung most of the way home, its angle a coin toss (94° median error); and after the throw the stick bounces the other way in 17 of 41 holds, up to 0.4. Both are why the latched aim matters: read after the lift, "toward" and "away" would flip about as often as not.
- **The 2 misses are the same kind**: holds whose direction was near the diagonal; 6 of 43 holds lay within 20° of a quarter-turn boundary, 1 within 10°. A hold that sits on a diagonal is a coin toss between two answers whatever the filter.

**So yes, with these rules** (all but the first are Combat's or the director's to adopt; the first is built, off, in `pending/beam-aim/`):
1. The release carries the latched aim (mean of the last 3 rim ticks), never the live stick at the throw.
2. The answer reads the quarter-turn, as the strike does (up, down, toward, away; toward and away from the facing). A diagonal within about 15° of a boundary leans to **toward/away** (the horizontal), on the reasoning that the fight is side-on and Orb's holds were 32 of 41 within 22° of straight left or right.
3. The pose shows the answer the stick is about to give (the pre-read the quick read already publishes: `pre_dir` for the strike), so a player can see a diagonal and correct before the lift. That is the usual fix for a coin toss: let the player see which side it is on.
4. Judge the release on the edge tick (`rsRelease`), as with every stick answer.

**What the file cannot say.** Orb's holds were strikes and charges, not answers: 32 of 41 pointed left or right and 2 up or down, so the up and down answers are untested on a real thumb, and a deliberate re-aim just before the lift (the player sweeping to "up" as the front arrives) is not in it. Re-aim speed on the rim is known (the ninetieth percentile of Orb's speeds is 94°/s, the 99th 397°/s, which is about 6.6° a tick), so a 3-tick mean lags even a fast sweep by about one tick, 7°: inside the quarter-turn's margin except on a diagonal. A drill for the capture tool would close it: "a front is coming, release up / down / toward / away on cue", 30 trials per direction, reading the latched direction against the cued one.
