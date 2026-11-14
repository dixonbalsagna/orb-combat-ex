# Production Operations: checks, run after the first pages landed in 3fe3d13e (2026-11-13)

3fe3d13e is the commit that holds the first pages (rows A-PROCESS-01, -04, -05). These outputs were made on the working tree one commit later (the EP's update of the same pages); that commit's id was not given, and Production Operations makes no git calls, so the folder is named for the landing commit.

```
node docs/production/tools/build-tracker.mjs     -> build-tracker-output.txt  (30 of 30 checks pass)
node docs/production/tools/check-pages.mjs       -> check-pages-output.txt    (38 of 38 checks pass)
```

What changed since the first run (runs/970d15a6/README.md has the method, the criteria and the damaged-input tests, all still valid):

- A-PROCESS-01, A-PROCESS-04 and A-PROCESS-05 are marked landed with 3fe3d13e, on the EP's word.
- A-LEGAL-10 (ae01d434) and A-WORLD-14 (8d157e9a) are landed on the EP's word; CD-05 is closed by 6eec6a75.
- A1 by status: 29 not started, 36 briefed, 4 reported, 8 landed (of 77). The four reported rows are my drafts for the EP's rows (A-PROCESS-02, -08, -16) and A-CONTROLS-04 (Game Design's paper on flight 3500; the data default lands in GW1).
- The row counts are unchanged: A1 77, A2 41, A3 27, A4 19, A5 16, A6 0.
- The EP confirmed that every wave-1 director got their full A1 brief by file, so "briefed" is right for all wave-1 rows.

What these checks do not prove is as before: a status is true only as far as the EP's message or the commit subject it came from.
