# Production Operations: checks for the A1 pages (2026-11-13)

Checks run on the pages written in sprint A1 (rows A-PROCESS-01, -04, -05 and the three supported drafts). Base commit when run: 970d15a6; the pages themselves were uncommitted (the EP commits them), so this folder is named for the base. Corrective item CD-22: the output is saved, not only summarised.

Run from the repository root, Node only, no Godot, no browser, no git change:

```
node docs/production/tools/build-tracker.mjs     -> build-tracker-output.txt  (30 of 30 checks pass)
node docs/production/tools/check-pages.mjs       -> check-pages-output.txt    (37 of 37 checks pass)
```

## Criterion 3 (milestones.md): the count and the trace

- Rows by milestone, read from the audit's 04-milestone-rows.json: **A1 77, A2 41, A3 27, A4 19, A5 16, A6 0, 180 in all**. Each placed row exists in the register and is placed exactly once.
- **Every A1 row appears exactly once** in the full table (milestone-rows.md) and exactly once on the page for Orb (milestones.md); the 6 rows kept to the EP's table sit in A2 only, so for A1 the two pages list the same 77.
- Every A1 row is led by a line in an A1 brief (05-directives/A1/), by its own owner.
- The rows that change the fingerprint match the path's four golden-window lists: A1 12, A2 0, A3 11, A4 10, A5 3, A6 0.
- Statuses: every row has one of not started, briefed, reported, landed. A landed row must carry a commit id (checked as 7 to 40 hex characters) and a reported row a report or record. A first seed: 3 landed: A-ENERGY-02 and A-COMBAT-15 (commit 970d15a6) and A-LEGAL-09 (commit ae01d434). Each is read from the commit's subject line; the diffs were not read, so the EP confirms that the rows close.
- The count the path asks the EP to report every two days (switch rows still differing between main and the 9 November build) is carried with its date; the seed is 72 of 92, as the path reports it from the audit's baseline. It is a figure the EP gives; Production Operations only records it.

## Criterion 2 (ideas log): the entries match the path's list

Section A holds the seven the path's "Change control" section names (the absorb, flinging debris, the power-up contest, slipstream, the right-stick flick, the wind-up throw, co-op synergy), in that order, each with the path's recommendation (the absorb at the next milestone only if the stamina loop's first measurement is in, otherwise after Alpha; the other six after Alpha). The check reads the table cell by cell.

## Criterion 5 (risk register)

24 live risks, each with an owner, an early sign, a guard and a standing; every risk in the path's section appears (the three, the four watched, and outside testers, LAN, the weekly token limit and the single Executive Producer session); 6 risks that have happened with what changed (CI broken for 38 pushes among them); all 11 old rows kept with a fate, a date and a reason, the two about parked mechanics closed.

## The checks themselves were tried on bad input

A check that has only ever passed proves little, so each script was run on a deliberately damaged copy (in the scratchpad, not in the repository):

- build-tracker.mjs, with a landed row given a bad commit id, a landed row with no reference, a status override naming a row that is not placed, an invalid status word and a held word inserted into a page for Orb: **4 checks failed, as they should** (21 of 25 passed at that time).
- check-pages.mjs, with the slipstream entry removed, a risk row's owner blanked, the "38 pushes" line altered, the A4 rule's heading renamed and an old row reopened: **6 checks failed, as they should** (31 of 37 passed).

## What these checks do not prove

- That a status is true. A status comes from the EP's messages and from commit subjects; the tracker only enforces that each one names a commit or a report.
- That a size class or a week range is right. They are the path's, copied.
- That the risk wording is complete. Early signs for R-04, R-12 and R-20 are partly Production Operations' own reading of the path and the register's risk lines.
