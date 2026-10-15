# The nine cells, pass 2: the charged medium, parked (2026-10-13)

Owner: Encounter Systems Director. Game Design's `docs/design/brawl-second-pass.md` sections 3 and 15, the nine cells' pass 2: a held Y is the charged medium, with its two changes (lights don't end it; at full it closes), and no blow of a held X can be perfect-blocked. **Built in scratch and read; with the seventh round on it (below), gated on main. Not applied.**

## What is built (`r2.cjs`, on the nine cells' chain)

- **A held Y charges.** From `medium.charge.fromTicks` (16) of its hold, full at `fullTicks` (24); it goes `landTicks` (4) after he lets go, and by itself at `maxTicks` (40). Worth 3 to 4 as it fills, 4 ki in all, a reel of 10. At full it closes: he staggers for `staggerTicks` (12) as from a flurry's close, whatever his run and the rival's close guard. Its piece is picked again from the `mediumHeld` cell when the charge begins.
- **It ends a charging heavy, always:** no armour holds a charged medium.
- **A held X's blows can't be perfect-blocked:** they carry `noPerfect`, read where the perfect block's window is opened (`DirInterrupt._windowBeat`, `_windupShowing`).
- **Data:** `brawl.medium.charge` in `data/director/interrupts.json`. One optional schema key for Tools (`schema10.cjs`).

**To build:** on a checkout with the chain (`../nine-cells-chain/`), `node r2.cjs <root>` then `node schema10.cjs <root>`. It applies with or without the planner's levers. On main 8e2ee750 with the chain and the levers the validator is clean, the import is clean and about 500 matches ran with no script error.

## What it read (the chain with the levers and pass 2, against the medium AI)

| Row | Without pass 2 | With | Band |
| :--- | ---: | ---: | :--- |
| Y held, QA's holder (26 ticks down, 6 up), 60 matches | 0 | 0 | |
| His own closes a match | 0 | 59 | |
| What he deals and takes a match | 4,404; 9,783 | 3,569; 10,810 | |
| The three buttons in turn (QA's mix, 60 matches) | 7 | 5 | |

**Not read:** X held and X mashed with `noPerfect` in; the edges; the proof rows (a full charged medium held through lights lands and closes at least 80% of the time when no medium answers; it ends a charging heavy every time; no blow of a held X is perfect-blocked).

## Why the Y holder closes 59 times a match and wins nothing

Every charge he starts in a brawl, followed to its end (my probe, his hold counted in live ticks as QA's is; 20 matches; 345 charges a match).

| What became of the charge | A match | Share |
| :--- | ---: | ---: |
| It missed: the AI gave ground | 96 | 28% |
| His press came to nothing: it lapsed, or no blow was thrown | 87 | 25% |
| The AI's close took it (its fourth light staggers him) | 61 | 18% |
| It landed and closed | 51 | 15% |
| It was blocked | 26 | 8% |
| A heavy's stagger took it | 14 | 4% |
| The brawl ended; it landed short of full; a perfect block | 10 | 3% |

- **The AI walks out of it.** A charged medium lands 28 ticks after the press, as slow as a heavy, and reaches 0.5 bh, a tap's reach. Every miss carries the cue's own reason, `gave_ground`. With his stick held toward the rival while he charges, the misses are the same (97 a match, 25%).
- **A miss costs the next charge too.** He is open for 20 ticks after it, and his next press falls inside them.
- **"Lights don't end it" holds one light at a time, and the fourth ends it.** The rival's run closes on him while he charges, and the stagger takes the charge.
- **So he is hit for the whole match and answers one time in seven.** He takes 2,250 a minute and deals 700, or 920 with his stick toward. He reaches the brink first every time, and a close by the fighter on the brink wins nothing.
- **The worth is not his lever.** At a full worth of 5.5 he wins 0 of 60 (deals 4,474, takes 10,492). With the close's stagger doubled to 24 as well, 0 of 60 (4,940; 10,464).

**What would answer the causes,** for Game Design; none is built: a charged medium's reach that grows as it fills, as the heavy's does; the AI's share of giving ground against a medium's charge; the open window after a charged medium's miss; a run that doesn't close on a fighter whose charge has begun.

## The seventh round on it (2026-10-14): `s7.cjs`, after `r2.cjs` and `schema10.cjs`

Game Design's `docs/design/brawl-second-pass.md` section 14, "The seventh round", takes three of the four causes above and gives the fourth to the AI. Built and read in scratch on main 6adf1f26 (3198301f's sim and data). Where it and pass 2 overlap, this is the build: `node r2.cjs <root>`, `node schema10.cjs <root>`, `node s7.cjs <root>`.

| Rule | As built |
| :--- | :--- |
| While he holds a charge, the rival's lights add nothing to the rival's run | A light (a tap, a flurry blow, a held X's, a bolt) that lands on a fighter whose wound blow is charging with its button down adds nothing to the run of the fighter who landed it. Its damage, and what it takes off his own run, are as before. A medium or anything heavier still ends the charge, and so does a close from anything else |
| A charged medium's reach grows as it fills | From `medium.reachBh` (0.5) to `medium.charge.reachBh` (1.0) at full, as the heavy's does; a medium let go from a charge steps through that reach |
| A missed medium leaves him open for 12 ticks | `medium.recoverWhiff` 20 to 12, tapped or charged; a heavy stays 20 |
| The AI's giving ground against a medium has its own share | `giveVsMediumCharge` 0.05, 0.25, 0.4 by level, under `giveGround` (0.1, 0.45, 0.7). A medium reaches the AI's reaction time only when it is held, so this is its share against a charge. The keyed draw is the same one: against a heavy nothing moves |
| The full charged medium's worth is 4 | As pass 2 has it |

**Schema keys for Tools:** `medium.charge.reachBh`, and `giveVsMediumCharge` in each level's brawl block (`s7.cjs` adds them after `schema10.cjs`).

| Row | Pass 2 | With the seventh round | Bound |
| :--- | ---: | ---: | :--- |
| QA's Y holder against the medium AI (60 matches) | 0 | 1 | Under a tenth: read on its proof rows (Game Design) |
| What he deals and takes a match | 3,569; 10,810 | 8,061; 11,997 | |
| His closes a match | 59 | 120 | |
| **The proof row:** full charges held through a flurry of lights that land and close (a lights-only masher, no medium answers; 20 matches) | | **99.6%** (243 of 244 a match) | At least 80% |
| Full charges against the medium AI that land and close; that miss (it gave ground); that are blocked (20 matches) | | 45%; 31%; 22% (235 full of 392 charges a match) | |
| The three buttons in turn (60 matches) | 5 | 6 | |

**On the default arm** (QA's harness, 100 matches): median 448 s, 10th percentile 329 s, brink to KO 86 s, limb breaks 0.42 a match, act 4 before the first brink in 89% of matches, people lost 21.2%, front-row structures 36.8%. 96 rows pass and 12 fail, no hard test among them. The X masher against the medium AI reads 50 of 100, as on main.

**Gates on main with pass 2 and the seventh round: 35 of 36.** The golden regenerated (it moves), npm, parity, the validator and its self-test, determinism plain and with intros, the seam sweep, `anim_check`, `joint_scan` and `held_scan` `--strict`, the cue, read and HUD checks, `brawl_cases.gd`, World's five, QA's run-all, the flash count, the mash probe, the nine input tests and the loader on 200 matches pass.
- **`lead_scan --strict` fails: 5 frames, feet first and not a tumble, of 8,002 fast frames.** A lip launch (two frames), a bounce with the heavy's charge pose still held, a quick get-up with the light's charge pose still held, and a knock-back's drift. The same seeds read 0 on main with the town levers. None of the five is the charged medium's own blow; the matches are different matches. Animation's to read, before this goes in.

**Not done:** Game Design's alone row says that under a tenth the Y holder is read on his proof rows alone. He reads 1 of 60, and the proof row reads 99.6%.
