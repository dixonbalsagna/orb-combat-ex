# A hard impact still buries on dented ground (World, 2026-11-23)

Park: `docs/world/pending/globe-step2/bury-refused.md` (and `.diff`, the two grants). Tree: main a345a380 plus the stack of `docs/ep/reviews/GW1c-stack.txt` (my copy), headless, one Godot at a time, below normal.

| File | What |
| :--- | :--- |
| `world-checks-7.txt` | `burial_check`, `craters_check`, `globe_check`, `bury_check`, `tier_ratio_check`, `relief_cap_check`, `crater_flatten_check` on the fixed stack through the gate's verdict: all pass |
| `bury_check-negative-control.txt` | `BURY` with the fix off: 4 of 16 rows fail (the three burying slams and the embed depth) |
| `parity-stack-without-fix-vs-target.txt` | The stack as it stood, against `golden-target.json`: passes (0 FAIL) |
| `parity-fix-vs-target.txt` | The stack with the fix: three matches fail on the per-tick digest, checkpoints agree |
| `parity-fix-event-off-vs-target.txt` | The same with the new event made a no-op (the bury alone): two fail, mirror-villain seed 1 (same digest) and swap-flip seed 2 (a different digest); default seed 11 passes, so it is the event alone that moves that one |
| `bury_probe4.gd.txt` | The first probe of the bury (before the sit depth was added) |
