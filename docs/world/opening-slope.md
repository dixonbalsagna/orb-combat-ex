# The opening shot on a steep flank, and the shoulder of a pad (World, 2026-11-01)

Rendering's trace of the grey slabs (seed 12345, planet 7), through the EP: a flat place cut into a 55 to 60 degree mountainside, the raw field about 790 and the ground about 540 for over 1,000 units along the line, so a cliff beside the fight and no horizon in frame. Two questions: should the fight's opening avoid a steep flank, and should a pad cut into a mountainside have a softer shoulder?

Measured on the sim: planets 1 to 30, touches 0 to 3 (116 openings; four have no ring), gen 3, first frame. "Slope" is the largest rise over run in any 150 units within 1,500 of the fighters' start, along the line, of the raw field and of the ground after the records (platforms, lots).

## 1. The opening

- **Most steep openings are the mountain itself.** The raw slope and the ground slope are the same in 114 of 116 openings; the records change it by more than 0.3 in 2. At the openings, the cut (raw minus ground) is over 100 in 4 and over 250 in none. So at these 116 the "cut" is not a cut; it is a flank.
- **How steep, how often.** Ground slope over 0.8 (39 degrees) at 24 of 116 openings (21%); over 1.0 (45 degrees) at 21 (18%); over 1.4 (55 degrees) at 10 (9%). Median 0.36, p90 1.37. Planet 7: touches 0 to 3 read 1.12, 0.43, 0.42, 1.37.
- **What a rule costs, two ways.**
  - **Redraw the touch-down** (`WorldPlanet.touchPoint`: ask for a calmer point, like the land test): it changes the ring through the point, so **every first-ring plan of a moved opening is a different place**: 18 to 28% of openings at a limit of 1.0 to 0.8. Cheap to write, expensive to the plans (and every planet-and-touch pair the campaign has already named).
  - **Slide the start along the same ring** (my recommendation): the ring, its places and its plans do not change (**0 plans move**); only where the fighters stand moves, to the nearest column whose 1,500-unit window is under the limit and dry. Scan along the ring (limit and openings it moves, of 116; this scan also moves an opening whose window touches water, so its counts are a little above the slope counts above): 0.6: 39 (34%), median slide 1,500 u, 24 within 3,000; 0.8: 32 (28%), median 1,650, 22 within 3,000, 31 within 6,000; **1.0: 27 (23%), median 1,050 u, 22 within 3,000, 26 within 6,000, all within 6,750.** A calm start was found within 9,000 for every one. The fight still goes up the mountain when it wants to: only the opening moves.
  - First value I'd take: **limit 1.0 (45 degrees), window 1,500, at most 6,000 slide** (data, `plans.opening`), switch off until the EP flips it. The pure function reads the ring's own ground (`S.base`), so it costs about 200 column reads and no frame read. It needs one line in Simulation's start (sim.gd, `start_x`): add the slide to the start column. Golden stays (planets are off there; the switch is off).

## 2. The shoulder

I could not find a deep cut at an opening, so I measured round the first ring (12 planets, 4 touches, 27,965 samples along the line, 7,500 units each side of the start): the cut (raw minus ground) is over 150 in 25 samples (0.09%), the largest 238, and in 74 samples the records make the ground more than 0.5 steeper than the raw field (worst +1.58: a true cliff). Rendering's 250 is at the top of that range. What the lots do:

| `lots.gradeAcross` (lean across the street), `blendSide` | cut over 150 | max cut | records steeper by over 0.5 | worst excess |
| :-- | ---: | ---: | ---: | ---: |
| 0.12, 360 (today) | 25 | 238 | 74 | 1.58 |
| 0.12, 720 | 28 | 238 | 79 | 1.58 |
| 0.40, 360 | 12 | 203 | 64 | 1.35 |
| **0.80, 360** | **6** | **167** | **50** | **1.12** |
| 1.40, 360 (grade along 0.40) | 8 | 167 | 51 | 1.12 |

- A wider side blend does not help (it makes it slightly worse); the lean does: the lot's flat follows a cross slope instead of cutting into it. The along-street grade makes no difference.
- **But the lean is what puts air under a building** (docs/world/lot-gap.md: the gap under the downhill corner is `lean x depth / 2`, about 0.12 x 600 / 2 = 36 today, 120 at 0.4, 240 at 0.8). So the shoulder and the float pull against each other: a fuller lean needs Rendering's plinth (cap about 120) to land first. My recommendation: **0.4** with the plinth (halves the deep cuts, a gap the plinth covers), **0.8** only if the plinth cap is raised.
- The remaining steepening (50 samples at 0.8) is at lot ends and platform edges, not the lean; a softer end blend would be the next look, and I have no number for it yet.
