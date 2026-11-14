# A2: Performance & Platform

Leads: A-CONTROLS-08, A-PERF-01, A-PERF-03
Supports: A-AUDIO-04, A-CONTROLS-07, A-QA-02, A-PERF-05, A-RENDER-08, A-TOOLS-04

Goal: Two friends each install the build on a real Steam Deck, play for 30 minutes, press one bench button and send back two files, so the team learns for the first time whether the game starts, draws and holds a frame rate on a Deck.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A2, and risk 2 under "The critical path"), `02-areas/PERF.md`, `docs/tools/steam-deck.md`, `docs/perf/oldpc/kit/run-test.template.cmd`, `docs/perf/tools/orb-native-bench.ps1`, `docs/perf/input-latency-2026-10-22.md`, the page from spike S5 (A1: a Linux build started under a virtual display in CI, one still saved).
- A-PERF-01 (blocker): no Linux build has run on a real graphics driver or a Steam Deck, so whether it starts, whether every shader runs on the Deck's driver and how it performs are unknown. Evidence: `docs/tools/steam-deck.md:9`, `:25`; `docs/perf/runs/d41ce393/cd-12/README.md:10`; `docs/tools/cloud-reports/2026-10-28-ci-linux.md:30`. Verified detail: one seeded match was drawn on Linux with a software driver on 2026-10-28 (`docs/tools/cloud-reports/2026-10-28-web-template.md:42`); nothing on real hardware.
- A-PERF-03 (blocker): there is no one-click bench a Deck tester can run that saves a file. Evidence: `docs/perf/oldpc/kit/run-test.template.cmd:1-12`; `docs/perf/tools/orb-native-bench.ps1:1-8`; `render/core/main.gd:35`, `:47` (the game's own bench prints to the console only).
- A-CONTROLS-08: the press-to-picture latency record measures the browser build with keyboard presses in October, before the right-stick scheme; nothing measures a pad, the desktop build or a Deck. Evidence: `docs/perf/input-latency-2026-10-22.md:1-12`, `:30-32`; `docs/perf/tools/latency-bench.mjs`.

You own: `docs/perf/` (including `docs/perf/tools/` and `docs/perf/runs/`).
- ask under NEEDS FROM EP for a grant: `render/core/main.gd` (the bench writing a file instead of printing) or have Rendering make it through the EP
- ask under NEEDS FROM EP for a grant: `ui/` (the bench row) or have UI make it through the EP
- ask under NEEDS FROM EP for a grant: `docs/tools/steam-deck.md` (to record what the session found; `docs/tools/` has no owner)
- The tester guide's draft and the one-page sheet are QA's and Community & Marketing's, through the EP; you supply the install and bench steps.

Acceptance criteria:
1. (A-PERF-03) One press in the tester's build runs a fixed, seeded bench of a few minutes and saves one small file beside the report: frame times (average, worst, count over 50 ms), time from start to menu and from "start match" to control, the build id, the quality level and the graphics driver's name. It works on Windows and Linux with no outside program. The bench cannot switch off the Reduce flashing lock or reach any developer route. Check: the file made on Windows locally and on Linux in CI, saved under `docs/perf/runs/<sha>/`; its cost when idle measured as nil.
2. (A-PERF-01) First real reading, not a pass: each of the two friends' sessions comes back with a bench file and a report file from a real Deck, plus the sheet saying how long install took and where they got stuck (X-18, X-19, X-24, X-26). Record: both files and a one-page reading under `docs/perf/runs/<sha>/deck/`, with anything that names a person removed first.
3. (A-PERF-01) The reading page states plainly: did it start; did every shader draw; the frame rate at the default quality; loading times; did the Deck's own controls arrive as a pad; did sound play. It ends with one recommendation on the Deck target ("30 held, 40 as the aim" stands, or what to change) for the EP to take to Orb.
4. (A-PERF-01) If a session fails to start or draw, the failure file and the driver's name go to the EP the same day; that is a finding that stops a newcomer step and is fixed in this milestone.
5. (A-CONTROLS-08) A current latency record: a scripted pad press (stick and face button) to picture on the desktop build on Orb's PC, saved under `docs/perf/runs/<sha>/`, with the October browser record marked superseded. A Deck figure is not asked for in this milestone.
6. (supports) A-AUDIO-04 and A-CONTROLS-07: the friends' sheet carries Audio's and Controls' questions, and their answers are passed back through the EP. A-QA-02: the soak's memory sampling uses a call you name. A-PERF-05: re-take the frame record for Rendering on a quiet machine. A-RENDER-08: time the cold start with the longer warm-up list. A-TOOLS-04: measure the crash file's per-tick cost in the bench.

Constraints:
- Tokens: about 2.65M as an estimate (two M rows and one S row at the size classes); most of A-PERF-01 is round trips with people, which tokens do not measure. Allow one to two weeks for two friends' evenings.
- State hash: no change. The bench reads the sim and never writes it; A2 has no golden window.
- Machine: headless Godot only on Orb's PC apart from the bench itself; at most 3 Godot processes for a short gate; long runs at below-normal priority; measurements only on a quiet machine, and a saturated reading is void, not reported; browser captures only through Tools' launcher.
- Determinism: the bench match is seeded and fixed-step so two Decks run the same thing; bench numbers and thresholds live in data, with a schema if a new data file is added.
- Originality: nothing copied from another game's benchmark scenes.
- Orb's rules: plain words on the sheet and the bench screen, seen by Orb before use; nothing drawn on, over or between the fighters (the bench shows no overlay during the fight); the AI disclosure is in the package the friends get; in-progress character art never public; never report the old laptop as a gap (ADR 0013). No friend's name, account or address goes into the repository.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: before the bench: A-TOOLS-01 (the one-command desktop build, A1) and spike S5's page. Before any friend gets a build: every gate on Legal's list green on the commit (A-LEGAL-03, A-LEGAL-01), Orb's one-line approval recorded, the itch.io rehearsal done (A-TOOLS-02, A-TOOLS-03), the crash file and the report in the build (A-TOOLS-04, A-TOOLS-05). Waiting on this brief: Orb's decision on the Deck frame-rate target, the Deck's default quality level (A5), Audio's and Controls' Deck rows (A-AUDIO-04, A-CONTROLS-07), and the re-estimate of the Alpha date at the end of A2.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- A tester's raw report and speed-test files are never committed: they live in a git-ignored folder, and only the team's own reading of them (numbers, no quoted notes) is saved under `docs/*/runs/<sha>/`. A tester's request to delete is carried out on that folder and on the report server. (PC-02)
- Criterion, added: one sourced page on the Deck round trip, written before the friends' sheet: the route chosen for install, start and update; where the report and speed-test files land on a Deck; how they are posted from the Deck. Each step cites the platform's own page. The look-up the audit skipped is done first, through the EP (directors do not browse). Move the "no keyboard and no terminal" package work here only if that look-up shows the itch.io app cannot do it. (MIS-05)
- The press-to-picture record on the desktop build is taken by Orb starting the one-click test, or in CI; no session opens a Godot window. (PC-07)
