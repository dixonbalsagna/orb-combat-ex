# Cloud brief: World & Environment, W7 (more buildings on a planet ring, long journeys, gen 2 bounces)

**Who you are.** You are the World and Environment Director for Orb Combat EX, working as a cloud session. Read in this order:
- CLAUDE.md;
- your charter `docs/directors/world-environment.md`;
- **`docs/ep/cloud-workflow.md`**: commit and push only to `cloud/world-environment/*`, never to main, and report in the branch.

Godot: `$GODOT` if set, else the pinned Linux build as cloud-workflow.md says. Then read:
- QA's `docs/qa/cloud-reports/2026-10-28-gen2-baseline.md` (findings 1 to 3);
- Game Design's `docs/design/rulings-2026-10-28.md` (ruling 1);
- your W6 report on main (`docs/world/cloud-reports/2026-10-28-biomes-w6.md`).

**Branch:** `cloud/world-environment/biomes-w7` from origin/main.

**Build:**
1. **Buildings on a ring** (GD ruling 1). Today a Half ring (2,400 columns) stands about 40 structures; give it at least 60, aiming for 80. Other ring lengths scale by columns and never go under 40. GD prefers denser settlements to more sites, so the route's site rules hold. Kinds stay as today (c08). How you do it is your call.
2. **Long journeys** (QA finding 2). With the extra buildings, re-read the share of journeys over 4,000 units; the band is at most 20%. If the buildings alone don't bring it in, say what else would, but don't touch Combat's or Encounter's tuning.
4. **PROP SMASH's kinds.** `sim/world/ground.gd`'s SMASH constant still lists `outcrop`. Combat's `data/combat/launch_biome.json` (5130ac2d) now names `lichen_rock` and `lava_rock`. Make the two agree, or read the list from that file.
3. **Gen 2's bounces** (QA finding 3). Bounces per bounced journey read 2.04 against the 1.2 to 2.0 band, and the cause is gen 2's ground profiles (`data/biomes/ground.json`, absorb). Tune the absorb on the new fine biomes so the row comes back into band. Gen 1 must not move.

**Acceptance criteria:**
- gen 1 and the hand-made world are bit-identical, and the golden is byte-identical;
- QA's runner on the gen 2 rings (`QA_PLANET="gen=2;planets=3,7,11,13,17,19,23,25,29,31;touches=0,1,2,3;cols=2400"`, `qa/godot/run-arm.js --count=200 --jobs=4`, with the arm-3 overlay QA's report names) shows:
  - structures a minute at tier 2 at most 4%;
  - journeys over 4,000 units at most 20%;
  - bounces per bounced journey 1.2 to 2.0;
  - every other band QA listed still holding;
  - `compare-arms.js` against QA's numbers;
- these pass, each one's last line in the report:
  - all World checks, gen2_soak and campaign_episode;
  - determinism, plain and `--intro`;
  - the standard gate set.
- **Performance note:** report the structure count per ring and the densest screen's count, so Performance can check draw cost on old laptops and phones.

**Report** as `docs/world/cloud-reports/2026-10-28-biomes-w7.md` with SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS and NEXT. Push and end your turn. Stay in the session while long runs finish.
