# Gen 2 with the biome candidates and the lake floor on (QA, 2026-10-30)

Brief: the EP's push "get the new planet ready for Orb to play". The whole table on gen 2 with `launch_biome.json` `biome.enabled` on and the lake floor on, against the floor off, same seeds. Build: **HEAD 7f5d14ab**, two clean `git archive` copies with the committed `qa/godot/` laid over them; nothing switched in the tree.

Overlay, both arms (disclosed): `brawl.launcher.anywhere.enabled`, `anywhere.answer.enabled`, `water.enabled` (interrupts) and `rally.enabled` true; `biome.enabled` true. Everything else is HEAD's own (density on, `linkWorth` 0.8, `pop.full` 0.72, `stringPoints` 3, easy's answer 0.25). The only difference between the arms is the floor: **on** = `water.json` `surface.enabled` and `floor.enabled` (with interrupts `water.enabled`, as the load error requires); **off** = both false.

Setup: `QA_PLANET="gen=2;planets=3,7,11,13,17,19,23,25,37,31;touches=0,1,2,3;cols=2400"`, 200 matches on seeds 1 to 200 (same ring and touch in both arms), newcomer 200 per level, masher 100 per level. `--jobs=3`, below-normal priority. 95% intervals: seeded bootstrap over matches (`ring-rows.js`, `compare-arms.js`).

## The table

| Row (band) | Floor off | **Floor on** |
| :--- | :--- | :--- |
| Match length median / p10 / p90 (360 to 480; at least 300; at most 600) | 397.5 / **298.1** (287.1 to 316.1) / 537.3 | 403.0 / 308.2 (286.8 to 321.8) / 547.4 |
| Structures on the ring, mean (60 at least, aim 80) | 80.5 | 80.5 |
| Structures levelled a minute, tier 1 / 2 / 3 / 4 (at most 2; at most 4; 2 to 10; 6 to 20) | 1.37 / 3.29 / 7.41 / 11.82 | 1.49 / 3.49 (2.78 to 4.26) / 7.93 / 11.80 |
| Journeys over 4,000 units (at most 20%) | 14.9% (12.6 to 17.4) | 17.4% (14.8 to 19.9) |
| Bounces a bounced journey (1.2 to 2.0) | 1.64 (1.52 to 1.77) | 1.93 (1.78 to 2.09) |
| Civilians lost at the KO (12 to 30%) | 22.1% | 22.9% |
| Fight time underwater (at most 10%) | 2.9% | 2.2% |
| **PROP SMASH picked where offered (5 to 30%)** | 15.7% (10.6 to 20.8); 30 of 191 offers | 8.0% (4.6 to 11.4); 16 of 200 offers |
| PROP SMASH share of all planner launches / matches with one | 1.55% / 12.5% | 0.82% / 7.5% |
| Newcomer v easy, L17 (50 to 95%; GD 82 to 92), 200 | 87.5% (175 of 200) | 87.0% (174 of 200) |
| Newcomer v medium, L17 (10 to 50%), 200 | 27.0% (54 of 200) | 26.0% (52 of 200) |
| First-launch rows (thrown60, landed120, first60), easy and medium | 100% | 100% |
| Masher easy / medium / hard (60+; 35 to 50; at most 15), 100 each | 94 / 38 / 0 | 98 / 38 / 0 |

Row count, both arms: 90 PASS, 21 FAIL, 32 PENDING. Four rows change status: `2.len.p10` and `zip.caught` go FAIL to PASS with the floor on; `10.reach` and `mood.act4beforeBrink` go PASS to FAIL.

## Out of band, with an owner

1. **`10.reach` (hard test, floor on only): 2 strikes of 427,048 reach beyond 68 units, the longest 78.8.** Off it is 0 of 428,770 (longest 67.9). Likely cause (not read): the floor lifts a fighter in water up to 65 units off the bed, so a strike between a floored body and one on the bed can span more than reach. Owner: Simulation (the reach test reads the floor) and Encounter. Two in 427,000 and in water only, but it is a hard test and it is new with the floor.
2. **`mood.act4beforeBrink` 83.5% (77.7 to 88.0) against at least 80%, floor on.** The point is in band; the row fails on the interval rule (the lower end under 78). Off it is 86.0%. Watch; Game Design owns the band, Encounter the mood.
3. **Bounces 1.93, interval 1.78 to 2.09 straddles the 2.0 ceiling** (1.64 off). The floor moves it up by 0.3. Owner: Combat (bounce tuning), World.
4. **PROP SMASH 8.0% where offered, interval 4.6 to 11.4 reaches under the 5% floor.** In band on the point. It falls with the floor on (15.7 off) on a similar number of offers (200 against 191); I have not read why. Rules row 4 puts the score lever with Combat; at 8.0% the point does not call for it.
5. **p10 match length: off 298.1 (interval 287.1 to 316.1) is under 300; on 308.2 (286.8 to 321.8) is over.** Both intervals straddle 300, so the floor is neither the cause nor the cure; the 10 point gap is within sampling. See the autopsy below.
6. **The other FAIL rows are not the floor's or the biome's.** They fail in both arms here at about the same values (and on the 10-30 re-read): 5b.perMin, 5c.mix (halted, against, slam, caught, water), 5c.bounced, 5c.lip, 5c.terrain, 10.reach.height, zip.countered, 7.chain, 8.lock.median, mood.frenzied, mood.act4, 10.exPerMin, 10.end.launch, 10.end.continue, chase.perMatch. `5c.mix.water` is 1.1% off and 0.7% on against 2 to 10%: lower with the floor, since fewer bodies sink. Owners: Combat (landing mix and exchange rows), Game Design (the bands).

## Autopsy of the shortest 20 (p10 under 300, floor off) and the same on the floor-on arm

`qa/godot/autopsy.js` (damage by source) and the new `qa/godot/short-launches.js` (launch kinds, shortest 20 against the other 180).

- **The shortest 20 run 247 to 297 s (median 278).** They are brawl matches: 80.4% of the loser's damage is brawl blows, 14.3% energy, 2.3% full-launch landings.
- **Launches a minute: 0.99 in the short ones against 1.35 in the rest, and damage a second 78.3 against 63.6.** They are short because the brawl hits harder and fewer launches interrupt it, not because a launch kills.
- **No candidate is the cause.** PROP SMASH has the largest ratio (4 launches in the short set, 24 in the rest, x2.3) on counts too small to read. The kinds the short matches have fewer of are UPPERCUT (x0.40) and SMASH ACROSS (x0.71); MOUNTAINSIDE is x1.23. The short 20 are spread over 18 different ring and touch pairs.
- **With the biome switch off the shape is the same** (HEAD 7dc7ca2a's biome-off records: short 74.5 against 63.5 damage a second, 1.03 against 1.32 launches a minute; p10 317.9). Floor on: shortest 20 run 227 to 307 s, 0.95 against 1.36 launches a minute, 77.9 against 62.9 damage a second: the same.
- **Read:** p10 near 300 is a feature of the brawl's damage rate, with a sampling spread of about ±15 s on 200 matches. The biome switch moves it by less than that. If Orb wants the tail lifted, the lever is the brawl's damage (Game Design, Combat), not any launch candidate.

## Validity

Machine load (CPU over 16 logical cores, between stages): floor off 48 / 68 / 58 / 57 / 23% and floor on 50 / 74 / 69 / 48 %, with 12 to 18 Godot processes of other sessions beside my 6. Both arms ran loaded. No match was capped, timed out or budget-stopped, no ring fell back to the hand-made world, and the matches are seed-deterministic, so load changes the clock and not a number; I have not marked either arm invalid on that ground. The newcomer and masher counts are of 100 or 200 matches, point estimates. Hashes repeat on 5 seeds: not re-run.

---

SUMMARY: With biome and the lake floor on, gen 2 reads in band on nearly every row, floor on against off: p10 308.2 against 298.1 (both straddle 300), PROP SMASH 8.0% where offered against 15.7% (in band both), newcomer 87.0 / 26.0%, masher 98 / 38 / 0, underwater 2.2%. New with the floor: `10.reach` fails by 2 strikes of 427,048 (longest 78.8). Bounces 1.93 straddle the 2.0 ceiling.

CHANGES: `qa/godot/short-launches.js` (new), this report.

DECISIONS: Arms differ only in `surface.enabled` and `floor.enabled`; the other switches match the 10-30 re-read.

NEEDS FROM EP: route `10.reach` (2 strikes beyond 68 in water, floor on) to Simulation and Encounter; decide whether bounces at 1.93 matter before the switch.

RISKS: Ten planets and four touches are a sample; both arms ran under other sessions' load (valid by determinism); the p10 gap is within sampling.

NEXT: Frozen; on the EP's word, a second 200 on seeds 201 to 400 to tighten p10 and the `10.reach` count.
