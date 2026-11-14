# A1: Tools & Pipeline

Leads: A-CODE-03, A-CODE-04, A-ENERGY-06, A-LEGAL-02, A-MODES-08, A-TOOLS-01, A-TOOLS-07, A-TOOLS-08, A-TOOLS-09, A-TOOLS-10, A-TOOLS-13, A-TOOLS-15, A-UI-02
Supports: A-CONTROLS-02, A-AI-05, A-ENERGY-04, A-COMBAT-14, A-WORLD-01, A-RENDER-01, A-CAMERA-01, A-AUDIO-01, A-CODE-02, A-UI-04, A-UI-09, A-NET-05, A-AI-04, A-QA-09, A-SAVES-01, A-PROCESS-03, A-RENDER-07

Goal: Orb starts the game they played on 9 November as a Windows program made from main by one command (a Linux build beside it), sees a version number, and the report button saves a file after any match.

Context: read first `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A1: the order of work is fixed), `02-areas/TOOLS.md`, `02-areas/CODE.md`, `docs/ep/playbook.md`, `docs/decisions/0010-look-gate.md`, `.github/workflows/desktop-builds.yml`, `tools/desktop-package.mjs`, `tools/preview/switches.mjs` (the private page's "switch table": the list of data keys the page tool flips to make Orb's build).
- A-TOOLS-01 (L, blocker): no one command or CI run makes the Windows and Linux builds of the game as Orb plays it. Evidence: `.github/workflows/desktop-builds.yml:15` (by hand only) and `:52` (refuses without `docs/ep/approvals/desktop-test-builds.txt`, which does not exist); 0 runs of the workflow (read 2026-11-13); `tools/desktop-package.mjs:219`.
- A-CODE-03 (M): Orb's solo build carries code that is not on main. Evidence: `tools/preview/switches.mjs:7`, `:8`, `:1027`; `render/core/main.gd:441`.
- A-UI-02 (M, blocker): on a plain desktop build the one-press report and "Save this match" save nothing. Evidence: `ui/hud/ui_hud.gd:3537`, `:3545`; `net/tools/lan_kit.mjs:58`; `tools/preview/blackbox.mjs:2` (the "black box", the browser page's match recorder).
- A-LEGAL-02 (M, blocker): no desktop package for an outside tester can be made today. Evidence: `.github/workflows/desktop-builds.yml:54`; `tools/desktop-package.mjs:31`, `:35`; `tools/site.json:5` (the notice is still marked draft).
- A-MODES-08 (M): no mode smoke suite. Evidence: `tools/preview/smoke.mjs:1-6` (fixed click points, `:110`); `docs/tools/runs/6a30b4c9/build-and-smoke.txt`; `.github/workflows/desktop-builds.yml:108-113`.
- A-CODE-04 (M): CI runs 116 of the 262 check and test scripts. Evidence: `.github/workflows/ci.yml:178`, `:221`; `tools/world-checks.json:3`; `docs/ep/gate/run-gate.sh:25`.
- A-ENERGY-06 (S): the two-fighter ratchet (a count that may only go down) does not measure X-15. Evidence: `tools/ratchet-two-fighter.mjs:1`, `:8`; `tools/ratchet-two-fighter.json:10-16`.
- A-TOOLS-07 (S): no version number, no changelog. Evidence: `tools/write-build-info.mjs:1`; `export_presets.cfg:79-80`; `ui/widgets/ui_feedback.gd:88`.
- A-TOOLS-08 (S): CI job times sit close to their limits. Evidence: `.github/workflows/ci.yml:181` (limit 75), `:285` (limit 60), `:491`; runs 42678877286 and 42752347377.
- A-TOOLS-09 (S): Orb's kept builds and play files sit in one git-ignored folder with no backup plan. Evidence: `.gitignore:28-29`; folder size read 2026-11-13 (2.9 GB).
- A-TOOLS-10 (S): the playbook's build check names a script that is not in the repository. Evidence: `docs/ep/playbook.md:21`; `tools/preview/pck-verify.mjs:4` (browser builds only).
- A-TOOLS-13 (S, nice to have): no CI job ever starts a Windows build. Evidence: `.github/workflows/desktop-builds.yml:10`, `:41`; `.github/workflows/ci.yml:8-9`.
- A-TOOLS-15 (S): corrective item CD-21 (stop silent passes) has no commit and no record. Evidence: `docs/ep/corrective-plan-2026-11-07.md:29`; `reads/RR-09.md`.

You own: `tools/`, `build/`, `.github/`.
- ask under NEEDS FROM EP for a grant: `docs/tools/` (your pages and `docs/tools/runs/<sha>/`)
- ask under NEEDS FROM EP for a grant: `render/core/main.gd` (the planet entry and the report hook now added by patch; or hand the patch text to the EP for Rendering to land)
- ask under NEEDS FROM EP for a grant: `export_presets.cfg` (version fields)
- The notice wording, the approval file `docs/ep/approvals/desktop-test-builds.txt` and `docs/ep/playbook.md` are not yours: name what you need under NEEDS FROM EP.

Acceptance criteria:
1. (A-CODE-03) The planet entry and the state probe that `tools/preview/switches.mjs` patches into a scratch copy exist on main as ordinary code; a build of that commit has the same files as the commit. Check: the patch steps are deleted from the switch table and the page build still works; a file compare of a fresh build against its commit, saved under `docs/tools/runs/<sha>/`.
2. (A-CODE-03, serving A-CODE-01) One command prints how many switch rows still differ between main and the 9 November build's packed data. The EP reads it every two days. As each owner's group lands (supports list above), its rows leave the switch table in the same commit.
3. (A-UI-02) After a solo and a two-player match on a plain Windows and a plain Linux build, the report press writes a match file and "Save this match" writes a replay; the line `prompt.report_none` is no longer reachable on a desktop build. Check: a headless test on both platforms that asserts the files exist; the replay then passes `tools/preview/blackbox-verify.mjs` or its desktop equivalent. Whether matches are kept automatically waits on Orb's answer (orb.md); build the manual save first.
4. (A-LEGAL-02) The workflow's refusal is proven and the package is complete: a run without the approval file refuses with its plain message; the package text step reads a notice that is no longer draft (wording arrives from Legal through the EP); every tester folder holds README.txt and NOTICES.txt. The real approval file is written by the EP only on Orb's recorded yes. Saved: the refusing run and a package file list.
5. (A-TOOLS-01, X-29, must pass) One command and one CI run make the Windows and Linux builds from a commit, solo game included, with main's data as shipped (no switch page). Windows first, then Linux. Each is started once and compared by stills, at the same ticks of the same replay, with the browser build Orb played. Look gate (ADR 0010): the side-by-side goes to the EP before the build is handed to Orb; a difference is reported as a finding, not fixed silently. The A1 build is for Orb and the trusted second player; an outside-tester package stays refused until criterion 4's approval exists.
6. (A-TOOLS-07) The build script derives a version number from a tag or counter, fills the Windows version fields, and the game shows the number on screen; a changelog file gains one entry per build. Check: the number read from a build's packed data equals the one on its menu still (still taken through your launcher; visible change, so a side-by-side for the EP).
7. (A-MODES-08, X-05 first reading) A mode smoke suite drives the menu by row name with a scripted pad, not by screen points, and has run solo and two players on one PC to a result, a rematch and a quit, on Windows and on Linux. Rows for unbuilt modes report "not built". Saved: one result file per mode per platform. A failing line is an acceptable first reading.
8. (A-CODE-04) A written table of all 262 scripts: runs in CI, runs in the landing gate, or deliberately not run with the reason. The input, UI, audio, camera, animation and globe-ground checks that owners name through the EP run in a workflow, and so does the Godot QA batch. Check: the table; a green CI run that includes them.
9. (A-TOOLS-08) Each CI job has a written time budget; jobs are split so none runs above about two thirds of its limit on three consecutive runs. Saved: the three run ids and times.
10. (A-ENERGY-06) A count of fighter-specific code in the energy, stamina, body and forms systems exists beside the ratchet, prints its number and cannot rise. First reading saved; the number need not be zero yet.
11. (A-TOOLS-09) A one-command copy of the kept builds and play files to a second place, a written restore step, and one rehearsed restore. Where the copy lives is Orb's answer (orb.md).
12. (A-TOOLS-10) A tracked script checks a desktop build's switch list against its packed data; you name the playbook line to correct under NEEDS FROM EP. Check: it runs on the first desktop build and its output is saved.
13. (A-TOOLS-15) Every tool behind a gate on the outside-tester list is searched for "grandfathered", "report only" and "CHECK" lines; each either fails the run or is listed with a reason. Saved: the list.
14. (A-TOOLS-13, nice to have) A CI job starts the Windows build once and saves its first lines of output. Do last; drop it first if the milestone is short.
15. (Spike S5, no register row) A CI job starts the Linux build under a virtual display and saves one still. One page: what was tried, what it cost, what it shows.
16. Supports: hand the scripted player "orbs" in `tools/feel/gauntlet.gd` to QA through the EP (A-QA-09, A-AI-04); fix the smoke's start-button step for the left-panel ("Rail") menus (A-UI-04); give UI a capture job at 1280 by 800 through your launcher (A-UI-09); stamp the build id the replay will carry (A-NET-05); a gate runner setting for "switches as shipped" (A-CODE-02); list your own uncommitted paths as commit or ignore (A-PROCESS-03).

Constraints: about 11.75M tokens at the register's size classes (1 L, 5 M, 7 S), an estimate, plus S5's share of the 4.5M spike budget. None of your lead rows changes the sim's state hash; the rows you support land in golden window GW1 "Main is the game" under their owners. Headless Godot only; at most 3 Godot processes for a short gate; anything over about ten minutes at below-normal priority; browser captures only through your own launcher (`tools/machine/capture.mjs`, `tools/flash/capture-web.mjs`), one at a time, with a time limit; check nothing is still running before you end a turn. A project-file change triggers the full flashing check set (`desktop-builds.yml:83-84`): plan it, do not slip it in. Seeded RNG, fixed step, no rendering state in the sim; numbers live in data and a data shape change updates its schema in the same commit. Nothing leaves a player's PC automatically. Text a player reads (version line, changelog, "can't save" lines) is seen by Orb before use, in plain words; the AI disclosure stays in every package; no in-progress character art in anything public; nothing drawn on, over or between the fighters; all content original.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: A-PROCESS-03 (the tree committed or ignored, the EP's) lands first. Then A-CODE-03 and A-UI-02, before any switch group. A-TOOLS-01 needs A-CODE-01, A-CODE-03 and A-LEGAL-02, so its real run is step 6 of A1; run the workflow's steps once early on the baseline commit to list what breaks. A-MODES-08's menu run needs A-MODES-01 (the mode list, UI's) and A-TOOLS-01; write it against today's menu meanwhile. Waiting on you: A-PERF-04, A-PERF-06, A-PERF-07 (first readings), QA's packed-data batches, every A2 row about the tester package, and Orb's play of the A1 build.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- Order, added: A-TOOLS-08 (split the CI jobs) before A-CODE-04; the table of check scripts in week one; the newly wired checks join CI on GW1's closing commit, on the data as shipped. A-CODE-04 is now sized L. (ORD-12, COS-06)
- A-TOOLS-13 is required, not optional: a Windows step in CI starts the build, saves a still, plays the bench match and compares its gameplay hash with the Linux run. Spike S5 (a Linux still in CI under a virtual display) is required too. Stills "through your launcher" of a desktop program come from CI or from Orb starting it once; no session opens a Godot window. (MIS-04, PC-07)
- The seed-only Windows-against-Linux planet comparison is read here, beside S5 (World's digest tool runs headless today); the dials are added to it in A4. (ORD-11)
- The first desktop build is compared with the 9 November build on GW1a's closing commit, before the riders land. (COS-11)
- Send-ahead from A2: the repair of the flash measuring chain (A-LEGAL-08) starts on day one. (ORD-06)
