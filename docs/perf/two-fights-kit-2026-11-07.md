# The two-fights old-PC kit (Performance and Platform, 2026-11-07; co-op 2v2 A7)

**What Orb does:** copy the folder `homework/Files/oldpc-kit-a8bc66e2-2v2` to the old PC, double-click `RUN-TEST.cmd`, press Enter, and click START in the game window twice (the page says when). About 8 minutes. One result file `oldpc-result-a8bc66e2-2v2-<stamp>.json` comes back to `homework/1 Urgent`. Read it with `node docs/perf/oldpc/kit/read-two-fights.mjs <that file>` (a second file can be named to set two PCs side by side). **Information only: ADR 0013, the old PC is a reading, never a gap.** The kit folder is untouched since it was built; run a copy here.

**What it holds.** Same kit as before (`docs/perf/oldpc-kit-2026-11-01.md`), built from the morning kept build a8bc66e2 (`homework/Files/builds/orb-first-play-a8bc66e2-dee2fb35`), plus:
- `game2\`: the same page with the match set to **two fights** (setup `fights 2`, `cross`, `outside`: hits across and blows from outside, A1's switches on in the setup, not in the data). Four fighters; the computer plays three, the player's slot stands idle as in the 1v1 kit page, and the view shows fight one (as the LAN's camera does). The page's probe reports `fights`: 1 in `game\`, 2 in `game2\`.
- Part 1c: the same match (planet 7, seed 77, 3,600 ticks, a match and a rematch) with one fight and with two, back to back (`oldpc_sim.gd --fights=1|2`).
- Part 2: the page runs `game\` then `game2\`, 2 minutes each (`?games=game,game2`), so the frame ratio is within one session.
- `build-kit.mjs --site <1v1 web> --site2 <two-fights web> --build a8bc66e2-2v2`; `kit-trial.mjs --games game,game2` tries it headless; `read-two-fights.mjs` reads the result.

**How the two-fights page was made (scratch, not in the repo):** Tools' stack tree of a8bc66e2 (`stack-preview.mjs --rev a8bc66e2 --keep-tree`, same key `0fefb541c93c`; its sim, data and net equal the kept tree byte for byte), then three edits to the scratch `render/core/main.gd` (the menu's `ai` gets slots 3 and 4, the setup gets the three keys, the probe reports `fights`), exported with the pinned single-thread template; its `index.pck` goes into a copy of the kept web folder (the shell is the kept one; the engine files are the kept ones). The 1v1 side of the kit is the kept web folder as it is. **A real page word `?fights=2` would be Tools' to add if this is wanted again** (a switch row with `setup`); the scratch tree and edits are not kept.

**Tried end to end on this PC** (headless Chrome through Tools' launcher, a copy of the kit, machine load 24 to 56% while it ran: under the 60% rule but not quiet, so read as indicative, ratios over milliseconds):

| | One fight | Two fights | Ratio |
| :--- | ---: | ---: | ---: |
| Sim tick mean, native (two runs of the kit) | 0.57 ms | 1.0 to 1.08 ms | 1.8 to 1.9 |
| Sim tick p99 / max, native | 2.4 to 2.7 / 5 to 6 ms | 2.2 to 2.3 / 5.5 to 9.5 ms | the tail does not double |
| Page frames p50 / p99 (this PC's GPU; the page runs ~80 fps and is not vsynced to 60 in the trial) | 11.5 / 27.7 to 27.9 ms | 11.6 to 12.5 / 28.3 to 29.6 ms | about +0.1 to +1 ms p50 |
| Page sim ticks per second (mean, slowest second) | 59.9 to 60.2, 40 to 48 | 59.7 to 60, 41 to 47 | same |

**Reading it:** a second fight doubles the sim's mean tick (about 0.5 ms more) but adds almost nothing to the frame, because the second fight is stepped and cued but not drawn, and the sim is a small part of a frame (the page's render side is the big part, `docs/perf/impact-stutter.md`). On this PC two fights cost no measurable frame time. What the old PC does with it is what the file will say.

**Not covered:** a human in the second fight (the kit's players are idle and the computer plays three), drawing the partner's fight (RL-249 keeps it private until its clips pass), LAN traffic, the full-length 2v2 (A6's 8 to 12 minute match: the trial's matches are 2 to 3 minutes of ticks), and a quiet-machine measurement of this PC (the loads above were 24 to 56%).
