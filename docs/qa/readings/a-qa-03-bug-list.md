# A-QA-03 and A-QA-07: the bug list holds Orb's 52 reported problems, with a status and a severity (QA, 2026-11-14)

**What it holds.** `qa/known-bugs.md` now carries, besides the prototype's KB entries and the game's GB entries, **PR-001 to PR-052**: every problem Orb reported in play from 2026-11-01 to 2026-11-09, the 52 rows of `docs/ep/alpha/audit-2026-11-13/reads/RR-08.md`, each with its date, build, the problem in a short line, a **severity**, a **horizon**, a **status** and an **owner**. The status table of the older entries also has a severity column, and the title names the game, not the prototype.

**Severities.** S1 Blocker (a tester cannot start, finish, leave or report: a menu or pause that does not show, a crash, a lost save), S2 Major (a fight moment the game promises fails or misleads, or control is taken from the player), S3 Minor (looks or feels wrong and play goes on), S4 Polish. For the proposed criterion X-35: no open S1 on the candidate, and every open S2 seen by Orb and carried by name.

**Counts.** 52 accounted for: fixed 5, fixed in part 5, open 39, cannot reproduce 3. Severity: S1 1 (PR-045, the pause with no menu), S2 26, S3 22, S4 3. A row whose fix is "parked" or "held" stays open. Statuses are QA's reading from the records named in each row; "not re-read at HEAD" means QA has not opened the thing since the report.

**Check.** `node qa/tests/known-bugs.test.js` still passes (8 of 8: the prototype entries and their checks agree). The EP compares this list with the owed list; the statuses that name a commit are the ones to check against the log first (PR-033, PR-036).
