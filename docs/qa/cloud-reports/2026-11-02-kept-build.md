# The kept build, read as Orb played it (QA, 2026-11-02)

Tree: `homework/Files/builds/orb-first-play-3d997381-7e2d88ff/tree`, copied to scratch and not edited (its switches are the page's: charge armour, swing, meteor arc, driver, stances, ending, kick with keepTop, biome, floor all on; launch anywhere off; hero relief off). QA's overlay is not laid over it. `--jobs=3`, below-normal; load 32 to 85%; nothing capped or timed out. Scripts copied in: `qa/godot` (current) and `prototype/tools`.

**Two runs, and why:** the swing exists only on a whole-ring field world (`QA_PLANET` gen=3 with cols=4800; a slice, as in all the earlier gen 2 records, has no frame and no swing). So the AI-vs-AI table is read twice: gen 2 slices (200 matches, comparable with the earlier reads) and gen 3 whole ring (60 matches, the swing rows).

## Plainly, biggest risk first

1. **The AI closes on a stick player far more than on a masher, still.** Trade breaks the AI wins, a minute: stick-only 4.22 easy and 2.62 medium; X mash 0.04 and 0.11; pad mix 1.18 and 0.23. (Game Design's row: fewer on a stick player. Reversed since reel-and-run.) Stick-only wins 2 of 30 easy and 0 of 30 medium; the X mash 26 and 5; the pad mix 8 and 0. The stick-only bot throws nothing but flicks, all of which count as medium blows (18,471 of 18,494).
2. **An idle player is knocked out in about 3.4 minutes** (10 of 10 lost, median 203 s, 7 light blows thrown in all ten). The ending's idle rung (10 s of no input, wear x3) is not what ends it: the AI simply wins. So an idle match is short, not long.
3. **The meteor route was not read.** No meteor, arc or armour cue fired in any pad cell: the bots never reached tier 4 and never threw one. It needs a scripted meteor player (not built). Charge armour is on in the build; the stick-only bot does not benefit from it.
4. **Swing on a whole ring (60 matches):** share of fight time **8.1%** (7.8 to 8.4; Game Design 10 to 15, missed); big swings **10.7 a match** (6 to 12, met); jolts **30.2** (20 to 40, met); causes in a match: three or more in 92% of matches with 6 big swings (met). My first values missed: no cause over half in 58% of matches (first value 90%) and no 30-degree band over half in 48% (first value 90%): these are QA's own guesses for Game Design to confirm or drop. Causes by count: small 1,310, brawl 480, chase 353, launch 191, form 121. **The shortest gap between two swing starts is 0 s: 52 of 2,395 gaps are a jolt and a launch swing starting on the same tick, and 620 (26%) are under 6 s.** Toll association: count r 0.18 (-0.07 to 0.42) and time r 0.11 (-0.14 to 0.36), neither wholly above 0 (RL-215 not failed; 60 matches is a weak test). The nudge: 0 nudge turns and 49 voice lines in 60 matches (the AI does not fly by choice, so nudge rows cannot read AI-vs-AI).
5. **The civilian band on a whole ring is 4.4% (12 to 30 band), a fail.** On the gen 2 slices it is 26.6%. The band was set for a slice; a whole ring has far more people, as RL-228 said it might. Game Design's call, not a bug. For RL-232 (power scale): the band cannot be read on a whole ring until it is re-based.
6. **Match length, AI vs AI:** gen 2 slices (200): median **464 s (7.7 min)**, p10 360, p90 **612.7 (over 600 by 13 s)**; whole ring (60): median 442, p10 365, p90 554. Longer than the earlier stack's 374 s median (this build has launch anywhere off and charge armour on; I did not split which). Encounter's 9.6 min does not reproduce here.
7. **`10.reach` is clean on this build:** 0 of 420,758 strikes beyond 68 units (gen 2, longest 68.0), 0 of 125,237 (whole ring, longest 67.6).
8. **Chase:** the pad mix starts 4.1 chases a match on easy (122 in 30) and 2.8 on medium, catching 83% and 85%; the X mash 0.1 to 0.2. AI-vs-AI `chase.perMatch` stays PENDING (the records do not count the cue on this build).
9. **PROP SMASH 4.6% where offered** (2.0 to 7.3; floor 5): in band by the point only.

Gen 2 slices, 200: 81 PASS, 24 FAIL. Fails other than the above are the old standing set (5b.perMin, the 5c landing mix, 10.reach.height, zip.countered, 7.beamEscape, 8.lock.median, 10.exPerMin, 10.end.launch, 10.end.continue) plus `2.len.p90`, `5.floor`, `5b.reach.care0`.

## Changed in QA

`swing-rows.js` now reads the build's real events: `swing_start` (kind the cause, amount signed degrees, dur ticks), `swing_rest`, `swing_place`, `swing_nudge` (a voice line); a nudge turn is a `swing_start` of kind `nudge`. `stickplay.gd` has an `afk` arm and counts the player's blows by strength and the chase, meteor, arc and armour cues.

## Not run

Meteor route (needs a bot), swing against swings-off (the swing setting is a setup key, `swing=off`, that `QA_PLANET` does not set), civilians-removed arm, stick-steals-run (waits for Game Design's yes), the energy core and launcher-against-full-B (waiting for Tools' power tree).
