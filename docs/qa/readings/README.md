# QA readings, sprint A1 (index; written 2026-11-20)

One page a reading: what it measures, the tool and command, the tree and data, the result with its interval, the date. Records (saved output, no user paths) are under `docs/qa/runs/<sha>/`; the method page is `docs/qa/sample-size.md` (every rate carries its interval and the tree it was read on).

| Reading | Result in one line | Page | Records |
| :--- | :--- | :--- | :--- |
| X-06, Orb's scheme at Easy, Medium, Hard | Easy 61.0% (56.1 to 65.7, 400); Medium 0 of 200; Hard 0 of 200; the script is the weakest pad and the game is hard at Medium for any scripted pad (best pads 6.7 to 8.3%) | `x06-orbs-scheme-win-rates.md` | `runs/6a30b4c9/x06-*` |
| X-13, the ten-item match checklist | Orb's 1646 play 6 of 10; scripted both-slot matches 5 of 10; three items in no play yet (lap, beam dodged off its line, the gravity well) | `x13-match-checklist.md` | `runs/6a30b4c9/x13-*.txt`, `pillars-seven-design-pillars-reading.md` |
| X-16, beam sidestep at three ranges | FAIL: 20 of 20 hit at 300, 2,500 and 6,000 units; the target is locked while a beam is on its way | `x16-beam-sidestep.md` | `runs/6a30b4c9/x16-first-reading.txt` |
| X-17, beams by source | 0 other on the played build 6a30b4c9; 6 other on 1931a0f8 (B alone, B with the dodge) | `x17-beam-sources.md` | `runs/6a30b4c9/x17-first-reading.txt` |
| A-QA-04, both-slots balance | PROTAGONIST 55.0% (48.1 to 61.7) of 200; no slot effect (50.0%) | `a-qa-04-balance.md` | `runs/6a30b4c9/balance-both-slots-table.md` |
| A-SAVES-01, replay verifies | `BLACKBOX OK ticks=19388` on 6a30b4c9; the first LAN save is not yet through the report tool (none exists) | `a-saves-01-replay-verify.md` | `runs/6a30b4c9/blackbox-verify-1646.txt` |
| A-COMBAT-05, stray beams before and after | late fires 12.8% to 0.5% in the scripted set; Orb's 5220 beam dropped | `a-combat-05-stray-beams.md` | `runs/6a30b4c9/stray-beams-*` |
| A-CODE-02, the batch as shipped | main cf909e93: 69 PASS, 33 FAIL, 45 INFO, 68 PENDING | `a-code-02-shipped-batch.md` | `runs/cf909e93/` |
| A-PERF-07, memory at 5 and 30 minutes | objects flat; static memory 114 to 131.7 MiB, +44 MiB over the start after disposal | `a-perf-07-memory.md` | `runs/6a30b4c9/memory-read-5-and-30-minutes.md` |
| A-QA-03 and A-QA-07, the bug list | 52 of 52 accounted for, severities S1 to S4 | `a-qa-03-bug-list.md` | `qa/known-bugs.md` |

Not yet run: X-04's forms probe (with Simulation and Encounter, through the EP), the cityHold city read, A-AI-10 (the computer's perfect-block rate against charged attacks), the planet-sizes batch.
