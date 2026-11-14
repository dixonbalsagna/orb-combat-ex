# Runs: the validator's self-test fixtures after the bystanders park (World, 2026-11-09), on main 66b66796 with cd05 and the bystanders park applied

The EP's find: with the bystanders park applied `node tools/validate.js` passes but `node tools/validate.js --self-test` failed 2 of 10,093: the two fixture fighters' `meters.json` (`tools/fixtures/virtual/data/fighters/FIXTURE_HERO` and `FIXTURE_VILLAIN`) still named the retired meter events (`casualty`, `evacuee`), which the park's meters schema no longer allows, so "the unmutated data has no errors" failed and the case `meters-unknown-event` (it sets the event of anguish source 0 to `birthday` and expects one new `enum` finding) found nothing new, the base already being invalid.

The fix is the fixtures only, `docs/world/pending/bystanders/grant-tools-fixtures.patch` (Tools' files: a grant): the hero fixture's anguish sources and the villain fixture's menace sources are the real fighters' destruction sources (copied from `PROTAGONIST` and `RIVAL` as the park has them). `tools/fixtures/cases.json` needs no change: with a valid base the case finds its `enum` again.

| Run | Result |
| :--- | :--- |
| before (stack without the grant) | `self-test: 10091 of 10093 checks passed, 2 FAILED` (the unmutated data; `meters-unknown-event`) |
| after (stack with the grant) | `self-test: 10093 of 10093 checks passed`; `node tools/validate.js` 321 files, 0 errors, 2 warnings (the two audio folders with no schema, as on main) |
| `node tools/content-screen.mjs` on the stack | `content screen: 6451 text files of 7660 scanned, 0 failing hit(s), 0 warning(s)` |
| the grant applies | cleanly after cd05's four patches and the park's three, in a clean export of 66b66796 |

## The two-fighter ratchet (the same night; Camera's run on the batch tree: 366 against 365)

`WorldCollateral._trauma` (the region broken and the brink feed the villain) named the foe by `SimRoster.opp`, which assumes one opponent and which the ratchet counts. It now tests the other team by the slot each body started in, `SimCross.team(f) != SimCross.team(victim)`, the roster-generic foe test (so in 2v2 a region broken on either foe counts). One line of `bystanders.patch` (sha1 of the patch file changed; no other file).

| Run (stack = main 66b66796 + cd05 + the park's four patches + golden-regen) | Result |
| :--- | :--- |
| `node tools/ratchet-two-fighter.mjs --root <stack>` | before: 366 against 365 (sim/world/collateral.gd 0 to 1); after: ok, 365 against a baseline of 365 |
| BYSTANDERS check | 0 check(s) failed |
| cross_check | 0 check(s) failed |
| parity (the golden check, wired rows included) | golden check passed |
| `node tools/content-screen.mjs` | content screen: 6451 text files of 7660 scanned, 0 failing hit(s), 0 warning(s) |
| `node tools/validate.js --self-test` | self-test: 10093 of 10093 checks passed |
