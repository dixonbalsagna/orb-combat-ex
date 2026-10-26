# campaign-slice1: the campaign's sim foundation, first slice step 1 (parked)

Owner: Simulation and Engine. 2026-10-25, on the EP's brief: one solo episode, five stages on one planet, choosing by flying (`docs/design/campaign.md` §7, step 1). The page is `docs/architecture/campaign-core.md`. Behind `data/fight/campaign.json`'s `enabled` (off).

## What it adds

- **`sim/core/campaign.gd` (`SimCampaign`):**
  - the arc block in the run state: arc id, kind, `arc_villain`, the episode's index, the five columns' place ids and the places taken, the side-story fields, and threads as ids only;
  - the episode seed `H(arc, "episode", e)`, with every column draw mixed from it;
  - column progression (`advance`: a stage won takes its place and draws the next column's);
  - the side story and the card's number;
  - the season record (the last main-story episode won: whole numbers, no personal data, mc02).
- **`sim/core/tools/campaign_recipes.gd` (`SimCampaignRun.play`):** a seeded episode played headless, each stage an AI match on a ring round the place flown to.
- **`sim/core/tools/campaign_episode.gd`:** that episode across five columns twice, at full stage length; it exits 1 unless the two are the same to the bit.
- **`data/fight/campaign.json`:** the switch (off), and Game Design's first values: 5 columns, 2 to 3 places, the cross-back from column 2 to 4, a side story on about half, 3 episodes an arc, Narrative's four filler families, and the stand-in ring's 1,200 columns.
- **`sim/core/run.gd`:** `checkState` checks an arc block.
- **`sim/core/tools/parity.gd`:** "the campaign's arc and episode".

No fighter reads any of it (mc01, mc06), and parity's scan holds it. With the switch off nothing moves, and **the golden does not.**

## Apply

From the repo root, on 49a46fde or later, in one commit, either:

```
python docs/sim/pending/campaign-slice1/campaign.py .
python docs/sim/pending/campaign-slice1/grant_tools.py .
```

or `git -c core.autocrlf=false apply docs/sim/pending/campaign-slice1/campaign-slice1.diff`. The patch holds both, Tools' lines included. **It applies on 4dc06456 as it stands.** After `docs/architecture/pending/units-to-data/` (which adds a case near the same lines of `cases.json`), use the scripts, which apply in either order.

`grant_tools.py` is Tools'. It adds `tools/schemas/fight-campaign.schema.json` (closed), its rule in `map.json` after the run's, 7 cases in `cases.json`, and the self-test's virtual copy.

## For World (the interface, proposed)

`docs/architecture/campaign-core.md` §4 has the proposed calls:
- `columnPlaces`: a column's places along the ring, 10 to 25 s apart;
- `sidePlace`;
- `stageArena`: the stage's arena after the ring turn;
- `stageEnd`: the per-place stage end, which `SimRun.carry` needs.

The seeds stay mine and are passed in. Today's stand-ins sit behind the same calls.

## Results (scratch, on 4dc06456; also on 49a46fde before World's water v2)

- **With the switch off:**
  - apply (either way) and import were clean;
  - parity on the committed golden: 74 of 74, with "the campaign's arc and episode" ok, and the golden byte-identical;
  - npm's 5 stages, det, det_intro, seam, flash with the count check, QA's run-all, loader and the flash self-test passed;
  - validate (265 files, 0 errors, 0 warnings) and its self-test (9097 of 9097, with Tools' 7 cases) passed;
  - **all 19 render gates** passed: Rendering's 15, the city check, VFX's effects and hash checks, and Camera's split sweep. So did Animation's `anim_check`;
  - the determinism lint passed.
- **With the switch on** (`campaign_episode.gd`, 1,800 ticks a stage), each episode played twice is the same to the bit:
  - **c0ffee00c0ffee00, a filler arc:** the Rival as villain, families rescue and training_day. Columns: [28, 34] to 34, [11, 35] to 11, [6, 1, 8] to 8, **[35, 12, 29]** to 12 (35 is the rise's untaken place, back at the escalation), and [0], the Rival's home, to 0.
  - **5eed0000decade42, main-story episode 12:** card "12", and the season record after it is lastMain 12.
- **The patch** (`campaign-slice1.diff`, sha1 25b9ad33ec91, 13 files) applied to a fresh export of 4dc06456 gives the proved copy, file for file.
