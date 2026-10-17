# The planner's levers for buildings, parked (2026-10-13, built on main 8e2ee750)

Owner: Encounter Systems Director. Game Design's `docs/design/buildings.md` section 3: a launch along a street stays in the street, the distance and new-biome bonuses are held back in a settlement, and a building on the line is preferred from tier 2. What is built and what it read is in `files/docs/director/town-levers.md`.

**Read and gated on main (the chain with the levers, 8e2ee750): 28 of 30 gates, the chain's own two failures and nothing new.** From the crossing start, bodies into buildings go from 1.67 to 3.58 a match on 12 matches (the bound is 4 to 8; a build that also carried pass 2 read 4.17 on the same seeds). From the default start, launches that end in a building go from 3.9% to 9.3%, with the length and the collateral inside their bands. With a building in reach the planner now takes it 97 times in 100. Game Design has since retired the 35 to 60% band and reads the share by care (`buildings.md` section 4): it passes. The re-gate on main is below.

**To apply.**
1. `bash apply.sh <root> --check`, then `bash apply.sh <root>`: `sim/director/launch.gd` and `data/director/launch.json`, whole files, each checked against its base (`base.txt`). `town-levers.md` is new and is copied by hand to `docs/director/`.
2. `node schema/schema9.cjs <root>`: one optional key, `town`, in the launch schema (Tools', or by grant).
3. The golden regenerated (the launch decisions change), the gates.

**Re-gated on main 3198301f (2026-10-14).** The bases still match. Every gate passes: the golden regenerated (it moves), npm, parity, the validator and its self-test, determinism plain and with intros, the seam sweep, `anim_check`, the three `--strict` scans, the cue, read and HUD checks, `brawl_cases.gd`, World's five, QA's run-all, the flash count, the mash probe, the nine input tests, the loader on 200 matches. QA's harness (100 matches of the default arm and 100 from the crossing): 91 pass, 19 fail, no hard test. From the crossing: bodies into buildings 2.55 a match by QA's count (4 to 8: under), wall slams 1.60, a building in reach taken by a fighter whose care is 0 or less 97% (at least 80%), median 449 s and 10th percentile 364 s. On the default arm: median 434 s, 10th percentile 331 s, people 21.5%, front-row structures 41.4%.

**World's offers (`docs/world/destruction-hook.md` section 9), read on the levers.** My town probe, 24 matches from the crossing on the same seeds. Bodies into buildings by my count (every `building_hit`), 3.54 a match with the levers alone, 4.29 with World's `BR_MIN` at 160 units instead of 720 (a scratch edit of World's constant). A building is taken in 22% of launches, then 26%. Offers go from 4.6 to 4.8 a match. People lost 24.0% then 24.4%, structures lost 43.3 then 46.2 of 118, length level. **I want built, in this order:** `BR_MIN` 160 (one constant, and the one that moved the count); the nearest building on each side as a candidate (more plans, so the vote has more to take); the face plan with depth, later. QA's count, which takes a chain's landing once, will still be under 4 with both. Reaching its band needs what World names, more chains or more launches, and that isn't the planner's.

**With World's offers built (2026-10-15; `docs/world/scratch-build/near-offers/`, World's `sim/world/brunt.gd`), on the levers, main dfcb3ca1:**

| Row | Levers | + offer 1 (`BR_MIN` 160) | + offers 1 and 2 (the nearest building on each side too) |
| :--- | ---: | ---: | ---: |
| Bodies into buildings a match from the crossing, my count (24 matches) | 3.54 | 4.29 | 4.34 |
| The same, QA's count, a chain's landing once (100 matches; band 4 to 8) | 2.55 | 2.66 | 2.84 |
| Wall slams a match from the crossing (1 to 3) | 1.60 | 1.64 | 1.85 |
| Launches that end in a building first, default arm (4 to 10%) | 9.3% | 9.8% | 10.4% |
| A building in reach taken by a fighter whose care is 0 or less (at least 80%) | 97.0% | 95.0% | 93.5% |
| People lost; front-row structures lost (default arm) | 21.5%; 41.4% | 21.2%; 40.8% | 22.3%; 42.3% |
| Median; 10th percentile (default arm) | 434 s; 331 s | 428 s; 329 s | 435 s; 326 s |
| QA's harness | 91 pass, 19 fail | 91, 19 | 92, 18 |

- **Both offers together are best on both counts, and I'd take both,** in one window with the levers. No hard test fails in any build. Gates on that build, all 35 pass: the golden regenerated (it moves), npm, parity, the validator and its self-test, determinism plain and with intros, the seam sweep, `anim_check`, the three `--strict` scans, the cue, read and HUD checks, `brawl_cases.gd`, World's five, QA's run-all, the flash count, the mash probe, the nine input tests and the loader on 200 matches. The window: this park, then World's two diffs in order, then `schema9.cjs`, one golden.
- **QA's count is still under 4.** A chain counts once there, and the levers already vote for a building 93 to 97 times in 100 that one is in reach. The rest is World's "more chains or more launches", and that isn't the planner's.
- **The brunt share per launch reaches 10.4%,** a point over its band's top, with its interval to 12.6%. If that band holds, `bruntPrefer` comes down from 40, and the bodies with it.

Neither file is touched by the nine cells' chain (`../nine-cells-chain/`). By the EP's word it goes in after the chain, as its own window with its own golden and QA's 100 matches from the crossing.

## Window 2, re-based on main 46734840 (2026-10-17)

The levers with World's two offers, on main with window 1 (9d0530dc) and Simulation's depth window (46734840, off: play the same to the bit).
- **To apply, in this order:**
  1. `bash apply.sh <root> --check`, then `bash apply.sh <root>`.
  2. `node schema/schema9.cjs <root>`.
  3. World's `offer-1-near-edge.diff`, then `offer-2-nearest-per-side.diff` (`docs/world/scratch-build/near-offers/`, by `git apply`).
  4. Regenerate the golden.
- The bases still match, and both offers apply.
- **The full gate list passes, 35 of 35.** Play changes in 7 of the golden's cases.

Read against window 1 on the same seeds (window 1's copy plays as main does, since the depth window is off):

| Row | Window 1 | Window 2 | Band |
| :--- | ---: | ---: | :--- |
| QA's harness: rows passing, failing | 91, 19 | 93, 17 | |
| A building in reach taken by a fighter whose care is 0 or less | 36.9% | **94.9%** | At least 80%: now passes |
| Wall slams a match, from the crossing | 0.68 | **2.13** | 1 to 3: now passes |
| Bodies into buildings a match from the crossing, QA's count | 1.15 | **3.30** | 4 to 8: still under |
| ... my count (24 matches, the town probe) | 1.71 | **4.92** | |
| Launches that end in a building first, default arm | 3.3% | **11.0%** | 4 to 10%: now just over |
| Planner launches that are building brunts | 3.8% | **12.1%** | 4 to 10%: now over |
| Brunts a minute | 0.07 | 0.22 | 0.3 to 1.0: still under |
| People lost; front-row structures lost (default arm) | 23.3%; 42.6% | 23.2%; 44.4% | |
| Median length, default arm; from the crossing | 454.8 s; 477.6 s | 452.6 s; 458.3 s | |

- **Newly passing:** rallies a match (0.24 to 0.37), second breath (26.1% to 24.6%) and zips that end with the zipper caught.
- **Newly failing, narrowly:**
  - the halted share of launches, 43.9% to 38.4% (band 40 to 60%), as more of them end in a building;
  - crater-lip flights, 0.51 to 0.47 a minute (band 0.5 to 2.5);
  - long launches over 9,000 units, 30.7% to 28.8%.
- **No hard test fails.**
- **For Game Design and World:** the default arm's brunt share now overshoots its band while QA's crossing count is still under it. The two rows want different things: the crossing wants more bodies into buildings, the default arm fewer brunts. The levers' weights are the knob.
