# Park: the headless Linux soak workflow (Tools, 2026-11-25; Legal RL-279)

`linux-soak.patch`, cut on HEAD 9c872829. `git apply docs/tools/pending/linux-soak/linux-soak.patch`. It adds `.github/workflows/linux-soak.yml` and removes QA's draft `docs/qa/pending/soak/linux-soak.yml` (moved).

**RL-279's four conditions are written in the header, each with where it is kept.** Beyond QA's draft:
- a length check (60 to 8400 seconds);
- a step that fails if the exported program names the soak probe;
- `tools/report-scan.mjs` over the three number files before anything is shown or kept; on a finding, nothing is published;
- the header's `--frames` note: in a locked build it cannot skip the flashing notice, it skips the How to play card.

Lock and routes steps are unchanged; no skip switch added; no display; no log or program uploaded.

**Run:** the workflow checks (workflows, shell, paths), CI budgets, desktop audience; the report scan over QA's trial numbers found nothing and does find a planted home path. **Not run:** the workflow. The harness has never run on Linux: dispatch it first with `seconds` 600.

**For QA:** the comments in `qa/soak/soak.mjs` (line 66) and in its README say `--frames` skips the flashing notice; RL-279 says that is wrong. Their README also still names the draft's old place.
