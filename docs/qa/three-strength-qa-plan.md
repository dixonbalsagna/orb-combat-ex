# QA plan: the three-strength brawl and the walk-out (paper only, 2026-10-06)

QA & Balance. This is a plan and nothing is built: no harness change is made until the slice that carries a row exists (C1 for §A and §C, C2a for §B, C2b for the holds). Sources: `docs/design/brawl-second-pass.md` §1, §2, §3, §7 and §11; `docs/director/brawl-plan.md` (walk-out, 4.3x). The mirror, momentum and first-slot rows that §11 retires are listed in §D. No retune is proposed here: every band below is Game Design's.

How to read a row: **Band** is the pass range. **Kind** is hard test (exact, any failure is a FAIL), point (a rate against a band, 95% interval shown), or reported (INFO, no band). **Needs** is what the harness needs from the build, and **Script** the player that produces the evidence. Rate rows follow the standing rule: PENDING below the sample size named.

## A. The three buttons

| # | Row | Band | Kind | Needs | Script |
| :-- | :--- | :--- | :--- | :--- | :--- |
| A1 | Press to contact, X | 2 ticks, 95% inside 4 | point | cue `blow` carries the press tick (`press_ack` tick against the blow's contact tick); a tapped X in each exchange | tapper X, medium AI |
| A2 | Press to contact, Y | 12 ticks, never past 16 | hard | same, a Y tap | tapper Y |
| A3 | Press to contact, B | 28 ticks, never past 32 | hard | same, a B tap | tapper B |
| A4 | Every press starts its move within 10 ticks | 100% | hard | the existing Encounter measure (press to first move), now per button | all three |
| A5 | A tap read as a hold, by device | under 2% on pad and keyboard; under 5% on touch | point, one row per device | a device tag on the scripted press (`dev=pad|key|touch`): a tap's real length drawn from Controls' ranges (pad 3 to 6 ticks, keyboard 4 to 8, touch 5 to 12) with a seeded draw; the sim cue or intent that says "this press became a charge" (`charge_start` on a button that was released inside the 4-tick grace is the failure) | `tapper` gets `tap=` (its release length) and `dev=` |
| A6 | Unintended charge (EP's row) | reported with the sample, then banded when Game Design names the band: the share of a masher's presses (Y and B mashers, the two-finger masher, the alternator) that open a charge | reported, then point | the same `charge_start` cue | Y, B, alternator and the two-finger masher, 100 matches each |
| A7 | Presses of a scripted two-finger masher that read as a pair | under 5% | point | a pair press cue or intent reading (X+Y or Y+B pressed within a window); the script presses two buttons on alternate ticks | `tapper` kind `twofinger` |
| A8 | A press on a cell with no move gives `press_ack` empty | every one, never silent | hard | cue `press_ack` text `empty` | a script that presses RT with X, Y and A, and the martial arts A |

## B. The flurries, the burst and the masher rows

| # | Row | Band | Kind | Needs | Script |
| :-- | :--- | :--- | :--- | :--- | :--- |
| B1 | X flurry against Y flurry | X wins 55 to 75% | point, 200 matches | none beyond the three mashers | `masher kind=X` against `masher kind=Y`, both `clock=tick`, on the seeded start offset the mirror uses (`off=7` on one side) |
| B2 | Y flurry against B flurry | Y wins 55 to 75% | point, 200 | same | Y against B |
| B3 | B flurry against X flurry | B wins 55 to 75% | point, 200 | same | B against X |
| B4 | Each flurry's own pace | X one blow every 6 ticks, Y 12, B 28, at its fastest | hard | blow cues by button | each masher alone against a guard-only dummy |
| B5 | Damage a second is level within a button, rising between buttons | within 10% inside X, Y, B; X below Y below B | point | damage events by button | the three mashers against the medium AI |
| B6 | The burst against a mash over the same time | 70 to 80% of the mash's damage, never over | point (never over is a hard test) | `burst` blow cues (kind or a flag on `blow`) | `holder kind=X` (hold X) against a never-defending dummy, and the 8-tick X masher over the same 55 ticks |
| B7 | A held X finishes eight blows with the gaps 4, 4, 5, 6, 8, 11, 15 | exact | hard | `burst` blow ticks | the holder |
| B8 | A full charged heavy thrown into an X flurry lands | at least 80% while the flurrier keeps flurrying | point | `charge_land` and the blow's end cue | `holder kind=B` against an X masher; arrives with C2b |
| B9 | A shove ends a heavy that is winding or charging | at least 90% of the tries in reach | point | `shove` cue and the heavy's `lost` end | `tapper` A against the heavy winder; C2b |
| B10 | The masher against the medium AI | X masher 35 to 50% (kept); Y masher, B masher, the alternator and the X holder reported | point, then reported | masher `kind=` Y, B and a new `alt` (X, Y, B in turn) and `hold` kinds | `masher` extended with `btn=X|Y|B` and `alt=XYB` |
| B11 | The mix-up: any order across X, Y and B | reported: wins against the medium AI, brawl length and share | reported | none | `mix` kind with `mix=XYB` |
| B12 | The brawl's median length | 3 to 8 s as a first band (Game Design re-reads after C2b) | point | none | the AI against itself, and the pressing script |
| B13 | A failed option leaves him open | at most 20 ticks, and no added damage of its own | hard | `open` state ticks (cue or state read) after a whiffed heavy, a dodged tackle, a failed clinch | scripts that whiff on purpose: a heavy thrown out of reach |
| B14 | Ki spent a minute, by what it bought | reported: mediums, heavies, charges, power attacks, zips, signatures | reported | the per-tick ki drop sum I already read, split by the cue that preceded it | the AI, and the zipper |

Notes. B1 to B3 are the three-way rock, paper, scissors: if any of them reads under 55 or over 75 the cause is nearly always the tie (identical start ticks), so each is read with the seeded start offset and with the exact tie as a reported number, as I do for the lights mirror. The presses are counted on S.tick so a hit freeze does not slow a script (clock=tick is the default for these).

## C. The centre, the double hit and the walk-out

| # | Row | Band | Kind | Needs | Script |
| :-- | :--- | :--- | :--- | :--- | :--- |
| C1 | The centre moves within 2 ticks of a stick, in every state where the stick works | exact | hard | the brawl's centre in a state read (`inBrawl` plus a `centre` field, or the two fighters' positions); per fighter state: striking, charging, reeling from a light, guarding | a script that holds a stick from a seeded tick in each state |
| C2 | The stick does nothing in knock-back, launch, lift, hold, buried, set piece, and a stagger | exact | hard | same | same, in each state |
| C3 | The centre moves at most 0.3 bh in one tick | exact | hard | same | any brawl, scan every tick |
| C4 | How far a held stick moves a brawl against a rival who holds none | reported, in bh a second; 0.4 and 0.8 of free-flight speed are the design values | reported | same | two scripts, one holding a direction |
| C5 | The brawl never passes through a building face, and a drifting brawl never damages a building | none | hard | the centre against `WorldStructures.blockedAt`; building damage events during a brawl with no throw, tackle, launch or blast | the nudging script flown at a building |
| C6 | Double hits a match | 0.5 to 2 in AI matches; at least one in 40 to 70% of matches; never more than 4 in a match | point, 400 matches | `brawl_end` text `double` | the AI against itself |
| C7 | Every trade still level at 240 ticks ends in a double hit | all | hard | the trade's tick count (`trade_break` or a `trade_level` cue) against the `double` end | the lights mirror |
| C8 | The double hit's worth and aftermath | 4 brawl lights to each, thrown back 6 bh, brawl ends, nobody won a decisive exchange | hard | damage events at the double tick and the positions 40 ticks later | the lights mirror |
| C9 | Walk-out, the two-stick rule: both sticks away within 45 degrees for 12 ticks running end the brawl `walk` | exact (12 ticks, free, no wait after it) | hard | `brawl_end` text `walk` and its tick; the sticks' scripted ticks | `walker` script: both fighters hold away from a seeded tick |
| C10 | A blow thrown by either in those 12 ticks starts the count again | exact | hard | same | the walker, with one blow thrown at tick 6 |
| C11 | The 12 ticks count while either guards; they do not count while either has a blow on its way or an attack button held, or is reeling or staggered | exact | hard | same | the walker, with a guard held; with a held X; and a stagger |
| C12 | One fighter's stick alone never ends a brawl | no `walk` end in the one-sided case | hard | same | the walker with one stick only, 24 and 60 ticks |
| C13 | A boost held with the stick away is the escape, not the walk | the escape's price is paid, the end text is `escape` and not `walk` | hard | `brawl_end` text | the walker with one boost |

Notes on the walk-out. The EP's ruling (2026-10-06): only the one-sided walk-out is retired (a fighter let go after 24 ticks of holding away with nothing landing on him; withdrawn in `brawl-second-pass.md` §1). The mutual walk-out stays, so C9 to C13 are all live: both hold away within 45 degrees for 12 ticks, free; the count runs while either guards, and does not run while either has a blow on its way or an attack button held, or is reeling or staggered. C12 is the hard test that the one-sided rule does not come back.

## D. Rows retired or re-read by §11

| Row | What happens |
| :--- | :--- |
| The even lights-only mirror finishes (95%) | Retired. It is a stalemate by rule; reported, with how it ends (double hits to the KO, or the cap) |
| An uneven mirror, 8 ticks against 10 | New: finishes at least 95%, the faster tapper wins at least 80%. Brink to KO 25 to 50 s read here. My `fast-slow` pair (6 against 12) is the nearest and gets re-pointed |
| Level trades that change who has the momentum; wins from the first slot | Retired with the draw. The first-slot read stays as a reported number on the tickoff mirror, since a slot effect would still be a bug |
| Knock-backs 60 to 75% and launches 25 to 40% of separating endings | Re-read after C2b with double hits as a third kind |
| Per-exchange rows already re-based | Unchanged |

## E. Harness work, in the order it is needed

1. **Before C1:** none beyond the baseline on 53d13b55. (The walker and the centre rows need the centre's state to be readable first. I ask Encounter for the field name, not the other way round.)
2. **With C1:** the walker script, C1 to C13, the `double` end, a `masher` stage for the double-hit rate, and the retirement of the momentum and finish rows in `masher.js` and `bands.js`.
3. **With C2a:** `masher` gets a button (`btn=`), the alternator (`alt=`), the holder kinds and the burst script; rows A1 to A8 and B1 to B7, B10, B11. `tapper` gets `tap=` and `dev=`.
4. **With C2b:** B8, B9, B13 and the unintended-charge row A6.
5. Each step lands with a synthetic self-test first, as the zip rows did.

## F. What I need from the build, collected

- `blow` and `press_ack` cues with the press tick, the button and the contact tick (A1 to A3).
- A cue or state for "this press became a charge" (A5, A6) and for a pair press (A7).
- `brawl_end` texts `walk`, `double`, `escape` and the tick counts for each (C6 to C13).
- The brawl's centre position, or the two fighters' positions each tick (readable already) plus the state they are in (C1 to C5).
- An `open` tick count after a whiff (B13).

## G. Harness state, 2026-10-06 (built in `qa/`, no Godot batch run; scripts smoke-tested on a scratch export at 2 matches, every row PENDING on a build with no C1)

Built against the cues and reads that `docs/director/brawl-plan.md` §9.2 promises, so the names are the plan's and must be confirmed when C1 lands:

| Plan row | In the harness | Reads |
| :--- | :--- | :--- |
| C1, C3, C4 | `c1.centre.latency` (hard, at most 2 ticks), `c1.centre.step.one` and `.both` (hard, 0.3 bh), `c1.drift.one` and `.both` (reported bh a second) | `DirBrawl.centre(S, ex)` returning `x`, `y`, `vx`, `vy` (the plan's keys); pairs `c1-drift-one` and `c1-drift-both`: lights mashers, one or both holding east from 24 ticks into a brawl for 60 ticks (`drift=east`) |
| C6 to C8 | `double.perMatch` (0.5 to 2), `double.matchesWith` (40 to 70%, at least 100 matches), `double.max` (at most 4, hard), `double.cue` (a double_hit cue for every double end, hard), `double.both` (both fighters take damage on the landing tick, hard), `double.after` (damage and separation 30 ticks later, reported) | the `double_hit` cue (`n` the landing tick) and `brawl_end` text `double`; the AI's default arm |
| C9 to C13 | `c1.walk.both`, `.jab`, `.guard` (hard: never under 12 ticks after the later stick or the jab press; the walk must happen), `.held` and `.one` (hard: no walk end at all) | `brawl_end` text `walk`; pairs `c1-walk-*`: both players hold away from 24 ticks into a brawl and stop pressing (`walk=1`), with `jab=6`, `wguard=1`, `wheld=1` as variants; the 12-tick floor is measured from the later stick or the jab's press tick, a lower bound that a blow cue could not give |
| C7 (every trade level at 240 ticks ends in a double) | **PENDING, not built**: it needs the trade's tick count on a cue (`trade_break` carries `amount` and `n` today; the double path has no equivalent) | ask Encounter for the level trade's tick on `double_hit` |
| C2 (the stick does nothing in a knock-back, launch, lift, hold, buried, a set piece, a stagger) and C5 (building faces) | not built: they need a script that holds a stick in each state | with C2a or after |
| the drop | `zip.drop` (hard; the hooked shot) and `zip.drop.bolt` (a real bolt; a coverage gap is PENDING, never a pass) | `drop_start`, `drop_land`, `drop_end` are **event types of their own** (`sim/core/fx.gd`), not cues, which the zip rows had read as cues until this batch: the earlier "0, 0, 0" in the baseline was that, and not only the missing coverage |

The drop row, what was found. A real bolt cannot reach a zipper on his way out in practice: the way out is 3 to 10 ticks, a bolt needs 6 to leave, and the zip's reach is itself a brawl, in which an energy press is a link and not a bolt. So the hard row (`zip.drop`) reports a shot of power 1 to `DirZip.shot` on a tick of the way out (`turret:...:hook=1`), the way Encounter's own check does; a second pair (`zip-turret`) fires real bolts with chance 25% a tick whenever no exchange runs, and reports how often one lands on the way out. On the build at 53d13b55, the hooked shot gives `zip_end down`, one `drop_start`, one `drop_end` and the state `dropped` in between. **`drop_land` did not fire in 3 of 3 drops** (the zipper was on the ground at the time, I suppose), so the row asks for one start and one end for each down, and reports the lands; Encounter to say whether a drop that begins on the ground should land.
