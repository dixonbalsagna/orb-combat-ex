# campaign-slice1c: the cross-back (parked)

Owner: Simulation and Engine. 2026-10-26, on the EP's brief: Game Design's `campaign.md` §2.2, the rise's untaken place offered again at the escalation, on World's `prefer` (`docs/world/pending/campaign-prefer/`). The page is `docs/architecture/campaign-core.md` §3 item 6. Behind `data/fight/campaign.json`'s `enabled` (off).

## What it changes

- **`sim/core/campaign.gd`:**
  - `crossBack` {from, to} read from the data (2 and 4);
  - `crossBackPlace(arc)`: the first named place column 2 offered that the pair didn't take, nor took before column 4, in World's order;
  - `beginColumn` passes it to World as `prefer` at column 4;
  - `columnDone` keeps the place asked (`arc.back`, -1 for none) and each site's `preferred` (0 or 1).
- **`data/fight/campaign.json`:** `crossBack` {from 2, to 4}.
- **`sim/core/tools/campaign_episode.gd`:** a cross-back row, and the preferred site marked `*`.
- **`sim/core/tools/parity.gd`:** the campaign's check holds that none is asked when column 2 left no named place (c0ffee00c0ffee00), and that seeded arc 0bac000000017334 has its rise's untaken place 12 asked at column 4 and leading it, preferred.
- With the switch off nothing moves, and **the golden does not.**

## Grants

- **`grant_tools.py` (Tools'):** fight-campaign's schema takes `crossBack` (required, closed), with one case (`/crossBack/to` 0) and the virtual copy.

## Apply

On main (223ffdcc or later: slice 1b is on main) after World's `campaign-prefer` diff (sha1 ef127ae8f99f), from the repo root, in one commit:

```
python docs/sim/pending/campaign-slice1c/campaign1c.py .
python docs/sim/pending/campaign-slice1c/grant_tools.py .
```

or `git -c core.autocrlf=false apply docs/sim/pending/campaign-slice1c/campaign-slice1c.diff` (sha1 590c8e225515, 7 files, both scripts). Applied to the base's files, it gives the proved copy, file for file.

## Results (scratch: main with slice 1b and World's campaign-prefer applied)

- **With the switch off:**
  - apply and import were clean;
  - parity on the committed golden: 74 of 74, and **the golden byte-identical**;
  - npm's 5 stages, det, det_intro, seam, flash with the count check, QA's run-all, loader and the flash self-test passed;
  - validate (268 files, 0 errors, 0 warnings) and its self-test (9141 of 9141) passed;
  - all 19 render gates passed, and so did `anim_check`, the lint and World's `campaign_check` (35 of 35).
- **With the switch on** (1,800 ticks a stage), each episode played twice in one run is the same to the bit, and the two filler arcs also run in two separate processes print the same, line for line:
  - **0bac000000017334, the cross-back:** column 2 offered town #12, open ground and open ground, and the pair flew to open ground. At column 4, after a -60° turn, town #12 leads the column (`*`, preferred), and the pair fly to it. The stage there fells buildings, so town #12's wear (band 2) carries into the climax: **the first wear from a real fight** in these runs.
  - **c0ffee00c0ffee00 and 5eed0000decade42:** none asked (column 2 left no named place untaken). Their columns, sites and stages are as in slice 1b. The run hashes differ only because each site now keeps `preferred`.
- **Over 40 seeded filler arcs** (60-tick stages): column 2 left a named place untaken in 11; World offered it again at column 4 in 5 of those; the seeded flight took it in 3.
