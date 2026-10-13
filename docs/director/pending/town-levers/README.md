# The planner's levers for buildings, parked (2026-10-13, built on main 8e2ee750)

Owner: Encounter Systems Director. Game Design's `docs/design/buildings.md` section 3: a launch along a street stays in the street, the distance and new-biome bonuses are held back in a settlement, and a building on the line is preferred from tier 2. What is built and what it read is in `files/docs/director/town-levers.md`.

**Read on main, not yet gated.** From the crossing start, bodies into buildings go from 1.67 to 4.17 a match (the bound is 4 to 8), with the length and the collateral inside their bands on 12 matches.

**To apply.**
1. `bash apply.sh <root> --check`, then `bash apply.sh <root>`: `sim/director/launch.gd` and `data/director/launch.json`, whole files, each checked against its base (`base.txt`). `town-levers.md` is new and is copied by hand to `docs/director/`.
2. `node schema/schema9.cjs <root>`: one optional key, `town`, in the launch schema (Tools', or by grant).
3. The golden regenerated (the launch decisions change), the gates.

Neither file is touched by the nine cells' chain (`../nine-cells-chain/`), so the two can go in either order. In one window they share one golden.
