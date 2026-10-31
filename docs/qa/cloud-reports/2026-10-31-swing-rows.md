# The turntable rows, and a read of what stacks now (QA, 2026-10-31)

Brief: the EP's work order for the playable with the swinging world and the right hand. Rows prepared against `docs/world/ring-any-angle/game-design.md` sections 10, 11, 13, RL-213 to RL-217 and `docs/combat/pending/stick`; a first run on what stacks now. Paused at the EP's machine order (96% load, 26 Godot processes): nothing of mine is running.

## The rows (qa/godot/swing-rows.js, wired into bands.js; selftest 33 passed, qa/run-all.js green)

`records.gd` keeps every `swing_*` and `nudge*` event or cue (and `arena_turn`) as `rec.swings`. The rows read it and are **PENDING until the sim sends those events** (no `DirSwing` yet; `simulation.md` names `swing_start` / `swing_rest`, `encounter.md` a cue of the same name: both are read).

| Row | Band | Source |
| :--- | :--- | :--- |
| `swing.share` | 10 to 15% of fight time | game-design section 11 |
| `swing.big` / `swing.jolts` | 6 to 12 / 20 to 40 a match | sections 2, 10 |
| `swing.cause.max` | no cause over 50% of a match's big swings (QA's first value: at least 90% of matches with 6 or more big swings) | section 11 |
| `swing.causes3` | three causes or more in most such matches (over 50%) | section 11 |
| `swing.size.bin` | no 30 degree band over half (at least 90% of such matches) | section 11 |
| `swing.biomes` | biomes seen at least +1 a match against the same seeds with swings off; needs an arm `swingsoff` | section 11 |
| `swing.gap.min` | reported | section 10 |
| `swing.toll.assoc` | civilian toll against big swing count and swing time: fails if either 95% interval of r is wholly above 0 (RL-215) | section 11 |
| `swing.civless` | civilians removed swings the same number of times, within one; needs an arm `nocivs` | section 11 |
| `nudge.turn.place`, `nudge.turn.10s`, `nudge.rate` | hard: at most 6 degrees a place, 10 in any 10 s, 3 degrees a second | section 13 |
| `nudge.lines`, `nudge.toll.assoc` | about 2 to 5 lines a match; no positive association (RL-216) | section 13 |
| `hunger.toll.assoc` | no association (RL-217); needs the Cyborg's Hunger stat | section 14 |
| `arena.turns.max`, `arena.turns.gap` | the existing calm turn: at most 4 a match, 60 s apart (hard) | rings.json turn |
| `stick.balance`, `stick.claw` | win rate within 3 points of the default arm with an arm `stick`; the claw gate is Controls' (`strike_gate_test.gd`) | right-hand rulings |

QA's choices where the page gives no number are in each row's text (the 90% for the variety rows, "wholly above 0" for an association). They are first values for Game Design to confirm. The walls and face rows are `10.reach` (hard, below) and `plane_read`, which I did not fold in: it runs as its own 30-match job and the machine order stopped it.

## What stacks now (HEAD a1b8bfd8; biome, floor and the standing overlay on; gen 2; 200 matches)

Two arms: floor and biome on (hS0), and the same with `rings.json` `turn.on` (hS1). **They are identical to the match: `turn.on` alone turns nothing.** `sim/director/calm.gd` also needs `data/director/interrupts.json` `calmTurn.enabled` (false), and tools/preview's `turn` switch flips only the first. With both on, a two-match test showed 3 and 2 turns, so the preview's turn switch is a no-op for a match as it stands (Tools). A full arm with both on was started and stopped at the EP's order; nothing from it is reported.

| Row (band) | 10-30 floor on (7f5d14ab) | HEAD a1b8bfd8 |
| :--- | :--- | :--- |
| Match length median / p10 / p90 | 403.0 / 308.2 / 547.4 | 386.9 / **304.0** / 502.2 |
| `10.reach` (hard) | 2 of 427,048, longest 78.8 | 2 of 426,748, **longest 98.6** |
| PROP SMASH picked where offered (5 to 30%) | 8.0% | 7.6% (3.8 to 11.5) |
| Bounces / long journeys | 1.93 / 17.4% | 1.86 (1.73 to 2.01) / 16.1% |
| Structures on the ring | 80.5 | 80.5 |
| `zip.price.kept` | 334 of 334 | 334 of 334 |

Rows 88 PASS, 23 FAIL (the lake-floor read had 90 and 21). The status changes are all at an edge: `10.brawl.share` 50.6% against 50, `8.survival` 27.3% (22.3 to 32.8) on the interval rule, `7.beamEscape` 23.8% (17.6 to 31.3), `7.chain` back to 10.04. The other FAILs are the same set as the 10-30 read (5b.perMin, 5c landing mix, 5c.bounced, 5c.lip, 5c.terrain, 10.reach.height, zip.countered, 8.lock.median, mood.frenzied, mood.act4, 10.exPerMin, 10.end.launch, 10.end.continue, chase.perMatch, mood.act4beforeBrink).

### Already wrong

1. **`10.reach` is worse: the longest strike beyond reach went from 78.8 to 98.6 units** (still 2 in 426,748). Encounter has it. The longer figure is a reason to read it before the floor goes on.
2. **The preview's `turn` switch does nothing for a match** (needs `calmTurn.enabled`). Tools.
3. **Nothing of the swing, the nudge or the stick exists in the sim yet,** so those rows read PENDING; the stick strikes are not thrown (Encounter's hook), and `strike_gate_test.gd` and the right-hand work are in the working tree and not on HEAD, so I could not run the claw gate on a clean copy.
4. Last session's note stands: ten planets and four touches are a sample; the runs were under the other sessions' load (73 to 100%), valid by determinism, nothing capped.

---

SUMMARY: The turntable, nudge, toll-association, arena-turn and stick rows are built and tested, PENDING until the sim sends swing events. On what stacks now the table is the 10-30 read at the edges; `10.reach` is worse (longest 98.6) and the preview's turn switch does nothing alone.

CHANGES: `qa/godot/swing-rows.js` (new), `bands.js` (call), `records.gd` (keeps swing, nudge and arena_turn events), `selftest.js` (two cases), this report.

NEEDS FROM EP: Tools: the preview `turn` switch also needs `interrupts.json` `calmTurn.enabled`. Encounter: `10.reach`. Controls/EP: land the right-hand work so the claw gate can run on a clean copy.

RISKS: Event names for swings and the nudge are read from the pages and may differ in the code; the variety first values are mine.

NEXT: Paused at --jobs=1 or nothing; full batches (`swingsoff`, `nocivs`, `stick` arms and the 30-match `plane_read`) when swings land.
