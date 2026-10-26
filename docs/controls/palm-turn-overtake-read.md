# The Palm Turn and the overtake: the left stick's read at the 45-degree edge

Controls, 2026-10-25, for `rulings-2026-10-23d.md` section 8, item 21. Short note; paper only.

**The rule.** "Back" is within 45 degrees of the reverse of the flight (the overtake); "across" is within 45 degrees of either perpendicular (the Palm Turn). The two sectors touch only at their edges, 45 degrees from the reverse.

**Confirmed: the left stick's read covers the boundary.** The sim already receives `mx` and `my` in every intent, quantised to 1/16 (a step of about 6 degrees at a 0.6 deflection), and the boundary is a comparison of the stick's angle against the flight vector, which is exact in the sim. Nothing new is needed in the input layer. Three rules make the read clean:

1. **A deliberate lean only.** The stick counts at 0.60 or more after the dead zone (0.20). Below that it reads neither back nor across, and the chase does what it does with no direction.
2. **Sample once, at the commit.** The sectors are relative to the flight, and the flight turns. Read the stick at the tick the chase commits (the zip's decision) and keep that read for the chase; do not re-read it every tick, or a turning flight flips back and across under a still thumb.
3. **Sticky edges only if needed.** If the stick is read while held (a level), a class changes only when the angle passes the edge by a small margin (the dead band below), so a thumb resting near 45 degrees does not flicker.

**Misread, modelled (an intended direction exactly on its sector's axis, a Gaussian aim error; assumed thumbs, not measured):**

| Aim error (one sigma) | No dead band | 6 degrees | 10 degrees |
| :--- | ---: | ---: | ---: |
| 8 degrees (practised) | 0.0% | 0.0% | 0.0% |
| 12 degrees | 0.02% | 0.00% | 0.00% |
| **18 degrees (casual)** | **1.2%** | **0.5%** | 0.2% |
| 24 degrees (tired, a phone) | 6.1% | 3.4% | 2.2% |

That is the "about 99 in 100" for the four-way read. Intended directions near the edge (a diagonal) are ambiguous by nature: the thumb is choosing neither, and either reading is a defensible answer, so no dead band removes that.

**Decision.** As GD ruled, **no dead band yet**: the casual case is already 1.2% and the dead band's gain is under one point. **If the thumb-test capture shows misreads above about 2% for casual thumbs, add a 6-degree sticky dead band** (a data key `chase.edgeDeadBandDeg`, default 0), applied only to a held level and never at the commit sample. The capture page already records the left stick in the flick and free-aim blocks; I will read the aim error from there. No change to the layout layer or the intent.
