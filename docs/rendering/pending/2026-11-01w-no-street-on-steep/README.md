# No street paint on a slope

Parked by Rendering, 2026-11-01. `low_street.diff` stacks on `2026-11-01v-lake-water-coarse/lake_l0.diff`. Only with the tile ground's switch on.

**The fault.** Part of Orb's note on low hills: street paint belongs to a column of the strip, so it runs across whatever land is at that place, and on a slope it stretches into pale streaks.

**The change.** No street paint where the slope is past where rock starts (`rock_slope.x`).

**Seen:** `docs/rendering/img/lookgate/low-hills-street-before-after.png`, tick 601, top before, bottom after; `low-hills-fight-sheet.png`, the six frames that changed most in the reel's first 3,421 ticks, each pair left before, right after. Those pictures also include `v` and the foreground edge's wander, which isn't parked. Nothing worse showed in those frames.

**Not parked:** the wander of the foreground tone's edge (`low_fore.py` in my scratch). No clear gain in these frames, and an earlier look found it busier near the feet. If anyone wants it, it's a small edit.

**Not done for low hills.** The low wide lens stills the EP asked for weren't re-shot on this stack. Other faults noted earlier remain: the shadow is a flat quad and cuts into a cross-slope as a hairline; lots on slopes read as walls (World's terracing). World's and Rendering's notes are in the queue.

**Gates:** as `2026-11-01v-lake-water-coarse`'s.
