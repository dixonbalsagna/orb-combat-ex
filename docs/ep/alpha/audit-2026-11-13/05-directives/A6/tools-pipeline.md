# A6: Tools & Pipeline

Leads: none
Supports: none

Goal: The build two friends download is made by one command from one commit, shows its version, can be taken back in one step, tells Orb why if it ever dies, and is filmed for the archive exactly as it is.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A6, "Change control"); `docs/ep/alpha/alpha-audit-specification.md` lines 188 and 195 to 201 (X-21, X-28 to X-34); `docs/tools/desktop-builds.md`; `tools/desktop-package.mjs`; `tools/write-build-info.mjs`; `.github/workflows/desktop-builds.yml`; your A5 rehearsal record and release checklist under `docs/tools/`.
- A6 closes no register row. The tools exist from earlier milestones: the one-command build and version stamp (A-TOOLS-01, A-TOOLS-07), a CI job that starts the Windows build (A-TOOLS-13), the itch.io upload and keys (A-TOOLS-02), the rollback checklist (A-TOOLS-03), crash and hang capture (A-TOOLS-04), the report folder off Orb's PC (A-TOOLS-05), the report's name-and-path check (A-LEGAL-06), the mode smoke suite (A-MODES-08) and the shot list, render job and archive (A-MARKET-01 to A-MARKET-03).

You own: `tools/`, `build/`, `.github/`.
- ask under NEEDS FROM EP for a grant: `docs/tools/` (run records; the folder has no owner).
- Uploading to itch.io uses Orb's account: you prepare the command and the record; Orb or the EP, on Orb's word, runs it.

Acceptance criteria (all on the candidate's commit, each saved under `docs/tools/runs/<sha>/`, CD-22):
1. (X-29) One command, in CI, makes the Windows and Linux desktop builds from the candidate's commit, the solo game included; the game shows the version number; a changelog entry exists for it. The packages are verified from their own packed data, not from a switch list. Checked by: the CI run and the verification output.
2. (X-31, X-30) The candidate is on the restricted itch.io page on the Windows and Linux channels as an update over the A5 build; one key per named friend exists; the step that returns testers to the A5 build is written on the checklist and was rehearsed in A5. Checked by: the upload record and the version each channel shows.
3. (X-28) A forced crash and a forced hang on Windows and on Linux each leave a file that says why, and the one-press report folder picks it up. Checked by: the forced-crash test's output per platform.
4. (X-21) A report made on a Steam Deck by one press is under 10 MB with clips separate, passes the name-and-path check, and nothing in the build sends data by itself. Checked by: a tester's report folder and its size; the saved read of the code for anything that sends.
5. (X-05) The mode smoke suite passes for each mode offered, from the menu with a pad alone, on Windows and on Linux, on the packaged builds. Checked by: one saved run per mode per platform.
6. (X-34) The fixed shot list renders from the candidate at full size, only "played" shots, each sequence with its flash-check verdict, and the set sits in the archive beside the A1 to A5 sets with one line on what changed. Checked by: the archive's index. Nothing in it is published.
7. (X-02) You give the EP one index of every gate record saved for the candidate's commit across `docs/*/runs/<sha>/`, and a list of any gate on the "before an outside tester plays" list with no record. Checked by: the index; the EP and Legal read it.
8. (fix round) Each fix is built and packaged by the same one command, the version number moves, the changelog gains a line, items 1, 2 and 5 are re-run on the new commit, and the friends receive it as a real update. Checked by: the records for the final candidate commit.

Constraints:
- Tokens: a share of the milestone's 5M for verification (an estimate); fixes draw on the 8M fix reserve, through the EP.
- State hash: no change. Tools' work does not touch the sim; a build step that changes packed data is a fix like any other and is said out loud.
- Machine: the browser only through the guarded launcher (`tools/machine/capture.mjs`), one capture at a time, time-limited, at below-normal priority; a full-size shot set is a long run and does not overlap a frame reading or the soak; headless Godot only, at most 3 processes for a short gate; check `tools/machine/captures.mjs` shows nothing of yours running before you end a turn; read CI after every push.
- Determinism: a recipe names its build, seed and tick window; the same commit gives the same packages.
- Originality: every shot is the game itself.
- Orb's rules: in-progress character art is never public and nothing leaves the archive without Orb's word; the AI disclosure is first in the package; plain words in the README and changelog, seen by Orb before use.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Items 1, 3 and 5 run first, on the commit GW4 landed on; item 2 waits on them, on Legal's rows and on Orb's upload action; the two friends are invited only after item 7's index shows every gate green. Item 4 waits on a tester. Item 8 waits on the fix list. The freeze waits on the final candidate's records.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- Say for each criterion which package it is read on: outside-tester or trusted-two, both from the candidate's commit. Every upload to itch.io is Orb's own action, listed on Orb's page for this milestone; no session uses Orb's sign-in, so "or the EP" does not apply. (PC-08) (MIS-08)
