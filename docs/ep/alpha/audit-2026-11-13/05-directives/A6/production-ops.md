# A6: Production Operations

Leads: none
Supports: none

Goal: On the day the candidate passes, everyone on the team knows the feature freeze has begun, where a new idea goes, and what is and is not still allowed.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A6; "Change control", both parts: "During the push" and "After the freeze"; "The nice-to-have pool"; "Deliberately after Alpha"; decision 23); `docs/ep/alpha/alpha-audit-specification.md` line 200 (X-33) and line 160 (after Alpha, feature freeze); the change-control page and ideas log you wrote under A-PROCESS-01 and the milestone tracker from A-PROCESS-05, in `docs/production/`; `docs/production/risk-register.md`; `docs/ep/playbook.md`.
- A6 closes no register row. Your part is X-33: the freeze is recorded, the rule is written where every session reads it, and the ideas log holds what waited.

You own: `docs/production/`.
- The playbook and CLAUDE.md are the EP's: hand the EP the exact lines to add. You do not edit them.

Acceptance criteria:
1. (X-33) The change-control page states the rule after the freeze in plain words: a new idea is logged for after launch, or brought to Orb as a scope change with its cost in tokens, weeks and golden windows and what it would re-open; only Orb lifts an idea in; fixes to broken things, tuning inside the data's existing shape and polish that passes the look gate carry on; anything touching a player-safety gate, a Legal flag, spending or something public still stops and goes to Orb as one question. Checked by: the page, read by the EP against the path's "Change control" section.
2. (X-33) The freeze is recorded: the date, the candidate's commit, the version number the game shows, and Orb's word, quoted. Checked by: the entry in `docs/production/`, and the line you hand the EP so the playbook points to it.
3. (X-33) The ideas log is complete up to the freeze: every idea raised from A1 to A6, in the speaker's words with a date, the EP's one-line recommendation, its size class, whether it changes the sim's fingerprint, and its state (built, waiting, declined). The first entries the path names for day one are present. Checked by: the log; the EP spot-checks ten entries against `docs/ep/vision.md` and the testers' reports.
4. The milestone tracker shows A1 to A6 closed, each with its exit date, the lines carried forward if any, and the tokens used against the path's estimate from the weekly token record (A-PROCESS-08). Checked by: the tracker.
5. The risk register is brought up to date at the freeze: the path's three named risks and what happened to each, and the risks open for Beta. Checked by: the file.
6. A one-page list of what is waiting for after Alpha, taken from the path's "Deliberately after Alpha" and "The nice-to-have pool" sections and the remainders of the rows made smaller, so the first Beta plan starts from one page. Checked by: the page; every item points at a register id or an ideas-log entry.

Constraints:
- Tokens: a small share of the milestone's 5M for verification (an estimate).
- State hash: no change.
- Machine: no Godot or browser runs are needed for this brief.
- Determinism: not touched.
- Originality: not touched.
- Orb's rules: plain words, no team nicknames without a gloss; an idea is recorded in the speaker's own words; "workshop this" means a page or a toy, not a change to the game; nothing personal about Orb or the testers is written into a tracked page (testers are "tester 1" and "tester 2").

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Items 1, 3 and 6 are prepared while the candidate is being verified. Item 2 waits on the day every A6 exit line passes on one commit and on Orb's word. Beta planning waits on this brief.
