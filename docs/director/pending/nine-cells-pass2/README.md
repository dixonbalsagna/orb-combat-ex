# The nine cells, pass 2: the charged medium, parked (2026-10-13)

Owner: Encounter Systems Director. Game Design's `docs/design/brawl-second-pass.md` sections 3 and 15, the nine cells' pass 2: a held Y is the charged medium, with its two changes (lights don't end it; at full it closes), and no blow of a held X can be perfect-blocked. **Built in scratch and read; not gated, and its proof rows are not run. Not applied.**

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
