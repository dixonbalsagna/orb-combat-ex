# Park: the nightly baseline re-recorded on d9bc2f07 (Tools, 2026-11-26; the EP's word)

`nightly-baseline.patch`: `tools/flash/nightly-baseline.json`, one self-test row in `nightly-ci-selftest.mjs`, and `ci-budgets.json` (the three rebalanced jobs' measured minutes: 19, 18, 8).

Nine clips take the worse of the two nights (they read the same): `docs/tools/runs/d9bc2f07/flash-nightly-baseline.md`.

**collapse-reduced is left at 3 / 0 / 3 / 2.5 on purpose.** It reads 4 / 0 / 4 / 3. The file's own rule is never to change a value to follow a clip that reads worse, so the nightly stays red on that one clip until it is fixed or explained. If you want it recorded at 4 anyway, that is one line, and the nightly goes green over the take-down line.

The four clash clips are recorded at 0: any flash there turns the night red.

Run: nightly-ci self-test 50, release-pass, nightly-seeds, CI budgets. Not run: a nightly against the new file.
