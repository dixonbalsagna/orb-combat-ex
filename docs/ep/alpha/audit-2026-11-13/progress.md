# Alpha audit: progress

Each session edits only its own section. Read the file again before each edit.

## Reading session ("Meridian - Alpha Audit (reading)", Opus 5.5)

**State:** phase 1 COMPLETE 2026-11-13 20:22 PST. Reading requests batch 1 (RR-01 to RR-09) answered ~20:31 PST in `reads/` (workflow wf_4a91c1d5-100, 1.30M subagent tokens; each file has a "Not covered" list; 3 citations spot-checked in RR-02 and RR-08, all correct; content screen 0 hits in audit files). Waiting for new requests at each check.

| Phase | Status | Tokens (tally) |
| --- | --- | ---: |
| 0 Baseline | done: `00-baseline.md`, `baseline-status.txt` | 0.15M |
| 1 Inventory | done: 14 slices (workflow wf_0e4069bd-537, 1.93M subagent tokens), merged `01-inventory/inventory.md`, 10 rows spot-checked (0 wrong, 1 imprecise), COMPLETE line added | 2.05M |
| Reading requests | batch 1 (RR-01 to RR-09) done | 1.35M |
| **Reading total** | | **3.55M** |

**Sum check at the phase 1 boundary:** reading 2.2M + judgment 0.3M (its own tally) = 2.5M of 20M.

**Meters:** 20:05 PST all-models 2%, Fable 3%. 20:21 PST all-models 3%, Fable 4%.

**Content screen** on the folder at 20:21 (`node tools/content-screen.mjs --root docs/ep/alpha/audit-2026-11-13`): 0 hits in the audit's own files; its 5 FAIL lines are must-contain rules for project files (`tools/site-*.json`, `tools/site-interim.mjs`) that are not in this folder, so they fire on any narrowed root.

**Check-in:** job 38c0b75c, minutes 4 and 34, serves `reading-requests.md`; delete it at DONE.

**Final (2026-11-13 22:08 PST):** DONE seen in `reading-requests.md` (written 21:53). Final reading tally **3.55M** (baseline 0.15M, inventory 2.05M, reading requests 1.35M); with the judgment session's about 14.9M, about 18.5M of 20M. Meters at 22:07: all models 26%, Fable 49%. Check-in 38c0b75c deleted; both of this session's workflows finished; nothing of this session's is running. Stopped; nothing else started.

## Judgment session ("Meridian - Alpha Audit", Fable 5.2)

Edited only by the judgment session. Times are read from `date`.

**State:** DONE 2026-11-13 21:53 PST. All phases finished; Orb's page written; the EP's closing message sent; DONE written in `reading-requests.md`. Nothing of this session's is running. Nothing else is started.

| Phase | Status | Tokens (tally) |
| --- | --- | ---: |
| Reading in | done: the specification (all 780 lines), vision.md (all 1,788 lines), taste.md, playbook.md, corrective-plan-2026-11-07.md, audit/disclosure/README.md, the EP's workshop draft, DIRECTORS.md (roster, schedule, owns lines), ADR titles, ADR 0010 and 0013 in full | 0.3M (session estimate) |
| 2 Area review | done. Wave 1 (LEGAL, MODES, COMBAT, PERF; run wf_d3b08f03-cde; 1.86M). Wave 2 (the other 18; run wf_443401bb-eec; 49 agents; 7.00M). 22 area files, 503 findings: after verification 35 blockers, 142 majors, 166 minors, 160 working; 0 refuted, 9 lowered, 47 corrected on a fact. Summaries: `02-areas/wave1-result.json`, `wave2-result.json`; by director: `02-areas/fact-check-by-director.md`; platform rules: `02-areas/web-checks.md` | 8.86M |
| 3 Gap register | done in the session: `03-gap-register.md` and `.json`, 270 rows (29 blockers, 109 majors, 132 minors; 174 required, 74 nice, 22 after Alpha), merged from 343 gap findings; every criterion X-01 to X-34 has at least one row; every corrective item is shown closed with its commit or has a row (table at the end of the .md). `03-id-map.json` maps finding ids to rows; `03-extra-rows.json` holds the five rows added for open corrective items. Built by a script in this session's scratch folder: if a correction changes a row, edit the JSON and the .md row directly and never renumber | 0.3M |
| 4 Path | done: `04-path-to-alpha.md` (six milestones A1 to A6, about 201M tokens of team work at size classes, 9 to 16 weeks; four golden windows; the risk-first draft, scored 82 of 100, with the scorer's grafts). Drafts and scores in `04-drafts/`; `04-milestone-rows.json` holds each milestone's rows. Checked by script: 174 of 174 required rows in exactly one milestone, 0 before a row they need. One register link removed (A-CONTROLS-06 no longer needs A-COMBAT-04). Workflow run wf_90ed064c-3f5, 4 agents | 0.76M + session |
| 5 Directives | done: 100 briefs in `05-directives/A1` to `A6` (22, 17, 16, 19, 16, 10), including an `ep.md` and an `orb.md` per milestone. Script check: all 180 placed rows (174 required) are on exactly one `Leads:` line, each in its owner's file and its own milestone; no unknown ids. The script's 55 path flags were lines that name another director's file in order to say it is NOT the director's (three briefs read by the auditor: A1 simulation-engine, A4 art, A6 qa-balance); the adversarial round's fifth lens re-checks owned paths. Workflow run wf_aa16abf0-967, 6 agents | 1.21M |
| 6 Adversarial review | done: one round, five lenses, a verifier each (workflow run wf_a02cb684-427, 10 agents). 58 criticisms: 36 confirmed, 22 in part, 0 refuted. Every survivor changed the plan: `04-path-to-alpha.md` (a binding section near the top plus direct edits), nine register rows, an "Amendments" section in 44 briefs. Record: `06-adversarial.md` | 2.16M |
| 7 Orb's page, hand-over | done: `report.md`, `07-skipped.md`, Orb's page in `homework/1 Urgent/`, content screen 0 hits in the audit's files, the EP's message, DONE | session |
| **Judgment total** | | **about 14.9M** (1.9M session estimate + 8.86M phase 2 + 0.76M phase 4 + 1.21M phase 5 + 2.16M phase 6) |

**Meters:** at open, all models 2%, Fable 3% (weekly reset 2026-11-20 19:00 PST). 20:22 PST before wave 1: all models 3%, Fable 4%. Sum check at the phase 2 start: reading 2.2M + judgment 0.4M = 2.6M of 20M.

**EP:** AQ-01 to AQ-04 sent in one message at open (message_id aaa2c249, delivered). All four answered at 20:08 PST and logged in questions.md. What they change: the delegated topic is flashing and photosensitivity (off Orb's page unless a safeguard has lapsed), and the public test build decision lapses 15 Nov; Legal's licence rundown v2 and tester note exist (74a46ed4); no clean weekly token figures, so the path's pace is marked estimated; ceilings unchanged; landings held from 19:46. The EP's caution: the Fable weekly allowance may be small against 20M, so read the Fable meter before and after the first phase 2 wave and scale from the measured cost.

**Check-in:** job 3852acb4 deleted at 20:22. The workflow notifies this session when it ends; no polling.

**Note:** my first entries here and in questions.md were appended at 20:05 and were replaced when the file was first laid out by the reading session; nothing was lost that isn't restated above.

**Reading requests:** batch 1 written 20:07 PST, RR-01 to RR-09 (move tables, forms, modes and menu, disk writes and network calls, leftover names, difficulty levels and win rates, performance records, Orb's reported problems against the bug list, corrective items against the log). None answered yet. `00-baseline.md` read: baseline 8901d351; CI on it pending at 20:05, to re-read before citing; no desktop-builds run on record.

**Budget at 20:53 PST (phase 2 boundary).** Meters: all models 18%, Fable 32%. Tally: reading 3.55M (its own figure) + judgment 9.5M (0.6M session, 8.86M phase 2) = 13.0M of 20M. The all-models meter moved 11 points for wave 2's 7.0M (about 1.6 points per 1M), so the 30% stop is the binding guard, not the cap: about 7M more would reach it. Rest of the audit held to about 5M: phase 3 in the session (about 0.3M), phase 4 about 1.0M, phase 5 about 1.2M, phase 6 one round about 1.5M, phase 7 about 0.3M. Dropped now (in `07-skipped.md`): the second adversarial round. Next in line if phase 4 or 5 overrun: full briefs after A2. Read the meters before launching each workflow; stop and report to Orb at 30%.

**Meters at 20:58 PST (phase 3 boundary):** all models 18%, Fable 32% (unchanged since 20:53). Sum: reading 3.55M + judgment 9.8M = 13.35M of 20M.

**Meters at 21:17 PST (phase 4 boundary):** all models 20%, Fable 36%. Sum: reading 3.55M + judgment 10.8M = 14.35M of 20M. Room under the 30% stop: about 6M more on the largest model; phases 5 to 7 are planned at about 3.2M.

**Meters at 21:31 PST (phase 5 boundary):** all models 22%, Fable 41%. Sum: reading 3.55M + judgment 12.2M = 15.75M of 20M. Phase 6 planned at about 1.5M (to about 25% all models); phase 7 in the session.

**Final meters, 21:52 PST:** all models 26%, Fable 49% (the 30% stop was not reached; no Fable reset was asked for). Final sum: reading 3.55M (its own figure) + judgment about 14.9M = about 18.5M of 20M. Phase 2 (8.86M against 7.4M) and phase 6 (2.16M against 1.5M) ran over; the second adversarial round was dropped to pay for it.

**EP:** closing message sent 21:53 (the folder, the headline numbers, Orb's twelve decisions). Fact-check answered 21:00: no corrections, directors not woken (logged in questions.md and 07-skipped.md). Sent 20:55; corrections of fact with evidence are applied before phase 6. The delegated topic's findings (F-LEGAL-01, F-RENDER-01, F-LEGAL-08, F-UI-03, F-SAVES-05) went to the EP with my reading that no safeguard has lapsed for today's players; no question put to Orb.

**Next:** nothing. If Orb or the EP asks a question about the audit, answer from the files; do not start new work.

**If restarted mid phase 2:** the script is `workflows/scripts/alpha-audit-phase2-area-review-wf_d3b08f03-cde.js` under this session's app folder; an area is done when `02-areas/<CODE>.md` and a `<CODE>.verify-1.md` exist; re-run the script with args = the codes still missing.

**After DONE:** Orb answered the twelve decisions on the page the same evening. Copied verbatim with the auditor's reading to `08-orb-answers.md` and sent to the EP. No other audit file was changed. Decision 12 overrides the audit's recommendation (the marks are placeholders to be replaced by diegetic effects, not removed); decision 10's standing yes was not given.
