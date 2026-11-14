# Horde trial T8: the clip's match files (scratch; never lands)

Encounter, 2026-11-15, sprint A1. These are the match files for the trial's clip (`docs/ep/proposals/horde-trial-design.md` section 9, clip 1).
- Each is one real Horde match from its start, with both pads scripted and a mark on each beat.
- Tools' clip kit cuts them: `node tools/clips/make.mjs --from-match <file> --build <a web build of the tree below>`.

**The tree:** the Horde trial's scratch git, commit `1aadbbd` ("horde trial T6 v2 + two-player keys + countMul 1.2"). That's main 5263c1a6 plus the trial: the sources in `../src/` with GD's two-player keys and count × 1.2. A Horde match starts from the file's own setup (`"horde": true`, planet 7), so the film hook doesn't have to start one.

| File | Ticks | Marks | Seconds marked | sha1 |
| :--- | ---: | ---: | ---: | :--- |
| `horde-clip-1.json`: it ends after the blast | 8,926 (2.5 min) | 3 | 34.5 | 28e230de0a9936b3d91f222cf38046c756285474 |
| `horde-clip-1-down.json`: the same match on to the first player down | 34,161 (9.5 min) | 4 | 43.5 | 9a60c99a69171a67c3415d326f8642a6ebd27b0f |
| `horde_clips.gd`: the recorder and its check (run from `sim/director/tools/` in the tree) | | | | 23500045aaecde2648795d81dbf15cc869111201 |

**Both files replay exactly on `1aadbbd`** (`horde_clips.gd --check=<file>`: first bad tick none, every checkpoint equal). Records are in `docs/director/runs/5263c1a6/horde-t8/`.

## The marks (seed 1)

| Window (ticks) | Seconds | What happens |
| :--- | ---: | :--- |
| 80 to 860 | 13.0 | **Wave 1, one pad:** weak fighters streak in at 3.2 × flat out and circle; an X string runs through them, and each replacement streaks in |
| 7,029 to 7,378 | 5.8 | **Wave 4, one pad:** a wind-up beaten by hitting first (7,269), then one guarded (7,318) |
| 7,583 to 8,526 | 15.7 | **Wave 4 on:** one dropped by a guard raised at the last moment (7,823); one that lands, the flinch (8,081); the second pad joins (8,082) and flies in under its own pad; a blast from seat 1 passes seat 0 and hits a weak fighter (8,436) |
| 33,538 to 34,078 | 9.0 | (`-down` file only) **Seat 1 goes down** (33,778). Seat 0 goes down 6 s later and the run ends |

## How the pads are scripted

- **Seat 0** is `horde_probe.gd`'s medium pad (4 presses a second, defends half) until the join, with one change: until one lands, it raises its guard 2 ticks before a wind-up lands and holds it. The medium pad's own strong block lands about twice a match, so it never showed in wave 4.
- **At the join, seat 0 lets go of its pad** (it stands still), so beat 5 can show a player going down.
- **Seat 1** is the medium pad from the join on. For the blast it holds RB and presses X with the partner between it and a weak fighter, holding the energy family through the wind-up. Both pads hold their blows for that second, so only the shot reaches the body.
- **The button strip** draws one pad: the kit picks the slot with the most inputs, which is seat 0. From the join on, seat 0's pad is idle, so the strip shows nothing in the join and blast window. If the strip should follow seat 1 there, it's Tools' call.

## Not in the clip, against the design's list

- **Beat 3, "B: one sent through a building", can't happen in this build.** A Horde B launches the body by the knock-out fallback's plain launch (`DirHorde._fell`), with no aimed building. A building is struck only by an aimed flight (`WorldBrunt.checkHit` reads `f.aimB`), so 25 B presses beside buildings struck none. The fix is to route the Horde's B through the launch planner: a small change to the trial's director half and a re-run of T3 to T6.
- **Beat 5's "the other finishes the wave; the first gets up" doesn't happen.** After seat 0 lets go in wave 4, seat 1 (the medium pad) carries a wave sized and toughened for two (count × 1.2, toughness × 1.5). It doesn't clear it in 7 minutes, and goes down first, at 33,778. Seat 0, standing still, follows at 34,160 and the run ends. In ten recordings over seeds 1 to 3, no wave was cleared after the partner let go. That's a finding for Game Design (Orb's question 4): with the two-player keys, a partner who goes down sinks the run.
- **Beat 6, the result screen,** is left out of the trial.
- **The first player goes down 5 to 8 minutes after the partner lets go** (seat 0 had about 1,490 hit points at the join). That's why the `-down` file is 9.5 minutes long.

## For Tools

- One capture at a time, through Tools' launcher. The `-down` file replays 9.5 minutes of a five-body match before its last mark: a long run, so below normal.
- The film variant's two jobs from the design's T8 row are Camera's many-body frame on and away bodies hidden. The Horde's render side was never walked (Camera's 37 sites, HUD 13, VFX 12), so five real bodies in the web build are unproven.
