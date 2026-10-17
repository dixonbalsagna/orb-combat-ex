# The re-read on ff68e994 with the Reduce flashing hook fix (2026-10-17)

Owner: Tools. 20 clips, one capture at a time, below-normal priority, on a scratch export of main ff68e994 with the hook patch applied (the game's own Reduce flashing set from the clip's mode and read back). 'Before' is the 9d0530dc run (hook not fixed: both modes were the calm look) or, for 1008 and 1009, the nightly on d3f1ca0e. Readings are primary / area-15% / 2 s memory; the limit is 3 on the primary.

| clip | now primary/area-15%/2s | verdict | red | before (primary/area/2s; old hook) | worst second at tick | counted changes around it (tick, sign, % of threshold) |
|---|---|---|---|---|---|---|
| ai-1008-normal | 2.5/3/2 | PASS | red 0 | 2/3.5/3 | 2523 | 2501+134% 2523-119% 2528+364% 2570-141% 2574+217% 2580-306% 2589+290% |
| ai-1008-reduced | 3/3/2 | OVER GATE | red 0 | 3/4/3 | 2970 | 2970-260% 2972+200% 2976-121% 2980+155% 2986-102% 3016+103% 3027+124% 3042+201% |
| ai-1009-normal | 1.5/2/1.5 | PASS | red 0 | 3/4.5/3 | 2327 | 2327+376% 2333-229% 2337+381% 2395+308% |
| ai-1009-reduced | 2.5/3.5/2 | FAIL | red 0 | 4/4/3 | 2328 | 2317-116% 2328+361% 2338+225% 2355-137% 2360+132% 2366-191% 2373+297% 2411+239% |
| ai-39-normal | 2/2.5/2 | PASS | red 0 | 3/3/3 | 148 | 119-145% 122-199% 148+256% 169-122% 184+110% 198-103% |
| ai-39-reduced | 3/3/3 | OVER GATE | red 0 | 3/3/3 | 1631 | 1631+230% 1637-342% 1654+190% 1676-166% 1680+122% 1688-190% 1709+399% |
| ai-43-normal | 2/2.5/2 | PASS | red 0 | 3.5/3.5/2.5 | 2607 | 2607+116% 2609-172% 2618+124% 2630+400% 2658-312% 2674-186% 2688+330% 2693+210% |
| ai-43-reduced | 3.5/3.5/2 | FAIL | red 0 | 3.5/3.5/2 | 2611 | 2611-105% 2614+243% 2628-107% 2633+311% 2659-308% 2662+135% 2665-172% 2676-122% 2688+343% 2696+162% |
| ai-PROTAGONIST-REFERENCE-8-normal | 3/3/3 | OVER GATE | red 0 | 4.5/5/3.5 | 859 | 859+175% 862-210% 879+370% 894+152% 898-120% 906+117% 910-156% 919+211% 940-304% |
| ai-PROTAGONIST-REFERENCE-8-reduced | 4/4.5/3.5 | FAIL | red 0 | 4/4.5/3.5 | 864 | 840+103% 861+101% 864-129% 869+186% 882-108% 886+169% 893-124% 898-178% 900+180% 909-145% 920+164% 940-331% |
| ai-RIVAL-REFERENCE-107-normal | 2.5/2.5/2 | PASS | red 0 | 3.5/3.5/3.5 | 936 | 907+298% 936-258% 941+200% 953-102% 976-188% 985+123% 987-346% |
| ai-RIVAL-REFERENCE-107-reduced | 2/2/1.5 | PASS | red 0 | 2/2.5/2.5 | 1112 | 1102+393% 1112-138% 1119-129% 1125+350% 1159-385% 1167+359% |
| blastdummy-PROTAGONIST-REFERENCE-normal | 1.5/3/1.5 | PASS | red 0 | 3/3/3 | 276 | 271-216% 276+390% 297+114% 306-207% 314-229% 334+398% |
| blastdummy-PROTAGONIST-REFERENCE-reduced | 3/3/3 | OVER GATE | red 0 | 3/3/3 | 250 | 250+123% 271-225% 279+120% 285+134% 294+118% 300-317% 303+185% 307-172% 316-166% 333+391% |
| blastdummy-RIVAL-REFERENCE-normal | 2/2/2 | PASS | red 0 | 3/3/3 | 83 | 83+181% 85-234% 103-149% 108+284% 126+139% 133-119% |
| blastdummy-RIVAL-REFERENCE-reduced | 3/3.5/3 | FAIL | red 0 | 3/3.5/3 | 250 | 250+123% 271-200% 278+144% 300-322% 303+191% 307-131% 314-172% 333+394% |
| ring-PROTAGONIST-RIVAL-RIVAL-normal | 2.5/2/1.5 | PASS | red 0 | 2.5/2.5/2 | 1296 | 1275-140% 1284-133% 1296+294% 1311-116% 1323+113% 1333+161% 1338-344% 1355+299% |
| ring-PROTAGONIST-RIVAL-RIVAL-reduced | 2/2.5/2 | PASS | red 0.5 | 2/2.5/2 | 160 | 160-124% 179+183% 196-374% 199+287% 215+321% 239+362% |
| ring-PROTAGONIST-RIVAL-RIVAL-RIVAL-RIVAL-normal | 2/2/2 | PASS | red 0.5 | 2.5/2.5/1.5 | 1751 | 1751+282% 1754-304% 1774+251% 1790-199% |
| ring-PROTAGONIST-RIVAL-RIVAL-RIVAL-RIVAL-reduced | 2/2/1.5 | PASS | red 0.5 | 2/2/1.5 | 1751 | 1751+182% 1758-156% 1781-107% 1782+179% 1789-240% |

## What it says

- **The fixed hook changes which mode is worse.** With Reduce flashing really off, the "normal" clips read as low or lower than before (ai-43 normal 2, ai-PROTAGONIST-REFERENCE-8 normal 3, ai-RIVAL-REFERENCE-107 normal 2.5, both blastdummy normals 1.5 and 2). **The mode that is over is Reduce flashing ON, the shipped default**: ai-43 reduced 3.5 and ai-PROTAGONIST-REFERENCE-8 reduced 4 are the only clips over 3 on the primary; ai-1008 reduced, ai-39 reduced, both blastdummy reduced clips read exactly 3; ai-1009 reduced and blastdummy-RIVAL reduced fail on the area-15% reading (3.5) though 2.5 and 3 on the primary. The reduced readings equal the 9d0530dc ones (the same tick, the same changes), because every earlier clip was that calm look.
- **The worst seconds are all camera and world changes in the same second** (a whole-frame step then several smaller ones): ai-43 reduced from 2611 (10 counted changes around it), PR-8 reduced from 840 to 940 (12 changes), ai-1009 reduced from 2317 to 2411, ai-39 reduced from 1631, blastdummy reduced from 250 (10 changes at 250 to 333). The same blast scene (blastdummy, tick 250) is the worst second in both pairings.
- **Red:** 0 in 17 clips; 0.5 in the three ring clips (reduced 3-body, normal and reduced 5-body). Half a flash is under the limit but the red gate wants 0.
- **Seeds 1008 and 1009 are not stable across sim changes:** on today's main ai-1009 normal reads 1.5 (3 on d3f1ca0e), ai-1009 reduced 2.5 (4); ai-1008 reduced 3 (3). They are still in the required set (Legal RL-156); their windows on d3f1ca0e itself are being re-captured on that build (docs/tools/seeds-1008-1009.md when done).

## Where the frames are

Each clip's worst-second window (30 ticks before to 90 after) and every dip are kept as PNGs, one per tick, with analysis.json (every counted change with its tick, sign and pooled pixels) in `/clips/<clip id>/` (nightly seeds in `/clips_nightly/`). They are on this PC only. To look at one: open the frames in order; the tick is in the file name.
