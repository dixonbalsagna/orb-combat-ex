# campaign-slice1b: the campaign on World's real calls (parked)

Owner: Simulation and Engine. 2026-10-26, on the EP's brief: wire `SimCampaign` to World's calls (`WorldCampaign`, on main since 630dcbad; `docs/world/campaign-route.md`) in place of the first slice's stand-ins. Also QA's campaign record (`docs/qa/rally-campaign-rows.md`). The page is `docs/architecture/campaign-core.md`. Behind `data/fight/campaign.json`'s `enabled` (off), the campaign's one switch.

## What it changes

- **`sim/core/campaign.gd` (`SimCampaign`), replaced:**
  - the route is World's: `beginColumn` begins World's column job (the host steps it a ring's read a frame), and `columnDone` keeps its sites, the ring the pair fly, their column on it, each column's ring length and its turn;
  - `stageSetup` re-centres the ring on the site flown to (World's `rebased`) and hands the run's wear to the stage;
  - `advance` merges the stage's wear (World's `mergeWear` of its `wearOf`), and refuses a site that is not one of the column's;
  - the side story is World's `side` (band, widened or turned), with `how` and the turn kept for the host;
  - `qaRecord(state)`: QA's `campaign` object from the run state (the fights' seconds, the arc, each column's ring, turn and places from the pair; rescues, rematches, partner and templates zero or empty until those steps exist).
- **`sim/core/tools/campaign_recipes.gd`, `campaign_episode.gd`, replaced:** a seeded episode on World's columns, each stage an AI duel at its site with the wear laid. `campaign_episode.gd --record=<file>` writes QA's record.
- **`data/fight/campaign.json`:** `ringCols` 2,400 (the first ring, Half) in place of `placesPerColumn`, `crossBack` and `stageCols`, which are World's now.
- **`sim/core/replay.gd`:** a setup with `wear` takes World's campaign data into the replay's data hash.
- **`sim/core/tools/parity.gd`:** "the campaign's arc and episode" on World's columns.
- Slice 1's `.uid` files stay. No fighter reads any of it (mc01, mc06). With the switch off nothing moves, and **the golden does not.**

## Grants

- **`grant_tools.py` (Tools'):** fight-campaign's schema takes `ringCols` in place of the three keys; the stage-cols case becomes a ring-cols one, and the virtual copy is refreshed.
- **`grant_world.py` (World's, two lines): the one switch.**
  - `WorldPlanetWorld.gen` lays a setup's `wear` whenever the setup has it, in place of only while World's `data/biomes/campaign.json` is on. The host gives a stage wear only while the campaign is on, so a match reads no second switch, and a replay lays the same wear whatever either file says. World's own `enabled` stays for World's tools.
  - World's `campaign_check` held the reverse ("with the campaign off a setup's wear is ignored"). Its line now holds that a setup's wear is laid the same with World's flag off.

## Apply

On main (1f95f42e or later) with World's `rivers`, `surfacing` and `w16` applied, from the repo root, in one commit:

```
python docs/sim/pending/campaign-slice1b/campaign1b.py .
python docs/sim/pending/campaign-slice1b/grant_tools.py .
python docs/sim/pending/campaign-slice1b/grant_world.py .
```

or `git -c core.autocrlf=false apply docs/sim/pending/campaign-slice1b/campaign-slice1b.diff` (sha1 cf501ffd2e49, 11 files: all three scripts, Tools' and World's lines included). Applied to the base's files, the patch gives the proved copy, file for file.

## Results (scratch: an export of 1f95f42e with World's rivers ddac96823bcb, surfacing 4a3035295526 and w16 d4d402419dcb applied)

- **With the switch off:**
  - apply and import were clean;
  - parity on the committed golden: 74 of 74, with "the campaign's arc and episode" ok, and **the golden byte-identical**;
  - npm's 5 stages, det, det_intro, seam, flash with the count check, QA's run-all (7 of 7), loader and the flash self-test passed;
  - validate (268 files, 0 errors, 0 warnings) and its self-test (9131 of 9131) passed;
  - **all 19 render gates** passed (Rendering's 15, the city check, VFX's effects and hash checks, Camera's split sweep), and so did Animation's `anim_check`;
  - the determinism lint passed, and so did World's `campaign_check` (31 of 31, with its line turned by `grant_world.py`).
- **With the switch on** (`campaign_episode.gd`, 1,800 ticks a stage), each episode played twice is the same to the bit, and the filler arc run in two separate processes prints the same, line for line:
  - **c0ffee00c0ffee00, a filler arc:** the Rival as villain, families rescue and training_day. Columns 1 to 4 on Half rings, turning -15°, 60°, none and 45°; flown to open ground, city #3, open ground, open ground; then the climax on the whole circle (a 89° turn) at city #0, the Rival's home.
  - **5eed0000decade42, main-story episode 12:** turns of none, none, -15° and 60°; flown to open ground, city #9, open ground, city #3, then city #0. Card "12", and the season record after it is lastMain 12. Its side-story draw said no; parity's search finds one that says yes and is placed.
  - The ring turned in 5 of these 8 columns (GD's band is 40 to 60%; two episodes are no sample: World's `campaign_turns` measures 47% over 96).
  - **No wear:** an AI duel of 1,800 ticks at a site fells no building, so both episodes end with none. Parity merges hand-made bands, and World's `campaign_check` lays them on a stage.
- **QA's record** (`--record`) is written for both episodes: 150 s of fights (5 stages of 30 s), Half rings for columns 1 to 4 and the Whole circle for the climax, and each place's `fromPair` to its near edge (World's band measure). Every place of columns 1 to 4 reads 322 to 806. (Read to a city's centre, one read 934, past the band: so `fromPair` is the edge.) Re-proved after that change: parity 74 of 74, the golden byte-identical, validate, its self-test, the lint and World's `campaign_check`, and the same columns and run hashes.
