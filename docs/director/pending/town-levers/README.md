# The planner's levers for buildings, parked (2026-10-13, built on main 8e2ee750)

Owner: Encounter Systems Director. Game Design's `docs/design/buildings.md` section 3: a launch along a street stays in the street, the distance and new-biome bonuses are held back in a settlement, and a building on the line is preferred from tier 2. What is built and what it read is in `files/docs/director/town-levers.md`.

**Read and gated on main (the chain with the levers, 8e2ee750): 28 of 30 gates, the chain's own two failures and nothing new.** From the crossing start, bodies into buildings go from 1.67 to 3.58 a match on 12 matches (the bound is 4 to 8; a build that also carried pass 2 read 4.17 on the same seeds). From the default start, launches that end in a building go from 3.9% to 9.3%, with the length and the collateral inside their bands. With a building in reach the planner now takes it 97 times in 100, which is over QA's band of 35 to 60%: that band or `bruntPrefer` has to move.

**To apply.**
1. `bash apply.sh <root> --check`, then `bash apply.sh <root>`: `sim/director/launch.gd` and `data/director/launch.json`, whole files, each checked against its base (`base.txt`). `town-levers.md` is new and is copied by hand to `docs/director/`.
2. `node schema/schema9.cjs <root>`: one optional key, `town`, in the launch schema (Tools', or by grant).
3. The golden regenerated (the launch decisions change), the gates.

Neither file is touched by the nine cells' chain (`../nine-cells-chain/`). By the EP's word it goes in after the chain, as its own window with its own golden and QA's 100 matches from the crossing.
