# The eighth round's window, as Game Design settled it (2026-10-15)

Owner: Encounter Systems Director. Game Design's tenth round (`docs/design/brawl-second-pass.md`, dfcb3ca1) settles the eighth round's window to **one data line**. The rest of the round is main's own values: the pursuit off, the launching blow at 3, no count of its own for a heavy, the medium AI's `digIn` at 0.55.

| Key | From | To | Why |
| :--- | ---: | ---: | :--- |
| `brawl.burst.runHalves` in `data/director/interrupts.json` | 1 | 2 | Every blow of a held X adds a full point to the run, as a tap's does (the sixth round's ruling c) |

**To apply:** `node docs/director/pending/sixth-round/s6.cjs <root> data runhalves`, or the same one-line edit by hand. No code, no schema key. Then the golden regenerated once (it moves: 6 of its 11 runs), and the gates.

**Gated in scratch on main 97d69fdb: all 35 pass.** The golden regenerated, npm, parity, the validator and its self-test, determinism plain and with intros, the seam sweep, `anim_check`, the three `--strict` scans, the cue, read and HUD checks, `brawl_cases.gd`, World's five, QA's run-all, the flash count, the mash probe, the nine input tests and the loader on 200 matches.

**What it reads.** With this step alone on main, the X masher against the medium AI is unchanged at 50 of 100 (100 matches, seed 1). In the sixth round's stack, QA's re-pressing X holder read 0 of 60 with it and 0 without, his closes unchanged at 19 a match. It is the rule as written, and it costs nothing measured.
