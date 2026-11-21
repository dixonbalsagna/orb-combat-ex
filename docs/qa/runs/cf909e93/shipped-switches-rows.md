| Status | Id | Measure | Value | Band |
| :--- | :--- | :--- | :--- | :--- |
| PENDING | 1.protagonist | Protagonist win rate over both slots |  |  |
| PENDING | 1.mirror-villain | mirror-villain slot and spawn effects |  |  |
| PENDING | 1.mirror-hero | mirror-hero slot and spawn effects |  |  |
| **FAIL** | 2.len.median | Match length median (game, 1v1) | 359.9 s | 360.0 s to 480.0 s |
| **FAIL** | 2.len.p10 | Match length, 10th percentile | 289.4 s | at least 300.0 s |
| PASS | 2.len.p90 | Match length, 90th percentile | 455.6 s | at most 660.0 s |
| **FAIL** | 2.timeouts | Timeouts at the 900 s cap | 0.0% [-0.0%, 6.0%] | at most 1.0% |
| PASS | 3.tier3 | A fighter reaches tier 3 before the KO | 100.0% [94.0%, 100.0%] | at least 70.0% |
| PASS | 3.tier4 | A fighter reaches tier 4 before the KO | 98.3% [91.1%, 99.7%] | at least 60.0% |
| PENDING | 3.transform | First transformation timing; the last 60 s has a clash or finisher |  |  |
| INFO | 4.civ.mean | Civilians lost at the KO, mean share of ALL the people on the planet (whole ring: information only, RL-244) | 0.00% |  |
| PENDING | 4.civ.reached | Civilians lost, share of the people in the places the fight reached (12 to 30%; RL-245) |  |  |
| PASS | 4.civ.worst | Worst pairing's mean civilians lost (default) | 0.00 | at most 55.00 |
| PASS | 4.civ90.default | Matches losing 90% or more of civilians (default) | 0.0% [-0.0%, 6.0%] | at most 10.0% |
| PASS | 4.bleed | Low-tier bleed: civilians lost per minute while both fighters are at tier 2 or below, % of population (default arm) | 0.00 | at most 4.00 |
| PASS | 4.struct.row1 | Structures lost at the KO, mean share of row-1 (front-row) structures | 38.19 | 25.00 to 50.00 |
| INFO | 4.struct.all | Structures lost, all rows (watch metric, not a gate; §21 band 15 to 40%) | 25.3% |  |
| INFO | 4.struct.row1 | Structures lost, row 1 | 38.2% |  |
| INFO | 4.struct.row2 | Structures lost, row 2 | 39.6% |  |
| INFO | 4.struct.row3 | Structures lost, row 3 | 0.0% |  |
| INFO | 4.struct.wrecked | Structures wrecked at the KO (stage 3 or 4), all rows, mean share (default arm) | 29.0% |  |
| INFO | 4.struct.wrecked.row1 | Structures wrecked at the KO, row 1 | 44.1% |  |
| INFO | 4.struct.wrecked.row2 | Structures wrecked at the KO, row 2 | 45.2% |  |
| INFO | 4.struct.wrecked.row3 | Structures wrecked at the KO, row 3 | 0.0% |  |
| PENDING | 4.cyborg | Civilians left at 4:00: at least 25% alive in at least 80% of matches |  |  |
| INFO | 4b.rolling | Matches with a 60 s window over the tier budget (2%, 4%, 8%, 15%): what the ramp will have to change (default arm) | 0.0% |  |
| INFO | 4b.ceiling | Matches over the cumulative ceiling (10%, 30%, 60%, 90% by highest tier so far) (default arm) | 0.0% |  |
| INFO | 4b.split | Per-tier split of casualties by the higher tier when they happened (default arm) | tier 1 NaN%, tier 2 NaN%, tier 3 NaN%, tier 4 NaN% |  |
| PASS | 5.cap.default | No launch type above 45% (default): largest is SMASH ACROSS | 23.5% [19.7%, 27.3%] | at most 45.0% |
| PASS | 5.cap.default.upper | Largest launch type's clustered upper bound at most 47% (default) | 27.3% | at most 47.0% |
| PASS | 5.floor | At least 4 launch types at or above 5% (default arm) | 4.00 | at least 4.00 |
| **FAIL** | 5b.share | Share of all planner launches that are building brunts (4 to 15%; was 4 to 10% until 2026-10-17, buildings.md section 4) | 16.1% [12.7%, 19.6%] | 4.0% to 15.0% |
| **FAIL** | 5b.perMin | Brunts per minute (0.3 to 1.0, game-scale band; re-based at M1b) | 0.19 | 0.30 to 1.00 |
| INFO | 5b.mirrors | Villain and hero mirror brunt rows | retired |  |
| INFO | 5b.reach | Launches that pick a building, out of those with a building candidate in reach, pooled (the 35 to 60% band is RETIRED: buildings.md section 3, 0c677f0c) | 73.7% |  |
| **FAIL** | 5b.reach.care0 | A building in reach is taken by a fighter whose care is 0 or less (at least 80%: "preferred" means taken; buildings.md section 4) | 73.7% [64.0%, 81.5%] | 80.0% to 100.0% |
| PENDING | 5b.reach.cares | A building in reach is taken by a fighter who cares, while people are inside (under 35%) |  |  |
| PENDING | 5b.propSmash | PROP SMASH is picked when it is offered (5 to 30%) |  |  |
| PENDING | 5b.chains | Chains among brunts, chain lengths, the per-tier casualty budget for one chain (hard test), the launcher tier cap (hard test) |  |  |
| **FAIL** | 5c.mix.halted: | How launches end: halted: of the journeys that end on the ground (halt, wall or slam), the journey ends skidding or tumbling to a stop, with or without bounces first (40 to 60%; re-based on ground endings 2026-10-17) (per launch) | 99.7% [99.2%, 100.3%] | 40.0% to 60.0% |
| **FAIL** | 5c.mix.against | How launches end: against a wall (a slope steeper than 0.8; 5 to 15%) (per launch) | 0.0% [0.0%, 0.0%] | 5.0% to 15.0% |
| **FAIL** | 5c.mix.slam: | How launches end: slam: the journey ends in a crater (8 to 18%) (per launch) | 0.2% [-0.2%, 0.7%] | 8.0% to 18.0% |
| **FAIL** | 5c.mix.caught | How launches end: caught in the air (the follow-up before the journey ends; 15 to 30%) (per launch) | 4.4% [2.4%, 6.4%] | 15.0% to 30.0% |
| INFO | 5c.haltOfGround | Halted as a share of journeys that end on the ground (halt, wall or slam; the old at-least-55% row is superseded by the re-based 40 to 60% row above, 2026-10-17) | 99.7% |  |
| PASS | 5c.largest | Halted is the largest class (balance-targets 20) | halt 80.2%, wall 0.0%, slam 0.2%, caught 4.4%, water 0.9%, brunt 13.1% | halted largest |
| PASS | 5c.bounced | Launches with at least one bounce (20 to 40%, balance-targets 23; the boundary is 40 degrees) | 35.5% [31.7%, 39.3%] | 20.0% to 40.0% |
| PASS | 5c.firstContacts | First contacts: skids at least as common as bounces | skid or tumble 139, bounce 41, slam 52, stop 0 | skids at least bounces |
| **FAIL** | 5c.mix.water | How launches end: water (skim or splash first; 2 to 10%, re-based at §21) (per launch) | 0.9% [0.0%, 1.8%] | 2.0% to 10.0% |
| PASS | 5c.mix.brunt | How launches end: brunt (a building first, launches that end in a building; 4 to 15%, was 4 to 10% until 2026-10-17) (per launch) | 13.1% [9.7%, 16.5%] | 4.0% to 15.0% |
| INFO | 5c.other | Planner launches with no contact and not caught (KO, the cap, launched again first), share of launches | 1.2% |  |
| INFO | 5c.stop | Planner launches that landed at a stop (a contact under 350, no skid or tumble), share of launches | 0.0% |  |
| INFO | 5c.all | Landing mix over every launch event, beam and finisher launches included (not banded) | slide 90.2%, slam 0.1%, caught 2.2%, bounce 0.0%, water 0.5%, brunt 4.6%, none 2.4% |  |
| **FAIL** | 5c.lip | Flights off a crater lip a minute, seen (in the air at least 10 ticks; 0.4 to 2.5, the floor was 0.5 until 2026-10-17) | 0.25 | 0.40 to 2.50 |
| **FAIL** | 5c.terrain | Flights off any terrain a minute, seen (lips, crests, cliffs, heaps; 1.5 to 5) | 0.59 | 1.50 to 5.00 |
| PASS | 5c.capped | Journeys that reach the 4 s or 8-contact bound (at most 8%) | 0.0% | at most 8.0% |
| **FAIL** | 5c.long | Journeys longer than 4,000 units (at most 20%; Camera chase rule covers them) | 24.5% | at most 20.0% |
| PASS | 5c.bounces | Bounces per bounced journey, mean (1.2 to 2.0) | 1.79 | 1.20 to 2.00 |
| PENDING | 5c.tumble | Halted journeys with a tumble that is seen (tumble_end of 18 ticks or more; 30 to 60%) |  |  |
| PENDING | 5c.tech | Early recoveries as a share of the chances, medium AI (20 to 40%) |  |  |
| INFO | 5c.detail | Slides: mean length and trench width; slams per match; water skims per match | 5743 units, 296.8 wide; 12.0 slams; 9.8 skims |  |
| PENDING | 5c.budget | Casualties from one slide at most 2% (tier 2 or below), 5% (tier 3), 10% (tier 4); 0 in open country; the planner declines launches over budget (hard tests) |  |  |
| INFO | 10.heavy.default | Heavies landed and heavy clashes won per minute of match, both fighters (default; Game Design's estimates about 6 and 1.5) | 3.32 and 0.00 |  |
| PASS | 15.str.t1 | Structures levelled per minute at tier 1, % of all structures (at most 2%) | 1.19 | at most 2.00 |
| PASS | 15.str.t2 | Structures levelled per minute at tier 2, % of all structures (at most 4%) | 1.45 | at most 4.00 |
| PASS | 15.str.t3 | Structures levelled per minute at tier 3, % of all structures (2 to 10%) | 3.99 | 2.00 to 10.00 |
| PASS | 15.str.t4 | Structures levelled per minute at tier 4, % of all structures (6 to 20%) | 8.05 | 6.00 to 20.00 |
| INFO | 10.launches.perMatch | Launches a match, the AI against itself, with the match median, the 10th percentile and the civilians lost beside it (6 to 12; the top is 14 if all three hold) | 7.2 a match; median 361 s, 10th percentile 291 s, civilians lost 0.0% |  |
| **FAIL** | 11.blast | Blasts as a share of match damage (10 to 25%, provisional) | 6.7% [6.5%, 7.0%] | 10.0% to 25.0% |
| PASS | 11.signature | Signatures (beams) as a share of match damage (at most 30%, provisional) | 6.8% [6.4%, 7.3%] | at most 30.0% |
| PASS | 10.reach | Damaging melee strikes within 68 units of horizontal reach (hard test, 100%) | 0 of 109437 strikes beyond 68 units; longest 67.6 | 100% within 68 |
| PASS | 10.reach.height | A height difference beyond 68 units only on sloped ground (hard test) | 4 strikes with more than 68 units of height difference, 0 of them on flat ground; largest 94.3 | none on flat ground (slope at most 0.15, no ground step between the two) |
| PASS | 6.time.default | No biome holds more than 40% of fight time (default): largest is forest | 32.5% | at most 40.0% |
| **FAIL** | 6.time.floor | Every biome holds at least half its planet share or 3% of fight time, whichever is lower (default arm) | ocean 19.8%, village 0.0%, plains 25.6%, city 0.0%, forest 32.5%, desert 9.7%, mountains 12.4% | see rule |
| PASS | 6.variant.cap | No beam variant above 40% of beams: largest is FIRESTORM | 32.9% | at most 40.0% |
| **FAIL** | 6.variant.floor | Every beam variant at least 3% of beams (one planet; FIELD SCAR at least 2%, §21) | HORIZON CLEAVE 18.4%, BOULEVARD RAZE 0.0%, FIRESTORM 32.9%, RIDGE BORE 11.5%, GLASS TRENCH 9.7%, FIELD SCAR 27.5% | at least 3.0% each (SCAR 2.0%) |
| PENDING | 6.planets | Location and variant bands over a fixed set of at least 20 seeded planets |  |  |
| INFO | 7.parry | Parries per 100 melee exchanges | retired |  |
| PASS | 7.pb.perMin.medium | Perfect blocks a minute, medium AI (1 to 4; Game Design, melee-press-feel 9f; sixth round: easy 0.5 to 2.5, hard 2 to 6.5) | 2.11 | 1.00 to 4.00 |
| INFO | 7.pb.medium | Perfect blocks per 100 melee exchanges, medium AI (the old basis, reported; 5 to 15 before the brawl) | 34.93 |  |
| INFO | 7.pb.perblow | Perfect blocks per 100 blows thrown in brawls (the brawl basis; proposed band to be set by Game Design) | 0.69 |  |
| INFO | 10.brawl.perMin | Brawls a minute, blows a minute, closes a minute (flurry staggers), heavy staggers a minute, trade breaks a minute | 3.0, 305.9, 1.8, 2.7, 2.0 |  |
| INFO | 10.brawl.len | Median brawl length and blows (B5: 6 to 12 s and 10 blows or more; the share of fight time in a brawl 45 to 60%) | 7.2 s and 79 blows; 45.9% of fight time |  |
| PASS | 10.brawl.share | Share of fight time in a brawl, the AI against itself (30 to 50%; until the zip the demo target is 25%) | 45.9% | 30.0% to 50.0% |
| INFO | 10.brawl.ends | How brawls end, as shares of brawls (the basis for "knock-backs" and "continues": a brawl continues until it ends; the 25 to 35% and 40 to 50% bands read against launch decisions) | signature 58.3%, launch 16.9%, double 11.9%, break 7.0%, idle 5.8%, knockback 0.1% |  |
| INFO | 10.partings.byKind | Partings a match, by kind: launch, knock-back, throw, shove, double hit (reported until C2b) | launch 3.05, knockback 0.02, throw 0.00, shove 0.00, double 2.15 |  |
| INFO | zip.perMin | Zips a minute, and by kind | 0.13 a minute (37 strikes, 12 heavies over 49) |  |
| **FAIL** | zip.clean | Zips whose blow lands clean, against an opponent who answers (35 to 55%) | 69.4% [55.5%, 80.5%] | 35.0% to 55.0% |
| **FAIL** | zip.countered | Zips countered by a tech or heavy strike (10 to 25%) | 8.2% [3.2%, 19.2%] | 10.0% to 25.0% |
| **FAIL** | zip.caught | Zips that end with the zipper caught (20 to 35%) | 10.2% [4.4%, 21.8%] | 20.0% to 35.0% |
| PASS | zip.kiShare | Ki spent on zips, as a share of all ki spent (at most 25%) | 1.3% | at most 25.0% |
| INFO | zip.reported | Zips reported: blocked, dodged (a zip that completed and did no damage), stopped by a shot, outrun, knocked down, and every end | blocked 18.4%, dodged 0.0%, stopped by a shot 2.0%, outrun 4.1%, down 0.0%; ends {"done":37,"outrun":2,"countered":4,"caught":5,"stopped":1} |  |
| PASS | zip.price | A zip costs exactly the table ki, paid at the press (hard test) | 49 of 49 on the table | strike 20, heavy 30 |
| PASS | zip.price.kept | Every zip record keeps the price the director printed at its press, one that ended in its first tick included (harness test) | 49 of 49 zips keep the printed price | all of them |
| PASS | zip.table | A zip tell is the table ticks and its whole length is in the table range for the default exit (hard test; the ticks in reach are the zip.reach row) | 49 of 49 on the table | strike tell 6, whole 32 to 34; heavy tell 10, whole 52 to 54 (up to 12 more for a longer exit) |
| PASS | zip.reach | The ticks in reach before and after the blow are exactly the table: strike 4 and 6 (8 before when held), heavy 12 and 10 (4 off a rushed tap, two at most) (hard test) | 42 played zips and 49 plans on the table | strike 4 and 6 (held 8 before); heavy 12 and 10 |
| PASS | zip.travel | Travel is never under the floor, each way: at least max(4, ceil(distance in bh / 3)) ticks (Legal RL-076, a hard test) | 49 of 49 at or over the floor | at least max(4, ceil(bh / 3)) ticks |
| PENDING | zip.exit | No stick exit over 12.5 bh from the rival or inside the ground or a building; the home exit is exempt (hard test) | no zip left by a stick exit yet | at most 12.5 bh, never inside |
| PASS | zip.brawl | No brawl is announced during a zip unless the zipper is caught or countered (hard test) | 0 over 49 zips | never |
| INFO | zip.drops | The dropped state: drop_start, drop_land and drop_end (reported; every start should land and end, apart from a KO in the air) | 0 starts, 0 lands, 0 ends |  |
| INFO | double.perMatch | Double hits a match, the AI against itself (reported; the band 0.5 to 2 is for a presser against the medium AI: the double.presser rows) | 2.15 |  |
| INFO | double.matchesWith | Matches with at least one double hit, the AI against itself (reported) | 91.7% (55 of 60) |  |
| PASS | double.max | Never more than 4 double hits in one match (hard test) | the most in one match is 4 | at most 4 |
| PASS | double.cue | Every double_hit cue ends its brawl with the text double, and every double end follows a cue (hard test; a KO in the 8 ticks between may cost one) | 129 cues, 129 double ends | equal (within 2%) |
| PASS | double.trade240 | Every double hit comes from a trade level for 240 ticks (hard test: the cue's dur, the trade's length, is 240 to 244) | 129 of 129 at 240 to 244 | 240 to 244 |
| PASS | double.both | Both fighters are hit by a double hit (hard test) | 129 of 129 hit both | both take damage on the landing tick |
| INFO | double.after | The double hit: damage to each and the separation 30 ticks after the landing (reported; the rule: 4 brawl lights each, thrown back 6 bh each way, so about 12 bh apart from the centre) | 35.8 and 36.6 damage; apart 0.8 bh at the throw, 9.0 bh after 30 ticks |  |
| INFO | 7.pb.byStrength | Perfect blocks per 100 blows by strength (reported; held as bands after the first three-strength baseline: lights 0.5 to 1.5, mediums 2 to 6, heavies 6 to 15 at medium) | no perfect block carries its strength on this build (the stagger source) |  |
| PASS | 10.energy.share | Energy blows as a share of the AI's brawl blows (5 to 15%) | 5.1% | 5.0% to 15.0% |
| PASS | 10.windup.perMin | The AI winds up or charges a medium or a heavy, a minute of brawl, per fighter (4 to 10; an AI-against-AI match has two fighters, so the total is counted twice: 8.9 in all) | 4.45 | 4.00 to 10.00 |
| PASS | 7.chain | Chains per 100 melee exchanges (10 to 30, agency pass 14; strings now come from the presses) | 17.55 | 10.00 to 30.00 |
| PASS | 7.slip | Pursuit slip rate (escape gamble) | 43.9% [39.5%, 48.3%] | 35.0% to 65.0% |
| PASS | 7.beamEscape | Beam escape rate against an ESCAPE defender | 30.0% [19.1%, 43.8%] | 20.0% to 50.0% |
| PENDING | 7.probe | Fixed-stance round robin: no forced stance above 55%, each stance below 45% against some other |  |  |
| INFO | 8.hides | Hides and ambushes | retired |  |
| PENDING | 8.sigs | Signatures fired per match (2 to 4, median 3) | today 13.0 (median) | 2 to 4 |
| **FAIL** | 8.clash | Beam clashes: share of signatures fired that end in a CLASH (30 to 60%; re-based at G0) | 20.7% [17.8%, 23.7%] | 30.0% to 60.0% |
| PASS | 8.lock.max.all | No lock break longer than 4 s, all arms (hard test) | longest 4.02 s (default seed 23 from 332.9 s); 0 over 4 s of 153 | at most 4 s |
| PASS | 8.lock.perMatch | Lock breaks per match (1 to 4) | 2.55 | 1.00 to 4.00 |
| **FAIL** | 8.lock.median | Median lock-break length (2 to 3 s) | 1.4 s | 2.0 s to 3.0 s |
| PASS | 8.lock.max | No lock break longer than 4 s (hard test) | longest 4.02 s over 153 breaks | at most 4 s |
| PASS | 8.lock.gap | Never within 6 s of the same fighters last one (hard test) | shortest gap 6.90 s over 74 | at least 6 s |
| INFO | 8.lock.attempts | Attacks refused for lost lock (lock_lost) per match | 0.05 |  |
| PASS | 8.brink2ko | Brink to KO, median (45 to 90 s) | 85.8 s | 45.0 s to 90.0 s |
| PASS | 8.firstBrink | First brink, median (4:30 to 7:00) | 275.6 s | 270.0 s to 420.0 s |
| **FAIL** | 8.survival | Finisher survival rate (25 to 40%) | 25.9% [17.6%, 36.4%] | 25.0% to 40.0% |
| **FAIL** | 8.rallies | Rallies per match (0.3 to 0.7) | 0.28 | 0.30 to 0.70 |
| PASS | 8.regionBreaks | Region breaks per match (1.5 to 2.5) | 2.37 | 1.50 to 2.50 |
| PASS | 8.limbBreaks | Limb breaks per match (0.3 to 0.5) | 0.32 | 0.30 to 0.50 |
| **FAIL** | 8.limbArms | Arms share of limb breaks (35 to 65%; legs is the rest) | 31.6% | 35.0% to 65.0% |
| PASS | 8.breath | Second breath: battered wear recovered through it, as a share of all battered wear taken (at most 25%) | 13.5% | at most 25.0% |
| INFO | k.rate | Damage per minute to the loser (input to the k retune: k_new = k_old x rate before / rate after) | 2072.7 |  |
| PENDING | 8.blitz | Blitz rate: 2 to 6 a minute in Tense and Frenzied acts |  |  |
| PENDING | 8.comebacks | Comebacks 15 to 35% of matches; lead changes median at least 2 |  |  |
| PASS | mood.calm | Mood: Calm share of match time (20 to 40%, re-based for the brawl, spec-wounds §9) | 29.9% | 20.0% to 40.0% |
| PASS | mood.tense | Mood: Tense share of match time (40 to 65%, re-based for the brawl, spec-wounds §9) | 53.3% | 40.0% to 65.0% |
| PASS | mood.frenzied | Mood: Frenzied share of match time (5 to 20%) | 16.7% | 5.0% to 20.0% |
| PASS | mood.calmAct1 | Calm share of act 1 (at least 60%) | 80.0% | at least 60.0% |
| PASS | mood.frenziedAct4 | Frenzied share of act 4, the climax (at least 15%) | 21.9% | at least 15.0% |
| PASS | mood.act2 | Act 2 starts at, median (1:30 to 2:30) | 101.0 s | 90.0 s to 150.0 s |
| PASS | mood.act3 | Act 3 starts at, median (2:30 to 4:00) | 169.6 s | 150.0 s to 240.0 s |
| **FAIL** | mood.act4 | Act 4 starts at, median (4:30 to 5:45) | 244.6 s | 270.0 s to 345.0 s |
| **FAIL** | mood.act4beforeBrink | Act 4 arrives before the first brink (at least 80% of matches with a brink) | 78.3% [66.4%, 86.9%] | at least 80.0% |
| PASS | style.entries | Style label entries per fighter per match, median (at most 3; AI play) | 1.00 | at most 3.00 |
| PASS | style.events | Style label events per fighter per match, entries and endings, median (at most 5) | 1.00 | at most 5.00 |
| PASS | style.shortest | Shortest label held (at least 12 s; a label cut off by the KO is not counted) | 36.4 s | at least 12.0 s |
| PASS | style.unlabelled | Unlabelled share of match time, mean (at most 40%) | 15.6% | at most 40.0% |
| **FAIL** | 10.exPerMin | Exchanges started per minute (15 to 28, agency pass 14) | 8.23 | 15.00 to 28.00 |
| INFO | 10.exLen | Exchange length, request to release, median | retired |  |
| INFO | 10.gap | Breathing room, release to the next request, median | retired |  |
| PASS | 10.gap10 | Matches with no gap over 10 s (a gap: no strike, blast, charge or taunt from either fighter) | 100.0% [94.0%, 100.0%] | at least 95.0% |
| PASS | 10.end.launch | Exchanges that end in a launch, of those that reach a launch decision (18 to 30%, agency pass 14) | 27.6% [25.7%, 29.6%] | 18.0% to 30.0% |
| INFO | 10.end.knockback | Exchanges that end in a knock-back, of those that reach a launch decision (RETIRED in the sixth round: a brawl has no launch decision for each exchange; it belonged to the planned exchange) | 16.3% |  |
| PENDING | 10.end.separating | Launches as a share of the partings (the brawls that end with the two parted: a launch, a knock-back, a throw, a shove or a double hit; 25 to 40%, the figure from Orb) |  |  |
| **FAIL** | 10.end.continue | Exchanges after which the brawl continues (STAY), of those that reach a launch decision (40 to 50%) | 56.1% [53.6%, 58.6%] | 40.0% to 50.0% |
| INFO | 10.end.split | Melee exchanges: reach a launch decision / of those launch, knock-back, stay | 42.2% reach one; 27.6% / 16.3% / 56.1% |  |
| INFO | 10.launchShare | Launches as a share of exchanges, planner launches over all exchanges (old row, band 40 to 65% retired by agency pass section 3) | 14.1% |  |
| **FAIL** | 10.longHaul | Launches with at least 9,000 units of horizontal travel (1,500 x the launch traversal factor), of the launches that do not end in a building | 21.0% | at least 30.0% |
| PENDING | flip.perMin | Recoil flips a minute, both fighters (2 to 6) |  |  |
| PENDING | flip.counter | Counter-rush follow-ups after a flip |  |  |
| PENDING | chase.perMatch | The chases of a launch the AI threw, a match, AI against AI (1 to 4) |  |  |
| PENDING | chase.catch | Of the chases of the AI, the share that catch the body (at least 60%) |  |  |
| PENDING | wallkick.perMatch | Wall kicks a match in AI play (0.2 to 2 from a city start; watched from the default start) |  |  |
| PENDING | campaign.episode | An episode's length, median (40 to 50 minutes) |  |  |
| PENDING | campaign.places | A column's places from the pair, each way, on a Half ring (322 to 806 columns; columns 1 to 4, the climax may lie farther) |  |  |
| PENDING | campaign.turns | Columns 1 to 4 that turn the ring (40 to 60%; raise minGain first, then lower turn.bonus: rulings-2026-10-26 item 5) |  |  |
| PENDING | campaign.partner | Stages won with a partner who joined mid-stage (read only, to tune x1.6) |  |  |
| PENDING | campaign.rescues | Rescues won (30 to 60%) |  |  |
| PENDING | campaign.rematches | Rematches won after Previously on (50 to 75%: the lesson should help, not decide) |  |  |
| PENDING | campaign.templates | Templates repeated inside one episode (none); inside an arc at most 3 |  |  |
| PENDING | rally.dazes | Dazes a match, AI against AI (2 to 8) |  |  |
| PENDING | rally.perMatch | Rallies a match (3 to 10) |  |  |
| PENDING | rally.links | Links a rally, median (2 to 4); a rally's links are their own row, and the full-launch row counts a rally once, by its opening send (rulings-2026-10-26 item 11) |  |  |
| PENDING | rally.repeat | Two links of one kind in a row, of the links (at most 25%) |  |  |
| PENDING | rally.autotech | Rallies ended by repetition, the tech by itself (at most 20%) |  |  |
| PENDING | rally.turns | Rallies that turn at least once (15 to 40%; 10 to 40% for AI v AI only if links and turns still conflict, rulings-2026-10-26 item 9) |  |  |
| PENDING | rally.time | Rally time, of match time (at most 25%) |  |  |
| PENDING | rally.sells | Sells a daze (reported) |  |  |
| PENDING | design.L16.ai | Full launches a match, the AI against itself (power 0.8 or more at the send, after freshness; 6 to 12) |  |  |
| PASS | 10.newBiome | Launches that land in a different biome | 47.5% | at least 25.0% |
| PASS | 10.underwater | Fight time underwater (both fighters) | 1.7% | at most 10.0% |
| PENDING | 10.rest | Strike spacing, wind-up width, hit-stop floors, gap-close flight |  |  |
| PASS | 11.bleed | Low-tier bleed with every living-destruction source included (same measure as §4) | 0.00 | at most 4.00 |
| PENDING | 11.fires | Spreading fires: 0.5 to 3 in matches with 5% of fight time in forest or villages |  |  |
| PENDING | 11.forest | Forest burnt at the end among tier-3 matches: 15 to 60% of trees |  |  |
| PENDING | 11.clouds | Cover-capable clouds 3 to 10 |  |  |
| PENDING | 11.slides | Real slides 0.5 to 2; at most 1 peak collapse |  |  |
| PENDING | 11.quakes | Quakes in 30 to 70% of tier-4 matches, at most 2; rifts at most 1 |  |  |
| PENDING | 11.lava | Lava events 1 to 3 in tier-4 matches |  |  |
| PENDING | 11.wear | Hazard share of all wear at most 15% |  |  |
| PENDING | arena.turns.max | The arena calm turn: at most 4 a match, 60 s apart (hard) |  |  |
| PENDING | stick.balance | Hand-to-hand balance with stick strikes on: the Protagonist win rate within 3 points of the default arm, same seeds |  |  |
| PENDING | stick.claw | Zero claw advantage with stick strikes on (the Controls claw-bot gate, strike_gate_test.gd: a hard test in the gate own run) |  |  |
| PENDING | swing.share | Swings: share of fight time spent swinging (3 to 8%; Game Design 2026-11-02, it was 10 to 15%) |  |  |
| PENDING | swing.big | Big swings a match, mean (6 to 12) |  |  |
| PENDING | swing.jolts | Jolts a match, mean (20 to 40, section 10) |  |  |
| PENDING | swing.batch.launch | Batch cap on the big swings (see below) |  |  |
| PENDING | swing.causes3 | Matches with at least three causes among the big swings (matches with at least 6; "most", so over 50%) |  |  |
| PENDING | swing.batch.size | Batch cap on the size bands (see below) |  |  |
| PENDING | swing.biomes | Biomes seen in a match, swings on against the same seeds with swings off (clearly above: at least +1 with the interval above 0) |  |  |
| PENDING | swing.gap.min | The shortest gap between two swings, a match (reported) |  |  |
| PENDING | swing.toll.assoc | No positive association between the civilian toll and a match's big swing count or swing time (RL-215) |  |  |
| PENDING | swing.civless | A run with the civilians removed swings the same number of times, within one (RL-215) |  |  |
| PENDING | nudge.turn.place | The nudge never turns over 6 degrees for one place (hard, section 13) |  |  |
| PENDING | nudge.turn.10s | The nudge never turns over 10 degrees in any 10 s (hard, section 13) |  |  |
| PENDING | nudge.rate | The nudge's rate is never over 3 degrees a second (hard, section 13) |  |  |
| PENDING | nudge.lines | Nudge voice lines a match (about 2 to 5, a soft count) |  |  |
| PENDING | nudge.toll.assoc | No positive association between the civilian toll and the nudge's strength or frequency (RL-216) |  |  |
| PENDING | hunger.toll.assoc | No association between the civilian toll and the Cyborg's Hunger (RL-217) |  |  |
| **FAIL** | clean.near | Time near a building: the pair midpoint with a standing structure within 1,500 units, sampled twice a second (20 to 35%; QA's definition of "near") | 16.07 | 20.00 to 35.00 |
| **FAIL** | clean.sends | Sends into a building a match (landings that end on a building; 4 to 8 from a start in town, QA does not restrict the start) | 0.95 | 3.00 to 6.00 |
| **FAIL** | clean.visited | Places visited a match (first ring and far alike; a fighter within 1,500 units of one of its buildings as it fell; 2 to 4) | 1.88 | 2.00 to 4.00 |
| PENDING | clean.felled | Buildings felled with swings on, against swings off (at least two thirds); needs an arm "swingsoff" |  |  |
| PASS | clean.sea | The open sea's share of fight time (at most 25%) | 19.75 | at most 25.00 |
| INFO | clean.broken | Buildings broken a minute (reported, whole fight; the in-frame read is Camera's) | 9.86 |  |
| INFO | clean.craters | Craters made a minute (reported, whole fight; the in-frame read is Camera's) | 6.47 |  |
