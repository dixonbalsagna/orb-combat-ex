# campaign-load: the campaign's host loads the arc's planet first (parked)

Owner: Simulation and Engine. 2026-10-26, on the EP's brief after planet-load (0c62c856) and Game Design's `rulings-2026-10-26.md` item 27 (the load starts as soon as the planet's seed is known, while the pair are picked). The page is `../../planet-load.md` §3, and `../../campaign-core.md` §3 item 0.

## What it changes

- **`sim/core/campaign.gd`:**
  - `SimCampaign.beginLoad(arcId)` is the arc's planet as a `SimPlanetLoad` job. The host steps it from the moment the arc is known, and then `newEpisode` and World's column jobs find the planet made. Every episode of the arc, and its side stories, fly it;
  - with `SimPlanetLoad.strict` on, `beginColumn` refuses a gen 2 planet that isn't made (null, counted in `refused`). World's column job would otherwise make it in one piece.
- **`sim/core/tools/campaign_recipes.gd`:** the test's episode loads the arc's planet a slice a step, and reads each stage's ring before its match (`beginFor`), as a host does. Its columns, stages and run states don't change.
- **`sim/core/tools/parity.gd`:** "the planet's load" adds two cases with strict on and a gen 2 arc planet:
  - a column's job is refused while the planet is cold;
  - it is given once `beginLoad` has run.
- Not `sim/core/planet_load.gd`, which World's gen2-read-speed grant edits. No other director's files. **The golden does not move.**

## Apply

On main (0c62c856 or later), before or after World's `gen2-read-speed`, from the repo root:

```
python docs/architecture/pending/campaign-load/campaign_load.py .
```

or `git -c core.autocrlf=false apply docs/architecture/pending/campaign-load/campaign-load.diff` (sha1 1f6581ba58ee, 3 files). Applied to the base's files, it gives the proved copy, file for file.

## Results (scratch: 0c62c856 with World's gen2-read-speed and its grant applied; HEAD has moved only in docs since)

- **The campaign off:**
  - parity 75 of 75 on the committed golden, and **the golden byte-identical**;
  - npm's 5 stages, det, det_intro, seam, flash with the count check, QA's run-all, loader and the flash self-test;
  - validate (268, 0, 0) and its self-test (9141 of 9141);
  - **all 19 render gates** and `anim_check`, and the lint;
  - World's `campaign_check` (35 of 35), `host_check`, `planet_world_check` and `gen2_state_check`.
- **The campaign on:**
  - the three seeded episodes (c0ffee00c0ffee00, the cross-back's 0bac000000017334 and 5eed0000decade42) are each the same to the bit played twice in one run, and the two filler arcs also run in two separate processes print the same, line for line;
  - their columns, stages and run hashes are slice 1c's exactly: loading the planet first, and each stage's ring before its match, changes nothing in them.
- **Parity's new case:** with strict on and a gen 2 arc planet, the column's job is refused while the planet is cold, and given once `beginLoad` has run.
- It applies with or without World's gen2-read-speed: World's diff touches none of its three files.
