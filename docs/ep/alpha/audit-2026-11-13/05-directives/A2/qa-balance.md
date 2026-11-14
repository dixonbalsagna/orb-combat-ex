# A2: QA & Balance

Leads: A-QA-02, A-QA-11
Supports: A-PERF-01, A-LEGAL-05, A-RENDER-02, A-AUDIO-04, A-CONTROLS-07

Goal: The game is left running computer against computer for two hours on Windows and on Linux and a file says whether it crashed, hung, threw a script error or grew in memory; and five old bug entries are either seen fixed in play or reopened with an owner.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A2), `02-areas/QA.md` (F-QA-02, F-QA-17), `qa/known-bugs.md`, `docs/qa/runs/6a30b4c9/README.md`.
- A-QA-02 (blocker): no soak test (a long unattended run) exists for the Godot game: nothing records crashes, hangs, script errors over hours or memory growth on Windows or Linux. Evidence: `qa/tests/soak.test.js:1`; `sim/core/tools/soak.js:2-3`; `sim/world/tools/gen2_soak.gd:2` (these cover the pinned prototype, the frozen JS core and short world matches); no game script samples memory.
- A-QA-11: five older bug entries (GB-002, GB-003, GB-005, GB-006, GB-007) are open, or fixed but never re-checked in play, since 2026-10-02. Evidence: `qa/known-bugs.md:22-27` (each row names what closes it and which director names the commit).

You own: `qa/`, `prototype/tools/`.
- ask under NEEDS FROM EP for a grant: `docs/qa/` (the saved records under `docs/qa/runs/<sha>/`; the folder has no owner)
- ask under NEEDS FROM EP for a grant: `.github/` (the two CI soak jobs) or have Tools add them through the EP
- The crash and hang file is Tools' (A-TOOLS-04); the memory call is named by Performance. Ask for both through the EP.

Acceptance criteria:
1. (A-QA-02) A soak runner starts the exported desktop game, plays computer-against-computer matches back to back with a fixed list of seeds, and writes one result file: matches played, crashes, hangs (no tick for a stated time), script errors, and memory sampled at each match's end. Check: a 20-minute pilot on Orb's PC first, saved under `docs/qa/runs/<sha>/`.
2. (A-QA-02, exit line X-25, first reading) A two-hour soak has run on Windows and on Linux in CI and both result files are saved under `docs/qa/runs/<sha>/` with memory growth stated as a percentage. This is a first reading: the tool existing and the reading saved closes the criterion for A2; the numbers must pass from A3 on (the proposed bar is no crash, hang or script error and memory growth under 10%).
3. (A-QA-02) Anything the soak finds is entered in `qa/known-bugs.md` with its seed, the result file and an owner proposed to the EP.
4. (A-QA-11) Each of GB-002, GB-003, GB-005, GB-006 and GB-007 is closed by the check its own row names (a read at main's head, a named test row, and a clip or Orb's confirmation on a current build where the row asks for one), or stays open with today's date, the director who owes the commit, and a one-line question to the EP. Record: the readings under `docs/qa/runs/<sha>/`.
5. (supports) A-PERF-01 and A-LEGAL-05: with Community & Marketing through the EP, the full draft of the tester guide and the one-page sheet for the two friends (install, play two matches, press the bench, post two files; how long install took; where they got stuck), carrying Audio's and Controls' questions (A-AUDIO-04, A-CONTROLS-07) and Legal's final words. A-RENDER-02: add the bug rows for the two picture faults once Rendering names them.

Constraints:
- Tokens: about 1.45M as an estimate (one M row and one S row at the size classes).
- State hash: no change; the soak plays the game as built. A2 has no golden window.
- Machine: the soak is a long run: below-normal priority, headless, at most 3 jobs for QA (one job is two Windows processes), never launched twice, and it must exit by itself with its time limit written in the script. The two-hour runs belong in CI, not on Orb's PC. Stop only your own processes by PID. A measurement taken while the machine was saturated is void.
- Determinism: seeded matches from a fixed list so a failure can be replayed; the runner reads the game and never writes sim state; thresholds live in data, with a schema if a new data file is added.
- Originality: nothing to add.
- Orb's rules: plain words in the guide and the sheet, seen by Orb before a friend gets them; the AI disclosure at the top of the guide; in-progress character art never public; no friend's name or account in the repository.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: before criterion 1: A-TOOLS-01 (the one-command desktop build, A1). Before criterion 2: A-TOOLS-04 (the crash and hang file), so a dead run says why. Criterion 4 can start today. Waiting on this brief: the soak must pass from A3; a two-hour soak on a friend's Deck is asked of Orb as a question and, if yes, is run with this runner at a later round.
