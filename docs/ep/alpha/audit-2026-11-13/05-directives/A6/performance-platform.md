# A6: Performance & Platform

Leads: none
Supports: none

Goal: The candidate runs smoothly on Orb's PC and holds the agreed frame rate on a friend's Steam Deck, and it loads quickly on both.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A6; decision 19; "Exit criteria this audit proposes to change", X-24); `docs/ep/alpha/alpha-audit-specification.md` lines 190 to 193 (X-23 to X-26); your A5 page on the Deck's default quality level and the frame records under `docs/perf/runs/`; `docs/perf/quality-range.md`; the bench files the two friends return, which the EP will send.
- A6 closes no register row. The tools exist from earlier milestones: the one-click bench that saves a file (A-PERF-03), the frame record on the played build (A-PERF-04), the loading timer (A-PERF-06) and the memory baseline (A-PERF-07).

You own: `docs/perf/`.
- ask under NEEDS FROM EP for a grant: `tools/` (name the bench file), only if the bench itself is wrong; a change to it during A6 means every reading is taken again.

Acceptance criteria (all on the candidate's commit, each saved under `docs/perf/runs/<sha>/`, CD-22):
1. (X-23) On Orb's PC, in a normal match at the PC's default quality level, 60 frames a second is held and no frame outside loading is longer than 50 ms. Checked by: the frame record from the bench, taken in a quiet window agreed with the EP; a reading taken while the machine was saturated is marked invalid and re-taken.
2. (X-24) On a real Steam Deck, at the Deck's default quality level, the figure Orb confirmed is held (30 frames a second held, 40 as the aim, unless Orb changed it after A2). Checked by: a tester's bench file that names the build, the quality level and the Deck; both friends' files are read, and a reading from anything but a real Deck does not count.
3. (X-26) From starting the game to the menu, and from "start match" to control, each is under 15 seconds on Orb's PC and under 30 seconds on the Deck. Checked by: the bench's loading figures from Orb's PC and from a tester's file.
4. (X-25, with QA) Memory growth over QA's two-hour soak is under 10% against your baseline on Windows and on Linux. Checked by: your read of QA's result files, with the growth figure and how it was computed.
5. (X-24's hardest scene; the frame line of X-10) The frame rate holds with the largest horde wave on screen at the Deck's default level. Checked by: the frame-time record at the largest wave from a tester's Deck, or, if no tester reached it, a plain statement that it is unmeasured on a Deck, sent to the EP as a question for Orb.
6. A one-page verdict in `docs/perf/` lists each of X-23 to X-26 as "holds" or "misses", with the number and the file behind it, and for any miss the smallest change that would fix it and whether that change alters the picture (which makes it a look-gate question for Orb, in pictures, not numbers). Checked by: the page.

Constraints:
- Tokens: a share of the milestone's 5M for verification (an estimate); fixes draw on the 8M fix reserve, through the EP.
- State hash: no change. A performance fix that would alter the sim's fingerprint is reported, not made; it would send the candidate back to A5's window.
- Machine: frame readings need a quiet machine: no soak, band batch or capture running; long benches at below-normal priority; headless Godot for script-side numbers only; at most 3 Godot processes for a short gate.
- Determinism: the bench plays seeded matches and names its seeds, commit and data hash.
- Originality: not touched.
- Orb's rules: no metric overrides the look (ADR 0010): a frame-rate fix that worsens the picture goes to Orb as a short visual question or does not ship; there is no target machine below the agreed specs (ADR 0013); plain words in the verdict.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Item 1 and the PC half of item 3 run as soon as the candidate is built, before the friends are invited. Items 2, 3 (Deck half) and 5 wait on the friends' bench files. The fix round and the freeze wait on your verdict.
