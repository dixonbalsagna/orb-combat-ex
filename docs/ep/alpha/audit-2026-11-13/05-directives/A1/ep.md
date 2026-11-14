# A1: Executive Producer

Leads: A-ANIM-06, A-CODE-01, A-PROCESS-02, A-PROCESS-03, A-PROCESS-06, A-PROCESS-07, A-PROCESS-08, A-PROCESS-09, A-PROCESS-10, A-PROCESS-11, A-PROCESS-13, A-PROCESS-14, A-PROCESS-15, A-PROCESS-16, A-RENDER-07, A-RENDER-11
Supports: A-TOOLS-01, A-TOOLS-10, A-LEGAL-02, A-PROCESS-01, A-PROCESS-04, A-PROCESS-05

This is the Executive Producer's own work list for A1, in the brief format so it can be checked the same way. It is not sent to a director.

Goal: a fresh copy of the repository is the game Orb played on 9 November, with nothing important living only on one PC or in one session, and every rule a session reads matches what Orb has actually said.

Context: read first `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (the top section, section A1 with its fixed order, "Change control", the decisions table), `01-inventory/inventory.md` (the switch table: 92 rows), `02-areas/PROCESS.md`, `02-areas/CODE.md`, `docs/ep/playbook.md`, `docs/ep/taste.md`, `docs/decisions/0010-look-gate.md`, `docs/ep/corrective-plan-2026-11-07.md`, `reads/RR-09.md`.
- A-CODE-01 (L, blocker, changes the hash): main does not hold the game Orb plays; 72 of 92 switch rows differ. Evidence: `01-inventory/I-08-data-schemas-switches.md:145`; `tools/preview/switches.mjs:13`; `docs/tools/runs/6a30b4c9/build-and-smoke.txt:6`.
- A-PROCESS-03 (M): the working tree carries 14,805 uncommitted paths. Evidence: `00-baseline.md:13`; `baseline-status.txt`; `reads/RR-09.md:8` (271 run-record files untracked).
- A-PROCESS-02 (S): no single backlog. Evidence: `docs/ep/corrective-plan-2026-11-07.md:14` (13 of 27 rows open), `:26`; `questions.md:16`.
- A-PROCESS-06 (S): the P0 to P5 roadmap in CLAUDE.md no longer describes the project. Evidence: `CLAUDE.md:102`, `:105`, `:106`; `DIRECTORS.md:29`, `:47`.
- A-PROCESS-07 (S): the corrective plan has not been kept. Evidence: `docs/ep/corrective-plan-2026-11-07.md:5`, `:19` (CD-11), `:28` (CD-20); `reads/RR-09.md:52`.
- A-PROCESS-08 (S): no weekly token record. Evidence: `questions.md:17`; `docs/ep/proposals/controller-vision.md:163`; `.claude/commands/sprint.md:21`.
- A-PROCESS-09 (S): the /sprint-plan and /sprint loop has never run. Evidence: `.claude/commands/sprint-plan.md:20`; `.claude/commands/sprint.md:12`; commit f104d4f5.
- A-PROCESS-10 (S): running state depends on one EP session. Evidence: `.claude/commands/sprint-plan.md:10`; `.claude/commands/sprint.md:8`, `:41`; `.claude/commands/crunch.md:6`; `docs/ep/handoff.md`.
- A-PROCESS-11 (S): CLAUDE.md and ADR 0005 still say Pro plan and no workflows, against Orb's order of 2026-11-06. Evidence: `CLAUDE.md:17`, `:128`; `docs/decisions/0005-lean-team-and-token-discipline.md:3`; `docs/ep/vision.md:1656`.
- A-PROCESS-13 (S): the roster has no Alpha mapping and stale parts. Evidence: `DIRECTORS.md:29`; `docs/directors/camera.md:3` against `DIRECTORS.md:297`; `DIRECTORS.md:672` (owns folders that do not exist).
- A-PROCESS-14 (S): replaced commands are still live. Evidence: `.claude/commands/crunch.md:10`, `:19`; `baseline-status.txt:103`; `README.md:18`.
- A-PROCESS-15 (S): the standup does not read CI first (CD-20). Evidence: `.claude/commands/standup.md:4`; `docs/ep/playbook.md:18`; `docs/ep/corrective-plan-2026-11-07.md:28`.
- A-PROCESS-16 (S): no page lists each Alpha feature with its done test. Evidence: `CLAUDE.md:113`; `.claude/commands/sprint-plan.md:66`; `docs/ep/playbook.md:12`.
- A-RENDER-07 (S, CD-22): no record ties a visible landing to its side-by-side. Evidence: `docs/decisions/0010-look-gate.md:8`; commit 3c9005ac (one commit, 133 parks); `docs/ep/runs/6a30b4c9/README.md:1-8`.
- A-RENDER-11 (S): the look gate's reference build is still d3f1ca0e of 2026-10-15. Evidence: `docs/ep/taste.md:7`; `docs/decisions/0010-look-gate.md:9`; `tools/flash/side-by-side.mjs:17-22`.
- A-ANIM-06 (S): `render/anim` and `data/anim` are on no director's owns line. Evidence: `DIRECTORS.md:247`; `docs/directors/animation.md:3`, `:10`.

You own: `docs/decisions/`, `docs/ep/`, shared files (`CLAUDE.md`, `DIRECTORS.md`, `README.md`, `.gitignore`), and the commit of every director's deliverable. `.claude/commands/` is on no owns line: record it as the EP's in the roster fix (criterion 11) before editing it. A change to `CLAUDE.md` is shown to Orb first. Data files are changed by their owners or under a written grant, never by the EP.

Acceptance criteria:
1. (A-PROCESS-03) Every uncommitted path is committed or deliberately ignored, one owner's group at a time, each commit reviewed. Orb's private replays, play files and in-progress character art are ignored with a written line, not committed. Check: `git status --short` on a quiet tree is saved under `docs/ep/runs/<sha>/` and holds only paths named as in progress; a fresh clone builds.
2. (A-CODE-01, golden window GW1) Each switch group lands as main's data under its owner (pad, computer opponent, match-ending rules, round planet, camera, look, sound sets, left-panel menus), each with its own gate run saved under `docs/<area>/runs/<sha>/` and its own side-by-side against the 9 November build (look gate, ADR 0010), which the EP opens before committing. Check: Tools' count of rows differing between main and the build's packed data reaches 0, or every remaining row is written down as a real choice; the count is reported to Orb every two days.
3. (A-CODE-01) Nothing from A3 lands until GW1 is closed and Simulation's golden record for the game as shipped exists (A-CODE-02).
4. (A-RENDER-11) `docs/ep/taste.md` names the reference build Orb chooses (decision 4), with that build's known picture faults listed as not part of the reference. It moves only on Orb's recorded word. Check: the page; `side-by-side.mjs` runs against it.
5. (A-RENDER-07) An index under `docs/ep/runs/` ties each visible landing from A1 on to its side-by-side (commit, owner, where the pictures are). Pictures showing private replays or in-progress character art are pointed to, not published. Check: every GW1 landing with a visible change has a line.
6. (A-PROCESS-02, X-33) One backlog file under `docs/ep/`, keyed by register id, absorbs the corrective plan's open rows, the owed list, parked folders and QA's bug list; Production drafts it. Check: no open item cited in a brief lacks a line.
7. (A-PROCESS-07) Every corrective-plan row is closed with a commit or record, or carries an owner and a date; the two overdue wave-1 items are closed or escalated; Orb is asked the CD-11 question (orb.md). Check: the plan read against `reads/RR-09.md`.
8. (A-PROCESS-08) A committed weekly token record, first row for the first week of A1. (A-PROCESS-09) One small sprint through /sprint-plan and /sprint with Orb at the PC, its report saved. (A-PROCESS-10) No command file carries a session id, and `docs/ep/handoff.md` holds the current handover; check by starting one command against a renamed session.
9. (A-PROCESS-06, A-PROCESS-11) `CLAUDE.md` points to the A1 to A6 path in place of P0 to P5 and states Orb's token rule of 2026-11-06; a new ADR supersedes ADR 0005; the activation schedule in `DIRECTORS.md` matches who works. Orb sees the `CLAUDE.md` diff first.
10. (A-PROCESS-16, X-33) A page lists each Alpha feature with its done test and exit criterion; `CLAUDE.md` and the playbook point to it and to Production's change-control page and ideas log (supports A-PROCESS-01).
11. (A-PROCESS-13, A-ANIM-06) The roster maps each director to their A1 to A6 rows; the camera charter and the roster agree on the model; the folder that does not exist is resolved; `render/anim`, `data/anim` and every other folder with no owner today has one or is recorded as shared with a grant rule.
12. (A-PROCESS-14, A-PROCESS-15) /crunch and /overnight are retired or rewritten to read the approved plan; the README lists every command; /standup's first step reads CI. Check: a standup run whose first line is the CI state.
13. Supports: correct the playbook's build-check line once Tools' tracked script exists (A-TOOLS-10); write `docs/ep/approvals/desktop-test-builds.txt` only on Orb's recorded yes, in Legal's wording (A-TOOLS-01, A-LEGAL-02); pass Production the figures for the tracker and risk register (A-PROCESS-04, A-PROCESS-05).

Constraints: about 8.7M tokens at the register's size classes (1 L, 1 M, 14 S), an estimate, beside the usual third of each week on briefs, reviews and gate runs. A-CODE-01 changes the sim's state hash and lands only in golden window GW1 "Main is the game", with the twelve rows the path lists; A-NET-05 lands before the window. Gate runs: headless Godot only, at most 3 Godot processes while long runs are going, long runs at below-normal priority, captures only through Tools' launcher. Determinism holds through every landing (seeded RNG, fixed step, no rendering state in the sim; a data shape change updates its schema in the same commit); read CI after every push. Orb's rules: nothing drawn on, over or between the fighters; no dissolves or fades; plain words; one clear question at a time; forward-facing text seen by Orb before use; in-progress character art never public; nothing personal in any committed file. Nothing is built from the ideas log without Orb's yes.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT), as the EP's report to Orb.

Order: Orb's approval of the path and decisions 1 to 6 come first. Then A-PROCESS-03; then Tools' A-CODE-03 with A-UI-02 and A-ENERGY-04; then the switch groups one owner at a time; A-CODE-01 closes when no row differs; A-CODE-02 follows; then Tools' first desktop build. The process rows run beside all of it. Waiting on this: every A1 exit line, and everything in A2 to A6.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- Golden window GW1 is split. GW1a: the golden record is made first on the kept 9 November build's own data, as the target; the switch groups land one at a time; A-CODE-01 closes when main reproduces that record bit for bit; the first desktop build and its same-replay comparison are made on that commit. GW1b, straight after: the riders (A-ENERGY-05, A-AI-10, A-COMBAT-05, A-COMBAT-11, A-CONTROLS-04), then one re-record. (ORD-01, COS-11, ORD-05)
- Before each push of the working-tree clean-up (A-PROCESS-03): run `node tools/content-screen.mjs` on the staged set; every committed GIF carries the clip analyser's verdict or is ignored; add the git-ignore line for testers' raw files. (PC-06, PC-02)
- Your milestone page lists the machine's long runs with their hours, the quiet window kept for frame readings, and which sessions pause while a reading is due. (COS-09)
- Tools' repair of the flash measuring chain (A-LEGAL-08, the first two criteria of `A2/tools-pipeline.md`) is sent on day one and does not wait on A1's landings. (ORD-06)
- Decisions 11 to 15 and 18 are put to Orb on day one with 1 to 6. No row is taken by silence: work that depends on an unanswered row waits, and you list what is waiting. (ORD-08, ORB-08, ORB-10)
