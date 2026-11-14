# A5: Performance & Platform

Leads: none
Supports: A-RENDER-06, A-QA-01, A-WORLD-05

Goal: The Steam Deck starts the game at a picture-quality level it can hold, chosen from real Deck readings, and the tester guide's install steps for a Deck are the ones that actually worked.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A5; decision 19; risk 2 "The Steam Deck says no to something"); `docs/perf/quality-range.md` (the Result list, line 30, and the ladder table at lines 117 to 121); `docs/decisions/0012-turntable-and-quality-range.md`; `docs/tools/steam-deck.md`; `docs/ep/proposals/terrain-globe-plan.md` line 149; the Deck session record from A2 and the bench files from A3 and A4, which the EP will send.
- A-RENDER-06 (Rendering leads): no working level picker, no Deck default. Evidence: `docs/perf/quality-range.md:7` (nothing a player can reach scales today); `docs/perf/quality-range.md:119-120` (the ladder's Deck row: 30 held, 60 when it can); `render/vfx/vfx_hub.gd:156-158`. Risk on the row: without real Deck readings the Deck's default is a guess.
- A-QA-01 (QA leads): no tester guide or Deck checklist exists. Evidence: `tools/desktop-package.mjs:56-59` (the Deck gets one line after unpack-and-chmod steps a newcomer without a keyboard is unlikely to finish); `docs/tools/steam-deck.md:13-25`.
- A-WORLD-05 (Rendering leads): the cost of rebuilding ground tiles is unmeasured (`docs/ep/proposals/terrain-globe-plan.md:149`).

You own: `docs/perf/`.
- Your benches live in Tools' folder: ask under NEEDS FROM EP for a grant: `tools/` (name the bench file), or hand the EP the change.

Acceptance criteria:
1. (supports A-RENDER-06) A page in `docs/perf/` reads every real Deck bench file collected from A2 to A4 and says, for each dial Rendering can move, what the Deck gains from it, and which combination holds the Deck figure Orb confirmed. Readings taken on anything but a real Deck are labelled as such and are not used for the default. Checked by: the page, each number pointing at a saved bench file.
2. (supports A-RENDER-06) Each of the three levels has a frame record on Orb's PC from the one-click bench (built under A-PERF-03), with median, 95th percentile and the longest frame outside loading, saved under `docs/perf/runs/<sha>/` (CD-22). A reading taken while the machine was saturated is marked invalid and re-taken.
3. (supports A-RENDER-06) The bench file a tester's Deck writes names the quality level it ran at, so A6's X-24 reading cannot be taken at the wrong level. Checked by: a bench file from the A5 build.
4. (supports A-WORLD-05) The worst frame caused by rebuilding ground tiles after a big crater is measured on the Windows build on the reduced record store, and stated against X-23's 50 ms. Checked by: the frame record, saved; a miss is reported before Rendering's change lands.
5. (supports A-QA-01) The Deck part of the tester guide (get the file, install, start, update, run the bench) is checked line by line against what happened at the A2 Deck session, and every step that needed a keyboard or a terminal is either removed by Tools or called out. Checked by: your marked copy returned to the EP for QA.

Constraints:
- Tokens: no row of its own; plan on about 0.5M of supporting work, an estimate.
- State hash: no change.
- Machine: headless Godot for script-side numbers only; a windowed frame record on Orb's PC needs the EP's word on when the machine is quiet; long benches at below-normal priority; at most 3 Godot processes for a short gate; browser captures only through Tools' launcher (`tools/machine/capture.mjs`).
- Determinism: a bench plays seeded matches and names its seeds, commit and data hash.
- Originality: not touched.
- Orb's rules: there is no target machine below the agreed specs (ADR 0013): never report the old laptop as a gap; no metric overrides the look (ADR 0010), so a level that looks worse than its neighbour by more than its frame gain is said so in pictures, not numbers; plain words in anything Orb reads.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Needs A-PERF-01 and A-PERF-03 (the real Deck session and the one-click bench, A2) and the bench files asked of the same friend at A3 and A4. Rendering's Deck default (its item 3) waits on your item 1. A6's X-23, X-24 and X-26 readings are yours and use the same bench.
