# The floating building: a gap under a building's downhill corner (World, 2026-11-01)

Rendering's finding, through the EP: a pink building floats at the top right from about tick 1441 (seed 12345), its underside showing. I could not run that clip (it is a web capture on Rendering's stack), so this is measured on the sim instead: for every building, the base the sim gives it (`WorldStructures.baseY`) against the ground at its four footprint corners (`WorldField.applyRecords` at the corner's planet point), planets 7 and 12, touch 1, everywhere on, first frame. The gap is base minus the ground at the worst corner.

## Two causes, one of them mine

**1. The terraces and the lean (lot-terraces, lot-lean), typical size.** A lot's flat now tilts along its street (`lots.grade` 0.12) and leans across it (`lots.gradeAcross` 0.12), but a building's base stays level at the plane's height at its centre. On the downhill corner the ground is lower by up to `0.12 * (w + d) / 2`: a 400 by 450 building, about 50 units (0.7 bh) of air under one corner. Measured, the first ring's gap (worst corner):

| | median | p90 | p99 | over 30 units |
| :-- | ---: | ---: | ---: | ---: |
| planet 7, old lots (flat) | 0 | 20 | 75 | 18 of 263 |
| planet 7, terraces + lean | 23 | 56 | 79 | 100 of 263 |
| planet 12, old lots | | | | 20 of 163 |
| planet 12, terraces + lean | 30 | 54 | 119 | 75 of 163 |

Flat lots had no gap (the sheer pale face beside the road was the other complaint); the tilt trades the face for a gap under every building on a slope. From the camera below a slope it reads as the underside of a building showing.

**2. A tail that is not the lots.** 133 of 3,812 free buildings on planet 7 (157 of 3,735 on planet 12) have a corner 100 or more above the ground, 18 and 21 of them over 300, the worst 1,046 (a corner at the ground, the opposite corner a thousand units up). Counts are the same with the lots flat, so it is not the tilt: the building's footprint overhangs a cliff or a step of another record (a platform's edge, a neighbouring lot, the shore). Free buildings are axis-aligned to the line while their lots and platform follow the plan's yaw. 60 of the 134 worst are inside a lot at the worst corner; 74 are outside every lot. The first ring has 1 and 2.

## What I'd do (not done; say which)

- **A (Rendering, cheapest):** draw each building's body down to the ground under its lowest corner, capped (a plinth of, say, 120 units): it closes cause 1 completely and the small end of cause 2, with no sim change.
- **B (World):** sink a building's base by its lot's tilt allowance, `0.5 * (|gt| * w + |gs| * d)`, so the downhill corner sits on the ground and the uphill corner is under it. It moves the collision base by up to about 55 units; it needs each building's lot (not kept per building today) and moves every hash with lots on.
- **C (World, for the tail):** do not lay a free building whose worst corner is more than a set gap above the ground (it is left out like one in the sea). Cuts the 3.5% with the gap over 100; costs those buildings.
- **D:** lower `lots.grade` and `lots.gradeAcross` (0.06 halves cause 1 and brings back some of the sheer face).

I'd take A for cause 1 and C for the tail. The probe is a scratch script; it is not in the repo.

## Option C built (2026-11-01, the EP's pick: A for Rendering, C for World)

The gap rule as I first wrote it (a building is not laid when a corner's ground is more than a set gap below its base) rejected 14.5% of the free buildings, because it reads the natural ground before the lot's flat exists: every hillside town fails. A step test (the ground off a straight line between the centre and the corner) missed the tail, which is not a step but a very steep slope. So the rule is a **slope**: `plans.maxFootSlope` (data, 0.7 = 35 degrees; 0 is off): a free building is not laid when the ground between its centre and any of eight points on the circle round its footprint (radius the half diagonal, so a footprint turned to any line has its corners on it) is steeper than that, read from the bake with the platform as `layFree` reads it. A hillside town stands on 0.3 to 0.6; a cliff is 3 or more.

Planet 7, free buildings, worst-corner gap measured after the lots (the same probe as above):

| `maxFootSlope` | not laid | gap over 100 | over 300 |
| :-- | ---: | ---: | ---: |
| off | 0 | 133 | 18 |
| **0.7 (the first value)** | **176 (4.6%)** | **80** | **3** |
| 1.0 | 61 (1.6%) | 109 | 8 |
| 1.5 | 3 | 134 | 18 |

The rest of the 100-plus gap is moderate (a steep-but-allowed slope under a footprint, or a footprint turned across a lot's edge): Rendering's plinth (A) closes it. Cost: about 1 second more on a cold match start on a loaded PC (eight more bake reads a building); a warm start reads the cache, which is keyed by the data, so it fills once. `everywhere_check` 0 failed (every place laid again with no limit stands more: 312 of 3,924 on the planet's places); `far_people_check`, `places_cache_check`, `field_lot_check` 0 failed. It is in the `front-limit` park (one park for the far buildings), `front-limit-code.diff` and `-data.diff`.
