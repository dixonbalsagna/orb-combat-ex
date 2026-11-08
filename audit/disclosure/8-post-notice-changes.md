# 8. Changes after the baseline

The baseline is commit `8d9b98a2` and 22:03 UTC (14:03 PST) on 2026-11-07. The notice was served to me later that afternoon, after the safe pause Orb ordered.

## After the baseline, before the notice was served
- Commit `53b6df82` (14:07 PST): `docs/rendering/2v2-drawn-plan.md` added. Not a frozen path.
- I deleted the folder `docs/tools/pending/shell-snippet-everywhere/`. It was untracked, and its patch had already landed in `fa10e83a`. It wasn't safety evidence, but it was a pending folder.
- I deleted my scratch gate trees and their results (about 7.7 GB) under my session scratchpad, following Orb's "no leftovers" pause order. They held the run-gate outputs (`s405-sim` to `s409-sim`, the `r.txt` gate rows) for the landings of `3c9005ac`, `d5582dbd` and `a8bc66e2`. The verdicts are summarised in those commit messages; the raw logs are gone.
- Under the same pause order, the directors reported deleting their own scratch copies, captures and temporary trees after about 22:00 UTC. Their reports: Tools (about 50 GB, including stack, clip, capture and `meridian-feel` folders; it kept `meridian-stack-preview/tree-868f521e4743`), Rendering, Netcode, UI, Camera, Performance (kept 108 MB of result files), Encounter and Animation. Some of that may have held safety evidence (captures, gate logs). I don't have a list of which files.
- Rendering stopped its gates part-way on three parks (`crater-store`, `fore-profile`, `others-near`) and wrote what had passed in each README.

## After the notice
- No commits to frozen paths by me.
- Written: `audit/disclosure/` (this pack).
- Outside the repository: my working notes (EP memory) gained `independent-audit-2026-11-07.md` and the 2026-11-07 handover.
