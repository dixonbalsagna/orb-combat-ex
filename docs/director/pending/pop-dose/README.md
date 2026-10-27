# The pop dose (parked 2026-10-27)

Owner: Encounter Systems Director. Game Design's `rulings-2026-10-26.md` §2j items 42 and 43, on c2a0dba2. The pop is read only with launch anywhere on (`DirBrawl.popOn`), which is off on main, so the golden doesn't move.

## To build it

On c2a0dba2 or later: `node pd.cjs <root>` from this folder. `--check` reads every anchor and writes nothing.

| File | Owner | Change |
| :--- | :--- | :--- |
| `data/director/interrupts.json` | Encounter | `brawl.launcher.anywhere.pop`: `full` 0.8 to 0.72, `stringPoints` 2 to 3, and its `_note` says why |

No schema change: `full` is a number of at least 0, `stringPoints` an integer of at least 1.

## Why

- A launcher under `full` (after freshness) pops him and the brawl holds; at `full` or over it sends. A pop counts `stringPoints` toward the next launcher.
- With `full` lower and a pop counting more toward the next launcher, more of a long string's launchers send instead of popping again. QA's reads (`docs/qa/rally-read-fa6f727a.md`, third and fourth addenda): the pops a match hardly move (12.0 to 11.7), full launches rise (6.9 to 9.0), and the shortest matches reach 300 s, p10 306 s on 200 matches on de029972 (from 284).
- **Not in this park:** easy's answer share (item 43's `brawl.anywhere.answer` in `ai.json`'s easy block, 0.2 to 0.3, then 0.35), for the newcomer against easy at 97%. QA reads it first, and it follows as a second park.

## What it reads

No new reads: QA's arm 3 on de029972 is the evidence (fourth addendum).

- **Switches off** (a scratch export of c2a0dba2 with the park): the golden is main's, byte for byte. Import clean, validate 269 files 0 errors, self-test passes. All 35 of Encounter's gate runs exit 0: npm, parity, determinism (and `--intro`), seam, anim_check, the lead, joint and held scans, cue, reads, hud, brawl cases, World's five tools, QA's run-all, flash worst and count, mash, the nine input tests and the loader. So do Rendering's 16 headless checks (cue with `--profile=spaced`; outline and cull need a window), split_sweep and campaign_episode.
