# ci-budgets-gw1b (park, Tools, 2026-11-22; the EP's low-priority order)

The first green CI run since GW1b (run 45069273235 on c83efe87): every job's minutes, read with `gh run view --json jobs`, recorded in `tools/ci-budgets.json`, and the two jobs that sit too close to their limits dealt with.

`ci-budgets-gw1b.patch` (sha1 `8b32ca5eb5c2d152954cc6c55accd404a44904a3`, two files, applies to c83efe87): `tools/ci-budgets.json` (a measured figure and the run id for every job; the old "estimated" and "to be recorded" texts are gone) and `.github/workflows/ci.yml` (the two changes below, and the timeout comments of the net jobs and the hash job brought up to date).

## The times (minutes)

| Job | Took | Limit / budget |
| :--- | :--- | :--- |
| godot-vfx-hash | 19.2 (18.2 on d168a518 as a step; over 21 and cancelled on bce578a7) | 60 / 40, kept |
| godot-audio-vfx | 5.9 | 30 / 20 |
| godot-parity, -b, -c | 14.3, 16.4, 18.6 | 45 / 30 |
| godot-sim | 21.4 | 45 / 30 |
| godot-roll-render, -b, **-c** | 9.9, 13.9, **26.9** | 45 / 30; **-c now 60 / 40** |
| net, net-b, net-2, net-3, net-4 | **31.1**, 27.5, 9.8, 19.9, 12.9 | 45 / 30 |
| world, shards 1, 2, 3 | 14.2, 9.6, 9.4 | 30 / 20 |
| flash sets | 9.7 to 13.6 (ai-1 13.6, ai-2 11.1, ai-3 9.7, scenes-1 10.3, scenes-2 10.6) | 30 / 20 |
| flash self-tests, recount | 7.8, 0.5 | 30 / 20, 15 / 10 |
| qa, site, deploy | 1.1, 1.0, 0.1 | unchanged |

My estimates were off for the network family (net: 18 estimated, 31.1 measured; net-b 17 against 27.5; net-3 24 against 19.9; net-4 19 against 12.9): the figures above are the run's own.

## What sat too close

1. **Network 1/5 (`net`) took 31.1 against a budget of 30** (limit 45): over its budget, 69 percent of its limit. The main steps in it: desync 9.4, spectator 1.6, transport 5.3, rollback AIs 5.2, sim AI 4.9, depth 2.8, planet2 about 1.4. And **net-b (2/5) took 27.5**, 92 percent of its budget, with the swing pair alone 11.3. **The patch rebalances the family into six jobs** by the step times of that run: the rollback sim AI, depth and planet2 pairs move from `net` to `net-2` (9.8 to about 19), the swing pair becomes its own job `net-5`, and `net` and `net-b` fall to about 22 and 16. No step is changed, added or lost (the splitter asserts the 42 steps of the family are the same set before and after); `deploy` waits for `net-5`; the names read "of 6"; `check-workflows` (with `lintJobs`) and `ci-budgets-check` pass. The "expected about" figures for the four changed jobs are the run's own step times added up, not a run.
2. **3/3-c (`godot-roll-render-c`, the bark reads) took 26.9, of which the one step is 26.4**: 9.0 on d168a518, 18.6 on bce578a7, 26.4 now. It is one check in one process, so it cannot be cut here, and it is growing with the runner and the planet. **Its limit is now 60 and its budget 40** (a factor of 2.2 over the last measurement). Its owner (`sim/director/tools/bark_reads_check.gd`, the director's) is to be asked, through the EP, whether it can run fewer matches or ticks; that is the owner's call, not CI's.

## Not proven

- The rebalanced net jobs have not run on a runner; their figures are expected, from this run's step times. Record the next run.
- The hash job at 60 / 40 measured 19.2: if it stays near 19, its limit could come down to 45 / 30; I left it, as it took more than 21 on the run before.
