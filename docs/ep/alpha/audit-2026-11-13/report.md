# The Alpha audit of 2026-11-13: index

An independent, read-only audit of the project against the Alpha Orb defined on 2026-11-09 (`../alpha-audit-specification.md`). Two sessions: a reading session (Opus 5.5: baseline, inventory, reading requests) and a judgment session (Fable 5.2: everything else). Baseline: commit 8901d351, which carries the same game code as the last build Orb played, 6a30b4c9. Nothing in the project was changed. Nothing here is decided: it is a recommendation to Orb, and no brief is sent until Orb approves the plan.

## Headline numbers

- **270 gaps** in the register: **29 blockers, 109 majors, 132 minors.** 175 are required for Alpha, 73 nice to have, 22 after Alpha. 50 change the sim's state hash.
- From 22 area reviews: 503 findings, 343 of them gaps and 160 things recorded as working. Every blocker and major was checked by a second agent told to refute it: none refuted, 9 lowered, 52 corrected on a fact.
- **Every exit criterion X-01 to X-34 is unmet or unmeasured today**; each has at least one register row. One criterion is added (X-35, the bug bar) and ten are proposed for change, listed in one table in the path.
- **The path: six milestones, A1 to A6**, each ending in a build Orb can play. About **228M tokens** of team work at size classes, plus 25% for rework; about **12 to 22 weeks**; four golden windows (the first split in two).
- **100 briefs**, one per director per milestone, with an `ep.md` and an `orb.md` in each. All 175 required rows are the lead row of exactly one brief.
- **One adversarial round:** 58 criticisms, 36 confirmed, 22 confirmed in part, none refuted; every one changed the plan.
- **Corrective items of 2026-11-07:** 9 closed with a commit (one of them only on paper: its workflow has never run), 3 closed in substance or in practice, 15 open or open in part, each with a register row.
- **Cost of the audit:** about 18.5M of the 20M cap (reading 3.55M, judgment about 14.9M). Weekly meters at the end are in `progress.md`.

## The three largest findings

1. **Main does not hold the game Orb plays** (A-CODE-01): 72 of 92 build switch rows differ between main and Orb's build, so a fresh clone, CI and any build from main are a different, mostly switched-off game.
2. **Nothing can be handed to an outside tester** (A-TOOLS-01, A-PERF-01, A-TOOLS-02, A-QA-01, A-LEGAL-01 and others): no desktop build of the solo game, no Linux picture, nothing ever run on a Steam Deck, no download page, guide or report route, and the outside-tester safety gates are not green.
3. **Parts of the Alpha are unbuilt** (A-MODES-01 to 06, A-COMBAT-01 to 04, A-ENERGY-01, A-AI-01, A-WORLD-02): no mode list or fighter pick; no horde, couch 2v2 or custom planet; the beam Orb picked, the signature inputs, stamina and the gravity well are not built; the move table has dead cells.

## What is in this folder

| File | What it is |
| --- | --- |
| `00-baseline.md`, `baseline-status.txt` | The commit, CI state, working tree and builds everything is measured against (reading session) |
| `01-inventory/` | What exists: fourteen slices and the merged `inventory.md` (reading session) |
| `reading-requests.md`, `reads/` | Nine fact-gathering requests and their answers (RR-01 to RR-09) |
| `02-areas/<CODE>.md` | The 22 area reviews: each question answered with evidence, the exit criteria's state, the findings. `<CODE>.findings.json` has the evidence per finding; `<CODE>.verify-<n>.md` the independent check |
| `02-areas/fact-check-by-director.md` | Blockers and majors grouped by owning director, as sent to the EP |
| `02-areas/web-checks.md` | itch.io, Discord, Steam Deck and Steam rules, with the pages and the date read |
| `03-gap-register.md`, `03-gap-register.json` | The register: one row per gap, in the specification's format; the corrective items' table is at the end of the .md. `03-id-map.json` maps finding ids to rows |
| `04-path-to-alpha.md` | The path: what the adversarial review changed, the six milestones, the smaller versions proposed, the criteria proposed for change, change control, the critical path and risks, Orb's decisions, each director's load. `04-milestone-rows.json` lists each milestone's rows; `04-drafts/` has the three planners' drafts and the scores |
| `05-directives/<milestone>/<director>.md` | The briefs, in the delegation template, each with `Leads:` and `Supports:` lines. **Read each to its end:** 44 carry an "Amendments after the adversarial review" section that overrides the text above it |
| `06-adversarial.md`, `06-adversarial/` | Every criticism, its verdict and what changed; and the nine phase 2 findings that were lowered |
| `07-skipped.md` | Everything not done or done at reduced depth, and why |
| `questions.md` | Every question to the EP and its answer |
| `progress.md` | The two sessions' ledgers: phases, token tallies, meter readings |

Orb's page is `homework/1 Urgent/0 Alpha audit - where we stand and the path (5 min).md` (git-ignored, not screened by the content screen; held to the same rules by hand).

## For the EP: how to use this

1. Orb reads the page and answers the decisions; the first six rows of the path's decisions table are needed before A1 can close, and the path says which answers each milestone waits on.
2. The register becomes the backlog (A-PROCESS-02 says where it lives and who keeps it). Ids are never renumbered.
3. Send A1's briefs in the order the path gives inside A1; the outside-tester gates' day-one briefs go first.
4. A director may still correct a fact when its first brief arrives: the directors did not fact-check phase 2 (`07-skipped.md`).

## Checks made before hand-over

- Every exit criterion has at least one register row: checked by script.
- Every blocker and major verified by a second agent: yes (`verified` is yes on all 138).
- Every required row in exactly one milestone and on exactly one `Leads:` line, in its owner's file: checked by script after the last change (175 of 175).
- No row placed before a row it needs: checked by script (0).
- No brief has a director editing a path it does not own: the script's flags were lines that name another director's file in order to hand it over; three briefs were read in full by the auditor and the adversarial review's fifth lens read A1's and A2's. Not every brief was read line by line.
- Every open corrective item is in the register or shown closed: yes (the table in `03-gap-register.md`).
- Content screen on this folder: 0 hits in the audit's files (its five remaining lines are must-contain rules for project files outside this folder).
