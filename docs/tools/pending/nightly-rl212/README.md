# nightly-rl212 (Tools, 2026-10-30): Legal's RL-212 tripwires and the clash clip in the nightly

`git apply docs/tools/pending/nightly-rl212/nightly-rl212.patch` (3 files, applies to HEAD, which holds the RL-208 nightly; verified with `nightly-selftest.mjs`, 84 checks, then reversed).

- **RL-212**: on a REDUCED clip the take-down also fires on an **area-15% reading over 4.5** (`AREA15_TRIP`, no worse than ai-1049-reduced's 4.5 at 960x540). The primary over 3.5 stays the trigger (at either size once `pin-child-readings` lands: the nightly reads the worst of the readings taken). A reduced clip **at** 3.5 on the primary is a finding: `AT THE LINE` in the report line (RL-212 (5): a pin move waits until it is explained). A normal clip's area reading is not a trigger.
- **The clash clip joins the nightly's fixed clips** (the EP): `clash-normal` and `clash-reduced` run every night with the signature clip (one second launcher run), counted among the night's clips and read like a seed clip.
- `docs/tools/site-interim.md`: the RL-212 and clash bullets and the self-test count.

Order with the other parks: independent of `pin-child-readings` (the nightly reads `result` as before); with it, a seed is read at 16:9 full-size first and a night costs about twice as long only for the fixed clips and for any seed at 2.5 or more.
