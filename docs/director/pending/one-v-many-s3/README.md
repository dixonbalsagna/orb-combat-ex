# One versus many, stage 3: the interjection and the guards' rules, parked (2026-10-15)

Owner: Encounter Systems Director. Stage 3 of `docs/director/one-v-many.md`, to Game Design's rulings in `docs/design/empress-guards.md` section 5. It goes on stage 2 (`../one-v-many-s2/`), which goes on Simulation's stage 1 (`docs/architecture/pending/n-bodies/`). **Built, read and gated in scratch on main ab1d5e24 with stages 1 and 2. Not applied.**

## To build it

On a checkout with stage 1 applied: `node s2.cjs <root>` from this folder (it copies this folder's `ring.gd`, stage 3's `DirRing`), then `node s3.cjs <root>`, then an import. Every anchor is exact text, and each script stops at the first one missing.

| File | Change (all inert with two bodies) |
| :--- | :--- |
| `sim/director/ring.gd` | `DirRing`, stage 3: the interjection (`_interject`, `_schedule`, `_pull`, `landX`), a guard's step in on a tag (`_stepTag`), the partner's hold (`holds`, `interjecting`), `isGuard` |
| `sim/director/brawl.gd` | A ring beat (`args.a` "X") lands in `DirRing.landX`; `_free` reads the ring's hold; a guard's blows build no run; a guard's launcher is never ready, and his charged heavy, send or knock-back staggers instead; the double hit and a held X's burst wait out the hold |
| `sim/director/exchange.gd` | An exchange doesn't start for a held partner (the request waits in the queue; it isn't lost) |
| `sim/director/melee.gd` | A guard's win in a planned exchange leaves the one in reach (no launch, no knock-back) |
| `sim/director/launch.gd` | `knock`, `knockBack` and `doLaunch` send nobody for a guard |
| `sim/director/blast.gd`, `bury.gd` | A guard in the ring never fires: his blast, his mine, his buried follow-up |
| `sim/director/interrupt.gd` | The perfect block's window reads no staleness for a ring beat |
| `data/director/interrupts.json`, its schema | `brawl.ring`: the step in (`tagStepTicks` 12, `tagStepBh` 0.3, `tagStepSpeed` 4000) and `interject` |

## As built

**The interjection.**
- **The grant.** Granted on an opening the one gave: open after his own miss, or staggered where he stands (not sent). At most one in `everyS` (1.5 s), to the nearest free guard in the ring. Not while the partner holds a blow past its wind-up, nor when the partner's blow is due within `clearTicks` (8) of where it would land.
- **The blow.** The guard moves in at the lunge's speed (`inTicksMax` 12 at most) and follows the one while his blow winds up in sight, `windTicks` (10). It lands as a beat of the partner's brawl that names him (`args.a` "X", `args.who`). So it is guarded, chipped and perfect-blocked by `DirMelee.strike` as any blow is. It is a light at `worthMul` (0.5) of a principal's, the one reels at most `reelTicks` (2), and it freezes as a light does. It builds no run and sends nobody.
- **Never within 8 ticks of the partner's blow.** An AI partner's line waits for it, from the grant to `clearTicks` after it lands: his presses are held, his new exchange waits, his double hit and his held X's burst wait.
- **A player partner is never held** (Game Design, 2026-10-15, d7831fad). Her guards interject only while her own line is committed past the landing and `clearTicks` more: a blow of hers on its way that lands after it, or a stagger or a reel that holds her until then (`DirRing._committedUntil`). A charge she holds doesn't count, since it lands whenever she lets go. If her blow comes due near it anyway, the guard yields (the grant is pulled).

**The guards' rules (Game Design's section 5).**
- **What guards never do.** A guard closes on the one never, launches him never, knocks him back never: his blows build no run, his B in an opening is the hammer, and his win in a planned exchange leaves the one in reach.
- **Tags.** The one's run is carried across a tag; the new partner's is fresh. The Empress (slot 1) as partner has no slice. A guard made partner by a tag steps in to striking distance (`tagStepTicks` 12 at most, at the lunge's speed).
- **The ring.** A guard in the ring never fires.

## What it read

`probes/ring3.gd` (the AI on every body) and `probes/ring2.gd` (the one a scripted player: X every 8 ticks, stick toward his partner), 4 and 3 matches of up to 5 minutes for each count, seeds 1 to 4.

| Row | 3 bodies | 4 bodies | 5 bodies | Bound |
| :--- | ---: | ---: | ---: | :--- |
| The 1v1 golden; parity (55); determinism plain and with intros; `brawl_cases`; the read check; the validator's self-test | Byte-identical; all pass | | | |
| A match played twice | The same hash | The same | The same | The same |
| **Blows from two fighters landing on him within 8 ticks** | **0** | **0** | **0** | Never (hard) |
| **A guard closing on, launching or knocking back the one** | **0** | **0** | **0** | Never (hard) |
| **A ring guard's blow landing without a grant** | **0** | **0** | **0** | Never |
| Interjections granted; landed; missed; pulled | 73; 54; 12; 7 | 46; 33; 2; 11 | 52; 37; 3; 12 | |
| Granted interjections that land | 74% | 72% | 71% | At least half |
| Blows that land on the one, a second of brawl | 5.58 | 5.37 | 5.25 | About a 1v1's (5.76) |
| The brawl's share in hit freeze | 26.4% | 26.4% | 25.7% | Under 32% |
| The scripted one's blows a press (a 1v1: 0.788) | 0.781 | 0.761 | 0.803 | About a 1v1's |
| The cost a tick, mean and 99th percentile | 428 µs; 1.19 ms | 489 µs; 1.26 ms | 561 µs; 1.37 ms | |

- **Every hard row reads zero.** Getting there closed five ways a partner's blow could land beside an interjection: a tag at the wrong moment, the brawl's own free-line tick (the flurry lowers it), a new brawl's first blow, the double hit, and a held X's burst.
- **The one is hit as in a 1v1 and stands in freeze as long,** with the interjections in.
- **His presses work as in a 1v1 again** at 4 and 5 bodies, now that a guard steps in on a tag (stage 2 read 0.68 and 0.70).
- **The cost rose by about 80 to 110 µs a tick over stage 2.** At 4v1 it is 561 µs, still under the paper's 0.92 ms estimate.
- **About 2.7 interjections land a minute of fight at 3v1.** Whether that reads as "the gang punishing a mistake" is Game Design's and Orb's to judge in play.

**With a player as the partner** (`probes/ring4.gd`: slot 1 is a scripted player, X every 10 ticks and B held 34 ticks every 60, his stick toward the one; the one and the guards are the AI; 4 matches of up to 5 minutes for each count).

| Row | 3 bodies | 4 bodies | 5 bodies |
| :--- | ---: | ---: | ---: |
| Ticks the ring held her line | 0 | 0 | 0 |
| Blows from two fighters on him within 8 ticks | 0 | 0 | 0 |
| A guard closing on, launching or knocking back the one; a stray ring blow | 0 | 0 | 0 |
| Interjections granted; landed | 4; 2 | 17; 11 | 13; 4 |

With the rule in, the AI-everywhere rows are as above (every hard row 0; 58, 36 and 46 interjections landed of 71, 57 and 63 granted), and the 1v1 golden is still byte-identical (parity 56 of 56, determinism). **Her guards go quiet with a player who keeps pressing:** about 0.1 to 0.55 interjections land a minute, where an AI partner gets 2 to 3. Game Design's fallback, if that is too quiet, is the hold as first built.

## Not built, and what is open

- **Not built:** a guard's covering volley as an interjection by bolt; a medium interjection (the data allows `kinds` ["medium"]; the first build throws lights); the Empress's orders; the resummon on a cooldown; a guard's KO not ending the match (stage 5, a few core lines of Simulation's).
- **For Game Design:** with a player who keeps pressing, her guards interject 0.1 to 0.55 times a minute (above). Whether that is too quiet is for play to show.
- **For Animation:** the interjection's tell is a `windup` cue with text `interject`, naming the guard and its landing tick; its blow is a `blow`-less beat (the brawl's own `blow` cue isn't sent for it). Animation reads which it needs.
