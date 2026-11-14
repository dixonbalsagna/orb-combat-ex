# A1: Performance & Platform

Leads: A-PERF-04, A-PERF-06, A-PERF-07
Supports: A-TOOLS-01

Goal: the team knows, from saved readings of the first desktop build on Orb's PC, how smoothly the game Orb plays runs, how long it takes to start and to enter a match, and how much memory it uses over half an hour.

Context: read first `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A1, "The tool rule"), `02-areas/PERF.md`, `docs/perf/README.md`, `docs/perf/budgets.md`, `docs/perf/desktop-boot-2026-10-27.md`, `docs/perf/oldpc-kit-2026-11-01.md` (the one-click kit to adapt), `docs/perf/tools/orb-native-bench.cmd`, `docs/perf/tools/make-desktop-export.mjs`, `docs/ep/alpha/alpha-audit-specification.md` lines 190 to 193 (X-23, X-25, X-26).
- A-PERF-04 (S): nothing about drawn frame rate, loading or memory has been measured on the build Orb last played, and no windowed native frame record exists for any commit after d7647634 (2026-10-27). Evidence: commit 090264d7 (newest under `docs/perf`, 2026-11-07); `docs/perf/desktop-boot-2026-10-27.md:31-41`; `docs/perf/impact-stutter.md:3`. The verifier's note: headless loop rows exist for the LAN program (`docs/net/runs/6a30b4c9/lan-folder/lan-loop-rows.txt:2-10`), but they draw nothing.
- A-PERF-06 (S): no loading time is on file for the desktop game with menus, the tile ground and generated planets; the last native figure was already 15 s on a first start. Evidence: `docs/perf/desktop-boot-2026-10-27.md:37`, `:46`; `docs/perf/README.md:22-23`.
- A-PERF-07 (S): memory has never been measured on a desktop build and growth over time is marked not measured, so the soak's 10% line has no baseline. Evidence: `docs/perf/budgets.md:32`, `:39`.
- A-TOOLS-01 (Tools' row, you support): no one command makes the desktop builds. Your `docs/perf/tools/make-desktop-export.mjs` already makes a Windows release export of one commit in a scratch folder.

You own: `docs/perf/` (including `docs/perf/tools/` and `docs/perf/runs/<sha>/`).
- The build itself, the report folder and CI are Tools': name what you need under NEEDS FROM EP.
- A change to any render, UI or world file that a reading suggests is not yours: describe it under NEEDS FROM EP with the reading that supports it.

Acceptance criteria:
1. (A-PERF-04, X-23 first reading) A one-click bench for the desktop build exists (adapted from the old-PC kit), plays a fixed seeded match on the round planet with the pad scheme and camera Orb plays, and writes one small file: frames a second held, the longest frame, and the count of frames over 50 ms outside loading. One reading from Orb's PC is saved under `docs/perf/runs/<sha>/`. The criterion is that the tool exists and a reading is saved, not that 60 is held.
2. (A-PERF-04) The reading names the build's commit and version, the scene, the seed, the quality setting and whether other sessions were running. A reading taken while the machine was saturated is marked invalid and repeated, not reported.
3. (A-PERF-06, X-26 first reading) The same bench times two spans on a first start and on a second start: program start to menu, and "start match" to control. Both saved in the same file. Over 15 s is an acceptable first reading; say which stage took the time.
4. (A-PERF-07) The bench reads the program's memory at start, at 5 minutes and at 30 minutes of computer-against-computer play (QA supplies the match script through the EP), and the three numbers are saved as the baseline the soak's 10% line will be measured from. `docs/perf/budgets.md` rows for desktop memory and growth change from "not measured" to the reading and its file.
5. (A-PERF-04, 06, 07) One short page under `docs/perf/` gives the three first readings in plain words, each beside its criterion (X-23, X-26, X-25), with the one or two findings that most threaten the Steam Deck session in A2.
6. (A-TOOLS-01, support) Through the EP, hand Tools what your export script already knows: the steps it takes, the traps you hit, and the boot marks option. When Tools' first desktop build arrives, confirm in one line that your bench runs on it unchanged.

Constraints: about 0.75M tokens at the register's size classes (3 S), an estimate; the path also asks, outside the register, for frame-time readings for spike S3 (six, eight and twelve weak bodies) if the EP routes that to you, from the 4.5M spike budget. Nothing here changes the sim's state hash. A drawn frame record cannot be taken headless and sessions never open a Godot window: the bench is a file Orb starts once on their own PC, at a quiet time, and the saved file comes back through the EP. Everything else you run is headless Godot only, at most 3 processes for a short gate, long runs at below-normal priority, and every run exits. Any browser capture goes through Tools' launcher only. The bench match is seeded and fixed-step so the reading can be repeated; the bench reads state and never writes it. There is no target machine yet (ADR 0013): report readings, not gaps against a spec. The bench sends nothing anywhere; its file holds no personal details. Any words the bench shows Orb are plain and short, and are seen by the EP first. No look change comes from this brief: if a reading suggests one, it is a visual question for Orb under the look gate (ADR 0010), with a side-by-side against the reference build, never a quiet trade of looks for frame rate.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: all three rows need A-TOOLS-01, the first desktop build (step 6 of A1, after golden window GW1 closes). Before that: adapt the bench and prove it on a scratch Windows export made by your own script from the baseline commit, so the first real reading takes one sitting. Waiting on you: Orb's frame-rate decision (decision 19), the soak in later milestones, and the five-minute bench file asked of the Steam Deck friends from A2 on, which reuses this bench.
